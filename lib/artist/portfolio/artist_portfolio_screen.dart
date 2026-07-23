import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/portfolio_card.dart';

import 'artist_portfolio_controller.dart';

class ArtistPortfolioScreen extends GetView<ArtistPortfolioController> {
  const ArtistPortfolioScreen({super.key});

  // ─── RESPONSIVE HELPERS ───────────────────────────────────────
  int _crossAxisCount(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  double _childAspectRatio(double width) {
    if (width >= 1200) return 0.80;
    if (width >= 900) return 0.76;
    if (width >= 600) return 0.72;
    return 0.62;
  }

  int _statColumns(double width) {
    if (width < 340) return 1;
    return 2;
  }

  double _contentMaxWidth(double width) {
    if (width >= 1400) return 1200;
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xffF8F9FC),
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Text(
          "My Portfolio",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : Colors.black87,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = _crossAxisCount(width);
          final childAspectRatio = _childAspectRatio(width);
          final statColumns = _statColumns(width);
          final maxContentWidth = _contentMaxWidth(width);
          final horizontalPadding = width >= 600 ? 24.0 : 16.0;

          return RefreshIndicator(
            onRefresh: controller.refreshPortfolio,
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      /// ============================
                      /// HEADER
                      /// ============================
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(horizontalPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatistics(statColumns),
                              const SizedBox(height: 20),
                              _buildSearch(isDark),
                              const SizedBox(height: 18),
                              _buildFilters(isDark),
                            ],
                          ),
                        ),
                      ),

                      /// ============================
                      /// GRID
                      /// ============================
                      Obx(() {
                        if (controller.filteredPortfolio.isEmpty) {
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
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item =
                                    controller.filteredPortfolio[index];

                                return PortfolioCard(
                                  service: item,
                                );
                              },
                              childCount:
                                  controller.filteredPortfolio.length,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: childAspectRatio,
                            ),
                          ),
                        );
                      }),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 20),
                      )
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  //==========================================================
  // SEARCH
  //==========================================================
  Widget _buildSearch(bool isDark) {
    return TextField(
      onChanged: controller.onSearchChanged,
      style: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: "Search portfolio...",
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  //==========================================================
  // FILTERS
  //==========================================================
  Widget _buildFilters(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(title: "All", onTap: controller.showAll, isDark: isDark),
          const SizedBox(width: 10),
          _filterChip(title: "Published", onTap: controller.showPublished, isDark: isDark),
          const SizedBox(width: 10),
          _filterChip(title: "Draft", onTap: controller.showDraft, isDark: isDark),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ActionChip(
      label: Text(title),
      onPressed: onTap,
      backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.primarySoft,
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
      ),
      side: BorderSide(color: isDark ? AppColors.darkBorder : Colors.transparent),
    );
  }

  //==========================================================
  // STATISTICS
  //==========================================================
  Widget _buildStatistics(int columns) {
    return Obx(() {
      final total = controller.portfolio.length;

      final published = controller.portfolio.where((e) {
        return (e['status'] ?? '').toString().toLowerCase() == 'published';
      }).length;

      final draft = controller.portfolio.where((e) {
        return (e['status'] ?? '').toString().toLowerCase() == 'draft';
      }).length;

      final orders = controller.portfolio.fold<int>(
        0,
        (sum, item) => sum + ((item['ordersCount'] ?? 0) as int),
      );

      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: columns == 1 ? 3.4 : 1.6,
        children: [
          _statCard(
            "Total",
            total.toString(),
            Icons.collections_rounded,
            AppColors.primary,
          ),
          _statCard(
            "Published",
            published.toString(),
            Icons.public,
            AppColors.success,
          ),
          _statCard(
            "Draft",
            draft.toString(),
            Icons.edit_document,
            AppColors.warning,
          ),
          _statCard(
            "Orders",
            orders.toString(),
            Icons.shopping_bag_outlined,
            AppColors.info,
          ),
        ],
      );
    });
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Card(
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.medium,
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            boxShadow: AppShadows.card(isDark),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: isDark ? 0.2 : 0.12),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: AppTextStyles.metricValue.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}