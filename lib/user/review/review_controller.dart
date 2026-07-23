import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../core/utils/helpers.dart';
import '../../controllers/auth_controller.dart';
import 'package:flutter/material.dart';

class ReviewController extends GetxController {
  final ReviewService _service = ReviewService.instance;
  final RxList<ReviewModel> reviews = <ReviewModel>[].obs;
  final RxList<ReviewModel> myReviews = <ReviewModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isUploadingImages = false.obs;
  final RxDouble averageRating = 0.0.obs;
  final RxInt totalReviews = 0.obs;
  final RxInt selectedRating = 5.obs;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<Map<String, dynamic>> eligibleBookings =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingBookings = false.obs;
  final RxString lastError = ''.obs;

  String get myId => AuthController.to.currentUserId ?? '';

  // ─── Load Artist Reviews ──────────────────────────────────────────────────
  void loadArtistReviews(String artistId) {
    print('🔵 loadArtistReviews called with artistId: $artistId');
    isLoading.value = true;
    
    _service.watchArtistReviews(artistId).listen(
      (data) {
        print('✅ loadArtistReviews SUCCESS: Got ${data.length} reviews');
        reviews.value = data;
        isLoading.value = false;
        lastError.value = '';
      },
      onError: (error, stacktrace) {
        print('❌ loadArtistReviews ERROR: $error');
        print('📍 Stack: $stacktrace');
        lastError.value = error.toString();
        AppHelpers.showError('Failed to load reviews');
        isLoading.value = false;
      },
    );
    _loadArtistRating(artistId);
  }

  // ─── Load My Reviews ──────────────────────────────────────────────────────
  void loadMyReviews() {
    print('\n╔═══════════════════════════════════════════════════╗');
    print('║        loadMyReviews() STARTED                   ║');
    print('╚═══════════════════════════════════════════════════╝');
    
    final userId = myId;
    print('🔵 User ID: $userId');
    print('🔵 Service: ${_service.runtimeType}');
    
    if (userId.isEmpty || userId == '') {
      print('❌ ERROR: User ID is empty!');
      lastError.value = 'No user logged in';
      AppHelpers.showError('Please login first');
      isLoading.value = false;
      return;
    }
    
    isLoading.value = true;
    print('🔵 Starting stream listener...');
    
    _service.watchMyReviews(userId).listen(
      (data) {
        print('✅ STREAM SUCCESS: Got ${data.length} reviews');
        
        if (data.isEmpty) {
          print('ℹ️  No reviews found (this is OK)');
        } else {
          for (int i = 0; i < data.length; i++) {
            final r = data[i];
            print('   Review $i: ${r.artistName ?? r.artistId} - ${r.rating}⭐');
          }
        }
        
        myReviews.value = data;
        isLoading.value = false;
        lastError.value = '';
        print('✅ myReviews.value updated');
      },
      onError: (error, stacktrace) {
        print('❌ STREAM ERROR RECEIVED:');
        print('   Type: ${error.runtimeType}');
        print('   Message: $error');
        print('   Full: ${error.toString()}');
        
        // Detailed error detection
        final errorMsg = error.toString().toLowerCase();
        
        if (errorMsg.contains('index')) {
          print('   🔑 DETECTED: Missing Firestore composite index');
          print('   💡 FIX: Create index in Firebase Console');
          print('           Collection: reviews');
          print('           Field 1: customerId (Ascending)');
          print('           Field 2: createdAt (Descending)');
        } else if (errorMsg.contains('permission')) {
          print('   🔒 DETECTED: Firestore security rules blocking access');
          print('   💡 FIX: Update Firestore security rules');
        } else if (errorMsg.contains('not found')) {
          print('   ❌ DETECTED: Collection or field not found');
          print('   💡 FIX: Check collection name is "reviews"');
        } else if (errorMsg.contains('deadline')) {
          print('   ⏱️  DETECTED: Network timeout');
          print('   💡 FIX: Check internet connection and retry');
        } else {
          print('   ❓ DETECTED: Unknown error');
        }
        
        print('📍 Stack Trace:');
        print(stacktrace.toString());
        
        lastError.value = error.toString();
        AppHelpers.showError('Failed to load reviews: ${error.toString().split(':').last.trim()}');
        isLoading.value = false;
      },
      onDone: () {
        print('🟡 Stream closed');
      },
    );
    
    print('🔵 Listener attached, waiting for Firestore response...');
    print('╔═══════════════════════════════════════════════════╗\n');
  }

  Future<void> _loadArtistRating(String artistId) async {
    try {
      final rating = await _service.getArtistRating(artistId);
      averageRating.value = rating['average'] as double;
      totalReviews.value = rating['total'] as int;
      print('✅ Artist rating loaded: ${averageRating.value}⭐');
    } catch (e) {
      print('❌ Error loading artist rating: $e');
    }
  }

  // ─── Submit Review ────────────────────────────────────────────────────────
  Future<void> submitReview({
    required String orderId,
    required String artistId,
    required String artistName,
    required int rating,
    String? comment,
    List<Uint8List> images = const [],
    Map<String, int> subRatings = const {},
  }) async {
    try {
      isSubmitting.value = true;
      
      print('📝 Submitting review...');
      print('   Order: $orderId');
      print('   Artist: $artistName ($artistId)');
      print('   Rating: $rating⭐');

      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        isUploadingImages.value = true;
        print('📸 Uploading ${images.length} images...');
        imageUrls = await _service.uploadImages(images);
        print('✅ Images uploaded: ${imageUrls.length}');
        isUploadingImages.value = false;
      }

      final review = ReviewModel(
        id: '',
        orderId: orderId,
        customerId: myId,
        artistId: artistId,
        artistName: artistName,
        rating: rating,
        comment: comment?.trim().isEmpty == true ? null : comment?.trim(),
        isVerifiedOrder: true,
        createdAt: DateTime.now(),
        imageUrls: imageUrls,
        subRatings: subRatings,
      );

      print('💾 Saving to Firestore...');
      await _service.submitReview(review);
      print('✅ Review submitted successfully!');

      AppHelpers.showSuccess('Review submitted successfully! 🎉');
      await Future.delayed(const Duration(seconds: 1));
      if (Get.isRegistered<ReviewController>()) {
        Get.back();
      }
    } catch (e, stack) {
      print('❌ Submit error: $e');
      print('📍 Stack: $stack');
      lastError.value = e.toString();
      AppHelpers.showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
      isUploadingImages.value = false;
    }
  }

  // ─── Delete Review ────────────────────────────────────────────────────────
  Future<void> deleteReview(String reviewId, String artistId) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        print('🗑️  Deleting review: $reviewId');
        await _service.deleteReview(reviewId, artistId);
        print('✅ Review deleted');
        AppHelpers.showSuccess('Review deleted');
      } catch (e) {
        print('❌ Delete error: $e');
        lastError.value = e.toString();
        AppHelpers.showError('Failed to delete review');
      }
    }
  }

  // ─── Load Eligible Bookings ───────────────────────────────────────────────
  Future<void> loadEligibleBookings(String userId) async {
    print('📚 Loading eligible bookings for user: $userId');
    isLoadingBookings.value = true;
    
    try {
      final snap = await _db
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .where('status',
              whereIn: ['pending', 'confirmed', 'completed']).get();
      
      print('📦 Found ${snap.docs.length} bookings');
      final List<Map<String, dynamic>> bookings = [];

      for (final doc in snap.docs) {
        final data = doc.data();

        final paymentMethod =
            (data['paymentMethod'] ?? '').toString().toLowerCase();
        final jazzCash = data['jazzCashNumber'];
        final easyPaisa = data['easyPaisaNumber'];
        final String status = (data['status'] ?? '').toString().toLowerCase();

        final bool isOnlinePayment = paymentMethod == 'jazzcash' ||
            paymentMethod == 'easypaisa' ||
            (jazzCash != null && jazzCash.toString().isNotEmpty) ||
            (easyPaisa != null && easyPaisa.toString().isNotEmpty);

        final bool isEligible = isOnlinePayment
            ? (status == 'pending' ||
                status == 'confirmed' ||
                status == 'completed')
            : (status == 'completed');

        if (!isEligible) {
          print('   ⏭️  Skipping: $status (not eligible)');
          continue;
        }

        // Check if already reviewed
        final alreadyReviewed = await _db
            .collection('reviews')
            .where('orderId', isEqualTo: data['id'] ?? doc.id)
            .where('customerId', isEqualTo: userId)
            .get();

        if (alreadyReviewed.docs.isNotEmpty) {
          print('   ⏭️  Skipping: Already reviewed');
          continue;
        }

        // Fetch artist details
        final artistId = data['artistId'] ?? '';
        String artistName = 'Unknown Artist';
        String? artistImageUrl;

        if (artistId.isNotEmpty) {
          try {
            final artistDoc = await _db.collection('users').doc(artistId).get();
            if (artistDoc.exists) {
              artistName = artistDoc.data()?['name'] ?? 'Unknown Artist';
              artistImageUrl = artistDoc.data()?['profileImageUrl'];
            }
          } catch (e) {
            print('   ⚠️  Error fetching artist: $e');
          }
        }

        bookings.add({
          'id': data['id'] ?? doc.id,
          'shortId': (data['id'] ?? doc.id).split('-')[0].toUpperCase(),
          'artistId': artistId,
          'artistName': artistName,
          'artistImageUrl': artistImageUrl,
          'serviceTitle': data['serviceTitle'] ?? '—',
          'paymentMethod': paymentMethod,
          'status': status,
        });
      }

      print('✅ Found ${bookings.length} eligible bookings');
      eligibleBookings.value = bookings;
    } catch (e, stack) {
      print('❌ Error loading bookings: $e');
      print('📍 Stack: $stack');
      lastError.value = e.toString();
      AppHelpers.showError("Could not load bookings: $e");
    } finally {
      isLoadingBookings.value = false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Map<int, int> get ratingBreakdown {
    final map = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      map[r.rating] = (map[r.rating] ?? 0) + 1;
    }
    return map;
  }

  String get ratingLabel {
    final avg = averageRating.value;
    if (avg >= 4.5) return 'Excellent';
    if (avg >= 4.0) return 'Very Good';
    if (avg >= 3.0) return 'Good';
    if (avg >= 2.0) return 'Fair';
    return 'Poor';
  }

  // ─── Debug Helper ─────────────────────────────────────────────────────────
  void printDebugInfo() {
    print('\n╔═══════════════════════════════════════════════════╗');
    print('║           DEBUG INFO                             ║');
    print('╠═══════════════════════════════════════════════════╣');
    print('║ User ID: $myId');
    print('║ My Reviews Count: ${myReviews.length}');
    print('║ Last Error: ${lastError.value.isEmpty ? "None" : lastError.value}');
    print('║ Is Loading: ${isLoading.value}');
    print('╚═══════════════════════════════════════════════════╝\n');
  }
}