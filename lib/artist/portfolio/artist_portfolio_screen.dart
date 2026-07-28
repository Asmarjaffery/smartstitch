import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/routes/routes.dart';

import 'artist_portfolio_controller.dart';

class ArtistPortfolioScreen extends GetView<ArtistPortfolioController> {
  const ArtistPortfolioScreen({super.key});

  // ─── RESPONSIVE HELPERS ───────────────────────────────────────
  int _crossAxisCount(double width) {
    if (width < 360) return 1;
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  int _statCrossAxisCount(double width) => width < 380 ? 2 : 4;

  double _contentMaxWidth(double width) {
    if (width >= 1400) return 1200;
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mediaQuery = MediaQuery.of(context);
    final clampedTextScaler =
        mediaQuery.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.25);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedTextScaler),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xffF8F9FC),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = _crossAxisCount(width);
            final statColumns = _statCrossAxisCount(width);
            final maxContentWidth = _contentMaxWidth(width);
            final horizontalPadding = width >= 600 ? 24.0 : 16.0;

            return RefreshIndicator(
              onRefresh: controller.refreshPortfolio,
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // ── Header + stats + search + filters ─────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                                horizontalPadding, 20, horizontalPadding, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(context, isDark),
                                const SizedBox(height: 20),
                                _buildStatistics(width, statColumns, isDark),
                                const SizedBox(height: 20),
                                _buildSearchAndFilterIcon(context, isDark),
                                const SizedBox(height: 14),
                                _FilterChips(controller: controller, isDark: isDark),
                              ],
                            ),
                          ),
                        ),

                        SliverPadding(
                          padding: EdgeInsets.only(top: 16),
                          sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                        ),

                        // ── Grid ───────────────────────────────────────
                        Obx(() {
                          final items = controller.filteredPortfolio.toList();

                          if (items.isEmpty) {
                            return SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  "No portfolio found",
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            );
                          }

                          return SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            // ✅ SliverMasonryGrid gives every card its own
                            // natural height based on its content (image +
                            // text + button), instead of forcing every card
                            // in a row to share one fixed aspect-ratio height.
                            // This is what removes the big empty gap above
                            // the "View Details" button.
                            sliver: SliverMasonryGrid.count(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childCount: items.length,
                              itemBuilder: (context, index) {
                                if (index < 0 || index >= items.length) {
                                  return const SizedBox.shrink();
                                }
                                return _PortfolioGridCard(
                                  service: items[index],
                                  controller: controller,
                                );
                              },
                            ),
                          );
                        }),

                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  //==========================================================
  // HEADER: title + subtitle + add button
  //==========================================================
  Widget _buildHeader(BuildContext context, bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "My Portfolio",
                style: AppTextStyles.h2.copyWith(color: textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                "Showcase your creativity",
                style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // ✅ Add new portfolio item
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Get.toNamed(AppRoutes.artistServiceCreate),
          child: Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppShadows.primary,
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  //==========================================================
  // STATISTICS — responsive, content-driven height (no fixed
  // aspect ratio grid) so it can never overflow at any text scale.
  //==========================================================
  Widget _buildStatistics(double width, int columns, bool isDark) {
    return Obx(() {
      final items = controller.portfolio;

      final total = items.length;
      final views = items.fold<int>(
          0, (sum, item) => sum + ((item['views'] ?? 0) as num).toInt());
      final likes = items.fold<int>(
          0, (sum, item) => sum + ((item['likes'] ?? 0) as num).toInt());
      final orders = items.fold<int>(
          0, (sum, item) => sum + ((item['ordersCount'] ?? 0) as num).toInt());

      final stats = [
        (icon: Icons.work_outline_rounded, label: "Works", value: "$total", color: AppColors.primary),
        (icon: Icons.visibility_outlined, label: "Views", value: "$views", color: AppColors.success),
        (icon: Icons.star_rounded, label: "Likes", value: "$likes", color: AppColors.warning),
        (icon: Icons.shopping_bag_outlined, label: "Orders", value: "$orders", color: AppColors.error),
      ];

      const spacing = 12.0;
      final horizontalPadding = width >= 600 ? 24.0 : 16.0;
      final available = width - horizontalPadding * 2;
      final itemWidth = (available - spacing * (columns - 1)) / columns;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: stats.map((s) {
          return SizedBox(
            width: itemWidth,
            child: _statCard(s.icon, s.value, s.label, s.color, isDark),
          );
        }).toList(),
      );
    });
  }

  Widget _statCard(IconData icon, String value, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.medium,
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: isDark ? 0.2 : 0.12),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.metricValue.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  //==========================================================
  // SEARCH + filter icon (opens the same status filter sheet
  // as the chips below, for parity with the reference design)
  //==========================================================
  Widget _buildSearchAndFilterIcon(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: controller.onSearchChanged,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: "Search your work...",
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: AppRadius.medium,
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          borderRadius: AppRadius.medium,
          onTap: () => _openFilterSheet(context),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface2 : AppColors.primarySoft,
              borderRadius: AppRadius.medium,
            ),
            child: Icon(
              Icons.tune_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }

  void _openFilterSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Filter by status",
                style: AppTextStyles.h5.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                )),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.all_inclusive_rounded),
              title: const Text("All"),
              onTap: () {
                controller.showAll();
                Get.back();
              },
            ),
            ListTile(
              leading: Icon(Icons.public, color: AppColors.success),
              title: const Text("Published"),
              onTap: () {
                controller.showPublished();
                Get.back();
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_document, color: AppColors.warning),
              title: const Text("Draft"),
              onTap: () {
                controller.showDraft();
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}

//==========================================================
// FILTER CHIPS — small local state just to highlight the
// active pill (controller only exposes actions, not a
// reactive "current filter", so this stays self-contained).
//==========================================================
class _FilterChips extends StatefulWidget {
  final ArtistPortfolioController controller;
  final bool isDark;
  const _FilterChips({required this.controller, required this.isDark});

  @override
  State<_FilterChips> createState() => _FilterChipsState();
}

class _FilterChipsState extends State<_FilterChips> {
  String _selected = 'All';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('All', () => widget.controller.showAll()),
          const SizedBox(width: 10),
          _chip('Published', () => widget.controller.showPublished()),
          const SizedBox(width: 10),
          _chip('Draft', () => widget.controller.showDraft()),
        ],
      ),
    );
  }

  Widget _chip(String title, VoidCallback onTap) {
    final isSelected = _selected == title;
    final isDark = widget.isDark;

    return GestureDetector(
      onTap: () {
        setState(() => _selected = title);
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : (isDark ? AppColors.darkSurface2 : Colors.white),
          borderRadius: AppRadius.full,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: isSelected ? AppShadows.soft(AppColors.primary) : [],
        ),
        child: Text(
          title,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }
}

//==========================================================
// PORTFOLIO GRID CARD — image + heart + status badge +
// title + price + rating/orders row + View Details button.
// Uses the controller's own accessor methods so data stays
// consistent with the details screen.
//
// ✅ CHANGE: outer Column is no longer mainAxisSize.min, so it
// stretches to the full card height that the grid gives it.
// The text-content block is wrapped in Expanded, and a Spacer()
// pushes the new "View Details" button to the bottom — this is
// what fills the white space that used to sit empty under the
// rating/orders row, and gives users an explicit way in to the
// details screen (in addition to tapping the whole card).
//==========================================================
class _PortfolioGridCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final ArtistPortfolioController controller;

  const _PortfolioGridCard({required this.service, required this.controller});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return AppColors.success;
      case 'draft':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  void _openDetails() {
    Get.toNamed(AppRoutes.portfolioDetails, arguments: service);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final status = controller.status(service);
    final statusColor = _statusColor(status);

    return GestureDetector(
      onTap: _openDetails,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: AppRadius.medium,
          boxShadow: AppShadows.card(isDark),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          // ✅ mainAxisSize.min — the masonry grid already sizes this
          // card to its own natural content height, so the Column
          // should only take exactly as much height as its children
          // need. No more Expanded/Spacer stretching the card taller
          // than its content.
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + heart overlay ────────────────────────────
            AspectRatio(
              aspectRatio: 1.05,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: controller.coverImage(service),
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: isDark ? AppColors.darkSurface2 : Colors.grey.shade200,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: isDark ? AppColors.darkSurface2 : Colors.grey.shade200,
                      child: Icon(Icons.image_not_supported, color: textSecondary),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Text content (sized to its own content only) ─────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: AppRadius.full,
                      ),
                      child: Text(
                        status.isEmpty ? '—' : status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      controller.serviceName(service),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Rs ${controller.price(service).toStringAsFixed(0)}",
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // ✅ mainAxisSize.min hata diya — is ke bina Row apni
                    // width khud nahi le sakta tha, jis wajah se Flexible
                    // ke andar ka text kabhi ellipsis nahi ho pa raha tha
                    // aur card ke right side se overflow ho raha tha.
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            controller.rating(service).toStringAsFixed(1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.shopping_bag_outlined, size: 13, color: textSecondary),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            "${controller.orders(service)} orders",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── View Details button ───────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: OutlinedButton(
                        onPressed: _openDetails,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.primary.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.medium,
                          ),
                        ),
                        child: Text(
                          "View Details",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}