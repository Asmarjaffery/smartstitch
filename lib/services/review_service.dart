import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/review_model.dart';

class ReviewService {
  static final ReviewService instance = ReviewService._internal();
  factory ReviewService() => instance;
  ReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── UPLOAD IMAGES (Cloudinary) ───────────────────────────────────────────

  Future<List<String>> uploadImages(List<Uint8List> images) async {
    final List<String> urls = [];

    for (final bytes in images) {
      try {
        final fileName = 'review_${DateTime.now().millisecondsSinceEpoch}.jpg';

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudinary.com/v1_1/dc58vppqz/image/upload'),
        );

        request.fields['upload_preset'] = 'smartstitch_profile';
        request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: fileName),
        );

        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseData);
        final url = jsonData['secure_url'];

        if (url == null) {
          throw Exception('Upload failed: ${jsonData['error']?['message']}');
        }

        urls.add(url as String);
      } catch (e) {
        continue;
      }
    }

    return urls;
  }

  // ─── SUBMIT REVIEW ────────────────────────────────────────────────────────

  Future<void> submitReview(ReviewModel review) async {
    if (review.orderId.isNotEmpty) {
      final existing = await _firestore
          .collection('reviews')
          .where('orderId', isEqualTo: review.orderId)
          .where('customerId', isEqualTo: review.customerId)
          .where('type', isEqualTo: review.type)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('You have already reviewed this order');
      }
    }

    await _firestore.collection('reviews').add(review.toJson());

    // ✅ Sirf artist_service reviews artist ke average rating mein count hon —
    // rider delivery review ab artist rating ko affect nahi karega.
    if (review.type == 'artist_service' && review.artistId.isNotEmpty) {
      await _updateArtistRating(review.artistId);
    }
    if (review.type == 'rider_delivery' &&
        review.riderId != null &&
        review.riderId!.isNotEmpty) {
      await _updateRiderRating(review.riderId!);
    }
  }

  // ─── WATCH ARTIST REVIEWS ─────────────────────────────────────────────────
  Stream<List<ReviewModel>> watchArtistReviews(String artistId) {
    return _firestore
        .collection('reviews')
        .where('artistId', isEqualTo: artistId)
        .where('type', isEqualTo: 'artist_service')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return ReviewModel.fromJson(data);
            }).toList());
  }

  // ─── WATCH RIDER REVIEWS ──────────────────────────────────────────────────
  Stream<List<ReviewModel>> watchRiderReviews(String riderId) {
    return _firestore
        .collection('reviews')
        .where('riderId', isEqualTo: riderId)
        .where('type', isEqualTo: 'rider_delivery')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final reviews = <ReviewModel>[];
      for (final d in snap.docs) {
        final data = d.data();
        data['id'] = d.id;

        try {
          final userDoc =
              await _firestore.collection('users').doc(data['customerId']).get();
          data['customerName'] = userDoc.data()?['name'] ??
              userDoc.data()?['fullName'] ??
              userDoc.data()?['displayName'] ??
              'Customer';
        } catch (_) {
          data['customerName'] = 'Customer';
        }

        reviews.add(ReviewModel.fromJson(data));
      }
      return reviews;
    });
  }

  // ─── WATCH MY REVIEWS (customer) ─────────────────────────────────────────
  Stream<List<ReviewModel>> watchMyReviews(String customerId) {
  return _firestore
      .collection('reviews')
      .where('customerId', isEqualTo: customerId)
      .orderBy('createdAt', descending: true)  // ✅ CORRECT
      .snapshots()
      .map((snap) => snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return ReviewModel.fromJson(data);  // ✅ CORRECT
          }).toList());
}

  // ─── WATCH ALL REVIEWS (admin) ────────────────────────────────────────────
  Stream<List<ReviewModel>> watchAllReviews() {
    return _firestore
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final reviews = <ReviewModel>[];
      for (final d in snap.docs) {
        final data = d.data();
        data['id'] = d.id;

        // ─── Customer name fetch ───
        try {
          final userDoc =
              await _firestore.collection('users').doc(data['customerId']).get();
          data['customerName'] = userDoc.data()?['name'] ??
              userDoc.data()?['fullName'] ??
              userDoc.data()?['displayName'] ??
              'Customer';
        } catch (_) {
          data['customerName'] = 'Customer';
        }

        final type = data['type'] as String? ?? 'artist_service';

        if (type == 'rider_delivery') {
          // ─── Rider name fetch ───
          if (data['riderName'] == null || data['riderName'] == '') {
            try {
              final riderDoc = await _firestore
                  .collection('riders')
                  .doc(data['riderId'])
                  .get();
              data['riderName'] = riderDoc.data()?['name'] ??
                  riderDoc.data()?['fullName'] ??
                  riderDoc.data()?['displayName'] ??
                  'Rider';
            } catch (_) {
              data['riderName'] = 'Rider';
            }
          }
        } else {
          // ─── Artist name fetch ───
          if (data['artistName'] == null || data['artistName'] == '') {
            try {
              final artistDoc = await _firestore
                  .collection('artists')
                  .doc(data['artistId'])
                  .get();
              data['artistName'] = artistDoc.data()?['businessName'] ??
                  artistDoc.data()?['name'] ??
                  'Artist';
            } catch (_) {
              data['artistName'] = 'Artist';
            }
          }
        }

        reviews.add(ReviewModel.fromJson(data));
      }
      return reviews;
    });
  }

  // ─── SAVE ADMIN REPLY ─────────────────────────────────────────────────────
  Future<void> saveAdminReply(String reviewId, String replyText) async {
    await _firestore.collection('reviews').doc(reviewId).update({
      'adminReply': replyText,
      'adminRepliedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── CHECK ALREADY REVIEWED ───────────────────────────────────────────────
  Future<bool> hasReviewed(String orderId, String customerId) async {
    final snap = await _firestore
        .collection('reviews')
        .where('orderId', isEqualTo: orderId)
        .where('customerId', isEqualTo: customerId)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ─── GET ARTIST RATING ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getArtistRating(String artistId) async {
    final snap = await _firestore
        .collection('reviews')
        .where('artistId', isEqualTo: artistId)
        .where('type', isEqualTo: 'artist_service')
        .get();

    if (snap.docs.isEmpty) return {'average': 0.0, 'total': 0};

    final total = snap.docs.length;
    final sum = snap.docs.fold<int>(0, (sum, doc) => sum + (doc['rating'] as int));
    final average = sum / total;

    return {'average': average, 'total': total};
  }

  // ─── GET RIDER RATING ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getRiderRating(String riderId) async {
    final snap = await _firestore
        .collection('reviews')
        .where('riderId', isEqualTo: riderId)
        .where('type', isEqualTo: 'rider_delivery')
        .get();

    if (snap.docs.isEmpty) return {'average': 0.0, 'total': 0};

    final total = snap.docs.length;
    final sum = snap.docs.fold<int>(0, (sum, doc) => sum + (doc['rating'] as int));
    final average = sum / total;

    return {'average': average, 'total': total};
  }

  // ─── UPDATE ARTIST AVERAGE ────────────────────────────────────────────────
  Future<void> _updateArtistRating(String artistId) async {
    final rating = await getArtistRating(artistId);
    await _firestore.collection('artists').doc(artistId).update({
      'averageRating': rating['average'],
      'totalReviews': rating['total'],
    });
  }

  // ─── UPDATE RIDER AVERAGE ─────────────────────────────────────────────────
  Future<void> _updateRiderRating(String riderId) async {
    final rating = await getRiderRating(riderId);
    await _firestore.collection('riders').doc(riderId).update({
      'averageRating': rating['average'],
      'totalReviews': rating['total'],
    });
  }

  // ─── DELETE REVIEW ────────────────────────────────────────────────────────
  Future<void> deleteReview(String reviewId, String artistId) async {
    final doc = await _firestore.collection('reviews').doc(reviewId).get();
    final data = doc.data();
    final type = data?['type'] as String? ?? 'artist_service';
    final riderId = data?['riderId'] as String?;

    await _firestore.collection('reviews').doc(reviewId).delete();

    if (type == 'rider_delivery' && riderId != null && riderId.isNotEmpty) {
      await _updateRiderRating(riderId);
    } else if (artistId.isNotEmpty) {
      await _updateArtistRating(artistId);
    }
  }
}