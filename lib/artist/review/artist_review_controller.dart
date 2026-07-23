import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/services/firebase_service.dart';

class ArtistReviewItem {
  final String id;
  final String customerId;
  final String customerName;
  final String comment;
  final int rating;
  final Map<String, int> subRatings;
  final List<String> imageUrls;
  final bool isVerifiedOrder;
  final String? adminReply;
  final DateTime? createdAt;

  ArtistReviewItem({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.comment,
    required this.rating,
    required this.subRatings,
    required this.imageUrls,
    required this.isVerifiedOrder,
    required this.adminReply,
    required this.createdAt,
  });
}

class ArtistReviewController extends GetxController {
  static ArtistReviewController get to => Get.find();

  final FirebaseService _firebaseService = FirebaseService();

  final RxBool isLoading = true.obs;
  final RxList<ArtistReviewItem> reviews = <ArtistReviewItem>[].obs;

  // Summary stats, derived from `reviews` whenever it's reloaded.
  final RxDouble averageRating = 0.0.obs;
  final RxInt totalReviews = 0.obs;
  final RxMap<int, int> starCounts =
      <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0}.obs;

  @override
  void onInit() {
    super.onInit();
    loadReviews();
  }

  Future<void> loadReviews() async {
    final artistId = AuthController.to.currentUserId;
    if (artistId == null) return;

    try {
      isLoading.value = true;

      // Single-field equality filter only (no orderBy paired with it) —
      // this avoids needing a composite Firestore index. We sort by
      // createdAt client-side instead, once parsed below.
      final snap = await _firebaseService.firestore
          .collection('reviews')
          .where('artistId', isEqualTo: artistId)
          .get();

      // Reviews store `customerId` but not the customer's name, so we
      // resolve names via a lookup against `users`, batched to respect
      // Firestore's 30-id limit on whereIn (chunked more conservatively
      // at 10 here).
      final customerIds = snap.docs
          .map((d) => d.data()['customerId'] as String?)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final nameById = <String, String>{};
      for (var i = 0; i < customerIds.length; i += 10) {
        final batch = customerIds.sublist(
          i,
          i + 10 > customerIds.length ? customerIds.length : i + 10,
        );
        if (batch.isEmpty) continue;
        final usersSnap = await _firebaseService.firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final u in usersSnap.docs) {
          nameById[u.id] = (u.data()['name'] as String?) ?? 'Customer';
        }
      }

      final items = snap.docs.map((doc) {
        final data = doc.data();
        final subRatingsRaw =
            (data['subRatings'] as Map<String, dynamic>?) ?? {};

        return ArtistReviewItem(
          id: doc.id,
          customerId: (data['customerId'] as String?) ?? '',
          customerName:
              nameById[data['customerId'] as String?] ?? 'Customer',
          comment: (data['comment'] as String?) ?? '',
          rating: (data['rating'] as num?)?.toInt() ?? 0,
          subRatings: subRatingsRaw.map(
            (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0),
          ),
          imageUrls:
              (data['imageUrls'] as List?)?.cast<String>() ?? const [],
          isVerifiedOrder: (data['isVerifiedOrder'] as bool?) ?? false,
          adminReply: data['adminReply'] as String?,
          createdAt: _parseDate(data['createdAt']),
        );
      }).toList();

      items.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      reviews.value = items;
      _computeStats(items);
    } catch (_) {
      reviews.clear();
      _computeStats([]);
    } finally {
      isLoading.value = false;
    }
  }

  void _computeStats(List<ArtistReviewItem> items) {
    totalReviews.value = items.length;

    if (items.isEmpty) {
      averageRating.value = 0;
      starCounts.value = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      return;
    }

    final sum = items.fold<int>(0, (acc, r) => acc + r.rating);
    averageRating.value = sum / items.length;

    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in items) {
      if (counts.containsKey(r.rating)) {
        counts[r.rating] = counts[r.rating]! + 1;
      }
    }
    starCounts.value = counts;
  }

  // `createdAt` shows up as a Firestore Timestamp on some collections and
  // an ISO-8601 string on others in this project — handle both.
  DateTime? _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  Future<void> refresh() => loadReviews();
}
