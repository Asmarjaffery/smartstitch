import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Withdraw Status Enum ─────────────────────────────────
enum WithdrawStatus { pending, approved, rejected, processing }

extension WithdrawStatusExtension on WithdrawStatus {
  String get label {
    switch (this) {
      case WithdrawStatus.pending:
        return 'Pending';
      case WithdrawStatus.approved:
        return 'Approved';
      case WithdrawStatus.rejected:
        return 'Rejected';
      case WithdrawStatus.processing:
        return 'Processing';
    }
  }

  Color get color {
    switch (this) {
      case WithdrawStatus.pending:
        return const Color(0xFFF59E0B);
      case WithdrawStatus.approved:
        return const Color(0xFF4CAF82);
      case WithdrawStatus.rejected:
        return const Color(0xFFEF4444);
      case WithdrawStatus.processing:
        return const Color(0xFF3B82F6);
    }
  }

  static WithdrawStatus fromString(String v) {
    switch (v.toLowerCase()) {
      case 'approved':
        return WithdrawStatus.approved;
      case 'rejected':
        return WithdrawStatus.rejected;
      case 'processing':
        return WithdrawStatus.processing;
      default:
        return WithdrawStatus.pending;
    }
  }
}

// ─── Payment Method Enum ──────────────────────────────────
enum PaymentMethod { easypaisa, jazzcash, bankTransfer }

extension PaymentMethodExtension on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.easypaisa:
        return 'Easypaisa';
      case PaymentMethod.jazzcash:
        return 'JazzCash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  String get hint {
    switch (this) {
      case PaymentMethod.easypaisa:
        return 'e.g. 03001234567';
      case PaymentMethod.jazzcash:
        return 'e.g. 03001234567';
      case PaymentMethod.bankTransfer:
        return 'e.g. PK00MEZN0000000000000000';
    }
  }

  String get accountLabel {
    switch (this) {
      case PaymentMethod.easypaisa:
        return 'Easypaisa Number';
      case PaymentMethod.jazzcash:
        return 'JazzCash Number';
      case PaymentMethod.bankTransfer:
        return 'Account / IBAN Number';
    }
  }
}

// ─── Booking Model (from Firestore bookings collection) ───
class BookingModel {
  final String id;
  final String artistId;
  final String customerId;
  final String serviceTitle;
  final double servicePrice;
  final String status;
  final DateTime createdAt;
  final DateTime appointmentDate;

  BookingModel({
    required this.id,
    required this.artistId,
    required this.customerId,
    required this.serviceTitle,
    required this.servicePrice,
    required this.status,
    required this.createdAt,
    required this.appointmentDate,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      artistId: d['artistId'] ?? '',
      customerId: d['customerId'] ?? '',
      serviceTitle: d['serviceTitle'] ?? 'Service',
      servicePrice: (d['servicePrice'] ?? 0).toDouble(),
      status: d['status'] ?? 'pending',
      createdAt: _parseDate(d['createdAt']),
      appointmentDate: _parseDate(d['appointmentDate']),
    );
  }

  // ─── Parse both Timestamp and String dates ─────────────
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {}
    }
    return DateTime.now();
  }

  // ─── Helpers ───────────────────────────────────────────
// NAYA
  bool get isPending =>
      status == 'pending' ||
      status == 'accepted' ||
      status == 'inProgress' ||
      status == 'stitchingCompleted' ||
      status == 'riderAssigned';

  bool get isCompleted =>
      status == 'delivered' || // ✅ YEH ADD KARO
      status == 'completed' ||
      status == 'approved';

  bool get isCancelled => status == 'cancelled' || status == 'rejected';
}

// ─── Withdraw Request Model ───────────────────────────────
class WithdrawRequestModel {
  final String id;
  final double amount;
  final String paymentMethod;
  final String accountTitle;
  final String accountNumber;
  final WithdrawStatus status;
  final DateTime date;

  WithdrawRequestModel({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.accountTitle,
    required this.accountNumber,
    required this.status,
    required this.date,
  });

  factory WithdrawRequestModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WithdrawRequestModel(
      id: doc.id,
      amount: (d['amount'] ?? 0).toDouble(),
      paymentMethod: d['paymentMethod'] ?? 'Bank Transfer',
      accountTitle: d['accountTitle'] ?? '',
      accountNumber: d['accountNumber'] ?? '',
      status: WithdrawStatusExtension.fromString(d['status'] ?? 'pending'),
      date: BookingModel._parseDate(d['date']),
    );
  }
}

// ─── Earnings Controller ──────────────────────────────────
class EarningsController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ─── Loading States ───────────────────────────────────
  final isLoading = false.obs;
  final isWithdrawLoading = false.obs;
  final isTransactionLoading = false.obs;

  // ─── Earnings Summary (calculated from bookings) ──────
  final totalEarnings = 0.0.obs; // all completed bookings
  final availableBalance = 0.0.obs; // completed - withdrawn
  final pendingBalance = 0.0.obs; // pending bookings
  final withdrawnBalance = 0.0.obs; // from withdrawRequests
  final monthlyEarnings = 0.0.obs; // completed in selected month

  // ─── Month Filter ─────────────────────────────────────
  final selectedMonth = DateTime.now().obs;

  // ─── Data Lists ───────────────────────────────────────
  final RxList<BookingModel> bookings = <BookingModel>[].obs;
  final RxList<WithdrawRequestModel> withdrawHistory =
      <WithdrawRequestModel>[].obs;

  // ─── Payment Method ───────────────────────────────────
  final selectedPaymentMethod = PaymentMethod.easypaisa.obs;

  // ─── Form Controllers ─────────────────────────────────
  final withdrawAmountController = TextEditingController();
  final accountTitleController = TextEditingController();
  final accountNumberController = TextEditingController();
  final bankNameController = TextEditingController();

  final double minimumWithdraw = 500.0;

  // ─── Current Artist ID ────────────────────────────────
  String get _artistId => _auth.currentUser?.uid ?? '';

  // ─── Withdraw Requests Reference ─────────────────────
  CollectionReference get _withdrawRef => _firestore
      .collection('users')
      .doc(_artistId)
      .collection('withdrawRequests');

  // ─── On Init ─────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    fetchEarningsData();
  }

  // ─── Fetch All Data ───────────────────────────────────
  Future<void> fetchEarningsData() async {
    if (_artistId.isEmpty) {
      _showError('User not logged in');
      return;
    }

    try {
      isLoading.value = true;
      isTransactionLoading.value = true;

      // ─── 1. Fetch artist's bookings ──────────────────
      final bookingSnap = await _firestore
          .collection('bookings')
          .where('artistId', isEqualTo: _artistId)
          .get();

      bookings.value = bookingSnap.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .where((b) => !b.isCancelled)
          .toList()
        ..sort(
            (a, b) => b.createdAt.compareTo(a.createdAt)); // client side sort

      // ─── 2. Fetch withdraw requests ──────────────────
      final wdSnap = await _withdrawRef.limit(20).get();

      withdrawHistory.value = wdSnap.docs
          .map((doc) => WithdrawRequestModel.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // client side sort

      // ─── 3. Calculate balances ────────────────────────
      _calculateBalances();
    } catch (e) {
      _showError('Failed to load data: ${e.toString()}');
    } finally {
      isLoading.value = false;
      isTransactionLoading.value = false;
    }
  }

  // ─── Calculate All Balances from Bookings ────────────
  void _calculateBalances() {
  final completed = bookings.where((b) => b.isCompleted).toList();
  final pending   = bookings.where((b) => b.isPending).toList();

  // ✅ Artist ko milega 85% (15% platform commission katega)
  totalEarnings.value = completed.fold(
    0.0, (sum, b) => sum + (b.servicePrice * 0.85));
    
  pendingBalance.value = pending.fold(
    0.0, (sum, b) => sum + (b.servicePrice * 0.85));

  withdrawnBalance.value = withdrawHistory
      .where((w) => w.status == WithdrawStatus.approved)
      .fold(0.0, (sum, w) => sum + w.amount);

  availableBalance.value =
      (totalEarnings.value - withdrawnBalance.value).clamp(0.0, double.infinity);

  _calculateMonthlyEarnings();
}

  // ─── Monthly Earnings ────────────────────────────────
  void _calculateMonthlyEarnings() {
    final m = selectedMonth.value;
    monthlyEarnings.value = bookings
        .where((b) =>
            b.isCompleted &&
            b.appointmentDate.year == m.year &&
            b.appointmentDate.month == m.month)
        .fold(0.0, (sum, b) => sum + b.servicePrice);
  }

  // ─── Change Month ─────────────────────────────────────
  void changeMonth(DateTime month) {
    selectedMonth.value = month;
    _calculateMonthlyEarnings();
  }

  // ─── Submit Withdraw Request ──────────────────────────
  Future<void> submitWithdrawRequest() async {
    if (!_validateWithdrawForm()) return;

    final amount = double.parse(withdrawAmountController.text.trim());
    final method = selectedPaymentMethod.value;

    try {
      isWithdrawLoading.value = true;

      await _withdrawRef.add({
        'amount': amount,
        'paymentMethod': method.label,
        'accountTitle': accountTitleController.text.trim(),
        'accountNumber': accountNumberController.text.trim(),
        'bankName': method == PaymentMethod.bankTransfer
            ? bankNameController.text.trim()
            : method.label,
        'status': 'pending',
        'date': FieldValue.serverTimestamp(),
        'artistId': _artistId,
      });

      _clearWithdrawForm();
      await fetchEarningsData();
      Get.back();

      Get.snackbar(
        'Request Submitted',
        'Withdraw request of Rs ${amount.toStringAsFixed(0)} via ${method.label} submitted.',
        backgroundColor: const Color(0xFF4CAF82),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      _showError('Withdraw request failed: ${e.toString()}');
    } finally {
      isWithdrawLoading.value = false;
    }
  }

  // ─── Bookings as Transactions (for UI) ───────────────
  List<BookingModel> get completedBookings =>
      bookings.where((b) => b.isCompleted).toList();

  List<BookingModel> get pendingBookings =>
      bookings.where((b) => b.isPending).toList();

  // ─── Formatted Values ─────────────────────────────────
  String get formattedTotal => 'Rs ${totalEarnings.value.toStringAsFixed(0)}';
  String get formattedAvailable =>
      'Rs ${availableBalance.value.toStringAsFixed(0)}';
  String get formattedPending =>
      'Rs ${pendingBalance.value.toStringAsFixed(0)}';
  String get formattedWithdrawn =>
      'Rs ${withdrawnBalance.value.toStringAsFixed(0)}';
  String get formattedMonthly =>
      'Rs ${monthlyEarnings.value.toStringAsFixed(0)}';

  bool get canWithdraw => availableBalance.value >= minimumWithdraw;

  String get withdrawHintText => canWithdraw
      ? 'Minimum withdraw: Rs ${minimumWithdraw.toStringAsFixed(0)}'
      : 'Minimum balance of Rs ${minimumWithdraw.toStringAsFixed(0)} required';

  // ─── Validate Form ────────────────────────────────────
  bool _validateWithdrawForm() {
    final amountText = withdrawAmountController.text.trim();
    if (amountText.isEmpty) {
      _showError('Please enter withdraw amount');
      return false;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return false;
    }
    if (amount < minimumWithdraw) {
      _showError(
          'Minimum withdraw is Rs ${minimumWithdraw.toStringAsFixed(0)}');
      return false;
    }
    if (amount > availableBalance.value) {
      _showError('Amount exceeds available balance');
      return false;
    }
    if (accountTitleController.text.trim().isEmpty) {
      _showError('Please enter account title');
      return false;
    }
    if (accountNumberController.text.trim().isEmpty) {
      _showError('Please enter ${selectedPaymentMethod.value.accountLabel}');
      return false;
    }
    if (selectedPaymentMethod.value == PaymentMethod.bankTransfer &&
        bankNameController.text.trim().isEmpty) {
      _showError('Please enter bank name');
      return false;
    }

    return true;
  }

  void _clearWithdrawForm() {
    withdrawAmountController.clear();
    accountTitleController.clear();
    accountNumberController.clear();
    bankNameController.clear();
    selectedPaymentMethod.value = PaymentMethod.easypaisa;
  }

  void _showError(String message) {
    Get.snackbar('Error', message,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP);
  }

  @override
  void onClose() {
    withdrawAmountController.dispose();
    accountTitleController.dispose();
    accountNumberController.dispose();
    bankNameController.dispose();
    super.onClose();
  }
}
