import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class ArtistDashboardController extends GetxController {
  final _db = FirebaseFirestore.instance;

  final isLoading = false.obs;
  final totalOrders = 0.obs;
  final totalEarnings = '0'.obs;
  final rating = 0.0.obs;
  final isAvailable = true.obs;
  final RxList<Map<String, dynamic>> pendingOrders =
      <Map<String, dynamic>>[].obs;

  String get artistId => AuthController.to.currentUser.value?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    if (artistId.isEmpty) return;
    try {
      isLoading.value = true;
      await Future.wait([
        _fetchArtistStats(),
        _fetchPendingOrders(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchArtistStats() async {
    try {
      // Artist profile se rating aur availability
      final doc = await _db.collection('artists').doc(artistId).get();
      if (doc.exists) {
        final data = doc.data()!;
        rating.value = (data['rating'] as num?)?.toDouble() ?? 0.0;
        isAvailable.value = (data['isAvailable'] as bool?) ?? true;
      }

      // ✅ Total orders — bookings se
      final allSnap = await _db
          .collection('bookings')
          .where('artistId', isEqualTo: artistId)
          .get();
      totalOrders.value = allSnap.docs.length;

      // ✅ Earnings — sirf delivered orders ka 85%
      final deliveredSnap = await _db
          .collection('bookings')
          .where('artistId', isEqualTo: artistId)
          .where('status', isEqualTo: 'delivered')
          .get();

      int earnings = 0;
      for (final doc in deliveredSnap.docs) {
        final price = (doc.data()['servicePrice'] as num?)?.toInt() ?? 0;
        // Artist = 85% (platform 15% katega, rider alag customer se lega)
        final artistAmount = (price * 0.85).toInt();
        earnings += artistAmount;
      }

      totalEarnings.value = earnings >= 1000
          ? '${(earnings / 1000).toStringAsFixed(1)}K'
          : '$earnings';
    } catch (e) {
      print('Stats error: $e');
    }
  }

  Future<void> _fetchPendingOrders() async {
    try {
      const activeStatuses = [
        'pending',
        'accepted',
        'inProgress',
        'stitchingCompleted',
        'riderAssigned',
      ];

      final results = await Future.wait([
        _db
            .collection('orders')
            .where('artistId', isEqualTo: artistId)
            .where('status', whereIn: activeStatuses)
            .get(),
        _db
            .collection('bookings')
            .where('artistId', isEqualTo: artistId)
            .where('status', whereIn: activeStatuses)
            .get(),
      ]);

      final allOrders = <Map<String, dynamic>>[];

      for (final snap in results) {
        for (final doc in snap.docs) {
          final data = doc.data();

          // ✅ Full order price (jo customer pay karta hai)
          final int totalAmount =
              ((data['totalAmount'] ?? data['servicePrice'] ?? 0) as num)
                  .toInt();

          // ✅ Artist ka hissa — wallet earnings jaisa hi 85% split
          final int artistEarning = (totalAmount * 0.85).toInt();

          allOrders.add({
            ...data,
            'id': doc.id,
            'customerName': data['customerName'] ?? '',
            'customerId': data['customerId'] ?? '',
            'designTitle':
                data['designTitle'] ?? data['serviceTitle'] ?? 'Order',
            'totalAmount': totalAmount, // full order price
            'artistEarning': artistEarning, // artist ka 85% hissa
          });
        }
      }
      final customerIds = allOrders
          .where((o) =>
              (o['customerName'] as String).isEmpty &&
              (o['customerId'] as String).isNotEmpty)
          .map((o) => o['customerId'] as String)
          .toSet();

      final nameMap = <String, String>{};
      for (final id in customerIds) {
        try {
          final doc = await _db.collection('users').doc(id).get();
          if (doc.exists) {
            nameMap[id] = doc.data()?['name'] ?? 'Customer';
          }
        } catch (_) {}
      }
      for (final order in allOrders) {
        if ((order['customerName'] as String).isEmpty) {
          final id = order['customerId'] as String;
          order['customerName'] = nameMap[id] ?? 'Customer';
        }
      }

      // Sort by createdAt descending
      allOrders.sort((a, b) {
        final aDate = a['createdAt'] as String? ?? '';
        final bDate = b['createdAt'] as String? ?? '';
        return bDate.compareTo(aDate);
      });

      pendingOrders.value = allOrders;
      print('✅ Orders: ${allOrders.length}');
    } catch (e) {
      print('❌ Orders error: $e');
    }
  }

  Future<void> toggleAvailability() async {
    try {
      final newVal = !isAvailable.value;
      await _db.collection('artists').doc(artistId).update({
        'isAvailable': newVal,
      });
      isAvailable.value = newVal;
    } catch (e) {
      print('Toggle error: $e');
    }
  }
}