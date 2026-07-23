import 'package:cloud_firestore/cloud_firestore.dart';

/// Fetches admin-level platform analytics from Firestore for AI prompts.
class AdminContext {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetch(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    final results = await Future.wait<Map<String, dynamic>>([
      _getBookingStats(startOfDay, startOfMonth),
      _getRevenueStats(startOfDay, startOfMonth),
      _getUserStats(startOfDay),
      _getPendingWithdrawals(),
      _getTopArtistThisMonth(startOfMonth),
    ]);

    return {
      'bookings': results[0],
      'revenue': results[1],
      'users': results[2],
      'pendingWithdrawals': results[3],
      'topArtist': results[4],
    };
  }

  // Firestore stores createdAt as either a String (most collections) or a
  // Timestamp (some older docs) — handle both instead of assuming Timestamp.
  DateTime? _parseDate(dynamic ts) {
    if (ts == null) return null;
    if (ts is Timestamp) return ts.toDate();
    if (ts is String) {
      try {
        return DateTime.parse(ts);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> _getBookingStats(
      DateTime startOfDay, DateTime startOfMonth) async {
    try {
      final all = await _db.collection('bookings').get();
      final docs = all.docs.map((d) => d.data()).toList();

      int total = docs.length;
      int pending = docs.where((d) => d['status'] == 'pending').length;
      int completed = docs.where((d) => d['status'] == 'delivered').length;
      int cancelled = docs.where((d) => d['status'] == 'cancelled').length;

      return {
        'total': total,
        'pending': pending,
        'completed': completed,
        'cancelled': cancelled,
      };
    } catch (e) {
      // ignore: avoid_print
      print('[AdminContext] ERROR: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getRevenueStats(
      DateTime startOfDay, DateTime startOfMonth) async {
    try {
      final snap = await _db
          .collection('bookings')
          .where('paymentStatus', isEqualTo: 'paid')
          .get();

      double total = 0;
      double monthly = 0;
      double today = 0;
      for (final doc in snap.docs) {
        final d = doc.data();
        final amount = (d['totalAmount'] as num?)?.toDouble() ?? 0;
        total += amount;
        final date = _parseDate(d['createdAt']);
        if (date != null) {
          if (date.isAfter(startOfMonth)) monthly += amount;
          if (date.isAfter(startOfDay)) today += amount;
        }
      }
      return {
        'totalRevenue': total.toStringAsFixed(0),
        'monthlyRevenue': monthly.toStringAsFixed(0),
        'todayRevenue': today.toStringAsFixed(0),
      };
    } catch (e) {
      // ignore: avoid_print
      print('[AdminContext] ERROR: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getUserStats(DateTime startOfDay) async {
    try {
      final users = await _db.collection('users').get();
      final artists = await _db.collection('artists').get();
      final riders = await _db.collection('riders').get();

      return {
        'totalUsers': users.size,
        'totalArtists': artists.size,
        'totalRiders': riders.size,
      };
    } catch (e) {
      // ignore: avoid_print
      print('[AdminContext] ERROR: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getPendingWithdrawals() async {
    try {
      final snap = await _db
          .collection('withdrawal_requests')
          .where('status', isEqualTo: 'pending')
          .get();
      return {
        'count': snap.size,
      };
    } catch (e) {
      // ignore: avoid_print
      print('[AdminContext] ERROR: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getTopArtistThisMonth(
      DateTime startOfMonth) async {
    try {
      final snap = await _db
          .collection('bookings')
          .where('paymentStatus', isEqualTo: 'paid')
          .get();

      final Map<String, double> earnings = {};
      final Map<String, int> counts = {};
      for (final doc in snap.docs) {
        final d = doc.data();
        final date = _parseDate(d['createdAt']);
        if (date == null || date.isBefore(startOfMonth)) continue;
        final artistId = d['artistId'] as String?;
        if (artistId == null) continue;
        final amount = (d['totalAmount'] as num?)?.toDouble() ?? 0;
        earnings[artistId] = (earnings[artistId] ?? 0) + amount;
        counts[artistId] = (counts[artistId] ?? 0) + 1;
      }

      if (earnings.isEmpty) return {};

      final topEntry =
          earnings.entries.reduce((a, b) => a.value >= b.value ? a : b);

      final artistDoc =
          await _db.collection('artists').doc(topEntry.key).get();
      final artistData = artistDoc.data();
      final artistName =
          artistData?['name'] ?? artistData?['fullName'] ?? 'Unknown';

      return {
        'name': artistName,
        'earnings': topEntry.value.toStringAsFixed(0),
        'bookings': counts[topEntry.key],
      };
    } catch (e) {
      // ignore: avoid_print
      print('[AdminContext] ERROR: $e');
      return {};
    }
  }

  String toSummary(Map<String, dynamic> ctx) {
    final bookings = ctx['bookings'] as Map? ?? {};
    final revenue = ctx['revenue'] as Map? ?? {};
    final users = ctx['users'] as Map? ?? {};
    final withdrawals = ctx['pendingWithdrawals'] as Map? ?? {};
    final topArtist = ctx['topArtist'] as Map? ?? {};

    final buf = StringBuffer();
    buf.writeln('=== PLATFORM SUMMARY ===');

    buf.writeln('Users: Total ${users['totalUsers']} | '
        'Artists: ${users['totalArtists']} | '
        'Riders: ${users['totalRiders']}');

    buf.writeln('Bookings: Total ${bookings['total']} | '
        'Pending: ${bookings['pending']} | '
        'Completed: ${bookings['completed']} | '
        'Cancelled: ${bookings['cancelled']}');

    buf.writeln('Revenue: Total PKR ${revenue['totalRevenue']} | '
        'This Month: PKR ${revenue['monthlyRevenue']} | '
        'Today: PKR ${revenue['todayRevenue']}');

    buf.writeln('Pending Withdrawals: ${withdrawals['count']}');

    if (topArtist.isNotEmpty) {
      buf.writeln('Top Earning Artist This Month: ${topArtist['name']} '
          '(PKR ${topArtist['earnings']} from ${topArtist['bookings']} bookings)');
    }

    return buf.toString();
  }
}