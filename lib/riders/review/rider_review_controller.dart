import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';

class RiderReviewController extends GetxController {
  final ReviewService _service = ReviewService.instance;

  final RxList<ReviewModel> myReviews = <ReviewModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadMyReviews();
  }

  void loadMyReviews() {
    final riderId = FirebaseAuth.instance.currentUser?.uid;
    if (riderId == null) return;

    isLoading.value = true;
    _service.watchRiderReviews(riderId).listen(
      (data) {
        myReviews.value = data;
        isLoading.value = false;
      },
      onError: (_) {
        isLoading.value = false;
      },
    );
  }

  int get totalReviews => myReviews.length;

  double get averageRating {
    if (myReviews.isEmpty) return 0.0;
    final sum = myReviews.fold<int>(0, (acc, r) => acc + r.rating);
    return sum / myReviews.length;
  }

  int get fiveStarCount => myReviews.where((r) => r.rating == 5).length;
}