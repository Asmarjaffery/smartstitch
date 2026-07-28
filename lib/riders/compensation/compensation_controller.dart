import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/delivery_exception_model.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/models/wallet_models.dart';
import 'package:smartstitch/services/notification_service.dart';

/// Drives: Report Delivery Issue → Delivery Attempt Summary → Request
/// Submitted → Rider Wallet → Compensation History.
///
/// Uses the project's existing RiderWallet / WalletTransaction /
/// TransactionType models (lib/models/enums.dart) — no separate wallet
/// models needed. Writes to its own 'delivery_exceptions' collection, plus
/// additive fields on 'rider_wallets' / 'wallet_transactions'.
class CompensationController extends GetxController {
  static CompensationController get to => Get.find();

  final _db = FirebaseFirestore.instance;

  // ─── Report Delivery Issue (step-by-step form state) ──────────────────
  final Rx<DeliveryExceptionReason?> selectedReason = Rx(null);
  final RxString notes = ''.obs;
  final RxBool isCapturingGps = false.obs;
  final RxBool isSubmitting = false.obs;

  // Captured at "Continue" time, shown on the summary screen, then written
  // on "Submit".
  final Rx<Position?> capturedPosition = Rx(null);
  final Rx<DateTime?> attemptTime = Rx(null);
  final RxInt attemptCount = 1.obs;

  // Set only when the rider taps "Call Now" for the "Customer Didn't
  // Answer" reason — proof the call was actually attempted.
  final Rx<DateTime?> callAttemptedAt = Rx(null);

  // ─── Wallet ─────────────────────────────────────────────────────────────
  final Rx<RiderWallet> wallet = RiderWallet.empty('').obs;
  final RxList<WalletTransaction> transactions = <WalletTransaction>[].obs;
  final RxBool isLoadingWallet = false.obs;

  // ─── Compensation History ───────────────────────────────────────────────
  final RxList<DeliveryExceptionModel> history = <DeliveryExceptionModel>[].obs;
  final RxBool isLoadingHistory = false.obs;

  void resetReportForm() {
    selectedReason.value = null;
    notes.value = '';
    capturedPosition.value = null;
    attemptTime.value = null;
    attemptCount.value = 1;
    callAttemptedAt.value = null;
  }

  bool get canContinue =>
      selectedReason.value != null &&
      (!selectedReason.value!.requiresNote || notes.value.trim().isNotEmpty) &&
      (selectedReason.value != DeliveryExceptionReason.customerDidNotAnswer ||
          callAttemptedAt.value != null);

  /// Called when the rider taps "Call Now" on the report sheet. Records the
  /// timestamp (proof of attempt) and opens the phone dialer.
  Future<void> logCallAttempt(String phone) async {
    callAttemptedAt.value = DateTime.now();
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ─── Step 1 → 2: capture GPS + timestamp, ready for the summary screen ──
  Future<bool> captureAttemptDetails() async {
    if (!canContinue) return false;
    try {
      isCapturingGps.value = true;
      attemptTime.value = DateTime.now();

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          capturedPosition.value = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.high),
          );
        }
      }
      return true;
    } catch (e) {
      debugPrint('captureAttemptDetails error: $e');
      // Still let the rider proceed without GPS rather than blocking them —
      // admin can see gpsAccuracyMeters == null on the details drawer.
      return true;
    } finally {
      isCapturingGps.value = false;
    }
  }

  // ─── Step 3: Submit ─────────────────────────────────────────────────────
  /// [deliveryFee] / [isCod] come from the order the rider is on — pass
  /// them in from OrderDetail so this controller doesn't need to know the
  /// OrderModel shape.
  Future<DeliveryExceptionModel?> submitReport({
    required String orderId,
    required String customerId,
    required String riderId,
    String? artistId,
    required double deliveryFee,
    required bool isCod,
  }) async {
    if (selectedReason.value == null) return null;
    try {
      isSubmitting.value = true;
      final now = DateTime.now();
      final docRef = _db.collection('delivery_exceptions').doc();

      final model = DeliveryExceptionModel(
        id: docRef.id,
        orderId: orderId,
        customerId: customerId,
        riderId: riderId,
        artistId: artistId,
        reason: selectedReason.value!,
        notes: notes.value.trim().isEmpty ? null : notes.value.trim(),
        attemptTime: attemptTime.value ?? now,
        attemptCount: attemptCount.value,
        gpsLat: capturedPosition.value?.latitude,
        gpsLng: capturedPosition.value?.longitude,
        gpsAccuracyMeters: capturedPosition.value?.accuracy,
        callAttemptedAt: callAttemptedAt.value?.toIso8601String(),
        compensationAmount: deliveryFee,
        outstandingCharge: isCod ? deliveryFee : 0,
        status: DeliveryExceptionStatus.submitted,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(model.toJson());

      // Reflect on the booking so customer-side screens (Delivery Attempt
      // Failed) can react without a second query.
      await _db.collection('bookings').doc(orderId).update({
        'lastDeliveryExceptionId': docRef.id,
        'deliveryExceptionReason': model.reason.name,
        'riderStatus': 'deliveryFailed', 
        'updatedAt': now.toIso8601String(),
      });

      // Bump the rider's pending-compensation figure so the Wallet screen
      // shows it immediately, before admin approves.
      await _db.collection('rider_wallets').doc(riderId).set({
        'riderId': riderId,
        'pendingCompensation': FieldValue.increment(deliveryFee),
      }, SetOptions(merge: true));

      final txRef = _db.collection('wallet_transactions').doc();
      final tx = WalletTransaction(
        id: txRef.id,
        riderId: riderId,
        orderId: orderId,
        type: TransactionType.compensation,
        status: TransactionStatus.pending,
        amount: deliveryFee,
        title: 'Compensation Claim',
        description: model.reason.label,
        createdAt: now,
      );
      await txRef.set(tx.toJson());

      // Notify admin — best-effort, doesn't block the success screen.
      try {
        await NotificationService.instance.sendNotification(
          recipientId: 'admin', // adjust to your actual admin fan-out target
          recipientRole: UserRole.admin,
          type: NotificationType.general,
          title: 'Delivery Issue Reported',
          body: '${model.reason.label} — Order $orderId needs review.',
          data: {'orderId': orderId, 'exceptionId': docRef.id},
        );
      } catch (e) {
        debugPrint('Admin notify error: $e');
      }

      Get.snackbar(
        'Submitted',
        'Your report has been sent to admin for review.',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      return model;
    } catch (e) {
      debugPrint('submitReport error: $e');
      Get.snackbar(
        'Error',
        'Could not submit report. Please try again.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── Wallet ─────────────────────────────────────────────────────────────
  Future<void> loadWallet(String riderId) async {
    if (riderId.isEmpty) return;
    try {
      isLoadingWallet.value = true;
      final doc = await _db.collection('rider_wallets').doc(riderId).get();
      wallet.value = doc.exists
          ? RiderWallet.fromJson(doc.data()!)
          : RiderWallet.empty(riderId);

      final txSnap = await _db
          .collection('wallet_transactions')
          .where('riderId', isEqualTo: riderId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      transactions.value = txSnap.docs
          .map((d) => WalletTransaction.fromJson({...d.data(), 'id': d.id}))
          .toList();
    } catch (e) {
      debugPrint('loadWallet error: $e');
    } finally {
      isLoadingWallet.value = false;
    }
  }

  // ─── Compensation History ───────────────────────────────────────────────
  Future<void> loadHistory(String riderId, {CompensationStatus? filter}) async {
    if (riderId.isEmpty) return;
    try {
      isLoadingHistory.value = true;
      Query<Map<String, dynamic>> q = _db
          .collection('delivery_exceptions')
          .where('riderId', isEqualTo: riderId)
          .orderBy('createdAt', descending: true);

      if (filter != null) {
        q = q.where('compensationStatus', isEqualTo: filter.name);
      }

      final snap = await q.limit(100).get();
      history.value = snap.docs
          .map((d) => DeliveryExceptionModel.fromJson(d.data()))
          .toList();
    } catch (e) {
      debugPrint('loadHistory error: $e');
    } finally {
      isLoadingHistory.value = false;
    }
  }
}