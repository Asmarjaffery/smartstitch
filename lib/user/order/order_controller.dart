import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/models/body_measurement_model.dart';
import 'package:smartstitch/models/booking_model.dart';
import 'package:smartstitch/models/order_model.dart';
import 'package:smartstitch/models/refund_model.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/services/firebase_service.dart';
import 'package:smartstitch/services/notification_service.dart';
import 'package:smartstitch/user/booking/booking_controller.dart';

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

  // ✅ NEW: raw `paymentMethod` string per order (e.g. 'cod', 'wallet',
  // 'card', 'stripe'), keyed by order/booking id. Used to gate the
  // "Request Refund" button so it only ever shows for card/Stripe
  // payments — COD and wallet orders never had money taken upfront in a
  // way that's refundable through this flow.
  final RxMap<String, String> orderPaymentMethods = <String, String>{}.obs;

  /// True only when the order was paid via card/Stripe. COD and wallet
  /// (and anything else) are treated as non-refundable through this flow.
  bool isCardPayment(String orderId) {
    final method = (orderPaymentMethods[orderId] ?? '').toLowerCase();
    return method == 'card' || method == 'stripe';
  }

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
      final paymentMethods = <String, String>{};
      int successCount = 0;
      int errorCount = 0;

      for (final doc in bookingSnap.docs) {
        try {
          final d = doc.data();

          debugPrint('📄 Processing booking: ${doc.id}');
          debugPrint('   Status: ${d['status']} | Service: ${d['serviceTitle']}');

          // ✅ NEW: track raw payment method (cod / wallet / card / stripe)
          // per order so the UI can gate refund eligibility on it.
          paymentMethods[doc.id] = (d['paymentMethod'] ?? 'cod').toString();

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
                d['designImageUrls'] != null && (d['designImageUrls'] as List).isNotEmpty
                    ? d['designImageUrls']
                    : (d['designImageUrl'] != null ? [d['designImageUrl']] : []),
            'payment': null,
            // ✅ Custom Design Quote Flow — so order list/detail screens
            // know whether this booking is waiting on the artist, waiting
            // on the customer's decision, or done.
            'quoteStatus': d['quoteStatus'],
            'quotedPrice': d['quotedPrice'],
            'quotedAt': d['quotedAt'],
            // ✅ Delivery Exception — rider-reported failed delivery.
            // These stay populated even while `status` is still stuck at
            // riderAssigned, so the customer UI can react to them directly.
            'riderStatus': d['riderStatus'],
            'deliveryExceptionReason': d['deliveryExceptionReason'],
            'lastDeliveryExceptionId': d['lastDeliveryExceptionId'],
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
      orderPaymentMethods.value = paymentMethods;

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

    // ✅ FIX: remember the status we already know about so we can detect
    // a *change* (e.g. cancelled by the artist/rider) instead of only
    // ever reading the rider's location.
    OrderStatus? lastKnownStatus = selectedOrder.value?.status;

    // ✅ `status` alone doesn't move when a delivery attempt fails —
    // rider side only flips `riderStatus`. Track it separately so the
    // customer gets notified even though `status` is still `riderAssigned`.
    String? lastKnownRiderStatus = selectedOrder.value?.riderStatus;

    _orderLocationSub = _firebaseService.firestore
        .collection('bookings')
        .doc(orderId)
        .snapshots()
        .listen((doc) async {
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;

      // ────────── Live rider location ──────────
      riderLocation.value = data['riderLocation'] as Map<String, dynamic>?;
      if (riderLocation.value != null) {
        debugPrint('📍 Rider location updated: ${riderLocation.value}');
      }

      // ✅ Keep payment method map fresh too, in case it's set/updated
      // after the initial load (e.g. payment completed after booking).
      final method = data['paymentMethod'];
      if (method != null) {
        orderPaymentMethods[orderId] = method.toString();
      }

      // ────────── Live status tracking ──────────
      // ✅ FIX: this is what actually lets the customer *find out* the
      // order was cancelled, in real time, without refreshing the screen.
      OrderStatus newStatus;
      try {
        newStatus = OrderStatus.values.byName(data['status'] ?? 'pending');
      } catch (e) {
        newStatus = OrderStatus.pending;
      }

      if (lastKnownStatus != null && lastKnownStatus != newStatus) {
        debugPrint('🔔 Order $orderId status changed: '
            '$lastKnownStatus -> $newStatus');

        if (newStatus == OrderStatus.cancelled) {
          AppHelpers.showError('Your order has been cancelled.');
          await _loadRefundRequest(orderId);
        }

        // Refresh the list + selected order so every screen (list,
        // detail, tracker) reflects the new status immediately.
        await loadOrders();
        for (final o in myOrders) {
          if (o.id == orderId) {
            selectedOrder.value = o;
            break;
          }
        }
      }
      lastKnownStatus = newStatus;

      // ────────── Live delivery-exception tracking ──────────
      // ✅ rider marks a failed delivery attempt by setting
      // `riderStatus: 'deliveryFailed'` on the booking doc — `status`
      // itself stays `riderAssigned` until admin resolves it. Without
      // this, the customer never finds out the delivery failed.
      final newRiderStatus = data['riderStatus'] as String?;
      if (newRiderStatus != lastKnownRiderStatus) {
        debugPrint('🔔 Order $orderId riderStatus changed: '
            '$lastKnownRiderStatus -> $newRiderStatus');

        if (newRiderStatus == 'deliveryFailed') {
          AppHelpers.showError(
              'Delivery failed. Check the order screen for details.');
        }

        await loadOrders();
        for (final o in myOrders) {
          if (o.id == orderId) {
            selectedOrder.value = o;
            break;
          }
        }
      }
      lastKnownRiderStatus = newRiderStatus;
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
        body: 'Customer cancelled the order: $orderId',
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

      // ✅ Safety net: even if this ever gets called from somewhere that
      // skipped the UI gate, refuse to create a refund request for a
      // non-card payment (COD / wallet / anything else).
      if (!isCardPayment(orderId)) {
        debugPrint('⚠️ Refund blocked — order $orderId is not a card payment '
            '(paymentMethod: ${orderPaymentMethods[orderId]})');
        AppHelpers.showError('Refunds are only available for card payments.');
        return;
      }

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
          body: 'Customer requested a refund: $orderId',
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

  // ✅ Reschedule flow — offered once an order has actually been
  // cancelled, OR once a rider has reported a failed delivery (since
  // `status` never leaves `riderAssigned` in that case, we check
  // `riderStatus` too). Reschedule is available regardless of payment
  // method — only the refund flow is card-only.
  bool canReschedule(OrderModel order) =>
      order.status == OrderStatus.cancelled || order.isDeliveryFailed;

  /// Puts a cancelled order back in front of the artist with a new
  /// appointment/delivery date, instead of the customer having to place
  /// a brand new booking from scratch.
  Future<void> rescheduleOrder(String orderId, DateTime newDate) async {
    try {
      isLoading.value = true;
      debugPrint('📅 Rescheduling order: $orderId -> $newDate');

      final bookingSnap = await _firebaseService.firestore
          .collection('bookings')
          .doc(orderId)
          .get();

      if (!bookingSnap.exists) {
        AppHelpers.showError('Order not found.');
        return;
      }

      final data = bookingSnap.data()!;
      final artistId = (data['artistId'] ?? '').toString();

      await _firebaseService.firestore.collection('bookings').doc(orderId).update({
        'status': OrderStatus.pending.name,
        'appointmentDate': newDate.toIso8601String(),
        'rescheduledAt': DateTime.now().toIso8601String(),
        // Clear any previous rider assignment — a rescheduled order starts
        // the pending → accepted → ... flow again.
        'riderId': null,
        'riderLocation': null,
        // ✅ clear the delivery-exception flags too, so a rescheduled
        // order doesn't still show as "delivery failed" once it's back in
        // the normal flow.
        'riderStatus': null,
        'deliveryExceptionReason': null,
      });

      if (artistId.isNotEmpty) {
        await NotificationService.instance.sendNotification(
          recipientId: artistId,
          recipientRole: UserRole.artist,
          type: NotificationType.orderUpdate,
          title: 'Order Rescheduled',
          body: 'Customer rescheduled the order: $orderId',
          data: {'orderId': orderId, 'action': 'reschedule'},
        );
      }

      AppHelpers.showSuccess('Order has been rescheduled.');
      await loadOrders();
      for (final o in myOrders) {
        if (o.id == orderId) {
          selectedOrder.value = o;
          break;
        }
      }
      debugPrint('✅ Order rescheduled successfully');
    } catch (e) {
      debugPrint('❌ Reschedule error: $e');
      AppHelpers.showError('Failed to reschedule: $e');
    } finally {
      isLoading.value = false;
    }
  }

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

  // ─── Custom Design Quote Flow ──────────────────────────────────────────
  // OrderModel is a read-only projection of the raw `bookings` doc, so the
  // actual quote-accept payment flow (Stripe/cash, Firestore writes,
  // artist notification) stays owned by BookingController — this just
  // fetches the full booking doc and hands it off, then refreshes the
  // local list once the follow-up screen is done.

  /// Fetches the full booking behind [order] and takes the customer to the
  /// Confirm Payment screen to accept the artist's quote.
  Future<void> acceptQuote(OrderModel order) async {
    try {
      final doc = await _firebaseService.firestore
          .collection('bookings')
          .doc(order.id)
          .get();
      if (!doc.exists) {
        AppHelpers.showError('Booking not found.');
        return;
      }
      final booking = BookingModel.fromJson({...doc.data()!, 'id': doc.id});
      BookingController.to.acceptQuote(booking);
    } catch (e) {
      AppHelpers.showError('Failed to load quote.');
    }
  }

  /// Declines the artist's quote for [order] — cancels the booking since
  /// no payment was ever taken for it — then refreshes the order list.
  Future<void> declineQuote(OrderModel order) async {
    try {
      final doc = await _firebaseService.firestore
          .collection('bookings')
          .doc(order.id)
          .get();
      if (!doc.exists) {
        AppHelpers.showError('Booking not found.');
        return;
      }
      final booking = BookingModel.fromJson({...doc.data()!, 'id': doc.id});
      await BookingController.to.declineQuote(booking);
      await loadOrders();
    } catch (e) {
      AppHelpers.showError('Failed to decline quote.');
    }
  }
}