import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/user/design/design_controller.dart';

class DesignExploreScreen extends StatelessWidget {
  const DesignExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DesignExploreController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: controller.refresh,
          child: CustomScrollView(
            slivers: [
              // ─── Header ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // ─ Back Button ─
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: AppRadius.full,
                              onTap: () => Get.back(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Explore Designs',
                              style: AppTextStyles.h2.copyWith(
                                  color: theme.colorScheme.onSurface)),
                        ],
                      ),
                      _SortButton(controller: controller),
                    ],
                  ),
                ),
              ),

              // ─── Search Bar ───────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: _SearchField(controller: controller),
                ),
              ),

              // ─── Category Chips ───────────────────────
              SliverToBoxAdapter(
                child: Obx(() => SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: controller.categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = controller.categories[index];
                          final selected =
                              controller.selectedCategory.value == cat;
                          return _CategoryChip(
                            label: cat,
                            selected: selected,
                            onTap: () => controller.setCategory(cat),
                          );
                        },
                      ),
                    )),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ─── Grid / States ────────────────────────
              Obx(() {
                if (controller.isLoading.value) {
                  return SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                }

                if (controller.errorMessage.value.isNotEmpty) {
                  return SliverFillRemaining(
                    child: _ErrorState(
                      message: controller.errorMessage.value,
                      onRetry: () => controller.fetchDesigns(),
                    ),
                  );
                }

                if (controller.filteredDesigns.isEmpty) {
                  return const SliverFillRemaining(
                    child: _EmptyState(),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = controller.filteredDesigns[index];
                        return _DesignCard(item: item);
                      },
                      childCount: controller.filteredDesigns.length,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// SEARCH FIELD
// ══════════════════════════════════════════════════════════════════════
class _SearchField extends StatelessWidget {
  final DesignExploreController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: theme.colorScheme.outline,
        ),
        boxShadow: AppShadows.card(theme.brightness == Brightness.dark),
      ),
      child: TextField(
        onChanged: controller.search,
        style: AppTextStyles.bodyMedium.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search designs, artists, categories...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant),
          prefixIcon: Icon(Icons.search_rounded,
              color: theme.colorScheme.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// CATEGORY CHIP
// ══════════════════════════════════════════════════════════════════════
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.tealGlow : null,
          color: selected
              ? null
              : theme.colorScheme.primaryContainer,
          borderRadius: AppRadius.full,
          border: Border.all(
            color: selected
                ? Colors.transparent
                : theme.colorScheme.outline,
          ),
          boxShadow: selected
              ? AppShadows.glow(theme.colorScheme.primary, alpha: 0.25, blur: 14)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: selected
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// SORT BUTTON
// ══════════════════════════════════════════════════════════════════════
class _SortButton extends StatelessWidget {
  final DesignExploreController controller;
  const _SortButton({required this.controller});

  String _label(DesignSortOption o) {
    switch (o) {
      case DesignSortOption.newest:
        return 'Newest';
      case DesignSortOption.priceLowToHigh:
        return 'Price ↑';
      case DesignSortOption.priceHighToLow:
        return 'Price ↓';
      case DesignSortOption.popular:
        return 'Popular';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() => PopupMenuButton<DesignSortOption>(
          onSelected: controller.setSort,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
          itemBuilder: (context) => DesignSortOption.values
              .map((o) => PopupMenuItem(
                    value: o,
                    child: Text(_label(o),
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurface)),
                  ))
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: AppRadius.medium,
              border: Border.all(
                  color: theme.colorScheme.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort_rounded,
                    size: 18,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(_label(controller.sortOption.value),
                    style: AppTextStyles.labelMedium.copyWith(
                        color: theme.colorScheme.primary)),
              ],
            ),
          ),
        ));
  }
}

// ══════════════════════════════════════════════════════════════════════
// DESIGN CARD
// ══════════════════════════════════════════════════════════════════════
class _DesignCard extends StatelessWidget {
  final DesignExploreItem item;
  const _DesignCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = item.imageUrls.isNotEmpty ? item.imageUrls.first : '';

    return GestureDetector(
      onTap: () {
        // TODO: navigate to design detail sheet using item.id / item.artistId
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.large,
          border: Border.all(
              color: theme.colorScheme.outline),
          boxShadow: AppShadows.card(theme.brightness == Brightness.dark),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ Image ─
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: theme.colorScheme.primaryContainer,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: theme.colorScheme.primaryContainer,
                            child: Icon(Icons.broken_image_outlined,
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.image_outlined,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),

                  // Verified badge
                  if (item.artistVerified)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.tealGlow,
                          borderRadius: AppRadius.full,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded,
                                size: 12, color: Colors.white),
                            SizedBox(width: 3),
                            Text('Verified',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),

                  // Price badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: AppRadius.full,
                      ),
                      child: Text('Rs ${item.price.toStringAsFixed(0)}',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),

            // ─ Info ─
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLarge.copyWith(
                          color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: item.artistImage.isNotEmpty
                              ? CachedNetworkImageProvider(item.artistImage)
                              : null,
                          child: item.artistImage.isEmpty
                              ? Icon(Icons.person,
                                  size: 11,
                                  color: theme.colorScheme.primary)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 13, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(item.artistRating.toStringAsFixed(1),
                            style: AppTextStyles.caption.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                        const Spacer(),
                        Text('${item.ordersCount} orders',
                            style: AppTextStyles.caption.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ══════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.design_services_outlined,
                  size: 40,
                  color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text('No designs found',
                style: AppTextStyles.h5.copyWith(
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 6),
            Text('Try changing filters or search terms',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// ERROR STATE
// ══════════════════════════════════════════════════════════════════════
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, 
              size: 40, 
              color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}