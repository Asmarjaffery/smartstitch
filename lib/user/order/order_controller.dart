import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/models/body_measurement_model.dart';
import 'package:smartstitch/models/order_model.dart';
import 'package:smartstitch/models/refund_model.dart';
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
  final RxString debugInfo = ''.obs; // 🔍 Debug tracking

  final Rx<BodyMeasurementModel?> selectedOrderMeasurement =
      Rx<BodyMeasurementModel?>(null);

  final RxString selectedOrderArtistName = ''.obs;
  final RxString selectedOrderArtistPhone = ''.obs;

  final RxString selectedRiderName = ''.obs;
  final RxString selectedRiderPhone = ''.obs;

  final Rx<Map<String, dynamic>?> riderLocation =
      Rx<Map<String, dynamic>?>(null);

  final Rx<RefundRequestModel?> selectedRefundRequest =
      Rx<RefundRequestModel?>(null);

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
      if (user != null) {
        debugPrint('🔄 Auth user changed, reloading orders...');
        loadOrders();
      }
    });
    if (AuthController.to.currentUser.value != null) {
      debugPrint('✅ User already logged in, loading orders on init');
      loadOrders();
    } else {
      debugPrint('⚠️ No user on init, skipping loadOrders');
    }
  }

  Future<void> loadOrders() async {
    try {
      isLoading.value = true;
      final uid = AuthController.to.currentUserId;
      
      // 🔍 DEBUG: Log the UID we're querying with
      debugPrint('📋 ===== LOADORDERS DEBUG =====');
      debugPrint('🔑 Current UID: $uid');
      
      if (uid == null || uid.isEmpty) {
        debugPrint('❌ UID is null or empty! Cannot query bookings.');
        debugInfo.value = 'UID is null. Please login.';
        myOrders.value = [];
        isLoading.value = false;
        AppHelpers.showError('Please login to see orders');
        return;
      }

      debugPrint('🔍 Querying bookings collection for customerId: $uid');

      final bookingSnap = await _firebaseService.firestore
          .collection('bookings')
          .where('customerId', isEqualTo: uid)
          .get();

      debugPrint('📊 Query returned ${bookingSnap.docs.length} documents');

      if (bookingSnap.docs.isEmpty) {
        debugPrint('⚠️ No bookings found for this UID');
        debugInfo.value = 'No bookings found for UID: $uid';
        myOrders.value = [];
        isLoading.value = false;
        return;
      }

      final now = DateTime.now().toIso8601String();
      final bookingOrders = <OrderModel>[];
      int successCount = 0;
      int errorCount = 0;

      for (final doc in bookingSnap.docs) {
        try {
          final d = doc.data();

          debugPrint('📄 Processing booking: ${doc.id}');
          debugPrint('   Status: ${d['status']} | Service: ${d['serviceTitle']}');

          // ────────── Status Conversion ──────────
          OrderStatus orderStatus;
          try {
            orderStatus = OrderStatus.values.byName(d['status'] ?? 'pending');
          } catch (e) {
            debugPrint('   ⚠️ Status parsing failed: $e, defaulting to pending');
            orderStatus = OrderStatus.pending;
          }

          // ────────── Timestamp Handling ──────────
          String placedAt = now;
          if (d['createdAt'] != null) {
            try {
              DateTime.parse(d['createdAt']);
              placedAt = d['createdAt'];
            } catch (e) {
              debugPrint('   ⚠️ createdAt parse failed: $e');
              placedAt = now;
            }
          }

          String updatedAt = now;
          if (d['updatedAt'] != null) {
            try {
              updatedAt = d['updatedAt'].toString();
            } catch (e) {
              debugPrint('   ⚠️ updatedAt parse failed: $e');
              updatedAt = now;
            }
          }

          // ────────── Amount Breakdown ──────────
          final servicePrice = (d['servicePrice'] as num?)?.toDouble() ?? 0.0;
          final deliveryFee = (d['deliveryFee'] as num?)?.toDouble() ?? 0.0;
          final totalAmount = (d['totalAmount'] as num?)?.toDouble() ??
              (servicePrice + deliveryFee);
          final platformCommission =
              (d['platformCommission'] as num?)?.toDouble() ??
                  (servicePrice * 0.15);
          final artistAmount =
              (d['artistAmount'] as num?)?.toDouble() ?? (servicePrice * 0.85);

          debugPrint(
              '   💰 Amount: Rs$totalAmount (Service: Rs$servicePrice + Delivery: Rs$deliveryFee)');

          // ────────── Create OrderModel ──────────
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
          successCount++;
          debugPrint('   ✅ Order added successfully');
        } catch (e, stack) {
          errorCount++;
          debugPrint('   ❌ Parse error for ${doc.id}: $e');
          debugPrintStack(stackTrace: stack);
        }
      }

      myOrders.value = bookingOrders;
      myOrders.sort((a, b) => b.placedAt.compareTo(a.placedAt));

      debugInfo.value =
          '✅ Loaded $successCount orders ($errorCount errors) | UID: $uid';
      debugPrint('✅ FINAL: Loaded $successCount orders with $errorCount errors');
      debugPrint('📋 ===== END DEBUG =====\n');
    } catch (e, stack) {
      debugPrint('❌ loadOrders CRITICAL error: $e');
      debugPrintStack(stackTrace: stack);
      debugInfo.value = '❌ Error: $e';
      myOrders.value = [];

      if (Get.context != null) {
        AppHelpers.showError('Failed to load orders: $e');
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
    selectedRefundRequest.value = null;

    // ────────── Load Measurement ──────────
    if (order.measurementId != null && order.measurementId!.isNotEmpty) {
      try {
        final doc = await _firebaseService.firestore
            .collection('measurements')
            .doc(order.measurementId)
            .get();
        if (doc.exists) {
          selectedOrderMeasurement.value =
              BodyMeasurementModel.fromJson({...doc.data()!, 'id': doc.id});
          debugPrint('✅ Measurement loaded: ${order.measurementId}');
        } else {
          debugPrint('⚠️ Measurement doc not found: ${order.measurementId}');
        }
      } catch (e) {
        debugPrint('❌ Measurement fetch error: $e');
        selectedOrderMeasurement.value = null;
      }
    }

    // ────────── Load Artist Info ──────────
    if (order.artistId.isNotEmpty) {
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
          debugPrint('✅ Artist loaded: ${selectedOrderArtistName.value}');
        } else {
          debugPrint('⚠️ Artist doc not found: ${order.artistId}');
          selectedOrderArtistName.value = 'Unknown Artist';
        }
      } catch (e) {
        debugPrint('❌ Artist fetch error: $e');
        selectedOrderArtistName.value = 'Unknown Artist';
      }
    }

    // ────────── Load Rider Info ──────────
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
          debugPrint('✅ Rider loaded: ${selectedRiderName.value}');
        } else {
          debugPrint('⚠️ Rider doc not found: ${order.riderId}');
          selectedRiderName.value = 'Unknown Rider';
        }
      } catch (e) {
        debugPrint('❌ Rider fetch error: $e');
        selectedRiderName.value = 'Unknown Rider';
      }
    }

    // ────────── Load Refund Request ──────────
    if (order.status == OrderStatus.cancelled) {
      await _loadRefundRequest(order.id);
    }
  }

  Future<void> _loadRefundRequest(String orderId) async {
    try {
      final refundDoc = await _firebaseService.firestore
          .collection('refundRequests')
          .doc(orderId)
          .get();

      if (refundDoc.exists) {
        selectedRefundRequest.value = RefundRequestModel.fromJson(
            {...refundDoc.data()!, 'orderId': orderId});
        debugPrint('✅ Refund request loaded for: $orderId');
      } else {
        debugPrint('ℹ️ No refund request for: $orderId');
        selectedRefundRequest.value = null;
      }
    } catch (e) {
      debugPrint('❌ Refund request fetch error: $e');
      selectedRefundRequest.value = null;
    }
  }

  void listenToOrder(String orderId) {
    _orderLocationSub?.cancel();
    debugPrint('👂 Listening to order updates: $orderId');
    _orderLocationSub = _firebaseService.firestore
        .collection('bookings')
        .doc(orderId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        riderLocation.value = data['riderLocation'] as Map<String, dynamic>?;
        if (riderLocation.value != null) {
          debugPrint(
              '📍 Rider location updated: ${riderLocation.value}');
        }
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
      debugPrint('🚫 Cancelling order: $orderId');

      final orderDoc = await _firebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .get();

      final collection = orderDoc.exists ? 'orders' : 'bookings';
      debugPrint('   Collection detected: $collection');

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
      debugPrint('✅ Order cancelled successfully');
    } catch (e) {
      debugPrint('❌ Cancel error: $e');
      AppHelpers.showError('Failed to cancel: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> requestRefund(
    String orderId,
    CancellationReason reason,
    String description,
  ) async {
    try {
      isLoading.value = true;
      debugPrint('💰 Requesting refund for: $orderId');

      final bookingSnap = await _firebaseService.firestore
          .collection('bookings')
          .doc(orderId)
          .get();

      if (!bookingSnap.exists) {
        AppHelpers.showError('Order not found.');
        return;
      }

      final bookingData = bookingSnap.data()!;
      final customerId = bookingData['customerId'] ?? '';
      final tailorId = bookingData['artistId'] ?? '';
      final paymentIntentId = bookingData['paymentIntentId'] ?? '';

      String customerName = 'Customer';
      String tailorName = 'Tailor';

      try {
        if (customerId.toString().isNotEmpty) {
          final customerDoc = await _firebaseService.firestore
              .collection('users')
              .doc(customerId)
              .get();
          if (customerDoc.exists) {
            final cd = customerDoc.data()!;
            customerName = cd['name'] ?? cd['displayName'] ?? 'Customer';
          }
        }
      } catch (e) {
        debugPrint('⚠️ Customer name fetch error: $e');
      }

      try {
        if (tailorId.toString().isNotEmpty) {
          final tailorDoc = await _firebaseService.firestore
              .collection('users')
              .doc(tailorId)
              .get();
          if (tailorDoc.exists) {
            final td = tailorDoc.data()!;
            tailorName = td['name'] ?? td['displayName'] ?? 'Tailor';
          }
        }
      } catch (e) {
        debugPrint('⚠️ Tailor name fetch error: $e');
      }

      final refundRequest = RefundRequestModel(
        orderId: orderId,
        customerId: customerId,
        tailorId: tailorId,
        paymentIntentId: paymentIntentId,
        cancellationReason: reason,
        cancellationDescription: description,
        refundStatus: RefundStatus.requested,
        customerName: customerName,
        tailorName: tailorName,
        paidAmount: (bookingData['totalAmount'] as num?)?.toDouble() ?? 0.0,
        bookingStatus: 'cancelled',
      );

      await _firebaseService.firestore
          .collection('refundRequests')
          .doc(orderId)
          .set(refundRequest.toCreateJson());

      await _firebaseService.firestore
          .collection('bookings')
          .doc(orderId)
          .update({
        'refundRequested': true,
        'refundRequestedAt': DateTime.now().toIso8601String(),
      });

      if (tailorId.isNotEmpty) {
        await NotificationService.instance.sendNotification(
          recipientId: tailorId,
          recipientRole: UserRole.artist,
          type: NotificationType.orderUpdate,
          title: 'Refund Requested',
          body: 'Customer ne refund ki request ki hai: $orderId',
          data: {'orderId': orderId, 'action': 'refundRequest'},
        );
      }

      AppHelpers.showSuccess('Refund request submitted.');
      await loadOrders();
      await _loadRefundRequest(orderId);
      debugPrint('✅ Refund request submitted successfully');
    } catch (e) {
      debugPrint('❌ Refund request error: $e');
      AppHelpers.showError('Failed to submit refund request: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String status) {
    filterStatus.value = status;
    debugPrint('🔍 Filter changed to: $status');
  }

  void removeOrderFromList(String orderId) {
    myOrders.removeWhere((o) => o.id == orderId);
    debugPrint('🗑️ Order removed from list: $orderId');
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