import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartstitch/models/artist_wallet_models.dart';
import 'package:smartstitch/services/artist_wallet_service.dart';
import 'package:smartstitch/services/stripe_connect_service.dart';
import 'package:smartstitch/core/widgets/card_input_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArtistWalletController extends GetxController {
  static ArtistWalletController get to => Get.find();

  final ArtistWalletService _service = ArtistWalletService.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Observables ──────────────────────────────────────────────────────────
  final Rx<ArtistWallet?> wallet = Rx(null);
  final RxList<ArtistWalletTransaction> transactions =
      <ArtistWalletTransaction>[].obs;
  final RxList<ArtistWithdrawalRequest> withdrawalHistory =
      <ArtistWithdrawalRequest>[].obs;

  final RxBool isLoadingWallet = false.obs;
  final RxBool isLoadingTransactions = false.obs;
  final RxBool isSubmittingWithdrawal = false.obs;

  // ─── Stripe Connect ───────────────────────────────────────────────────────
  final RxBool isLaunchingStripeOnboarding = false.obs;
  final RxnString stripeAccountId = RxnString();
  final RxBool isPayoutReady = false.obs;

  // ─── Withdraw form — CARD-based ────────────────────────────────────────────
  final amountController = TextEditingController();
  final cardNumberController = TextEditingController();
  final cardHolderController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();
  final notesController = TextEditingController();
  final withdrawFormKey = GlobalKey<FormState>();

  // Kept for backend compatibility — populated automatically at submit time
  final accountNumberController = TextEditingController();
  final bankNameController = TextEditingController();

  // ─── Artist info ──────────────────────────────────────────────────────────
  String _artistId = '';
  String _artistName = '';
  String _artistEmail = '';

  String get artistId => _artistId;
  String get artistName => _artistName;
  String get artistEmail => _artistEmail;

  // ─── Streams ──────────────────────────────────────────────────────────────
  StreamSubscription? _walletSub;
  StreamSubscription? _txSub;
  StreamSubscription? _historySub;

  // ─── Init ─────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _initFromAuth();
  }

  /// Auto-loads the currently logged-in artist
  Future<void> _initFromAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('❌ ArtistWalletController: no logged-in user, cannot init');
      return;
    }

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};

      setArtistInfo(
        id: user.uid,
        name: data['name'] ?? user.displayName ?? 'Artist',
        email: data['email'] ?? user.email ?? '',
      );
    } catch (e) {
      debugPrint('❌ ArtistWalletController init error: $e');
      setArtistInfo(
        id: user.uid,
        name: user.displayName ?? 'Artist',
        email: user.email ?? '',
      );
    }
  }

  void setArtistInfo({
    required String id,
    required String name,
    required String email,
  }) {
    if (_artistId == id && _walletSub != null) {
      _artistName = name;
      _artistEmail = email;
      return;
    }

    _artistId = id;
    _artistName = name;
    _artistEmail = email;
    _startListening();
    _loadStripeAccountId();
  }

  void _startListening() {
    if (_artistId.isEmpty) return;

    isLoadingWallet.value = true;
    isLoadingTransactions.value = true;

    _service.syncWalletFromBookings(artistId: _artistId);

    _walletSub?.cancel();
    _walletSub = _service.watchWallet(_artistId).listen((w) {
      wallet.value = w;
      isLoadingWallet.value = false;
    }, onError: (_) => isLoadingWallet.value = false);

    Future.delayed(const Duration(milliseconds: 50), () {
      if (_artistId.isEmpty) return;
      _txSub?.cancel();
      _txSub = _service.watchTransactions(_artistId).listen((list) {
        transactions.value = list;
        isLoadingTransactions.value = false;
      }, onError: (_) => isLoadingTransactions.value = false);
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_artistId.isEmpty) return;
      _historySub?.cancel();
      _historySub = _service.watchWithdrawalHistory(_artistId).listen((list) {
        withdrawalHistory.value = list;
      });
    });
  }

  // ─── Getters ──────────────────────────────────────────────────────────────

  double get availableBalance => wallet.value?.availableBalance ?? 0;
  double get pendingWithdrawal => wallet.value?.pendingWithdrawal ?? 0;
  double get lifetimeEarnings => wallet.value?.lifetimeEarnings ?? 0;

  PaymentMethod get selectedMethod => PaymentMethod.bankAccount;

  CardBrand get detectedBrand => detectCardBrand(cardNumberController.text);

  // ─── Withdraw form ────────────────────────────────────────────────────────

  void resetWithdrawForm() {
    amountController.clear();
    cardNumberController.clear();
    cardHolderController.clear();
    expiryController.clear();
    cvvController.clear();
    accountNumberController.clear();
    bankNameController.clear();
    notesController.clear();
  }

  String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter an amount';
    }
    final amount = double.tryParse(value.trim());
    if (amount == null) return 'Enter a valid amount';
    if (amount < 500) return 'Minimum withdrawal is Rs. 500';
    if (amount > availableBalance) return 'Exceeds available balance';
    return null;
  }

  String? validateCardHolder(String? value) => CardValidators.cardHolderName(value);

  String? validateCardNumber(String? value) => CardValidators.cardNumber(value);

  String? validateExpiry(String? value) => CardValidators.expiry(value);

  String? validateCardCvv(String? value) =>
      CardValidators.cvv(value, detectedBrand);

  Future<ArtistWithdrawalRequest?> submitWithdrawal() async {
    if (!(withdrawFormKey.currentState?.validate() ?? false)) return null;

    isSubmittingWithdrawal.value = true;

    try {
      final amount = double.parse(amountController.text.trim());

      // Build masked card info
      final brand = detectedBrand;
      final rawDigits = cardNumberController.text.replaceAll(' ', '');
      final last4 =
          rawDigits.length >= 4 ? rawDigits.substring(rawDigits.length - 4) : rawDigits;
      bankNameController.text = brand.label;
      accountNumberController.text = '**** **** **** $last4';

      final request = await _service.createWithdrawalRequest(
        artistId: _artistId,
        artistName: _artistName,
        artistEmail: _artistEmail,
        amount: amount,
        paymentMethod: selectedMethod,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
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

  // ─── Credit Earning ────────────────────────────────────────────────────────

  Future<void> creditEarning({
    required String artistId,
    required String orderId,
    required double amount,
    String title = 'Order Earning',
  }) async {
    try {
      await _service.creditEarning(
        artistId: artistId,
        orderId: orderId,
        amount: amount,
        title: title,
      );
    } catch (e) {
      debugPrint('creditEarning error: $e');
    }
  }

  // ─── Admin: Update Status ─────────────────────────────────────────────────
  Future<void> adminUpdateStatus({
    required ArtistWithdrawalRequest request,
    required WithdrawalStatus newStatus,
    String? adminNotes,
  }) async {
    try {
      await _service.updateWithdrawalStatus(
        withdrawalId: request.id,
        artistId: request.artistId,
        amount: request.amount,
        newStatus: newStatus,
        adminNotes: adminNotes,
      );
      Get.snackbar('Updated', 'Status: ${newStatus.label}');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  // ─── Stripe Connect ────────────────────────────────────────────────────────
  Future<void> _loadStripeAccountId() async {
    if (_artistId.isEmpty) return;
    try {
      final doc = await _db.collection('artists').doc(_artistId).get();
      final savedId = doc.data()?['stripeAccountId'] as String?;
      if (savedId != null) {
        stripeAccountId.value = savedId;
        isPayoutReady.value =
            await StripeConnectService.instance.isReadyForPayouts(savedId);
      }
    } catch (e) {
      debugPrint('_loadStripeAccountId error: $e');
    }
  }

  Future<String?> startStripeOnboarding() async {
    if (_artistId.isEmpty || _artistEmail.isEmpty) {
      Get.snackbar(
        'Please wait',
        'Still loading your account info — try again in a moment.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }

    isLaunchingStripeOnboarding.value = true;
    try {
      String? accountId = stripeAccountId.value;

      if (accountId == null) {
        accountId = await StripeConnectService.instance.createConnectAccount(
          userId: _artistId,
          email: _artistEmail,
          name: _artistName,
        );

        if (accountId == null) {
          Get.snackbar('Error', 'Could not start payout setup. Try again.');
          return null;
        }

        stripeAccountId.value = accountId;

        await _db.collection('artists').doc(_artistId).set(
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

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String formatCurrency(double amount) =>
      'Rs. ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  String formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hour:$min $ampm';
  }

  @override
  void onClose() {
    _walletSub?.cancel();
    _txSub?.cancel();
    _historySub?.cancel();
    amountController.dispose();
    cardNumberController.dispose();
    cardHolderController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    accountNumberController.dispose();
    bankNameController.dispose();
    notesController.dispose();
    super.onClose();
  }
}