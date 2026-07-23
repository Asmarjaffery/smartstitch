import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/models/body_measurement_model.dart';
import 'package:smartstitch/models/order_model.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/services/firebase_service.dart';
import 'package:smartstitch/services/notification_service.dart';

class OrderController extends GetxController {
  static OrderController get to => Get.find();

  final FirebaseService _firebaseService = FirebaseService();

  final RxList<OrderModel> myOrders = <OrderModel>[].obs;
  final Rx<OrderModel?> selectedOrder = Rx<OrderModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString filterStatus = 'all'.obs;

  final Rx<BodyMeasurementModel?> selectedOrderMeasurement =
      Rx<BodyMeasurementModel?>(null);

  final RxString selectedOrderArtistName = ''.obs;
  final RxString selectedOrderArtistPhone = ''.obs;

  final RxString selectedRiderName = ''.obs;
  final RxString selectedRiderPhone = ''.obs;

  final Rx<Map<String, dynamic>?> riderLocation =
      Rx<Map<String, dynamic>?>(null);

  List<OrderModel> get filteredOrders {
    switch (filterStatus.value) {
      case 'all':
        return myOrders;
      case 'pending':
        return myOrders
            .where((o) =>
                o.status == OrderStatus.pending ||
                o.status == OrderStatus.accepted)
            .toList();
      case 'inProgress':
        return myOrders
            .where((o) =>
                o.status == OrderStatus.inProgress ||
                o.status == OrderStatus.stitchingCompleted ||
                o.status == OrderStatus.riderAssigned)
            .toList();
      case 'delivered':
        return myOrders
            .where((o) => o.status == OrderStatus.delivered)
            .toList();
      case 'cancelled':
        return myOrders
            .where((o) => o.status == OrderStatus.cancelled)
            .toList();
      default:
        return myOrders;
    }
  }

  @override
  void onInit() {
    super.onInit();
    ever(AuthController.to.currentUser, (user) {
      if (user != null) loadOrders();
    });
    if (AuthController.to.currentUser.value != null) loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      isLoading.value = true;
      final uid = AuthController.to.currentUserId;
      if (uid == null) return;

      final bookingSnap = await _firebaseService.firestore
          .collection('bookings')
          .where('customerId', isEqualTo: uid)
          .get();

      final now = DateTime.now().toIso8601String();
      final bookingOrders = <OrderModel>[];

      for (final doc in bookingSnap.docs) {
        try {
          final d = doc.data();

          OrderStatus orderStatus;
          try {
            orderStatus = OrderStatus.values.byName(d['status'] ?? 'pending');
          } catch (_) {
            orderStatus = OrderStatus.pending;
          }

          String placedAt = now;
          if (d['createdAt'] != null) {
            try {
              DateTime.parse(d['createdAt']);
              placedAt = d['createdAt'];
            } catch (_) {
              placedAt = now;
            }
          }

          String updatedAt = now;
          if (d['updatedAt'] != null) {
            updatedAt = d['updatedAt'].toString();
          }

          // ── Amount breakdown ──────────────────────────────────────
          final servicePrice = (d['servicePrice'] as num?)?.toDouble() ?? 0.0;
          final deliveryFee = (d['deliveryFee'] as num?)?.toDouble() ?? 0.0;
          // If totalAmount already stored in Firestore, use it; else compute
          final totalAmount = (d['totalAmount'] as num?)?.toDouble() ??
              (servicePrice + deliveryFee);
          // platformCommission is 10% of service price only (not delivery)
          final platformCommission =
              (d['platformCommission'] as num?)?.toDouble() ??
                  (servicePrice * 0.15);

          final artistAmount =
              (d['artistAmount'] as num?)?.toDouble() ?? (servicePrice * 0.85);
          // ──────────────────────────────────────────────────────────

          final order = OrderModel.fromJson({
            'id': doc.id,
            'customerId': d['customerId'] ?? '',
            'artistId': d['artistId'] ?? '',
            'measurementId': d['measurementId'],
            'riderId': d['riderId'],
            'status': orderStatus.name,
            'placedAt': placedAt,
            'updatedAt': updatedAt,
            'specialInstructions': d['specialInstructions'],
            'isHomeVisit': d['bookingType'] == 'homeVisit',
            'appointmentDate': d['appointmentDate'],
            'service': {
              'id': d['serviceId'] ?? '',
              'name': d['serviceTitle'] ?? 'Service',
              'title': d['serviceTitle'] ?? 'Service',
              'description': '',
              'price': servicePrice,
              'basePrice': servicePrice,
              'imageUrl': '',
              'isActive': true,
              'createdAt': now,
            },
            'servicePrice': servicePrice,
            'deliveryFee': deliveryFee,
            'totalAmount': totalAmount,
            'platformCommission': platformCommission,
            'artistAmount': artistAmount,
            'measurements': {
              'id': d['measurementId'] ?? 'temp',
              'userId': d['customerId'] ?? '',
              'height': 0.0,
              'chest': 0.0,
              'waist': 0.0,
              'shoulder': 0.0,
              'hips': 0.0,
              'sleevLength': 0.0,
              'inseam': 0.0,
              'neck': 0.0,
              'aiAccuracyScore': 0.0,
              'isAiGenerated': false,
              'measuredAt': now,
            },
            'deliveryAddress': {
              'id': '',
              'label': d['bookingType'] == 'homeVisit'
                  ? 'Home Delivery'
                  : 'Drop Off at Studio',
              'fullAddress': d['address'] != null
                  ? (d['address']['fullAddress'] ?? 'Drop Off at Studio')
                  : (d['bookingType'] == 'homeVisit'
                      ? 'Home Visit'
                      : 'Drop Off at Studio'),
              'city': d['address'] != null ? (d['address']['city'] ?? '') : '',
              'province':
                  d['address'] != null ? (d['address']['province'] ?? '') : '',
              'latitude': d['address'] != null
                  ? ((d['address']['latitude'] ?? 0) as num).toDouble()
                  : 0.0,
              'longitude': d['address'] != null
                  ? ((d['address']['longitude'] ?? 0) as num).toDouble()
                  : 0.0,
              'isDefault': false,
            },
            'designImages':
                d['designImageUrl'] != null ? [d['designImageUrl']] : [],
            'payment': null,
          });
          bookingOrders.add(order);
        } catch (e) {
          debugPrint('Parse error for ${doc.id}: $e');
        }
      }

      myOrders.value = bookingOrders;
      myOrders.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    } catch (e) {
      debugPrint('loadOrders error: $e');
      if (Get.context != null) {
        AppHelpers.showError('Failed to load orders.');
      }
    } finally {
      isLoading.value = false;
    }
  }

  StreamSubscription<DocumentSnapshot>? _orderLocationSub;

  Future<void> loadOrderExtras(OrderModel order) async {
    selectedOrderMeasurement.value = null;
    selectedOrderArtistName.value = '';
    selectedOrderArtistPhone.value = '';
    selectedRiderName.value = '';
    selectedRiderPhone.value = '';
    riderLocation.value = null;

    if (order.measurementId != null) {
      try {
        final doc = await _firebaseService.firestore
            .collection('measurements')
            .doc(order.measurementId)
            .get();
        if (doc.exists) {
          selectedOrderMeasurement.value =
              BodyMeasurementModel.fromJson({...doc.data()!, 'id': doc.id});
        }
      } catch (e) {
        debugPrint('Measurement fetch error: $e');
        selectedOrderMeasurement.value = null;
      }
    }

    try {
      final artistDoc = await _firebaseService.firestore
          .collection('users')
          .doc(order.artistId)
          .get();
      if (artistDoc.exists) {
        final data = artistDoc.data()!;
        selectedOrderArtistName.value =
            data['name'] ?? data['displayName'] ?? 'Unknown Artist';
        selectedOrderArtistPhone.value = data['phone'] ?? '';
      } else {
        selectedOrderArtistName.value = 'Unknown Artist';
      }
    } catch (e) {
      debugPrint('Artist fetch error: $e');
      selectedOrderArtistName.value = 'Unknown Artist';
    }

    if (order.riderId != null && order.riderId!.isNotEmpty) {
      try {
        final riderDoc = await _firebaseService.firestore
            .collection('users')
            .doc(order.riderId)
            .get();
        if (riderDoc.exists) {
          final data = riderDoc.data()!;
          selectedRiderName.value =
              data['name'] ?? data['displayName'] ?? 'Unknown Rider';
          selectedRiderPhone.value = data['phone'] ?? '';
        } else {
          selectedRiderName.value = 'Unknown Rider';
        }
      } catch (e) {
        debugPrint('Rider fetch error: $e');
        selectedRiderName.value = 'Unknown Rider';
        selectedRiderPhone.value = '';
      }
    }
  }

  // ── Live rider location ──

  void listenToOrder(String orderId) {
    _orderLocationSub?.cancel();
    _orderLocationSub = _firebaseService.firestore
        .collection('bookings')
        .doc(orderId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        riderLocation.value = data['riderLocation'] as Map<String, dynamic>?;
      }
    });
  }

  @override
  void onClose() {
    _orderLocationSub?.cancel();
    super.onClose();
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      isLoading.value = true;

      final orderDoc = await _firebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .get();

      final collection = orderDoc.exists ? 'orders' : 'bookings';

      final data = orderDoc.exists
          ? orderDoc.data()!
          : (await _firebaseService.firestore
                  .collection('bookings')
                  .doc(orderId)
                  .get())
              .data()!;

      await _firebaseService.firestore
          .collection(collection)
          .doc(orderId)
          .update({
        'status': OrderStatus.cancelled.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await NotificationService.instance.sendNotification(
        recipientId: data['artistId'],
        recipientRole: UserRole.artist,
        type: NotificationType.orderUpdate,
        title: 'Order Cancelled',
        body: 'Customer ne order cancel kar diya: $orderId',
        data: {'orderId': orderId},
      );

      AppHelpers.showSuccess('Booking cancelled.');
      await loadOrders();
    } catch (e) {
      debugPrint('Cancel error: $e');
      AppHelpers.showError('Failed to cancel.');
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String status) {
    filterStatus.value = status;
  }

  void removeOrderFromList(String orderId) {
    myOrders.removeWhere((o) => o.id == orderId);
  }

  bool canCancel(OrderStatus status) =>
      status == OrderStatus.pending || status == OrderStatus.accepted;

  int statusStep(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.accepted:
        return 1;
      case OrderStatus.inProgress:
        return 2;
      case OrderStatus.stitchingCompleted:
        return 3;
      case OrderStatus.riderAssigned:
        return 4;
      case OrderStatus.delivered:
        return 5;
      case OrderStatus.cancelled:
        return -1;
    }
  }
}
