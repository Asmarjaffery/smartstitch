import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app.theme.dart';
import '../../models/review_model.dart';
import 'rider_review_controller.dart';

class RiderReviewsScreen extends StatefulWidget {
  const RiderReviewsScreen({super.key});

  @override
  State<RiderReviewsScreen> createState() => _RiderReviewsScreenState();
}

class _RiderReviewsScreenState extends State<RiderReviewsScreen> {
  late final RiderReviewController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(RiderReviewController());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Reviews'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats ──
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          Text('${controller.totalReviews}',
                              style: AppTextStyles.h3.copyWith(
                                  color: AppColors.primary, fontWeight: FontWeight.w700)),
                          Text('Total Reviews',
                              style: AppTextStyles.caption.copyWith(color: textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          Text(controller.averageRating.toStringAsFixed(1),
                              style: AppTextStyles.h3.copyWith(
                                  color: Colors.amber.shade700, fontWeight: FontWeight.w700)),
                          Text('Avg Rating',
                              style: AppTextStyles.caption.copyWith(color: textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          Text('${controller.fiveStarCount}',
                              style: AppTextStyles.h3.copyWith(
                                  color: Colors.green, fontWeight: FontWeight.w700)),
                          Text('5-Star',
                              style: AppTextStyles.caption.copyWith(color: textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text('Delivery Reviews',
                  style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w600, color: textPrimary)),

              const SizedBox(height: 14),

              if (controller.myReviews.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primaryDark.withValues(alpha: 0.25)
                                : AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.rate_review_outlined,
                              size: 48, color: AppColors.primaryLight),
                        ),
                        const SizedBox(height: 16),
                        Text('No reviews yet',
                            style: AppTextStyles.h4.copyWith(color: textSecondary)),
                        const SizedBox(height: 6),
                        Text('Customer feedback on your deliveries will appear here',
                            style: AppTextStyles.bodySmall.copyWith(color: textHint),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              else
                ...controller.myReviews.map((r) => _RiderReviewTile(
                      review: r,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textHint: textHint,
                      borderColor: borderColor,
                      isDark: isDark,
                    )),
            ],
          ),
        );
      }),
    );
  }
}

class _RiderReviewTile extends StatelessWidget {
  final ReviewModel review;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color borderColor;
  final bool isDark;

  const _RiderReviewTile({
    required this.review,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.borderColor,
    required this.isDark,
  });

  Color get _ratingColor {
    switch (review.rating) {
      case 5: return Colors.green;
      case 4: return Colors.teal;
      case 3: return Colors.orange;
      case 2: return Colors.deepOrange;
      default: return Colors.red;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    isDark ? AppColors.primaryDark.withValues(alpha: 0.35) : AppColors.primarySoft,
                child: Text(
                  (review.customerName ?? review.customerId)[0].toUpperCase(),
                  style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.customerName ?? 'Customer',
                  style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600, color: textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _ratingColor.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _ratingColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 12, color: _ratingColor),
                    const SizedBox(width: 3),
                    Text('${review.rating}',
                        style: AppTextStyles.caption
                            .copyWith(color: _ratingColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '"${review.comment!}"',
              style: AppTextStyles.bodySmall.copyWith(
                  color: textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 11, color: textHint),
              const SizedBox(width: 4),
              Text(_formatDate(review.createdAt),
                  style: AppTextStyles.caption.copyWith(color: textHint)),
            ],
          ),
        ],
      ),
    );
  }
}