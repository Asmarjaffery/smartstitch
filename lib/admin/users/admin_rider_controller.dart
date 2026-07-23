import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminRiderController extends GetxController {
  static AdminRiderController get to => Get.find();

  final _db = FirebaseFirestore.instance;

  // ── Observables ─────────────────────────────────────────────
  final isLoading = false.obs;

  final allRiders = <QueryDocumentSnapshot>[].obs;
  final pendingRiders = <QueryDocumentSnapshot>[].obs;
  final verifiedRiders = <QueryDocumentSnapshot>[].obs;
  final activeRiders = <QueryDocumentSnapshot>[].obs; // currently delivering

  // Rider performance { riderId: stats }
  final riderStats = <String, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToRiders();
  }

  // ── Stream ───────────────────────────────────────────────────

  void _listenToRiders() {
    _db
        .collection('users')
        .where('role', isEqualTo: 'rider')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      allRiders.value = snap.docs;
      pendingRiders.value =
          snap.docs.where((d) => d['isVerified'] != true).toList();
      verifiedRiders.value =
          snap.docs.where((d) => d['isVerified'] == true).toList();
      activeRiders.value =
          snap.docs.where((d) => d['isOnline'] == true).toList();

      for (final doc in snap.docs) {
        _loadRiderPerformance(doc.id);
      }
    });
  }

  Future<void> _loadRiderPerformance(String riderId) async {
    try {
      final deliveriesSnap = await _db
          .collection('orders')
          .where('riderId', isEqualTo: riderId)
          .where('status', isEqualTo: 'completed')
          .get();

      double earnings = 0;
      for (final o in deliveriesSnap.docs) {
        // Rider gets delivery fee, not full order amount
        earnings +=
            ((o.data())['deliveryFee'] ?? 0).toDouble();
      }

      riderStats[riderId] = {
        'totalDeliveries': deliveriesSnap.docs.length,
        'totalEarnings': earnings,
      };
    } catch (_) {}
  }

  // ── Actions ──────────────────────────────────────────────────

  /// Approve rider
  Future<void> approveRider(String riderId, String name) async {
    try {
      await _db.collection('users').doc(riderId).update({
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar('Approved ✓', '$name is now verified!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (e) {
      _showError('Approval failed: $e');
    }
  }

  /// Reject rider
  Future<void> rejectRider(String riderId, String name) async {
    try {
      await _db.collection('users').doc(riderId).update({
        'isVerified': false,
        'isBlocked': true,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar('Rejected', '$name has been rejected.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (e) {
      _showError('Rejection failed: $e');
    }
  }

  /// Process rider payment
  Future<void> processRiderPayment({
    required String riderId,
    required String riderName,
    required double amount,
  }) async {
    if (amount <= 0) {
      _showError('Invalid payment amount.');
      return;
    }
    isLoading.value = true;
    try {
      await _db.collection('payments').add({
        'recipientId': riderId,
        'recipientName': riderName,
        'recipientRole': 'rider',
        'amount': amount,
        'status': 'completed',
        'type': 'rider_payment',
        'processedAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('users').doc(riderId).update({
        'walletBalance': FieldValue.increment(-amount),
        'totalWithdrawn': FieldValue.increment(amount),
      });

      Get.snackbar(
          'Payment Sent', 'Rs. ${amount.toStringAsFixed(0)} paid to $riderName.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (e) {
      _showError('Payment failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Monitor: get live deliveries stream
  Stream<QuerySnapshot> get liveDeliveriesStream => _db
      .collection('orders')
      .where('status', isEqualTo: 'in_progress')
      .where('riderId', isNotEqualTo: '')
      .snapshots();

  Future<void> toggleBlockRider(String riderId, bool currentlyBlocked) async {
    try {
      await _db
          .collection('users')
          .doc(riderId)
          .update({'isBlocked': !currentlyBlocked});
    } catch (e) {
      _showError('Update failed: $e');
    }
  }

  void _showError(String msg) {
    Get.snackbar('Error', msg,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12);
  }
}