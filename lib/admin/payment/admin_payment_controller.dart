import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPaymentController extends GetxController {
  static AdminPaymentController get to => Get.find();

  final _db = FirebaseFirestore.instance;

  // ── Business Rule ────────────────────────────────────────────
  static const double commissionRate = 0.10; // 10% per order

  // ── Observables ─────────────────────────────────────────────
  final isLoading = false.obs;

  // Revenue
  final totalRevenue = 0.0.obs;
  final totalCommission = 0.0.obs; // platform's 10%
  final totalPaidOut = 0.0.obs; // paid to artists + riders
  final netRevenue = 0.0.obs; // commission - paidOut

  // Withdrawal requests
  final pendingWithdrawals = <QueryDocumentSnapshot>[].obs;
  final processedWithdrawals = <QueryDocumentSnapshot>[].obs;

  // Payment history
  final paymentHistory = <QueryDocumentSnapshot>[].obs;

  // Monthly revenue chart { month: amount }
  final monthlyRevenue = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToRevenue();
    _listenToWithdrawals();
    _listenToPaymentHistory();
  }

  // ── Streams ──────────────────────────────────────────────────

  void _listenToRevenue() {
    _db
        .collection('orders')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snap) {
      double revenue = 0;
      double commission = 0;
      final Map<String, double> monthly = {};

      for (final doc in snap.docs) {
        final data = doc.data();
        final amount = (data['totalAmount'] ?? 0).toDouble();
        revenue += amount;
        commission += amount * commissionRate;

        // Group by month
        final ts = data['createdAt'];
        if (ts != null) {
          final date = (ts as Timestamp).toDate();
          final key =
              '${date.year}-${date.month.toString().padLeft(2, '0')}';
          monthly[key] = (monthly[key] ?? 0) + amount;
        }
      }

      totalRevenue.value = revenue;
      totalCommission.value = commission;
      netRevenue.value = commission - totalPaidOut.value;
      monthlyRevenue.value = monthly;
    });
  }

  void _listenToWithdrawals() {
    _db
        .collection('withdrawals')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .listen((snap) {
      pendingWithdrawals.value =
          snap.docs.where((d) => d['status'] == 'pending').toList();
      processedWithdrawals.value =
          snap.docs.where((d) => d['status'] != 'pending').toList();
    });
  }

  void _listenToPaymentHistory() {
    _db
        .collection('payments')
        .orderBy('processedAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      paymentHistory.value = snap.docs;

      double paid = 0;
      for (final doc in snap.docs) {
        paid += ((doc.data())['amount'] ?? 0).toDouble();
      }
      totalPaidOut.value = paid;
      netRevenue.value = totalCommission.value - paid;
    });
  }

  // ── Actions ──────────────────────────────────────────────────

  /// Approve a withdrawal request
  Future<void> approveWithdrawal(String withdrawalId, Map data) async {
    isLoading.value = true;
    try {
      final amount = (data['amount'] ?? 0).toDouble();
      final userId = data['userId'] ?? '';
      final userName = data['userName'] ?? '';
      final role = data['role'] ?? 'artist';

      // Mark withdrawal approved
      await _db
          .collection('withdrawals')
          .doc(withdrawalId)
          .update({
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
      });

      // Deduct from user wallet
      await _db.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(-amount),
        'totalWithdrawn': FieldValue.increment(amount),
      });

      // Record in payments
      await _db.collection('payments').add({
        'recipientId': userId,
        'recipientName': userName,
        'recipientRole': role,
        'amount': amount,
        'type': 'withdrawal',
        'status': 'completed',
        'withdrawalId': withdrawalId,
        'processedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Approved', 'Withdrawal of Rs. ${amount.toStringAsFixed(0)} approved.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (e) {
      _showError('Approval failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reject a withdrawal request
  Future<void> rejectWithdrawal(String withdrawalId, String reason) async {
    try {
      await _db
          .collection('withdrawals')
          .doc(withdrawalId)
          .update({
        'status': 'rejected',
        'rejectionReason': reason,
        'processedAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar('Rejected', 'Withdrawal request rejected.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (e) {
      _showError('Rejection failed: $e');
    }
  }

  /// Calculate commission for a specific order
  double calculateCommission(double orderAmount) =>
      orderAmount * commissionRate;

  void _showError(String msg) {
    Get.snackbar('Error', msg,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12);
  }
}