import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/models/wallet_models.dart';
import 'package:smartstitch/services/wallet_brevo_service.dart';
import 'package:smartstitch/services/wallet_service.dart';
import 'package:smartstitch/services/stripe_connect_service.dart';
import 'package:smartstitch/core/widgets/card_input_widgets.dart';

class WalletController extends GetxController {
  static WalletController get to => Get.find();

  final WalletService _service = WalletService.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── OBSERVABLES ───────────────────────────────────────
  final Rx<RiderWallet?> wallet = Rx(null);
  final RxList<WalletTransaction> transactions = <WalletTransaction>[].obs;
  final RxList<WithdrawalRequest> withdrawalHistory =
      <WithdrawalRequest>[].obs;

  final RxBool isLoadingWallet = false.obs;
  final RxBool isLoadingTransactions = false.obs;
  final RxBool isSubmittingWithdrawal = false.obs;

  // ─── Stripe Connect ───────────────────────────────────────────────────────
  final RxBool isLaunchingStripeOnboarding = false.obs;
  final RxnString stripeAccountId = RxnString();
  final RxBool isPayoutReady = false.obs;

  // Withdraw form — CARD-based (bank fields replaced)
  final RxDouble withdrawAmount = 0.0.obs;
  final amountController = TextEditingController();
  final accountTitleController = TextEditingController(); // → Card Holder Name
  final cardNumberController = TextEditingController();   // full number, local only
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();
  final notesController = TextEditingController();
  final withdrawFormKey = GlobalKey<FormState>();

  // Kept for backend compatibility — populated automatically at submit time
  // from card data (masked last-4 + detected brand). Never holds raw card data.
  final accountNumberController = TextEditingController();
  final bankNameController = TextEditingController();

  final RxBool isCvvFocused = false.obs;

  // Streams
  StreamSubscription? _walletSub;
  StreamSubscription? _txSub;
  StreamSubscription? _historySub;

  // ─── CURRENT RIDER ──────────────────────────────────────
  String get riderId => _riderId;
  String get riderName => _riderName;
  String get riderEmail => _riderEmail;

  String _riderId = '';
  String _riderName = '';
  String _riderEmail = '';

  // ─── LIFECYCLE ─────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _initFromAuth();
  }

  Future<void> _initFromAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('❌ WalletController: no logged-in user, cannot load wallet');
      return;
    }

    try {
      final doc = await _db.collection('riders').doc(user.uid).get();
      final data = doc.data() ?? {};

      setRiderInfo(
        id: user.uid,
        name: data['name'] ?? user.displayName ?? 'Rider',
        email: data['email'] ?? user.email ?? '',
      );

      final savedStripeId = data['stripeAccountId'] as String?;
      if (savedStripeId != null) {
        stripeAccountId.value = savedStripeId;
        isPayoutReady.value = await StripeConnectService.instance
            .isReadyForPayouts(savedStripeId);
      }
    } catch (e) {
      debugPrint('❌ WalletController init error: $e');
      setRiderInfo(
        id: user.uid,
        name: user.displayName ?? 'Rider',
        email: user.email ?? '',
      );
    }
  }

  void setRiderInfo({
    required String id,
    required String name,
    required String email,
  }) {
    _riderId = id;
    _riderName = name;
    _riderEmail = email;
    _startListening();
  }

  @override
  void onClose() {
    _walletSub?.cancel();
    _txSub?.cancel();
    _historySub?.cancel();
    amountController.dispose();
    accountTitleController.dispose();
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    accountNumberController.dispose();
    bankNameController.dispose();
    notesController.dispose();
    super.onClose();
  }

  void _startListening() {
    if (_riderId.isEmpty) return;

    _walletSub?.cancel();
    _walletSub = _service.watchWallet(_riderId).listen((w) {
      wallet.value = w;
    });

    _txSub?.cancel();
    _txSub = _service.watchTransactions(_riderId).listen((list) {
      transactions.value = list;
    });

    _historySub?.cancel();
    _historySub = _service.watchWithdrawalHistory(_riderId).listen((list) {
      withdrawalHistory.value = list;
    });
  }

  // ─── GETTERS ───────────────────────────────────────────

  double get availableBalance => wallet.value?.availableBalance ?? 0;
  double get pendingWithdrawal => wallet.value?.pendingWithdrawal ?? 0;

  PaymentMethod get selectedMethod => PaymentMethod.bankAccount;

  CardBrand get detectedBrand => detectCardBrand(cardNumberController.text);

  // ─── WITHDRAW FORM ──────────────────────────────────────

  void resetWithdrawForm() {
    amountController.clear();
    accountTitleController.clear();
    cardNumberController.clear();
    expiryController.clear();
    cvvController.clear();
    accountNumberController.clear();
    bankNameController.clear();
    notesController.clear();
    withdrawAmount.value = 0;
    isCvvFocused.value = false;
  }

  String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter an amount';
    final amount = double.tryParse(value.trim());
    if (amount == null) return 'Enter a valid amount';
    if (amount < 500) return 'Minimum withdrawal is Rs. 500';
    if (amount > availableBalance) return 'Exceeds available balance';
    return null;
  }

  String? validateCardHolder(String? value) => CardValidators.cardHolderName(value);

  String? validateCardNumber(String? value) => CardValidators.cardNumber(value);

  String? validateExpiry(String? value) => CardValidators.expiry(value);

  String? validateCvv(String? value) =>
      CardValidators.cvv(value, detectedBrand);

  Future<WithdrawalRequest?> submitWithdrawal() async {
    if (!(withdrawFormKey.currentState?.validate() ?? false)) return null;

    isSubmittingWithdrawal.value = true;

    try {
      final amount = double.parse(amountController.text.trim());

      // ── Build masked card info — full number & CVV never leave this
      // function or get sent anywhere. Only brand + last 4 are stored.
      final brand = detectedBrand;
      final rawDigits = cardNumberController.text.replaceAll(' ', '');
      final last4 =
          rawDigits.length >= 4 ? rawDigits.substring(rawDigits.length - 4) : rawDigits;
      bankNameController.text = brand.label;
      accountNumberController.text = '**** **** **** $last4';

      final request = await _service.createWithdrawalRequest(
        riderId: _riderId,
        riderName: _riderName,
        riderEmail: _riderEmail,
        amount: amount,
        paymentMethod: selectedMethod,
        accountTitle: accountTitleController.text.trim(),
        accountNumber: accountNumberController.text.trim(),
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      await WalletBrevoService.sendWithdrawalRequested(
        toEmail: _riderEmail,
        riderName: _riderName,
        withdrawalId: request.id.substring(0, 8).toUpperCase(),
        amount: amount.toStringAsFixed(0),
        paymentMethod: selectedMethod.label,
        accountTitle: accountTitleController.text.trim(),
        accountNumber: accountNumberController.text.trim(),
        requestedDate: _formatDate(request.requestedAt),
      );

      resetWithdrawForm();
      return request;
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceFirst('Exception: ', ''),
          backgroundColor: Colors.red.shade100);
      return null;
    } finally {
      isSubmittingWithdrawal.value = false;
    }
  }

  // ─── ADMIN ACTIONS ─────────────────────────────────────

  Future<void> adminUpdateStatus({
    required WithdrawalRequest request,
    required WithdrawalStatus newStatus,
    String? adminNotes,
  }) async {
    try {
      if (newStatus == WithdrawalStatus.paid) {
        final doc = await _db.collection('riders').doc(request.riderId).get();
        final accountId = doc.data()?['stripeAccountId'] as String?;

        if (accountId == null) {
          Get.snackbar('Error',
              'This rider has not completed Stripe payout setup yet.');
          return;
        }

        final payoutResult = await StripeConnectService.instance.sendPayout(
          accountId: accountId,
          amount: request.amount,
          idempotencyKey: request.id,
          currency: 'usd',
          withdrawalId: request.id,
        );

        if (!payoutResult.success) {
          Get.snackbar(
            'Error',
            payoutResult.errorMessage ??
                'Stripe transfer failed. Payout not marked as paid.',
          );
          return;
        }
      }

      // ✅ Now passing riderEmail/riderName so the service can send the
      // status-update email AND the in-app notification correctly —
      // previously these were left blank, so emails for paid/rejected
      // were silently being skipped.
      await _service.updateWithdrawalStatus(
        withdrawalId: request.id,
        riderId: request.riderId,
        amount: request.amount,
        newStatus: newStatus,
        adminNotes: adminNotes,
        riderEmail: request.riderEmail,
        riderName: request.riderName,
      );

      final now = _formatDate(DateTime.now());

      if (newStatus == WithdrawalStatus.approved) {
        await WalletBrevoService.sendWithdrawalApproved(
          toEmail: request.riderEmail,
          riderName: request.riderName,
          withdrawalId: request.id.substring(0, 8).toUpperCase(),
          amount: request.amount.toStringAsFixed(0),
          paymentMethod: request.paymentMethod.label,
          approvedDate: now,
        );
      } else if (newStatus == WithdrawalStatus.paid) {
        await WalletBrevoService.sendWithdrawalPaid(
          toEmail: request.riderEmail,
          riderName: request.riderName,
          withdrawalId: request.id.substring(0, 8).toUpperCase(),
          amount: request.amount.toStringAsFixed(0),
          paymentMethod: request.paymentMethod.label,
          accountNumber: request.accountNumber,
          paidDate: now,
        );
      } else if (newStatus == WithdrawalStatus.rejected) {
        await WalletBrevoService.sendWithdrawalRejected(
          toEmail: request.riderEmail,
          riderName: request.riderName,
          withdrawalId: request.id.substring(0, 8).toUpperCase(),
          amount: request.amount.toStringAsFixed(0),
          reason: adminNotes ?? 'No reason provided',
          rejectedDate: now,
        );
      }

      Get.snackbar('Updated', 'Status changed to ${newStatus.label}');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<String?> startStripeOnboarding() async {
    isLaunchingStripeOnboarding.value = true;
    try {
      String? accountId = stripeAccountId.value;

      if (accountId == null) {
        accountId = await StripeConnectService.instance.createConnectAccount(
          userId: _riderId,
          email: _riderEmail,
          name: _riderName,
        );

        if (accountId == null) {
          Get.snackbar('Error', 'Could not start payout setup. Try again.');
          return null;
        }

        stripeAccountId.value = accountId;

        await _db.collection('riders').doc(_riderId).set(
          {'stripeAccountId': accountId},
          SetOptions(merge: true),
        );
      }

      final url = await StripeConnectService.instance.createOnboardingLink(
        accountId: accountId,
      );

      if (url == null) {
        Get.snackbar('Error', 'Could not open payout setup form.');
        return null;
      }

      return url;
    } finally {
      isLaunchingStripeOnboarding.value = false;
    }
  }

  Future<bool> checkStripePayoutReady() async {
    final accountId = stripeAccountId.value;
    if (accountId == null) return false;
    final ready =
        await StripeConnectService.instance.isReadyForPayouts(accountId);
    isPayoutReady.value = ready;
    return ready;
  }

  // ─── HELPERS ───────────────────────────────────────────

  String formatCurrency(double amount) =>
      'Rs. ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hour:$min $ampm';
  }
}