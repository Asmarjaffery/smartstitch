import 'package:cloud_firestore/cloud_firestore.dart';

/// Fetches artist-specific context from Firestore for AI prompts.
class ArtistContext {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetch(String userId) async {
    final results = await Future.wait([
      _getArtist(userId),
      _getActiveOrders(userId),
      _getWallet(userId),
      _getRecentReviews(userId),
    ]);

    return {
      'artist': results[0],
      'activeOrders': results[1],
      'wallet': results[2],
      'recentReviews': results[3],
    };
  }

  Future<Map<String, dynamic>> _getArtist(String userId) async {
    try {
      final doc = await _db.collection('artists').doc(userId).get();
      if (!doc.exists) {
        // ignore: avoid_print
        print('[ArtistContext] artists/$userId does NOT exist in Firestore');
        return {};
      }
      final d = doc.data()!;
      return {
        'name': d['name'],
        'specializations': d['specializations'],
        'rating': d['rating'],
        'totalOrders': d['totalOrders'],
      };
    } catch (e) {
      // ignore: avoid_print
      print('[ArtistContext] _getArtist ERROR: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _getActiveOrders(String userId) async {
    try {
      final snap = await _db
          .collection('bookings')
          .where('artistId', isEqualTo: userId)
          .where('status', whereIn: ['accepted', 'inProgress', 'pending'])
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'customerName': data['customerName'],
          'status': data['status'],
          'totalAmount': data['totalAmount'],
          'createdAt': data['createdAt']?.toString(),
        };
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('[ArtistContext] _getActiveOrders ERROR: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _getWallet(String userId) async {
    try {
      final snap = await _db
          .collection('artist_wallets')
          .where('artistId', isEqualTo: userId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        // ignore: avoid_print
        print('[ArtistContext] no artist_wallets doc for artistId=$userId');
        return {};
      }
      final d = snap.docs.first.data();
      // NOTE: actual Firestore fields are availableBalance / lifetimeEarnings /
      // monthEarnings / weekEarnings / todayEarnings / pendingWithdrawal —
      // NOT 'balance' / 'totalEarned' (those don't exist in the document).
      return {
        'availableBalance': d['availableBalance'],
        'lifetimeEarnings': d['lifetimeEarnings'],
        'monthEarnings': d['monthEarnings'],
        'weekEarnings': d['weekEarnings'],
        'todayEarnings': d['todayEarnings'],
        'pendingWithdrawal': d['pendingWithdrawal'],
      };
    } catch (e) {
      // ignore: avoid_print
      print('[ArtistContext] _getWallet ERROR: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentReviews(String userId) async {
    try {
      // NOTE: verify this is the correct collection name — the artist
      // average-rating bug earlier turned out to be 'design_reviews', not
      // 'reviews'. If this logs a permission-denied or always returns 0
      // docs, that mismatch is almost certainly why.
      final snap = await _db
          .collection('reviews')
          .where('artistId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        return {
          'rating': data['rating'],
          'comment': data['comment'],
        };
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('[ArtistContext] _getRecentReviews ERROR: $e');
      return [];
    }
  }

  String toSummary(Map<String, dynamic> ctx) {
    final artist = ctx['artist'] as Map? ?? {};
    final orders = ctx['activeOrders'] as List? ?? [];
    final wallet = ctx['wallet'] as Map? ?? {};
    final reviews = ctx['recentReviews'] as List? ?? [];

    final buf = StringBuffer();
    buf.writeln('Artist: ${artist['name'] ?? 'Unknown'} | '
        'Rating: ${artist['rating'] ?? 'N/A'} | '
        'Total Orders: ${artist['totalOrders'] ?? 0}');

    if (wallet.isNotEmpty) {
      buf.writeln('Wallet: Available Balance PKR ${wallet['availableBalance'] ?? 0} | '
          'Lifetime Earnings PKR ${wallet['lifetimeEarnings'] ?? 0} | '
          'This Month PKR ${wallet['monthEarnings'] ?? 0} | '
          'This Week PKR ${wallet['weekEarnings'] ?? 0} | '
          'Today PKR ${wallet['todayEarnings'] ?? 0} | '
          'Pending Withdrawal PKR ${wallet['pendingWithdrawal'] ?? 0}');
    }

    buf.writeln('Active Orders (${orders.length}):');
    for (final o in orders) {
      buf.writeln('  - #${(o['id'] as String?)?.substring(0, 8) ?? '?'} | '
          'Customer: ${o['customerName']} | Status: ${o['status']} | '
          'Amount: PKR ${o['totalAmount']}');
    }

    if (reviews.isNotEmpty) {
      buf.writeln('Recent Reviews:');
      for (final r in reviews) {
        buf.writeln('  - ★${r['rating']}: ${r['comment']}');
      }
    }

    return buf.toString();
  }
}