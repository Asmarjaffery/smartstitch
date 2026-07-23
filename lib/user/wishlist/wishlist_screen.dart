import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/models/design_model.dart';
import 'package:smartstitch/models/artist_model.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/user/booking/booking_controller.dart';
import 'package:smartstitch/user/wishlist/wishlist_controller.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = WishlistController.to;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('My Wishlist', style: AppTextStyles.h4),
          centerTitle: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: AppTextStyles.labelMedium,
            tabs: const [
              Tab(text: 'Designs'),
              Tab(text: 'Artists'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ─── Designs Tab ──────────────────────────────────────
            Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (ctrl.favoriteDesigns.isEmpty) {
                return const _EmptyState(
                  icon: Icons.checkroom_outlined,
                  message: 'No favorite designs yet',
                  subtitle: 'Tap ❤️ on any design to save it',
                );
              }
              return RefreshIndicator(
                onRefresh: ctrl.loadWishlist,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ctrl.favoriteDesigns.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _DesignWishCard(design: ctrl.favoriteDesigns[i]),
                ),
              );
            }),

            // ─── Artists Tab ──────────────────────────────────────
            Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (ctrl.favoriteArtists.isEmpty) {
                return const _EmptyState(
                  icon: Icons.person_outline_rounded,
                  message: 'No favorite artists yet',
                  subtitle: 'Tap ❤️ on any artist to save them',
                );
              }
              return RefreshIndicator(
                onRefresh: ctrl.loadWishlist,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ctrl.favoriteArtists.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _ArtistWishCard(artist: ctrl.favoriteArtists[i]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Design Wish Card ─────────────────────────────────────────────────────────
class _DesignWishCard extends StatelessWidget {
  final DesignModel design;
  const _DesignWishCard({required this.design});

  // ─── Book Now: fetch artist by design.artistId then go to booking ──────
  Future<void> _bookNow(BuildContext context) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      final artistDoc = await FirebaseFirestore.instance
          .collection('artists')
          .doc(design.artistId)
          .get();

      Get.back(); // close loading dialog

      if (!artistDoc.exists) {
        Get.snackbar(
          'Error',
          'Artist not found',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final artist = ArtistModel.fromJson({
        ...artistDoc.data()!,
        'id': artistDoc.id,
      });

      final bookingCtrl = Get.find<BookingController>();
      bookingCtrl.setArtistDirectly(artist);
      Get.toNamed(AppRoutes.bookingCreate);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        'Error',
        'Could not load artist details',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = WishlistController.to;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: AppShadows.soft(theme.colorScheme.primary),
      ),
      child: Row(
        children: [
          // ─── Image Thumbnail ────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: AppRadius.medium,
                child: design.imageUrls.isNotEmpty
                    ? Image.network(
                        design.imageUrls.first,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(context),
                      )
                    : _placeholder(context, width: 100, height: 100),
              ),
              // Trending Badge
              if (design.isTrending)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Trending',
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9)),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // ─── Design Info ────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  design.title,
                  style: AppTextStyles.labelLarge.copyWith(
                      color: theme.colorScheme.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Price
                Text(
                  'PKR ${design.estimatedPrice.toInt()}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // Color Tags
                if (design.colorTags.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: design.colorTags.take(4).map((c) {
                      return Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _colorFromTag(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.outline,
                            width: 1,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ─── Action Buttons ─────────────────────────────────────
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Heart Button
              GestureDetector(
                onTap: () => ctrl.toggleDesign(design.id, designTitle: design.title),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Book Button
              GestureDetector(
                onTap: () => _bookNow(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Book',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context, {double width = 100, double height = 100}) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.checkroom_rounded,
          color: theme.colorScheme.onPrimaryContainer,
          size: 30,
        ),
      ),
    );
  }

  Color _colorFromTag(String tag) {
    switch (tag.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'pink':
        return Colors.pink;
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      case 'gold':
        return Colors.amber;
      case 'purple':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }
}

// ─── Artist Wish Card ─────────────────────────────────────────────────────────
class _ArtistWishCard extends StatelessWidget {
  final ArtistModel artist;
  const _ArtistWishCard({required this.artist});

  @override
  Widget build(BuildContext context) {
    final ctrl = WishlistController.to;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: AppShadows.soft(theme.colorScheme.primary),
      ),
      child: Row(
        children: [
          // ─── Avatar ────────────────────────────────────────────
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: artist.portfolioImages.isNotEmpty
                ? NetworkImage(artist.portfolioImages.first)
                : null,
            child: artist.portfolioImages.isEmpty
                ? Text(
                    artist.businessName[0].toUpperCase(),
                    style: AppTextStyles.h3
                        .copyWith(color: theme.colorScheme.onPrimaryContainer),
                  )
                : null,
          ),

          const SizedBox(width: 12),

          // ─── Info ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(artist.businessName,
                    style: AppTextStyles.labelLarge
                        .copyWith(color: theme.colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(artist.bio,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: artist.specializations
                      .take(2)
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: AppRadius.full,
                            ),
                            child: Text(s,
                                style: AppTextStyles.caption.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          // ─── Heart Button ───────────────────────────────────────
          GestureDetector(
            onTap: () => ctrl.toggleArtist(artist.id, artistName: artist.businessName),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: AppColors.error, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 60, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 20),
          Text(message,
              style: AppTextStyles.h4.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}