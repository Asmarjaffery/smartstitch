import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/models/delivery_model.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/models/rider_model.dart';
import 'package:smartstitch/services/rider_assignment_service.dart';
import 'package:smartstitch/services/rider_service.dart';
import 'package:smartstitch/services/notification_service.dart';
import 'package:smartstitch/riders/profile/profile_rider_controller.dart';

class RiderController extends GetxController {
  static RiderController get to => Get.find();

  final RiderService _service = RiderService.instance;
  final _db = FirebaseFirestore.instance;

  // ─── State ────────────────────────────────────────────────────────────────
  final Rx<RiderModel?> riderProfile = Rx<RiderModel?>(null);
  final RxList<DeliveryModel> activeDeliveries = <DeliveryModel>[].obs;
  final RxList<DeliveryModel> deliveryHistory = <DeliveryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isOnline = false.obs;
  final RxDouble totalEarnings = 0.0.obs;
  final RxDouble walletBalance = 0.0.obs;
  final RxInt totalDeliveries = 0.obs;
  final RxString otpInput = ''.obs;

  // ── New fields ──────────────────────────────────────────────────────────
  final RxDouble todayEarnings = 0.0.obs;
  final RxDouble weekEarnings = 0.0.obs;
  final RxInt completedDeliveries = 0.obs;

  // ── Rating (read from 'riders' doc directly — 'rating' field mein stale
  // 0 pada rehta hai, isliye 'averageRating' / totalRating/totalReviews se
  // live calculate karte hain) ───────────────────────────────────────────
  final RxDouble ratingValue = 0.0.obs;

  final RxBool isTracking = false.obs;
  final RxString trackingDeliveryId = ''.obs;
  StreamSubscription<Position>? _trackingSub;
  StreamSubscription? _deliveriesSub;
  StreamSubscription? _walletSub;       // ← new
  StreamSubscription? _ratingSub;       // ← new
  bool _listenersStarted = false;
  Timer? _locationTimer;

  String get myId => AuthController.to.currentUserId ?? '';
  String get riderName => riderProfile.value?.name ?? '';
  double get rating => ratingValue.value;

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    _locationTimer?.cancel();
    _trackingSub?.cancel();
    _deliveriesSub?.cancel();
    _walletSub?.cancel();
    _ratingSub?.cancel();
    if (isOnline.value) _service.setOffline(myId);
    super.onClose();
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  void loadProfile(String riderId) {
    if (riderId.isEmpty) return;
    _service.watchRiderProfile(riderId).listen(
      (rider) {
        riderProfile.value = rider;
        isOnline.value = rider.isOnline;
        totalEarnings.value = rider.totalEarnings;
        walletBalance.value = rider.walletBalance;

        if (!_listenersStarted) {
          _listenersStarted = true;
          _listenToDeliveries();
          _listenToEarnings();
          _listenToWallet();   // ← new
          _listenToRating();   // ← new
        }
      },
      onError: (_) => AppHelpers.showError('Failed to load profile'),
    );
  }

  // ─── Toggle Online ────────────────────────────────────────────────────────
  Future<void> toggleOnline() async {
    try {
      if (isOnline.value) {
        await _service.setOffline(myId);
        _locationTimer?.cancel();
        isOnline.value = false;
        AppHelpers.showSuccess('You are now Offline');
      } else {
        await _service.setOnline(myId);
        isOnline.value = true;
        _startLocationUpdates();
        AppHelpers.showSuccess('You are now Online');
      }
    } catch (e) {
      AppHelpers.showError('Failed to update status');
    }
  }

  void _startLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final pos = await _service.getCurrentLocation();
      if (pos != null) {
        await _service.updateRiderLocation(myId, pos.latitude, pos.longitude);
      }
    });
  }

  // ─── Deliveries stream ────────────────────────────────────────────────────
  void _listenToDeliveries() {
    if (myId.isEmpty) return;
    _deliveriesSub?.cancel();
    _deliveriesSub = _db
        .collection('bookings')
        .where('riderId', isEqualTo: myId)
        .snapshots()
        .listen((snap) {
      final delivered = snap.docs
          .where((d) => d.data()['status'] == 'delivered')
          .length;
      totalDeliveries.value = delivered;
      completedDeliveries.value = delivered;
    });
  }

  // ─── Earnings stream ──────────────────────────────────────────────────────
  void _listenToEarnings() {
    if (myId.isEmpty) return;
    _service.watchEarnings(myId).listen((data) {
      totalEarnings.value = (data['totalEarnings'] as num?)?.toDouble() ?? 0.0;
      walletBalance.value = (data['walletBalance'] as num?)?.toDouble() ?? 0.0;
    });
  }

  // ─── Wallet real-time listener (today + week earnings) ───────────────────
  void _listenToWallet() {
    if (myId.isEmpty) return;
    _walletSub?.cancel();
    _walletSub = _db
        .collection('wallets')
        .doc(myId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final d = snap.data()!;
      walletBalance.value =
          (d['availableBalance'] as num?)?.toDouble() ?? walletBalance.value;
      todayEarnings.value =
          (d['todayEarnings'] as num?)?.toDouble() ?? 0.0;
      weekEarnings.value =
          (d['weekEarnings'] as num?)?.toDouble() ?? 0.0;
      totalEarnings.value =
          (d['lifetimeEarnings'] as num?)?.toDouble() ?? totalEarnings.value;
    }, onError: (e) => debugPrint('wallet listen error: $e'));
  }

  // ─── Rating real-time listener ────────────────────────────────────────────
  // 'riders' doc ka 'rating' field stale/0 hota hai — 'averageRating' ya
  // (totalRating / totalReviews) se live calculate karte hain
  void _listenToRating() {
    if (myId.isEmpty) return;
    _ratingSub?.cancel();
    _ratingSub = _db
        .collection('riders')
        .doc(myId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final d = snap.data()!;

      final avgField = (d['averageRating'] as num?)?.toDouble();
      if (avgField != null && avgField > 0) {
        ratingValue.value = avgField;
        return;
      }

      final totalRating = (d['totalRating'] as num?)?.toDouble() ?? 0.0;
      final totalReviews = (d['totalReviews'] as num?)?.toDouble() ?? 0.0;
      ratingValue.value =
          totalReviews > 0 ? (totalRating / totalReviews) : 0.0;
    }, onError: (e) => debugPrint('rating listen error: $e'));
  }

  // ─── Pull-to-refresh ─────────────────────────────────────────────────────
  Future<void> refreshAll() async {
    if (myId.isEmpty) return;
    try {
      // Re-fetch wallet snapshot
      final snap = await _db.collection('wallets').doc(myId).get();
      if (snap.exists) {
        final d = snap.data()!;
        walletBalance.value =
            (d['availableBalance'] as num?)?.toDouble() ?? 0.0;
        todayEarnings.value =
            (d['todayEarnings'] as num?)?.toDouble() ?? 0.0;
        weekEarnings.value =
            (d['weekEarnings'] as num?)?.toDouble() ?? 0.0;
        totalEarnings.value =
            (d['lifetimeEarnings'] as num?)?.toDouble() ?? 0.0;
      }

      // Re-fetch rating snapshot too
      final riderSnap = await _db.collection('riders').doc(myId).get();
      if (riderSnap.exists) {
        final d = riderSnap.data()!;
        final avgField = (d['averageRating'] as num?)?.toDouble();
        if (avgField != null && avgField > 0) {
          ratingValue.value = avgField;
        } else {
          final totalRating = (d['totalRating'] as num?)?.toDouble() ?? 0.0;
          final totalReviews = (d['totalReviews'] as num?)?.toDouble() ?? 0.0;
          ratingValue.value =
              totalReviews > 0 ? (totalRating / totalReviews) : 0.0;
        }
      }
    } catch (e) {
      debugPrint('refreshAll error: $e');
    }
  }

  // ─── Accept Delivery ──────────────────────────────────────────────────────
  Future<void> acceptDelivery(String deliveryId) async {
    try {
      isLoading.value = true;

      final deliveryDoc =
          await _db.collection('deliveries').doc(deliveryId).get();
      final bookingId = deliveryDoc.data()?['bookingId'] as String? ??
          deliveryDoc.data()?['orderId'] as String?;

      await _service.acceptDelivery(deliveryId);

      if (bookingId != null && bookingId.isNotEmpty) {
        await RiderAssignmentService.instance.riderAccepted(bookingId);
      }

      AppHelpers.showSuccess('Delivery accept kar li — studio se pick karein!');
    } catch (e) {
      AppHelpers.showError('Accept nahi ho saka');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Reject Delivery ──────────────────────────────────────────────────────
  Future<void> rejectDelivery(String deliveryId) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Delivery'),
        content:
            const Text('Are you sure you want to reject this delivery?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Get.back(result: true),
            child:
                const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await _service.rejectDelivery(deliveryId, myId);
        AppHelpers.showSuccess('Delivery rejected');
      } catch (e) {
        AppHelpers.showError('Failed to reject delivery');
      }
    }
  }

  // ─── Start Delivery ───────────────────────────────────────────────────────
  Future<void> startDelivery(DeliveryModel delivery) async {
    try {
      final pos = await _service.getCurrentLocation();
      if (pos == null) {
        AppHelpers.showError('Location permission ya service enable karein.');
        return;
      }

      isLoading.value = true;

      _trackingSub?.cancel();
      isTracking.value = true;
      trackingDeliveryId.value = delivery.id;

      _trackingSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen(
        (position) {
          _service.updateRiderLocation(
              myId, position.latitude, position.longitude);
        },
        onError: (_) => isTracking.value = false,
      );

      await _service.updateDeliveryStatus(
          delivery.id, DeliveryStatus.onTheWay);

      final bookingId = delivery.orderId;
      await _db.collection('bookings').doc(bookingId).update({
        'riderStatus': 'delivering',
        'deliveryStartedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final adminSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      if (adminSnap.docs.isNotEmpty) {
        await NotificationService.instance.sendNotification(
          recipientId: adminSnap.docs.first.id,
          recipientRole: UserRole.admin,
          type: NotificationType.orderUpdate,
          title: '🛵 Rider Delivery Pe Nikal Gaya',
          body: 'Rider ne booking $bookingId ki delivery shuru kar di.',
          data: {'bookingId': bookingId, 'deliveryId': delivery.id},
        );
      }

      if (delivery.customerId.isNotEmpty) {
        await NotificationService.instance.sendNotification(
          recipientId: delivery.customerId,
          recipientRole: UserRole.customer,
          type: NotificationType.orderUpdate,
          title: '🛵 Rider Raste Mein Hai!',
          body:
              'Aapka order deliver hone aa raha hai — OTP ready rakhein.',
          data: {'bookingId': bookingId},
        );
      }

      AppHelpers.showSuccess('Delivery shuru! Admin ko notify kar diya.');
    } catch (e) {
      AppHelpers.showError('Start nahi ho saki: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── OTP Verify + Delivered ───────────────────────────────────────────────
  Future<void> verifyOtp(String deliveryId) async {
    if (otpInput.value.length != 4) {
      AppHelpers.showError('Please enter 4-digit OTP');
      return;
    }
    try {
      isLoading.value = true;

      final success = await _service.verifyOtp(deliveryId, otpInput.value);

      if (success) {
        _trackingSub?.cancel();
        _trackingSub = null;
        isTracking.value = false;
        trackingDeliveryId.value = '';

        final deliveryDoc =
            await _db.collection('deliveries').doc(deliveryId).get();
        final bookingId = deliveryDoc.data()?['bookingId'] as String? ??
            deliveryDoc.data()?['orderId'] as String?;
        final customerId = deliveryDoc.data()?['customerId'] as String?;

        if (bookingId != null && bookingId.isNotEmpty) {
          await _db.collection('bookings').doc(bookingId).update({
            'status': 'delivered',
            'riderStatus': 'delivered',
            'riderLocation': FieldValue.delete(),
            'deliveredAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }

        if (myId.isNotEmpty) {
          await _db.collection('riders').doc(myId).update({
            'totalDeliveries': FieldValue.increment(1),
          });

          if (Get.isRegistered<RiderProfileController>()) {
            await Get.find<RiderProfileController>().reloadRiderData();
          }
        }

        if (customerId != null && customerId.isNotEmpty) {
          await NotificationService.instance.sendNotification(
            recipientId: customerId,
            recipientRole: UserRole.customer,
            type: NotificationType.orderUpdate,
            title: '🎉 Order Deliver Ho Gaya!',
            body:
                'Aapka order deliver ho gaya. SmartStitch use karne ka shukriya!',
            data: {'bookingId': bookingId ?? ''},
          );
        }

        otpInput.value = '';
        Get.back();
        AppHelpers.showSuccess('Delivery confirmed! ✅');
      } else {
        AppHelpers.showError('OTP galat hai — dobara try karein.');
      }
    } catch (e) {
      AppHelpers.showError('OTP verification failed');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Update Status ────────────────────────────────────────────────────────
  Future<void> updateStatus(String deliveryId, DeliveryStatus status) async {
    try {
      await _service.updateDeliveryStatus(deliveryId, status);
      AppHelpers.showSuccess('Status updated');
    } catch (e) {
      AppHelpers.showError('Failed to update status');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String getStatusLabel(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.assigned:
        return 'New Delivery';
      case DeliveryStatus.pickedUp:
        return 'Accepted';
      case DeliveryStatus.onTheWay:
        return 'On the Way';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.failed:
        return 'Failed';
    }
  }
}