import 'package:cloud_firestore/cloud_firestore.dart';

/// Fetches rider-specific context from Firestore for AI prompts.
class RiderContext {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetch(String userId) async {
    final results = await Future.wait([
      _getRider(userId),
      _getAssignedDeliveries(userId),
      _getWallet(userId),
    ]);

    return {
      'rider': results[0],
      'assignedDeliveries': results[1],
      'wallet': results[2],
    };
  }

  Future<Map<String, dynamic>> _getRider(String userId) async {
    try {
      final doc = await _db.collection('riders').doc(userId).get();
      if (!doc.exists) return {};
      final d = doc.data()!;
      return {
        'name': d['name'],
        'phone': d['phone'],
        'isAvailable': d['isAvailable'],
      };
    } catch (e) {
      // ignore: avoid_print
      print('[RiderContext] ERROR: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _getAssignedDeliveries(String userId) async {
    try {
      final snap = await _db
          .collection('bookings')
          .where('riderId', isEqualTo: userId)
          .where('status', whereIn: ['riderAssigned', 'inProgress'])
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final deliveries = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = d.data();
        final artistId = data['artistId'] as String?;

        // Pickup point = artist's shop address (from the artists collection).
        Map<String, dynamic>? pickupAddress;
        if (artistId != null && artistId.isNotEmpty) {
          try {
            final artistDoc = await _db.collection('artists').doc(artistId).get();
            final shop = artistDoc.data()?['shopAddress'] as Map<String, dynamic>?;
            if (shop != null) {
              pickupAddress = {
                'fullAddress': shop['fullAddress'],
                'city': shop['city'],
              };
            }
          } catch (e) {
            // ignore: avoid_print
            print('[RiderContext] pickup address fetch ERROR: $e');
          }
        }

        deliveries.add({
          'id': d.id,
          'customerName': data['customerName'],
          'customerPhone': data['customerPhone'],
          'artistName': data['artistName'],
          // NOTE: Firestore field is 'address' (a nested object with
          // fullAddress/city/etc — see AddressModel), NOT 'deliveryAddress'.
          // Will be null for dropOff-type orders (no home visit).
          'deliveryAddress': (data['address'] as Map<String, dynamic>?)?['fullAddress'],
          'pickupAddress': pickupAddress,
          'status': data['status'],
        });
      }
      return deliveries;
    } catch (e) {
      // ignore: avoid_print
      print('[RiderContext] ERROR: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _getWallet(String userId) async {
    try {
      final snap = await _db
          .collection('rider_wallets')
          .where('riderId', isEqualTo: userId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return {};
      final d = snap.docs.first.data();
      // ASSUMPTION: same field names as artist_wallets (availableBalance /
      // lifetimeEarnings / monthEarnings). If rider_wallets uses different
      // field names, check the console print below and adjust.
      // ignore: avoid_print
      print('[RiderContext] wallet doc raw fields: ${d.keys.toList()}');
      return {
        'availableBalance': d['availableBalance'],
        'lifetimeEarnings': d['lifetimeEarnings'],
        'monthEarnings': d['monthEarnings'],
        'weekEarnings': d['weekEarnings'],
        'todayEarnings': d['todayEarnings'],
      };
    } catch (e) {
      // ignore: avoid_print
      print('[RiderContext] ERROR: $e');
      return {};
    }
  }

  String toSummary(Map<String, dynamic> ctx) {
    final rider = ctx['rider'] as Map? ?? {};
    final deliveries = ctx['assignedDeliveries'] as List? ?? [];
    final wallet = ctx['wallet'] as Map? ?? {};

    final buf = StringBuffer();
    buf.writeln('Rider: ${rider['name'] ?? 'Unknown'} | '
        'Available: ${rider['isAvailable'] ?? false}');

    if (wallet.isNotEmpty) {
      buf.writeln('Wallet: Available Balance PKR ${wallet['availableBalance'] ?? 0} | '
          'Lifetime Earnings PKR ${wallet['lifetimeEarnings'] ?? 0} | '
          'This Month PKR ${wallet['monthEarnings'] ?? 0} | '
          'This Week PKR ${wallet['weekEarnings'] ?? 0} | '
          'Today PKR ${wallet['todayEarnings'] ?? 0}');
    }

    buf.writeln('Assigned Deliveries (${deliveries.length}):');
    for (final d in deliveries) {
      final pickup = d['pickupAddress'] as Map?;
      final pickupText = pickup != null
          ? '${pickup['fullAddress'] ?? ''}${pickup['city'] != null ? ', ${pickup['city']}' : ''}'
          : 'Not available';
      buf.writeln('  - #${(d['id'] as String?)?.substring(0, 8) ?? '?'} | '
          'Customer: ${d['customerName']} | '
          'Artist: ${d['artistName']} | Status: ${d['status']} | '
          'Pickup (from artist): $pickupText | '
          'Drop-off (to customer): ${d['deliveryAddress'] ?? 'N/A (not a home-visit order)'}');
    }

    return buf.toString();
  }
}