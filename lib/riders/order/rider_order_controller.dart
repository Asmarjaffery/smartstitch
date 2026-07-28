import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/ai/controller/ai_chat_controller.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/riders/profile/profile_rider_controller.dart';
import 'package:smartstitch/services/firebase_service.dart';
import 'package:smartstitch/services/notification_service.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/services/rider_assignment_service.dart';

class RiderOrderController extends GetxController {
  static RiderOrderController get to => Get.find();

  final FirebaseService _firebaseService = FirebaseService();
  final _db = FirebaseFirestore.instance;

  final RxList<Map<String, dynamic>> assignedOrders =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isTracking = false.obs;
  final RxString activeOrderId = ''.obs;
  final RxString riderId = ''.obs;
  final RxBool isOnline = false.obs;

  // Cache: userId → {name, phone}
  final Map<String, Map<String, dynamic>> _userCache = {};

  StreamSubscription<Position>? _locationSub;

  // real-time listener for "Ask AI to Call Rider" requests from
  // customers, and a guard so the same request doesn't pop the dialog twice.
  StreamSubscription<QuerySnapshot>? _callRequestSub;
  final Set<String> _handledCallRequests = {};

  @override
  void onClose() {
    _locationSub?.cancel();
    _callRequestSub?.cancel();
    super.onClose();
  }

  void toggleOnline() {
    isOnline.value = !isOnline.value;
  }

  // ─── Load assigned orders + enrich with names ─────────────────────────────
  Future<void> loadAssignedOrders(String rId) async {
    if (rId.isEmpty) {
      print("Error: riderId is EMPTY");
      return;
    }
    riderId.value = rId;

    try {
      isLoading.value = true;

      final snap = await _db
          .collection('bookings')
          .where('riderId', isEqualTo: rId)
          .get();

      final orders = snap.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      orders.sort((a, b) {
        final aDate = a['updatedAt'] as String? ?? '';
        final bDate = b['updatedAt'] as String? ?? '';
        return bDate.compareTo(aDate);
      });

      // Enrich each order with customer + artist info
      for (final order in orders) {
        final customerId = order['customerId'] as String? ?? '';
        final artistId = order['artistId'] as String? ?? '';

        if (customerId.isNotEmpty) {
          final info = await _fetchUserInfo(customerId);
          order['customerName'] = info['name'] ?? 'Customer';
          order['customerPhone'] = info['phone'] ?? '';
          // ✅ NEW: carry customer lat/lng through if we have it cached,
          // used as a fallback for the call-request map if the booking
          // document itself doesn't carry delivery coordinates.
          order['customerLat'] = info['lat'];
          order['customerLng'] = info['lng'];
        }

        if (artistId.isNotEmpty) {
          final info = await _fetchArtistInfo(artistId);
          order['artistName'] = info['name'] ?? 'Artist';
          order['artistPhone'] = info['phone'] ?? '';
          // shopAddress map — used on screen
          order['shopAddressMap'] = info['shopAddressMap'];
          order['shopFullAddress'] = info['shopFullAddress'] ?? 'Tailor Shop';
          order['shopCity'] = info['shopCity'] ?? '';
        }
      }

      assignedOrders.value = orders;
    } catch (e) {
      print('Load orders error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Listen for "Call Rider" requests from customers ──────────────────────
  // Lightweight real-time listener — separate from loadAssignedOrders() (which
  // is a one-time fetch) so we don't have to convert that whole enrichment
  // pipeline into a stream. Pops a dialog the moment a customer taps
  // "Ask AI to Call Rider" while this rider has this app open.
  void listenForCallRequests(String rId) {
    if (rId.isEmpty) return;
    _callRequestSub?.cancel();
    _callRequestSub = _db
        .collection('bookings')
        .where('riderId', isEqualTo: rId)
        .where('callRequestedByCustomer', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      for (final doc in snap.docs) {
        if (_handledCallRequests.contains(doc.id)) continue;
        _handledCallRequests.add(doc.id);
        _handleCallRequest(doc.id, doc.data());
      }
    }, onError: (e) => print('Call request listener error: $e'));
  }

  // ─── ✅ NEW: push an InDrive-style card into the rider's AI chat ──────────
  // No popup/dialog anymore — the request shows up as a message bubble
  // inside the rider's own "AI Assistant" chat (see ai_message_bubble.dart /
  // _CustomerCallCard), exactly like the customer-side "Call Rider" card.
  Future<void> _handleCallRequest(
      String orderId, Map<String, dynamic> data) async {
    // Prefer info already enriched in the local list; fall back to a
    // direct Firestore lookup if the order isn't in assignedOrders yet.
    final existing = assignedOrders.firstWhere(
      (o) => o['id'] == orderId,
      orElse: () => {},
    );

    String customerName = existing['customerName'] as String? ?? '';
    String customerPhone = existing['customerPhone'] as String? ?? '';
    double? lat = existing['customerLat'] as double?;
    double? lng = existing['customerLng'] as double?;

    if (customerPhone.isEmpty || customerName.isEmpty) {
      final customerId = data['customerId'] as String? ?? '';
      if (customerId.isNotEmpty) {
        final info = await _fetchUserInfo(customerId);
        customerPhone = customerPhone.isNotEmpty
            ? customerPhone
            : (info['phone'] as String? ?? '');
        customerName = customerName.isNotEmpty
            ? customerName
            : (info['name'] as String? ?? 'Customer');
        lat ??= info['lat'] as double?;
        lng ??= info['lng'] as double?;
      }
    }
    if (customerName.isEmpty) customerName = 'Customer';

    // Delivery-address coordinates coming straight from the booking doc take
    // priority over the customer's profile location — this is where the
    // rider actually needs to go / where the customer is calling from.
    // NOTE: adjust these keys if your booking schema names them differently
    // (this mirrors the same lat/lng-in-a-map pattern used for shopAddress).
    final deliveryAddr = data['deliveryAddress'] ?? data['address'];
    if (deliveryAddr is Map) {
      final dLat = (deliveryAddr['lat'] ?? deliveryAddr['latitude']);
      final dLng = (deliveryAddr['lng'] ?? deliveryAddr['longitude']);
      if (dLat is num) lat = dLat.toDouble();
      if (dLng is num) lng = dLng.toDouble();
    } else {
      final dLat = data['latitude'];
      final dLng = data['longitude'];
      if (dLat is num) lat = dLat.toDouble();
      if (dLng is num) lng = dLng.toDouble();
    }

    // If the rider's AI chat controller is already alive somewhere in
    // memory, just append the card directly — if they happen to already be
    // looking at the chat screen it'll appear live, InDrive-style. Either
    // way, take them to the chat screen so they actually see it.
    if (Get.isRegistered<AiChatController>()) {
      await AiChatController.to.sendCallCustomerAction(
        phone: customerPhone,
        name: customerName,
        lat: lat,
        lng: lng,
      );
      if (Get.currentRoute != AppRoutes.aiChat) {
        Get.toNamed(AppRoutes.aiChat);
      }
    } else {
      // Not initialized yet — navigate there and let ai_chat_screen.dart's
      // argument handling create the card once it boots up.
      Get.toNamed(AppRoutes.aiChat, arguments: {
        'type': 'callCustomer',
        'phone': customerPhone,
        'name': customerName,
        'lat': lat,
        'lng': lng,
      });
    }

    // Reset the flag on Firestore so it doesn't fire again on the next
    // snapshot, and let this order be handled again in future.
    try {
      await _db.collection('bookings').doc(orderId).update({
        'callRequestedByCustomer': false,
      });
    } catch (_) {}
    _handledCallRequests.remove(orderId);
  }

  // ─── ✅ NEW: Rider-initiated "Ask AI to Call Customer" ────────────────────
  // Mirrors order_detail_screen.dart's _askAiToCallRider() 1:1, just in the
  // other direction — notifies the customer, then shows the InDrive-style
  // card directly in the RIDER's own AI chat (no Firestore listener needed
  // here since the rider is the one initiating).
  Future<void> askAiToCallCustomer(Map<String, dynamic> order) async {
    final String orderId = order['id'] as String? ?? '';
    final String customerId = order['customerId'] as String? ?? '';
    final String customerName =
        order['customerName'] as String? ?? 'Customer';
    final String customerPhone = order['customerPhone'] as String? ?? '';
    double? lat = order['customerLat'] as double?;
    double? lng = order['customerLng'] as double?;

    // Delivery-address coordinates (confirmed field names from
    // order_controller.dart: address.latitude / address.longitude) take
    // priority over the customer's profile location.
    final addrRaw = order['address'];
    if (addrRaw is Map) {
      final dLat = addrRaw['latitude'] ?? addrRaw['lat'];
      final dLng = addrRaw['longitude'] ?? addrRaw['lng'];
      if (dLat is num) lat = dLat.toDouble();
      if (dLng is num) lng = dLng.toDouble();
    }

    try {
      if (customerId.isNotEmpty) {
        await NotificationService.instance.sendNotification(
          recipientId: customerId,
          recipientRole: UserRole.customer,
          type: NotificationType.orderUpdate,
          title: 'Rider Calling',
          body: 'Your rider wants to talk to you.',
          data: {'orderId': orderId, 'action': 'callRequest'},
        );
      }
    } catch (e) {
      print('Call customer notify error: $e');
    }

    if (Get.isRegistered<AiChatController>()) {
      await AiChatController.to.sendCallCustomerAction(
        phone: customerPhone,
        name: customerName,
        lat: lat,
        lng: lng,
        statusLabel: 'Wants to talk about the order',
      );
      if (Get.currentRoute != AppRoutes.aiChat) {
        Get.toNamed(AppRoutes.aiChat);
      }
    } else {
      Get.toNamed(AppRoutes.aiChat, arguments: {
        'type': 'callCustomer',
        'phone': customerPhone,
        'name': customerName,
        'lat': lat,
        'lng': lng,
        'status': 'Wants to talk about the order',
      });
    }
  }

  // ─── Fetch customer from `users` ──────────────────────────────────────────
  Future<Map<String, dynamic>> _fetchUserInfo(String userId) async {
    if (_userCache.containsKey(userId)) return _userCache[userId]!;
    try {
      final doc = await _db.collection('users').doc(userId).get();
      final data = doc.data() ?? {};

      // ✅ NEW: pull along a lat/lng if the user profile carries one
      // (e.g. `location: {lat, lng}` or top-level `latitude`/`longitude`),
      // used as a fallback for the call-request map.
      double? lat;
      double? lng;
      final loc = data['location'];
      if (loc is Map) {
        final rawLat = loc['lat'] ?? loc['latitude'];
        final rawLng = loc['lng'] ?? loc['longitude'];
        if (rawLat is num) lat = rawLat.toDouble();
        if (rawLng is num) lng = rawLng.toDouble();
      } else {
        final rawLat = data['latitude'];
        final rawLng = data['longitude'];
        if (rawLat is num) lat = rawLat.toDouble();
        if (rawLng is num) lng = rawLng.toDouble();
      }

      final info = <String, dynamic>{
        'name': data['name'] ?? data['displayName'] ?? 'Customer',
        'phone': data['phone'] ?? data['phoneNumber'] ?? '',
        'lat': lat,
        'lng': lng,
      };
      _userCache[userId] = info;
      return info;
    } catch (e) {
      print('Fetch user error: $e');
      return {'name': 'Customer', 'phone': '', 'lat': null, 'lng': null};
    }
  }

  // ─── Fetch artist from `artists` (fallback: `users`) ─────────────────────
  Future<Map<String, dynamic>> _fetchArtistInfo(String artistId) async {
    final cacheKey = 'artist_$artistId';
    if (_userCache.containsKey(cacheKey)) return _userCache[cacheKey]!;
    try {
      DocumentSnapshot doc =
          await _db.collection('artists').doc(artistId).get();
      Map<String, dynamic> data =
          (doc.exists ? doc.data() as Map<String, dynamic>? : null) ?? {};

      if (data.isEmpty) {
        doc = await _db.collection('users').doc(artistId).get();
        data =
            (doc.exists ? doc.data() as Map<String, dynamic>? : null) ?? {};
      }

      // shopAddress can be a nested map with fullAddress/city fields
      final shopAddrRaw = data['shopAddress'];
      Map<String, dynamic>? shopAddrMap;
      String shopFullAddress = 'Tailor Shop';
      String shopCity = '';

      if (shopAddrRaw is Map<String, dynamic>) {
        shopAddrMap = shopAddrRaw;
        shopFullAddress =
            shopAddrRaw['fullAddress'] as String? ?? 'Tailor Shop';
        shopCity = shopAddrRaw['city'] as String? ?? '';
      } else if (shopAddrRaw is String) {
        shopFullAddress = shopAddrRaw;
      }

      final info = <String, dynamic>{
        'name': data['name'] ?? data['displayName'] ?? 'Artist',
        'phone': data['phone'] ?? data['phoneNumber'] ?? '',
        'shopAddressMap': shopAddrMap,
        'shopFullAddress': shopFullAddress,
        'shopCity': shopCity,
      };
      _userCache[cacheKey] = info;
      return info;
    } catch (e) {
      print('Fetch artist error: $e');
      return {
        'name': 'Artist',
        'phone': '',
        'shopAddressMap': null,
        'shopFullAddress': 'Tailor Shop',
        'shopCity': '',
      };
    }
  }

  // ─── Accept order ─────────────────────────────────────────────────────────
  Future<void> acceptOrder(String orderId) async {
    try {
      await RiderAssignmentService.instance.riderAccepted(orderId);
      await _db.collection('bookings').doc(orderId).update({
        'riderStatus': 'accepted',
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await loadAssignedOrders(riderId.value);

      Get.snackbar(
        'Order Accepted',
        'You\'ve accepted the order — tap "Start Delivery" once you pick it up.',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Accept order error: $e');
    }
  }

  // ─── Reject order ─────────────────────────────────────────────────────────
  Future<void> rejectOrder(String orderId) async {
    try {
      await _db.collection('bookings').doc(orderId).update({
        'riderStatus': 'rejected',
        'riderId': null,
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
          title: 'Rider Rejected the Order',
          body:
              'Order $orderId has been rejected by the rider — please assign another rider.',
          data: {'orderId': orderId},
        );
      }

      await loadAssignedOrders(riderId.value);

      Get.snackbar(
        'Order Rejected',
        'The order has been rejected.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Reject order error: $e');
    }
  }

  // ─── Start delivery ───────────────────────────────────────────────────────
  Future<void> startDelivery(String orderId) async {
    final started = await _startLocationTracking(orderId);
    if (!started) return;

    try {
      await _db.collection('bookings').doc(orderId).update({
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
          title: 'Rider Started Delivery',
          body: 'Rider has started delivery for order $orderId.',
          data: {'orderId': orderId},
        );
      }

      activeOrderId.value = orderId;
      await loadAssignedOrders(riderId.value);

      Get.snackbar(
        'Delivery Started',
        'Location tracking is now on.',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Start delivery error: $e');
    }
  }

  // ─── Mark delivered ───────────────────────────────────────────────────────
  Future<void> markDelivered(String orderId) async {
    try {
      stopTracking();

      final bookingDoc =
          await _db.collection('bookings').doc(orderId).get();

      if (!bookingDoc.exists) {
        Get.snackbar('Error', 'Booking not found');
        return;
      }

      final data = bookingDoc.data();
      final customerId = data?['customerId'] as String?;
      final bookingRiderId = data?['riderId'] as String?;

      // Rider earning (Delivery Fee)
      final riderEarning =
          (data?['deliveryFee'] as num?)?.toDouble() ?? 0.0;

      // 1. Update booking status
      await _db.collection('bookings').doc(orderId).update({
        'status': 'delivered',
        'riderStatus': 'delivered',
        'riderLocation': FieldValue.delete(),
        'deliveredAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (bookingRiderId != null && bookingRiderId.isNotEmpty) {
        // 0. FIRST: Ensure wallet document exists with initial values
        print('Initializing wallet for $bookingRiderId...');
        await _db.collection('rider_wallets').doc(bookingRiderId).set({
          'riderId': bookingRiderId,
          'availableBalance': 0.0,
          'todayEarnings': 0.0,
          'weekEarnings': 0.0,
          'monthEarnings': 0.0,
          'lifetimeEarnings': 0.0,
          'pendingWithdrawal': 0.0,
          'totalTransactions': 0,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('Wallet doc initialized');

        // 2. Increase rider deliveries
        await _db.collection('riders').doc(bookingRiderId).set({
          'totalDeliveries': FieldValue.increment(1),
        }, SetOptions(merge: true));

        // 3. Update rider wallet - increment now works correctly
        print('Adding earnings: Rs. $riderEarning');
        await _db.collection('rider_wallets').doc(bookingRiderId).set({
          'availableBalance': FieldValue.increment(riderEarning),
          'todayEarnings': FieldValue.increment(riderEarning),
          'weekEarnings': FieldValue.increment(riderEarning),
          'monthEarnings': FieldValue.increment(riderEarning),
          'lifetimeEarnings': FieldValue.increment(riderEarning),
          'totalTransactions': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('Earnings added successfully');

        // 4. Save transaction history
        await _db.collection('wallet_transactions').add({
          'riderId': bookingRiderId,
          'orderId': orderId,
          'type': 'earning',
          'status': 'paid',
          'amount': riderEarning,
          'title': 'Delivery Earnings',
          'description': 'Earnings from completed order',
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Transaction recorded');

        // Reload rider profile if available
        if (Get.isRegistered<RiderProfileController>()) {
          await Get.find<RiderProfileController>().reloadRiderData();
        }
      }

      // 5. Customer notification
      if (customerId != null && customerId.isNotEmpty) {
        await NotificationService.instance.sendNotification(
          recipientId: customerId,
          recipientRole: UserRole.customer,
          type: NotificationType.orderUpdate,
          title: 'Order Delivered!',
          body: 'Your order has been delivered. Thank you for choosing SmartStitch!',
          data: {'orderId': orderId},
        );
      }

      await loadAssignedOrders(riderId.value);

      Get.snackbar(
        'Delivered!',
        'Order completed — Rs. ${riderEarning.toStringAsFixed(0)} has been added to your wallet.',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('Mark delivered error: $e');

      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  // ─── Location tracking ────────────────────────────────────────────────────
  Future<bool> _startLocationTracking(String orderId) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('Location Off', 'Please enable location services',
            backgroundColor: AppColors.error,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('Permission Denied', 'Location permission is required',
              backgroundColor: AppColors.error,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM);
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
            'Permission Blocked', 'Please enable location from device settings',
            backgroundColor: AppColors.error,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
        return false;
      }

      _locationSub?.cancel();
      isTracking.value = true;

      _locationSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen(
        (position) async {
          try {
            await _db.collection('bookings').doc(orderId).update({
              'riderLocation': {
                'lat': position.latitude,
                'lng': position.longitude,
                'updatedAt': FieldValue.serverTimestamp(),
              }
            });
          } catch (e) {
            print('Location update error: $e');
          }
        },
        onError: (e) {
          print('Location stream error: $e');
          isTracking.value = false;
        },
      );

      return true;
    } catch (e) {
      print('Start tracking error: $e');
      isTracking.value = false;
      return false;
    }
  }

  void stopTracking() {
    _locationSub?.cancel();
    _locationSub = null;
    isTracking.value = false;
    activeOrderId.value = '';
  }

  // ─── Legacy aliases ───────────────────────────────────────────────────────
  @Deprecated('Use startDelivery() instead')
  Future<void> startTracking(String orderId) => startDelivery(orderId);

  @Deprecated('Use markDelivered() instead')
  Future<void> updateOrderStatus(String orderId, String status) async {
    if (status == 'delivered') await markDelivered(orderId);
  }
}