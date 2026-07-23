import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartstitch/models/order_model.dart';
import 'package:smartstitch/models/enums.dart';

class ArtistOrderController extends GetxController {
  static ArtistOrderController get to => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get artistId => _auth.currentUser?.uid ?? '';

  final isLoading = true.obs;
  final orders = <OrderModel>[].obs;
  final filterStatus = 'all'.obs;
  final customerNames = <String, String>{}.obs;

  final _ordersMap = <String, OrderModel>{};
  final _bookingsMap = <String, OrderModel>{};

  // ─── Filtered Orders ──────────────────────────────────────────────────────
  List<OrderModel> get filteredOrders {
    switch (filterStatus.value) {
      case 'all':
        return orders;
      case 'new':
        return orders.where((o) => o.status == OrderStatus.pending).toList();
      case 'active':
        return orders
            .where((o) =>
                o.status == OrderStatus.accepted ||
                o.status == OrderStatus.inProgress)
            .toList();
      case 'completed':
        return orders
            .where((o) =>
                o.status == OrderStatus.stitchingCompleted ||
                o.status == OrderStatus.riderAssigned ||
                o.status == OrderStatus.delivered)
            .toList();
      case 'cancelled':
        return orders.where((o) => o.status == OrderStatus.cancelled).toList();
      default:
        return orders;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _listenToOrders();
  }

  // ─── Listen to Orders + Bookings assigned to this artist ───────────────────
  void _listenToOrders() {
    if (artistId.isEmpty) {
      isLoading.value = false;
      return;
    }

    // Orders collection
    _db
        .collection('orders')
        .where('artistId', isEqualTo: artistId)
        .snapshots()
        .listen((snap) {
      final list = snap.docs
          .map((doc) => OrderModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      _mergeOrders(list, 'orders');
    });

    // Bookings collection
    _db
        .collection('bookings')
        .where('artistId', isEqualTo: artistId)
        .snapshots()
        .listen((snap) {
      final now = DateTime.now().toIso8601String();
      final list = snap.docs.map((doc) {
        final d = doc.data();
        return OrderModel.fromJson({
          'id': doc.id,
          'customerId': d['customerId'] ?? '',
          'artistId': d['artistId'] ?? '',
          'riderId': null,
          'status': d['status'] ?? 'pending',
          'placedAt': d['createdAt'] ?? now,
          'updatedAt': d['updatedAt'] ?? now,
          'specialInstructions': d['specialInstructions'],
          'isHomeVisit': d['isHomeVisit'] ?? false,
          'appointmentDate': d['appointmentDate'],
          'service': {
            'id': d['serviceId'] ?? '',
            'name': d['serviceTitle'] ?? 'Service',
            'description': '',
            'price': (d['servicePrice'] ?? 0).toDouble(),
            'imageUrl': '',
            'isActive': true,
            'createdAt': now,
          },
          // ✅ Use the actual values saved in Firestore at booking-creation
          // time instead of recalculating here with different (wrong)
          // percentages — this keeps what the artist sees consistent with
          // what was actually stored (15% commission / 85% artist share).
          'servicePrice': (d['servicePrice'] ?? 0).toDouble(),
          'deliveryFee': (d['deliveryFee'] ?? 0).toDouble(),
          'totalAmount': (d['totalAmount'] ?? 0).toDouble(),
          'platformCommission': (d['platformCommission'] ??
                  ((d['servicePrice'] ?? 0) * 0.15))
              .toDouble(),
          'artistAmount': (d['artistAmount'] ??
                  ((d['servicePrice'] ?? 0) * 0.85))
              .toDouble(),
          'measurements': {
            'id': d['measurementId'] ?? '',
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
            'id': d['address']?['id'] ?? '',
            'label': d['bookingType'] == 'homeVisit'
                ? (d['address']?['label'] ?? 'Home')
                : 'Drop Off',
            'fullAddress': d['address']?['fullAddress'] ?? 'Drop Off at Studio',
            'city': d['address']?['city'] ?? 'N/A',
            'province': d['address']?['province'] ?? 'N/A',
            'latitude': (d['address']?['latitude'] ?? 0).toDouble(),
            'longitude': (d['address']?['longitude'] ?? 0).toDouble(),
            'isDefault': false,
          },
          'designImages':
              d['designImageUrl'] != null ? [d['designImageUrl']] : [],
          'payment': null,
          'measurementId': d['measurementId'],
        });
      }).toList();
      _mergeOrders(list, 'bookings');
    });
  }

  // ─── Merge both collections ───────────────────────────────────────────────
  void _mergeOrders(List<OrderModel> list, String source) {
    if (source == 'orders') {
      for (final o in list) {
        _ordersMap[o.id] = o;
      }
    } else {
      for (final o in list) {
        _bookingsMap[o.id] = o;
      }
    }
    final merged = [..._ordersMap.values, ..._bookingsMap.values];
    merged.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    orders.value = merged;
    isLoading.value = false;
    _fetchCustomerNames();
  }

  // ─── Fetch Customer Names ─────────────────────────────────────────────────
  Future<void> _fetchCustomerNames() async {
    final ids = orders.map((o) => o.customerId).toSet();
    for (final id in ids) {
      if (customerNames.containsKey(id)) continue;
      try {
        final doc = await _db.collection('users').doc(id).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          customerNames[id] = data['name'] ?? 'Unknown';
        }
      } catch (_) {}
    }
  }

  String getCustomerName(String id) => customerNames[id] ?? 'Customer';

  // ─── Helper: figure out which collection an order belongs to ──────────────
  Future<String> _collectionFor(String orderId) async {
    final orderDoc = await _db.collection('orders').doc(orderId).get();
    return orderDoc.exists ? 'orders' : 'bookings';
  }

  // ─── Accept Order ────────────────────────────────────────────────────────
  Future<void> acceptOrder(String orderId) async {
    try {
      final collection = await _collectionFor(orderId);
      await _db.collection(collection).doc(orderId).update({
        'status': OrderStatus.accepted.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      _showSuccess('Order accepted.');
    } catch (e) {
      _showError('Failed to accept order: $e');
    }
  }

  // ─── Reject Order ────────────────────────────────────────────────────────
  Future<void> rejectOrder(String orderId) async {
    try {
      final collection = await _collectionFor(orderId);
      await _db.collection(collection).doc(orderId).update({
        'status': OrderStatus.cancelled.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      _showSuccess('Order rejected.');
    } catch (e) {
      _showError('Failed to reject order: $e');
    }
  }

  // ─── Start Work (move to In Progress) ──────────────────────────────────────
  Future<void> startWork(String orderId) async {
    try {
      final collection = await _collectionFor(orderId);
      await _db.collection(collection).doc(orderId).update({
        'status': OrderStatus.inProgress.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      _showSuccess('Work started.');
    } catch (e) {
      _showError('Failed to update order: $e');
    }
  }

  // ─── Mark Stitching Completed ──────────────────────────────────────────────
  Future<void> markStitchingCompleted(String orderId) async {
    try {
      final collection = await _collectionFor(orderId);
      await _db.collection(collection).doc(orderId).update({
        'status': OrderStatus.stitchingCompleted.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      _showSuccess('Marked as stitching completed.');
    } catch (e) {
      _showError('Failed to update order: $e');
    }
  }

  void setFilter(String status) => filterStatus.value = status;

  void _showSuccess(String msg) => Get.snackbar(
        'Success',
        msg,
        backgroundColor: const Color(0xFF4CAF82),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

  void _showError(String msg) => Get.snackbar(
        'Error',
        msg,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
}