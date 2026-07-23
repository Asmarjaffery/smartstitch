import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminArtistController extends GetxController {
  static AdminArtistController get to => Get.find();

  final _db = FirebaseFirestore.instance;

  // ── Observables ─────────────────────────────────────────────
  final isLoading = false.obs;

  final allArtists = <QueryDocumentSnapshot>[].obs;
  final pendingArtists = <QueryDocumentSnapshot>[].obs;
  final verifiedArtists = <QueryDocumentSnapshot>[].obs;

  // Artist Performance map  { artistId: { totalOrders, totalEarnings, rating } }
  final artistStats = <String, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToArtists();
  }

  // ── Stream ───────────────────────────────────────────────────

  void _listenToArtists() {
    _db
        .collection('users')
        .where('role', isEqualTo: 'artist')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      allArtists.value = snap.docs;
      pendingArtists.value =
          snap.docs.where((d) => d['isVerified'] != true).toList();
      verifiedArtists.value =
          snap.docs.where((d) => d['isVerified'] == true).toList();

      // Load performance for each artist
      for (final doc in snap.docs) {
        _loadArtistPerformance(doc.id);
      }
    });
  }

  Future<void> _loadArtistPerformance(String artistId) async {
    try {
      // Completed orders by this artist
      final ordersSnap = await _db
          .collection('orders')
          .where('artistId', isEqualTo: artistId)
          .where('status', isEqualTo: 'completed')
          .get();

      double earnings = 0;
      for (final o in ordersSnap.docs) {
        earnings += ((o.data())['totalAmount'] ?? 0).toDouble();
      }

      // Average rating from reviews
      final reviewsSnap = await _db
          .collection('reviews')
          .where('artistId', isEqualTo: artistId)
          .get();

      double avgRating = 0;
      if (reviewsSnap.docs.isNotEmpty) {
        final sum = reviewsSnap.docs
            .fold<double>(0, (s, r) => s + (r['rating'] ?? 0).toDouble());
        avgRating = sum / reviewsSnap.docs.length;
      }

      artistStats[artistId] = {
        'totalOrders': ordersSnap.docs.length,
        'totalEarnings': earnings,
        'avgRating': avgRating,
        'totalReviews': reviewsSnap.docs.length,
      };
    } catch (_) {}
  }

  // ── Actions ──────────────────────────────────────────────────

  /// Approve artist verification
  Future<void> approveArtist(String artistId, String name) async {
    try {
      await _db.collection('users').doc(artistId).update({
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar('Approved ✓', '$name has been verified!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (e) {
      _showError('Approval failed: $e');
    }
  }

  /// Reject & block artist
  Future<void> rejectArtist(String artistId, String name) async {
    try {
      await _db.collection('users').doc(artistId).update({
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

  /// Process artist payment / withdrawal
  Future<void> processArtistPayment({
    required String artistId,
    required String artistName,
    required double amount,
  }) async {
    if (amount <= 0) {
      _showError('Invalid payment amount.');
      return;
    }
    isLoading.value = true;
    try {
      // Record in payments collection
      await _db.collection('payments').add({
        'recipientId': artistId,
        'recipientName': artistName,
        'recipientRole': 'artist',
        'amount': amount,
        'status': 'completed',
        'type': 'artist_payment',
        'processedAt': FieldValue.serverTimestamp(),
      });

      // Update artist wallet balance
      await _db.collection('users').doc(artistId).update({
        'walletBalance': FieldValue.increment(-amount),
        'totalWithdrawn': FieldValue.increment(amount),
      });

      Get.snackbar('Payment Sent',
          'Rs. ${amount.toStringAsFixed(0)} paid to $artistName.',
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

  /// Toggle block/unblock artist
  Future<void> toggleBlockArtist(String artistId, bool currentlyBlocked) async {
    try {
      await _db
          .collection('users')
          .doc(artistId)
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
