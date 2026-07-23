import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/user/review/review_controller.dart';
import '../../core/theme/app.theme.dart';
import '../../models/review_model.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  late final ReviewController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ReviewController()); 
    controller.loadMyReviews();             
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Reviews'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Summary Card ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Reviews',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer)),
                          const SizedBox(height: 4),
                          Text(
                            // ✅ averageRating ki jagah myReviews.length
                            '${controller.myReviews.length}',
                            style: AppTextStyles.h1.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontSize: 40,
                                fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Reviews Given',
                            style: AppTextStyles.caption.copyWith(
                                color: theme.colorScheme.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.checkroom_rounded,
                          size: 40,
                          color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Reviews List ──
              if (controller.myReviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      Icon(Icons.star_outline_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('No reviews yet',
                          style: AppTextStyles.h4.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                )
              else
                ...controller.myReviews
                    .map((r) => _MyReviewTile(
                          review: r,
                          controller: controller,
                        ))
                    .toList(),
            ],
          ),
        );
      }),
    );
  }
}

class _MyReviewTile extends StatelessWidget {
  final ReviewModel review;
  final ReviewController controller;

  const _MyReviewTile({required this.review, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAdminReply = review.adminReply != null && review.adminReply!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  review.customerId[0].toUpperCase(),
                  style: AppTextStyles.labelLarge.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.artistName ?? review.artistId,
                      style: AppTextStyles.labelLarge.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          review.rating.toDouble().toStringAsFixed(1),
                          style: AppTextStyles.caption.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Comment ──
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],

          // ── Images ──
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    review.imageUrls[i],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],

          // ── Admin Reply Box ──
          if (hasAdminReply) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings_rounded,
                          size: 14,
                          color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 4),
                      Text(
                        'Admin Reply',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600),
                      ),
                      if (review.adminRepliedAt != null) ...[
                        const Spacer(),
                        Text(
                          _formatDate(review.adminRepliedAt!),
                          style: AppTextStyles.caption.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review.adminReply!,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // ── Footer — date + buttons ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(review.createdAt),
                style: AppTextStyles.caption
                    .copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              // Edit/Delete sirf tab show ho jab admin ne reply na kiya ho
              if (!hasAdminReply)
                Row(
                  children: [
                    TextButton(
                      onPressed: () {}, // Edit logic baad mein
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Edit Review',
                        style: AppTextStyles.caption.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () =>
                          controller.deleteReview(review.id, review.artistId),
                      child: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.error),
                    ),
                  ],
                )
              else
                // Admin reply aa gayi — locked state
                Row(
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Replied',
                      style: AppTextStyles.caption.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }
}