import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smartstitch/core/theme/app.theme.dart';
import 'artist_portfolio_controller.dart';

class PortfolioDetailsScreen extends GetView<ArtistPortfolioController> {
  const PortfolioDetailsScreen({super.key});

  // ─── RESPONSIVE HELPERS ───────────────────────────────────────
  int _galleryCrossAxisCount(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  double _contentMaxWidth(double width) {
    if (width >= 1400) return 1100;
    return width;
  }

  double _expandedHeaderHeight(double width) {
    if (width >= 900) return 420;
    if (width >= 600) return 360;
    return 320;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> service =
        Get.arguments as Map<String, dynamic>;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final Color textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final List<String> gallery = controller.galleryImages(service);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final galleryCrossAxisCount = _galleryCrossAxisCount(width);
          final maxContentWidth = _contentMaxWidth(width);
          final expandedHeight = _expandedHeaderHeight(width);
          final horizontalPadding = width >= 600 ? 28.0 : 20.0;
          // On wide/tablet+ screens, show the two info-card rows as a
          // single 4-across row instead of two stacked 2-across rows.
          final infoCardsPerRow = width >= 700 ? 4 : 2;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: expandedHeight,
                elevation: 0,
                backgroundColor:
                    isDark ? AppColors.darkSurface : AppColors.lightSurface,
                foregroundColor: textPrimary,
                leading: IconButton(
                  onPressed: Get.back,
                  icon: const Icon(Icons.arrow_back_ios_new),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => controller.editService(service),
                  ),
                  PopupMenuButton<String>(
                    color: isDark
                        ? AppColors.darkSurface2
                        : AppColors.lightSurface,
                    onSelected: (value) {
                      if (value == "delete") {
                        controller.confirmDelete(
                          service['id'],
                          // After the service is deleted, pop this
                          // details screen so the artist lands back
                          // on ArtistPortfolioScreen (My Portfolio).
                          onDeleted: () => Get.back(),
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: "delete",
                        child: Text(
                          "Delete",
                          style: TextStyle(color: textPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: service['id'],
                    child: CachedNetworkImage(
                      imageUrl: controller.coverImage(service),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: isDark
                            ? AppColors.darkSurface2
                            : Colors.grey.shade300,
                        child: Icon(
                          Icons.image_not_supported,
                          size: 70,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Padding(
                      padding: EdgeInsets.all(horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.serviceName(service),
                            style: AppTextStyles.h2.copyWith(
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              Chip(
                                label: Text(controller.category(service)),
                              ),
                              Chip(
                                label: Text(controller.status(service)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ─── Info cards: responsive wrap grid ────────
                          _buildInfoCardsGrid(
                            context,
                            service: service,
                            perRow: infoCardsPerRow,
                            spacing: 12,
                          ),

                          const SizedBox(height: 24),
                          if (controller.tags(service).isNotEmpty) ...[
                            Text(
                              "Tags",
                              style:
                                  AppTextStyles.h4.copyWith(color: textPrimary),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: controller
                                  .tags(service)
                                  .map(
                                    (tag) => Chip(
                                      label: Text(tag),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                          Text(
                            "Description",
                            style: AppTextStyles.h4.copyWith(color: textPrimary),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            controller.shortDescription(service),
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: textSecondary),
                          ),
                          const SizedBox(height: 24),
                          _featureTile(
                            context,
                            Icons.local_shipping_outlined,
                            "Home Pickup",
                            controller.homePickup(service)
                                ? "Available"
                                : "Not Available",
                          ),
                          _featureTile(
                            context,
                            Icons.flash_on_outlined,
                            "Urgent Delivery",
                            controller.urgentDelivery(service)
                                ? "Available"
                                : "Not Available",
                          ),
                          const SizedBox(height: 30),
                          if (gallery.isNotEmpty) ...[
                            Text(
                              "Gallery",
                              style:
                                  AppTextStyles.h4.copyWith(color: textPrimary),
                            ),
                            const SizedBox(height: 15),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: gallery.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: galleryCrossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemBuilder: (_, index) {
                                return ClipRRect(
                                  borderRadius: AppRadius.medium,
                                  child: CachedNetworkImage(
                                    imageUrl: gallery[index],
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Builds the 4 info cards (Price, Rating, Orders, Delivery) as a
  // responsive wrap-based grid: 2-per-row on phones, 4-per-row on
  // tablets/desktop/web.
  Widget _buildInfoCardsGrid(
    BuildContext context, {
    required Map<String, dynamic> service,
    required int perRow,
    required double spacing,
  }) {
    final items = [
      (
        icon: Icons.payments_rounded,
        title: "Starting Price",
        value: "Rs ${controller.price(service).toStringAsFixed(0)}",
        color: AppColors.primary,
      ),
      (
        icon: Icons.star_rounded,
        title: "Rating",
        value: controller.rating(service).toStringAsFixed(1),
        color: Colors.amber,
      ),
      (
        icon: Icons.shopping_bag_outlined,
        title: "Orders",
        value: controller.orders(service).toString(),
        color: AppColors.success,
      ),
      (
        icon: Icons.schedule,
        title: "Delivery",
        value: "${controller.deliveryDays(service)} Days",
        color: AppColors.info,
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final totalSpacing = spacing * (perRow - 1);
      final itemWidth = (constraints.maxWidth - totalSpacing) / perRow;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: items.map((item) {
          return SizedBox(
            width: itemWidth,
            child: _infoCard(
              context,
              icon: item.icon,
              title: item.title,
              value: item.value,
              color: item.color,
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _infoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: AppTextStyles.h4.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
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
    );
  }

  Widget _featureTile(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.10),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
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
    );
  }
}