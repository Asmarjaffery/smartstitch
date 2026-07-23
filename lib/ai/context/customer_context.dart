import 'package:cloud_firestore/cloud_firestore.dart';

/// Fetches customer-specific context from Firestore for AI prompts.
class CustomerContext {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetch(String userId) async {
    final results = await Future.wait([
      _getUser(userId),
      _getRecentBookings(userId),
      _getWallet(userId),
      _getMeasurements(userId),
    ]);

    return {
      'user': results[0],
      'recentBookings': results[1],
      'wallet': results[2],
      'measurements': results[3],
    };
  }

  Future<Map<String, dynamic>> _getUser(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return {};
      final d = doc.data()!;
      return {
        'name': d['name'],
        'email': d['email'],
        'phone': d['phone'],
        'preferredLanguage': d['preferredLanguage'],
      };
    } catch (e) {
      // ignore: avoid_print
      print('[CustomerContext] ERROR: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentBookings(String userId) async {
    try {
      final snap = await _db
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'status': data['status'],
          'paymentStatus': data['paymentStatus'],
          'totalAmount': data['totalAmount'],
          'artistName': data['artistName'],
          'createdAt': data['createdAt']?.toString(),
        };
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('[CustomerContext] ERROR: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _getWallet(String userId) async {
    try {
      final snap = await _db
          .collection('wallets')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return {};
      final d = snap.docs.first.data();
      return {
        'balance': d['balance'],
        'currency': d['currency'] ?? 'PKR',
      };
    } catch (e) {
      // ignore: avoid_print
      print('[CustomerContext] ERROR: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getMeasurements(String userId) async {
    try {
      final snap = await _db
          .collection('measurements')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return {};
      final d = snap.docs.first.data();
      return {
        'chest': d['chest'],
        'waist': d['waist'],
        'shoulder': d['shoulder'],
        'height': d['height'],
        'hip': d['hip'],
      };
    } catch (e) {
      // ignore: avoid_print
      print('[CustomerContext] ERROR: $e');
      return {};
    }
  }

  String toSummary(Map<String, dynamic> ctx) {
    final user = ctx['user'] as Map? ?? {};
    final bookings = ctx['recentBookings'] as List? ?? [];
    final wallet = ctx['wallet'] as Map? ?? {};
    final m = ctx['measurements'] as Map? ?? {};

    final buf = StringBuffer();
    buf.writeln('Customer: ${user['name'] ?? 'Unknown'} (${user['email'] ?? ''})');

    if (wallet['balance'] != null) {
      buf.writeln('Wallet Balance: PKR ${wallet['balance']}');
    }

    if (bookings.isNotEmpty) {
      buf.writeln('Recent Bookings (${bookings.length}):');
      for (final b in bookings) {
        buf.writeln('  - #${(b['id'] as String?)?.substring(0, 8) ?? '?'} | '
            'Status: ${b['status']} | Payment: ${b['paymentStatus']} | '
            'Amount: PKR ${b['totalAmount']}');
      }
    } else {
      buf.writeln('No recent bookings.');
    }

    if (m.isNotEmpty) {
      buf.writeln('Saved Measurements: Chest ${m['chest']}cm, '
          'Waist ${m['waist']}cm, Shoulder ${m['shoulder']}cm, '
          'Height ${m['height']}cm');
    } else {
      buf.writeln('No saved measurements.');
    }

    return buf.toString();
  }
}