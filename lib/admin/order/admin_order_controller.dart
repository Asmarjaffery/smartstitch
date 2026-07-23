import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/models/order_model.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/services/rider_assignment_service.dart';
import 'package:smartstitch/services/rider_service.dart';


// ─── Simple User Model ────────────────────────────────────────────────────────


class SimpleUser {
  final String id;
  final String name;
  final String phone;
  final String role;

  SimpleUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });

  factory SimpleUser.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SimpleUser(
      id: doc.id,
      name: d['name'] ?? 'Unknown',
      phone: d['phone'] ?? '',
      role: d['role'] ?? '',
    );
  }
}


// ─── Admin Order Controller ───────────────────────────────────────────────────


class AdminOrderController extends GetxController {
  static AdminOrderController get to => Get.find();

  final _db = FirebaseFirestore.instance;

  final isLoading = false.obs;
  final orders = <OrderModel>[].obs;
  final artists = <SimpleUser>[].obs;
  final riders = <SimpleUser>[].obs;
  final filterStatus = 'all'.obs;
  final customerNames = <String, String>{}.obs;

  final _ordersMap = <String, OrderModel>{};
  final _bookingsMap = <String, OrderModel>{};

  final Rx<Map<String, dynamic>?> riderLocation = Rx<Map<String, dynamic>?>(null);
  StreamSubscription<DocumentSnapshot>? _riderLocationSub;

  // ─── Self Pickup Helper ───────────────────────────────────────────────────
  bool isSelfPickup(OrderModel order) =>
      order.deliveryAddress.label == 'Drop Off';

  // ─── Filtered Orders ──────────────────────────────────────────────────────
  List<OrderModel> get filteredOrders {
    switch (filterStatus.value) {
      case 'all':
        return orders;
      case 'pending':
        return orders
            .where((o) =>
                o.status == OrderStatus.pending ||
                o.status == OrderStatus.accepted)
            .toList();
      case 'inProgress':
        return orders
            .where((o) =>
                o.status == OrderStatus.inProgress ||
                o.status == OrderStatus.stitchingCompleted ||
                o.status == OrderStatus.riderAssigned)
            .toList();
      case 'delivered':
        return orders.where((o) => o.status == OrderStatus.delivered).toList();
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
    _loadArtists();
    _loadRiders();
  }

  // ─── Listen to Orders + Bookings ─────────────────────────────────────────
  void _listenToOrders() {
    _db
        .collection('orders')
        .orderBy('placedAt', descending: true)
        .snapshots()
        .listen((snap) {
      final list = snap.docs
          .map((doc) => OrderModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      _mergeOrders(list, 'orders');
    });

    _db
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      final now = DateTime.now().toIso8601String();
      final list = snap.docs.map((doc) {
        final d = doc.data();
        return OrderModel.fromJson({
          'id': doc.id,
          'customerId': d['customerId'] ?? '',
          'artistId': d['artistId'] ?? '',
          'riderId': d['riderId'],
          'status': d['status'] ?? 'pending',
          'placedAt': d['createdAt'] ?? now,
          'updatedAt': d['updatedAt'] ?? now,
          'specialInstructions': d['specialInstructions'],
          'isHomeVisit': d['isHomeVisit'] ?? false,
          'appointmentDate': d['appointmentDate'],
          'service': {
            'id': d['serviceId'] ?? '',
            'name': d['serviceTitle'] ?? 'Service',
            'title': d['serviceTitle'] ?? 'Service',
            'description': '',
            'price': (d['servicePrice'] ?? 0).toDouble(),
            'basePrice': (d['servicePrice'] ?? 0).toDouble(),
            'imageUrl': '',
            'isActive': true,
            'createdAt': now,
          },
          // Use the correct fields from Firestore as-is
          'servicePrice': (d['servicePrice'] ?? 0).toDouble(),
          'deliveryFee': (d['deliveryFee'] ?? 0).toDouble(),
          'totalAmount': (d['totalAmount'] ?? d['servicePrice'] ?? 0).toDouble(),
          'platformCommission': (d['platformCommission'] ?? (d['servicePrice'] ?? 0) * 0.15).toDouble(),
          'artistAmount': (d['artistAmount'] ?? (d['servicePrice'] ?? 0) * 0.85).toDouble(),
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
          'riderLocation': d['riderLocation'],
          'designImages':
              d['designImageUrl'] != null ? [d['designImageUrl']] : [],
          'payment': null,
        });
      }).toList();
      _mergeOrders(list, 'bookings');
    });
  }

  // ─── Live Rider Location ──────────────────────────────────────────────────
  void listenToOrderLocation(String orderId) {
    _riderLocationSub?.cancel();
    riderLocation.value = null;
    _riderLocationSub = _db
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

  void stopListeningLocation() {
    _riderLocationSub?.cancel();
    _riderLocationSub = null;
    riderLocation.value = null;
  }

  @override
  void onClose() {
    _riderLocationSub?.cancel();
    super.onClose();
  }

  void _mergeOrders(List<OrderModel> list, String source) {
    if (source == 'orders') {
      for (final o in list) _ordersMap[o.id] = o;
    } else {
      for (final o in list) _bookingsMap[o.id] = o;
    }
    final merged = [..._ordersMap.values, ..._bookingsMap.values];
    merged.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    orders.value = merged;
    _fetchCustomerNames();
  }

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

  Future<void> _loadArtists() async {
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'artist')
          .get();
      artists.value = snap.docs.map((d) => SimpleUser.fromDoc(d)).toList();
    } catch (e) {
      debugPrint('❌ Artists load error: $e');
    }
  }

  Future<void> _loadRiders() async {
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'rider')
          .where('isBlocked', isEqualTo: false)
          .get();
      riders.value = snap.docs.map((d) => SimpleUser.fromDoc(d)).toList();
    } catch (e) {
      debugPrint('❌ Riders load error: $e');
    }
  }

  // ─── Assign Artist ────────────────────────────────────────────────────────
  Future<void> assignArtist(String orderId, String artistId) async {
    try {
      final orderDoc = await _db.collection('orders').doc(orderId).get();
      final collection = orderDoc.exists ? 'orders' : 'bookings';

      await _db.collection(collection).doc(orderId).update({
        'artistId': artistId,
        'status': OrderStatus.accepted.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      _showSuccess('Artist has been assigned.');
    } catch (e) {
      _showError('Artist could not be assigned: $e');
    }
  }

  // ─── Assign Rider ─────────────────────────────────────────────────────────
  Future<void> assignRider(String orderId, String riderId) async {
    try {
      final order = orders.firstWhereOrNull((o) => o.id == orderId);
      if (order != null && isSelfPickup(order)) {
        _showError('This is a Self Pickup order — rider is not needed.');
        return;
      }

      final allRiderIds = riders.map((r) => r.id).toList();

      await RiderAssignmentService.instance.assignRiderWithTimeout(
        orderId: orderId,
        riderId: riderId,
        allRiderIds: allRiderIds,
      );

      _showSuccess('Rider has been assigned — they must accept within 60 seconds.');
    } catch (e) {
      _showError('Rider could not be assigned: $e');
    }
  }

  // ─── Update Status ────────────────────────────────────────────────────────
  Future<void> updateStatus(String orderId, OrderStatus newStatus) async {
    try {
      final orderDoc = await _db.collection('orders').doc(orderId).get();
      final collection = orderDoc.exists ? 'orders' : 'bookings';

      await _db.collection(collection).doc(orderId).update({
        'status': newStatus.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      _showSuccess('Status has been updated.');
    } catch (e) {
      _showError('Status could not be updated: $e');
    }
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────
  void showAssignArtistDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => _AssignDialog(
        title: 'Assign Artist',
        subtitle: 'Select an artist for this order',
        users: artists,
        currentId: order.artistId.isEmpty ? null : order.artistId,
        onSelect: (userId) {
          Navigator.pop(ctx);
          assignArtist(order.id, userId);
        },
      ),
    );
  }

  void showAssignRiderDialog(BuildContext context, OrderModel order) {
    if (isSelfPickup(order)) {
      _showError('This is a Self Pickup order — rider is not needed.');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _AssignDialog(
        title: 'Assign Rider',
        subtitle: 'Select a rider for delivery (60s timeout)',
        users: riders,
        currentId: order.riderId,
        onSelect: (userId) {
          Navigator.pop(ctx);
          assignRider(order.id, userId);
        },
      ),
    );
  }

  void showStatusDialog(BuildContext context, OrderModel order) {
    final statuses = isSelfPickup(order)
        ? OrderStatus.values
            .where((s) => s != OrderStatus.riderAssigned)
            .toList()
        : OrderStatus.values;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Status'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: statuses.length,
            itemBuilder: (_, i) {
              final s = statuses[i];
              final isCurrent = s == order.status;
              return ListTile(
                dense: true,
                leading: Icon(
                  isCurrent
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isCurrent ? Colors.purple : Colors.grey,
                ),
                title: Text(
                  _statusLabel(s),
                  style: TextStyle(
                    fontWeight:
                        isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: s == OrderStatus.cancelled ? Colors.red : null,
                  ),
                ),
                onTap: isCurrent
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        updateStatus(order.id, s);
                      },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void setFilter(String status) => filterStatus.value = status;

  String _statusLabel(OrderStatus s) => switch (s) {
        OrderStatus.pending => 'Pending',
        OrderStatus.accepted => 'Accepted',
        OrderStatus.inProgress => 'In Progress',
        OrderStatus.stitchingCompleted => 'Stitching Completed',
        OrderStatus.riderAssigned => 'On Delivery',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };

  void _showSuccess(String msg) => Get.snackbar(
        'Success', msg,
        backgroundColor: Colors.green, colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16), borderRadius: 12,
      );

  void _showError(String msg) => Get.snackbar(
        'Error', msg,
        backgroundColor: Colors.red, colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16), borderRadius: 12,
      );
}


// ─── Reusable Assign Dialog ───────────────────────────────────────────────────


class _AssignDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<SimpleUser> users;
  final String? currentId;
  final void Function(String userId) onSelect;

  const _AssignDialog({
    required this.title,
    required this.subtitle,
    required this.users,
    required this.currentId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return AlertDialog(
        title: Text(title),
        content: const Text('No users are available.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (_, i) {
                  final user = users[i];
                  final isCurrent = user.id == currentId;
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade100,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.purple),
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.phone),
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () => onSelect(user.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}