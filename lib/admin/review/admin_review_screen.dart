import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/admin/review/admin_review_controller.dart';
import '../../core/theme/app.theme.dart';
import '../../models/review_model.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  late final AdminReviewController controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(AdminReviewController());
    controller.loadAllReviews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Review Management'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final list = controller.filteredReviews;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatCard(
                    label: 'Total',
                    value: '${controller.totalReviews}',
                    icon: Icons.star_rounded,
                    color: AppColors.primary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Avg Rating',
                    value: controller.averageRating.toStringAsFixed(1),
                    icon: Icons.bar_chart_rounded,
                    color: Colors.amber,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Pending',
                    value: '${controller.pendingReplies}',
                    icon: Icons.pending_actions_rounded,
                    color: Colors.orange,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: '5-Star',
                    value: '${controller.fiveStarCount}',
                    icon: Icons.workspace_premium_rounded,
                    color: Colors.green,
                    textSecondary: textSecondary,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Search + Filters Card ────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: controller.setSearchQuery,
                      style: AppTextStyles.bodySmall,
                      decoration: InputDecoration(
                        hintText: 'Search by customer, artist, or rider name...',
                        hintStyle: TextStyle(color: textHint, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: textHint, size: 20),
                        suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  controller.setSearchQuery('');
                                },
                                child: Icon(Icons.close_rounded, color: textHint, size: 18),
                              )
                            : const SizedBox.shrink()),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurface2 : AppColors.lightBackground,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Single-line combined filters ────────────────────
                    Obx(() => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: controller.filterType.value == 'all' &&
                                  controller.filterStatus.value == 'all',
                              onTap: () {
                                controller.setTypeFilter('all');
                                controller.setStatusFilter('all');
                              },
                              isDark: isDark,
                            ),
                            _FilterChip(
                              label: 'Service',
                              icon: Icons.design_services_rounded,
                              selected: controller.filterType.value == 'service',
                              onTap: () => controller.setTypeFilter('service'),
                              isDark: isDark,
                            ),
                            _FilterChip(
                              label: 'Delivery',
                              icon: Icons.delivery_dining_rounded,
                              selected: controller.filterType.value == 'delivery',
                              onTap: () => controller.setTypeFilter('delivery'),
                              isDark: isDark,
                            ),
                            _FilterChip(
                              label: 'Replied',
                              icon: Icons.check_circle_rounded,
                              selected: controller.filterStatus.value == 'replied',
                              onTap: () => controller.setStatusFilter('replied'),
                              isDark: isDark,
                            ),
                            _FilterChip(
                              label: 'Pending',
                              icon: Icons.pending_actions_rounded,
                              selected: controller.filterStatus.value == 'pending',
                              onTap: () => controller.setStatusFilter('pending'),
                              isDark: isDark,
                            ),
                          ],
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Customer Reviews (${list.length})',
                    style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              if (list.isEmpty)
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
                        Text(
                          controller.allReviews.isEmpty
                              ? 'No reviews yet'
                              : 'No matching reviews',
                          style: AppTextStyles.h4.copyWith(color: textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          controller.allReviews.isEmpty
                              ? 'Customer reviews will appear here'
                              : 'Try adjusting your search or filters',
                          style: AppTextStyles.bodySmall.copyWith(color: textHint),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...list.map((r) => _AdminReviewTile(
                      review: r,
                      controller: controller,
                    )),

              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurface2 : AppColors.lightBackground),
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: selected
                      ? Colors.white
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: selected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color textSecondary;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(value,
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700, color: color)),
            Text(label,
                style: AppTextStyles.caption.copyWith(color: textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Admin Review Tile ──────────────────────────────────────────────────────
class _AdminReviewTile extends StatefulWidget {
  final ReviewModel review;
  final AdminReviewController controller;

  const _AdminReviewTile({required this.review, required this.controller});

  @override
  State<_AdminReviewTile> createState() => _AdminReviewTileState();
}

class _AdminReviewTileState extends State<_AdminReviewTile> {
  bool _isExpanded = false;

  Color get _ratingColor {
    switch (widget.review.rating) {
      case 5: return Colors.green;
      case 4: return Colors.teal;
      case 3: return Colors.orange;
      case 2: return Colors.deepOrange;
      default: return Colors.red;
    }
  }

  String get _ratingLabel {
    switch (widget.review.rating) {
      case 5: return 'Excellent';
      case 4: return 'Good';
      case 3: return 'Average';
      case 2: return 'Poor';
      default: return 'Terrible';
    }
  }

  bool get _hasReply =>
      widget.review.adminReply != null && widget.review.adminReply!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bgSubtle = isDark ? AppColors.darkSurface2 : AppColors.lightBackground;

    final isRider = widget.review.isRiderReview;
    final subjectName = isRider
        ? (widget.review.riderName ?? 'Rider')
        : (widget.review.artistName ?? widget.review.artistId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded ? AppColors.primary.withValues(alpha: 0.5) : borderColor,
          width: _isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          isDark ? AppColors.primaryDark.withValues(alpha: 0.35) : AppColors.primarySoft,
                      child: Text(
                        (widget.review.customerName ?? widget.review.customerId)[0].toUpperCase(),
                        style: AppTextStyles.h5.copyWith(
                            color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subjectName,
                            style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w600, color: textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 11, color: textHint),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  widget.review.customerName ?? widget.review.customerId,
                                  style: AppTextStyles.caption.copyWith(color: textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ── Type badge + rating badge on the same line ──────
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isRider
                                ? Colors.blue.withValues(alpha: isDark ? 0.2 : 0.1)
                                : AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isRider ? 'Delivery' : 'Service',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isRider
                                  ? (isDark ? Colors.blue.shade200 : Colors.blue.shade700)
                                  : AppColors.primaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
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
                              Text(
                                '${widget.review.rating} · $_ratingLabel',
                                style: AppTextStyles.caption.copyWith(
                                    color: _ratingColor, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < widget.review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  ),
                ),

                if (widget.review.comment != null && widget.review.comment!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      '"${widget.review.comment!}"',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: textSecondary, fontStyle: FontStyle.italic),
                    ),
                  ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 11, color: textHint),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(widget.review.createdAt),
                          style: AppTextStyles.caption.copyWith(color: textHint),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (_hasReply)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: isDark ? 0.15 : 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 11, color: isDark ? Colors.green.shade300 : Colors.green),
                                const SizedBox(width: 3),
                                Text('Replied',
                                    style: AppTextStyles.caption.copyWith(
                                        color: isDark ? Colors.green.shade300 : Colors.green,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        GestureDetector(
                          onTap: () => widget.controller
                              .deleteReview(widget.review.id, widget.review.artistId),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                size: 16, color: AppColors.error),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _isExpanded = !_isExpanded),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isExpanded
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.primaryDark.withValues(alpha: 0.3)
                                      : AppColors.primarySoft),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isExpanded ? 'Close' : 'Respond',
                                  style: AppTextStyles.caption.copyWith(
                                      color: _isExpanded ? Colors.white : AppColors.primaryLight,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  _isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: _isExpanded ? Colors.white : AppColors.primaryLight,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_hasReply && !_isExpanded)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: isDark ? 0.1 : 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.admin_panel_settings_rounded,
                        size: 12, color: isDark ? Colors.green.shade300 : Colors.green),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.review.adminReply!,
                      style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
                    ),
                  ),
                ],
              ),
            ),

          if (_isExpanded)
            Obx(() {
              final isGenerating = widget.controller.generatingMap[widget.review.id] == true;
              final isSubmitting = widget.controller.submittingMap[widget.review.id] == true;
              final textController = widget.controller.replyControllers[widget.review.id];

              return Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryDark.withValues(alpha: 0.15)
                      : AppColors.primarySoft.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.smart_toy_rounded, size: 15, color: AppColors.primaryLight),
                        const SizedBox(width: 6),
                        Text('Admin Reply',
                            style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryLight)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('AI Assisted',
                              style: AppTextStyles.caption.copyWith(
                                  fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isGenerating)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                            const SizedBox(width: 10),
                            Text('Generating AI response...',
                                style: AppTextStyles.caption.copyWith(color: textSecondary)),
                          ],
                        ),
                      )
                    else
                      TextField(
                        controller: textController,
                        maxLines: 4,
                        style: AppTextStyles.bodySmall.copyWith(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Write your reply here...',
                          hintStyle: TextStyle(color: textHint),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isGenerating || isSubmitting
                                ? null
                                : () => widget.controller.generateAdminReply(widget.review),
                            icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                            label: const Text('Auto-Generate', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryLight,
                              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isGenerating || isSubmitting
                                ? null
                                : () => widget.controller.submitAdminReply(widget.review.id),
                            icon: isSubmitting
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.send_rounded, size: 14),
                            label: Text(isSubmitting ? 'Sending...' : 'Send Reply',
                                style: const TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
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