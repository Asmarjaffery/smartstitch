import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smartstitch/core/theme/app.theme.dart';
import 'artist_portfolio_controller.dart';

class PortfolioDetailsScreen extends GetView<ArtistPortfolioController> {
  const PortfolioDetailsScreen({super.key});

  // ─── RESPONSIVE HELPERS ───────────────────────────────────────
  double _contentMaxWidth(double width) {
    if (width >= 1400) return 1100;
    return width;
  }

  double _heroHeight(double width) {
    if (width >= 900) return 500;
    if (width >= 600) return 420;
    return 360;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> service = Get.arguments as Map<String, dynamic>;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final gallery = controller.galleryImages(service);
    final status = controller.status(service);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final maxContentWidth = _contentMaxWidth(width);
          final heroHeight = _heroHeight(width);
          final horizontalPadding = width >= 600 ? 28.0 : 20.0;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Hero Section (Images Slider + Thumbnails) ────────
                          _HeroSection(
                            coverImage: controller.coverImage(service),
                            gallery: gallery,
                            heroHeight: heroHeight,
                            onEdit: () => controller.editService(service),
                            onDelete: () => controller.confirmDelete(
                              service['id'],
                              onDeleted: () => Get.back(),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.all(horizontalPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Status Badge ─────────────────────
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: (status.toLowerCase() == 'published'
                                            ? AppColors.success
                                            : AppColors.warning)
                                        .withValues(alpha: isDark ? 0.22 : 0.12),
                                    borderRadius: AppRadius.full,
                                  ),
                                  child: Text(
                                    status.isEmpty ? '—' : status,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: status.toLowerCase() == 'published'
                                          ? AppColors.success
                                          : AppColors.warning,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // ── Title ─────────────────────────────
                                Text(
                                  controller.serviceName(service),
                                  style: AppTextStyles.h2.copyWith(color: textPrimary),
                                ),
                                const SizedBox(height: 10),

                                // ── Price + rating ────────────────────
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Rs ${controller.price(service).toStringAsFixed(0)}",
                                          style: AppTextStyles.h1.copyWith(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkSurface2
                                            : AppColors.primarySoft,
                                        borderRadius: AppRadius.medium,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              size: 16, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          Text(
                                            controller.rating(service).toStringAsFixed(1),
                                            style: AppTextStyles.labelMedium.copyWith(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            "(${controller.orders(service)})",
                                            style: AppTextStyles.bodySmall
                                                .copyWith(color: textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // ── Description ───────────────────────
                                Text(
                                  controller.shortDescription(service),
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: textSecondary, height: 1.5),
                                ),
                                const SizedBox(height: 22),

                                // ── Key Info Cards (Price / Rating / Orders / Delivery) ──
                                _buildInfoCardsGrid(
                                  context,
                                  service: service,
                                  perRow: 4,
                                  spacing: 12,
                                ),

                                const SizedBox(height: 24),

                                // ── Tags (if any) ──────────────────────
                                if (controller.tags(service).isNotEmpty) ...[
                                  Text("Tags",
                                      style: AppTextStyles.h4.copyWith(color: textPrimary)),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: controller
                                        .tags(service)
                                        .map((tag) => Chip(label: Text(tag)))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // ── Add-ons (Home Pickup + Urgent Delivery) ──
                                _featureTile(
                                  context,
                                  Icons.local_shipping_outlined,
                                  "Home Pickup",
                                  controller.homePickup(service) ? "Available" : "Not Available",
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Fixed Bottom Action Bar: Back + Edit ───────────────
              _BottomActionBar(
                isDark: isDark,
                horizontalPadding: horizontalPadding,
                onBack: () => Get.back(),
                onEdit: () => controller.editService(service),
              ),
            ],
          );
        },
      ),
    );
  }

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
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: AppTextStyles.h4.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureTile(BuildContext context, IconData icon, String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.medium,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.10),
            child: Icon(icon, color: AppColors.primary, size: 20),
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
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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

//==========================================================
// HERO SECTION — FULL-WIDTH CLEAN IMAGE + THUMBNAIL STRIP
// Images are now the main focus, clearer and larger
//==========================================================
class _HeroSection extends StatefulWidget {
  final String coverImage;
  final List<String> gallery;
  final double heroHeight;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HeroSection({
    required this.coverImage,
    required this.gallery,
    required this.heroHeight,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  int _selectedIndex = 0;

  List<String> get _images =>
      widget.gallery.isNotEmpty ? widget.gallery : [widget.coverImage];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeImage = _images[_selectedIndex.clamp(0, _images.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── MAIN HERO IMAGE (LARGER & CLEARER) ───────────────────────
        SizedBox(
          height: widget.heroHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main Image
              CachedNetworkImage(
                imageUrl: activeImage,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: isDark ? AppColors.darkSurface2 : Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: isDark ? AppColors.darkSurface2 : Colors.grey.shade300,
                  child: Icon(Icons.image_not_supported,
                      size: 70, color: isDark ? AppColors.darkTextSecondary : Colors.grey),
                ),
              ),

              // Back Button (Top Left)
              Positioned(
                top: 16,
                left: 16,
                child: _circleIconButton(Icons.arrow_back_ios_new_rounded, Get.back),
              ),

              // Edit + Delete Buttons (Top Right)
              Positioned(
                top: 16,
                right: 16,
                child: Row(
                  children: [
                    _circleIconButton(Icons.edit_outlined, widget.onEdit),
                    const SizedBox(width: 10),
                    _circleIconButton(Icons.delete_outline_rounded, widget.onDelete,
                        iconColor: AppColors.error),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── THUMBNAIL STRIP (SCROLLABLE) ─────────────────────────────
        if (_images.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.medium,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.medium,
                        child: CachedNetworkImage(
                          imageUrl: _images[index],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _circleIconButton(IconData icon, VoidCallback onTap, {Color? iconColor}) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: iconColor ?? Colors.black87),
      ),
    );
  }
}

//==========================================================
// FIXED BOTTOM ACTION BAR — BACK + EDIT
//
// ✅ CHANGE: previously this bar only had a single full-width
// "Edit Service" button. Now it has two buttons side by side:
//   - "Back" (outlined, secondary style) → returns to the
//     Artist Portfolio screen via Get.back().
//   - "Edit Service" (filled, primary style, gradient-ready) →
//     unchanged behaviour, just restyled to sit next to Back.
// The outlined/filled pairing plus consistent height, radius,
// icon sizing, and spacing is what gives it a more "professional"
// polished look instead of a single stretched button.
//==========================================================
class _BottomActionBar extends StatelessWidget {
  final bool isDark;
  final double horizontalPadding;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const _BottomActionBar({
    required this.isDark,
    required this.horizontalPadding,
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Back button (secondary / outlined) ──────────────
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: onBack,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
                  ),
                  label: Text(
                    'Back',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.primarySoft,
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Edit Service button (primary / filled) ──────────
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    textStyle: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}