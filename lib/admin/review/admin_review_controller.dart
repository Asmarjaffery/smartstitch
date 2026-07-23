import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../core/utils/helpers.dart';

class AdminReviewController extends GetxController {
  final ReviewService _service = ReviewService.instance;

  final RxList<ReviewModel> allReviews = <ReviewModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, bool> generatingMap = <String, bool>{}.obs;
  final RxMap<String, bool> submittingMap = <String, bool>{}.obs;

  final Map<String, TextEditingController> replyControllers = {};

  // ─── Filter & Search state ──────────────────────────────────────────────
  final RxString searchQuery = ''.obs;
  final RxString filterType = 'all'.obs; // all, service, delivery
  final RxString filterStatus = 'all'.obs; // all, replied, pending

  @override
  void onClose() {
    for (final c in replyControllers.values) {
      c.dispose();
    }
    super.onClose();
  }

  // ─── Load All Reviews ─────────────────────────────────────────────────────
  void loadAllReviews() {
    isLoading.value = true;
    _service.watchAllReviews().listen(
      (data) {
        allReviews.value = data;
        for (final r in data) {
          replyControllers.putIfAbsent(
            r.id,
            () => TextEditingController(text: r.adminReply ?? ''),
          );
        }
        isLoading.value = false;
      },
      onError: (_) {
        AppHelpers.showError('Failed to load reviews');
        isLoading.value = false;
      },
    );
  }

  // ─── Filtered + Searched Reviews ────────────────────────────────────────
  List<ReviewModel> get filteredReviews {
    var list = allReviews.toList();

    // Filter by type (Service = artist review, Delivery = rider review)
    if (filterType.value == 'service') {
      list = list.where((r) => !r.isRiderReview).toList();
    } else if (filterType.value == 'delivery') {
      list = list.where((r) => r.isRiderReview).toList();
    }

    // Filter by reply status
    if (filterStatus.value == 'replied') {
      list = list
          .where((r) => r.adminReply != null && r.adminReply!.isNotEmpty)
          .toList();
    } else if (filterStatus.value == 'pending') {
      list = list
          .where((r) => r.adminReply == null || r.adminReply!.isEmpty)
          .toList();
    }

    // Search by customer name, artist/rider name, or comment text
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((r) {
        final customer = (r.customerName ?? r.customerId).toLowerCase();
        final subject = r.isRiderReview
            ? (r.riderName ?? '').toLowerCase()
            : (r.artistName ?? r.artistId).toLowerCase();
        final comment = (r.comment ?? '').toLowerCase();
        return customer.contains(query) ||
            subject.contains(query) ||
            comment.contains(query);
      }).toList();
    }

    return list;
  }

  void setSearchQuery(String value) => searchQuery.value = value;
  void setTypeFilter(String value) => filterType.value = value;
  void setStatusFilter(String value) => filterStatus.value = value;

  // ─── Auto-Generate Reply (Fallback) ───────────────────────────────────────
  Future<void> generateAdminReply(ReviewModel review) async {
    generatingMap[review.id] = true;
    generatingMap.refresh();

    await Future.delayed(const Duration(milliseconds: 600)); // fake loading
    replyControllers[review.id]?.text = _fallbackReply(review.rating);

    generatingMap[review.id] = false;
    generatingMap.refresh();
  }

  // ─── Submit Admin Reply ───────────────────────────────────────────────────
  Future<void> submitAdminReply(String reviewId) async {
    final replyText = replyControllers[reviewId]?.text.trim() ?? '';
    if (replyText.isEmpty) {
      AppHelpers.showError('Reply cannot be empty');
      return;
    }

    submittingMap[reviewId] = true;
    submittingMap.refresh();

    try {
      await _service.saveAdminReply(reviewId, replyText);
      AppHelpers.showSuccess('Reply sent successfully!');
    } catch (e) {
      print('REPLY ERROR: $e');
      AppHelpers.showError('Failed to send reply: $e');
    } finally {
      submittingMap[reviewId] = false;
      submittingMap.refresh();
    }
  }

  // ─── Delete Review ────────────────────────────────────────────────────────
  Future<void> deleteReview(String reviewId, String artistId) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Review'),
        content: const Text(
            'Are you sure you want to permanently delete this review?'),
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
        await _service.deleteReview(reviewId, artistId);
        AppHelpers.showSuccess('Review deleted');
      } catch (e) {
        AppHelpers.showError('Failed to delete review');
      }
    }
  }

  // ─── Stats ────────────────────────────────────────────────────────────────
  int get totalReviews => allReviews.length;

  double get averageRating {
    if (allReviews.isEmpty) return 0.0;
    final sum = allReviews.fold<int>(0, (acc, r) => acc + r.rating);
    return sum / allReviews.length;
  }

  int get pendingReplies => allReviews
      .where((r) => r.adminReply == null || r.adminReply!.isEmpty)
      .length;

  int get fiveStarCount => allReviews.where((r) => r.rating == 5).length;

  // ─── Fallback Replies ─────────────────────────────────────────────────────
  String _fallbackReply(int rating) {
    switch (rating) {
      case 5:
        return 'Thank you so much for your wonderful review! '
            'We are delighted to hear that you enjoyed our service. '
            'We look forward to serving you again soon! 🌟';
      case 4:
        return 'Thank you for your positive feedback! '
            'We truly appreciate your support and have noted your suggestions. '
            'We will continue working to improve and hope to welcome you again soon.';
      case 3:
        return 'Thank you for taking the time to share your feedback. '
            'We are sorry that your experience did not fully meet your expectations. '
            'Please feel free to contact us so we can address your concerns.';
      case 2:
        return 'We sincerely apologize for the disappointing experience you had. '
            'This does not reflect the standard of service we aim to provide. '
            'Please contact us directly so we can resolve the issue as quickly as possible.';
      default:
        return 'We deeply apologize for your experience and understand your frustration. '
            'What you experienced is not acceptable, and we take full responsibility. '
            'Please reach out to us directly so we can work toward a satisfactory resolution.';
    }
  }
}