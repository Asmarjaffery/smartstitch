import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/artist/portfolio/artist_portfolio_controller.dart';
import 'package:smartstitch/artist/portfolio/portfolio_details_screen.dart';

import 'package:smartstitch/core/theme/app.theme.dart';

class PortfolioCard extends GetView<ArtistPortfolioController> {
  const PortfolioCard({
    super.key,
    required this.service,
  });

  final Map<String, dynamic> service;

  // Formats a price as Pakistani Rupees with thousands separators,
  // e.g. 8000 -> "8,000".
  String _formatPrice(num price) {
    final value = price.round();
    final digits = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final String image = controller.coverImage(service);
    final String title = controller.serviceName(service);
    final String category = controller.category(service);
    final double price = controller.price(service);
    final double rating = controller.rating(service);
    final int orders = controller.orders(service);
    final String status = controller.status(service);

    return Hero(
      tag: service['id'] ?? title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.large,
          onTap: () {
            Get.to(
              () => const PortfolioDetailsScreen(),
              arguments: service,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: AppRadius.large,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              boxShadow: AppShadows.card(isDark),
            ),
            // Column, NOT split by fixed flex ratios. The details block
            // below sizes itself to whatever its content actually needs
            // (mainAxisSize.min), and the image simply takes whatever
            // height is left over via Expanded. This means the details
            // block can NEVER be squeezed smaller than its content
            // requires — which is what caused the overflow before, when
            // both image and details were forced into a fixed 6:5 flex
            // split regardless of how much text/buttons needed to fit.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                /// IMAGE — fills whatever space remains after the
                /// details block below claims what it needs.
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: isDark
                                  ? AppColors.darkSurface2
                                  : AppColors.lightSurface2,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 45,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: status.toLowerCase() == "published"
                                ? AppColors.success
                                : AppColors.warning,
                            borderRadius: AppRadius.full,
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case "edit":
                                controller.editService(service);
                                break;
                              case "delete":
                                controller.confirmDelete(service["id"]);
                                break;
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: "edit",
                              child: Text("Edit"),
                            ),
                            PopupMenuItem(
                              value: "delete",
                              child: Text("Delete"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                /// DETAILS — natural height, never force-squeezed.
                /// mainAxisSize.min means this Column only ever takes
                /// exactly as much vertical space as its children need.
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h5.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Price — "Rs." instead of ₹, comma-formatted.
                      Text(
                        "Rs. ${_formatPrice(price)}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h5.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      // Fixed spacing instead of Spacer(): Spacer needs
                      // a bounded parent height to expand into, which
                      // conflicts with mainAxisSize.min sizing-to-content.
                      // A fixed gap keeps the layout predictable and
                      // measurable regardless of parent constraints.
                      const SizedBox(height: 8),

                      // Rating + Orders — compact single row.
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.shopping_bag_outlined,
                            size: 15,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              "$orders Orders",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        height: 34,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.to(
                              () => const PortfolioDetailsScreen(),
                              arguments: service,
                            );
                          },
                          icon: const Icon(
                            Icons.visibility_outlined,
                            size: 16,
                          ),
                          label: const Text(
                            "View Details",
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.medium,
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
        ),
      ),
    );
  }
}