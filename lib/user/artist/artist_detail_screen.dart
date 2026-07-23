import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/user/booking/booking_controller.dart';
import 'package:smartstitch/user/chat/chat_room_screen.dart';
import 'package:smartstitch/user/wishlist/wishlist_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../core/theme/app.theme.dart';
import '../../models/artist_model.dart';

// ─── Portfolio Item Model ──────────────────────────────────────────────────
class PortfolioItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final double price;
  final List<String> imageUrls;
  final bool isTrending;
  final DateTime? createdAt;

  PortfolioItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrls,
    required this.isTrending,
    this.createdAt,
  });

  factory PortfolioItem.fromJson(String id, Map<String, dynamic> data) {
    DateTime? createdAt;
    final raw = data['createdAt'];
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    } else if (raw is String) {
      createdAt = DateTime.tryParse(raw);
    }

    final imgs = <String>[];
    if (data['imageUrls'] is List) {
      for (final i in data['imageUrls'] as List) {
        if (i is String && i.isNotEmpty) imgs.add(i);
      }
    }

    return PortfolioItem(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      imageUrls: imgs,
      isTrending: data['isTrending'] as bool? ?? false,
      createdAt: createdAt,
    );
  }
}

// ─── Artist Detail Screen ──────────────────────────────────────────────────
class ArtistDetailScreen extends StatefulWidget {
  const ArtistDetailScreen({super.key});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  ArtistModel? artist;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is ArtistModel) {
      artist = arg;
      _refreshArtist(arg.userId);
    }
  }

  Future<void> _refreshArtist(String artistId) async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('artists').doc(artistId).get(),
        // ✅ FIXED: Was 'orders' — real booking documents live in 'bookings'.
        // That mismatch was why totalOrders always showed a stale/low number.
        FirebaseFirestore.instance
            .collection('bookings')
            .where('artistId', isEqualTo: artistId)
            .count()
            .get(),
      ]);

      final doc = results[0] as DocumentSnapshot;
      final countSnap = results[1] as AggregateQuerySnapshot;

      if (doc.exists && mounted) {
        final data = {...doc.data()! as Map<String, dynamic>, 'id': doc.id};
        final liveCount = countSnap.count ?? 0;
        data['totalOrders'] = liveCount;

        debugPrint('🔍 averageRating: ${data['averageRating']}');
        debugPrint('🔍 rating: ${data['rating']}');
        debugPrint('📦 liveOrderCount (from bookings): $liveCount');

        setState(() {
          artist = ArtistModel.fromJson(data);
        });
        if (liveCount !=
            ((doc.data() as Map<String, dynamic>?)?['totalOrders'] ?? 0)) {
          await FirebaseFirestore.instance
              .collection('artists')
              .doc(artistId)
              .update({'totalOrders': liveCount});
        }

        debugPrint(
            '✅ orders: ${artist?.totalOrders}, rating: ${artist?.rating}');
      }
    } catch (e, stack) {
      debugPrint('❌ _refreshArtist error: $e');
      debugPrint('$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (artist == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final a = artist!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ─── Purple Header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // ── Top Bar ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.more_horiz_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Avatar ───────────────────────────────────────────
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.3),
                            backgroundImage: a.profileImageUrl.isNotEmpty
                                ? NetworkImage(a.profileImageUrl)
                                : a.portfolioImages.isNotEmpty
                                    ? NetworkImage(a.portfolioImages.first)
                                    : null,
                            child: (a.profileImageUrl.isEmpty &&
                                    a.portfolioImages.isEmpty)
                                ? Text(
                                    a.businessName[0].toUpperCase(),
                                    style: AppTextStyles.h2.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                        ),
                        if (a.isVerified)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_rounded,
                                  color: AppColors.success, size: 22),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Name ─────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          a.businessName,
                          style: AppTextStyles.h3.copyWith(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        if (a.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              color: Colors.white, size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.specializations.isNotEmpty
                          ? a.specializations.first
                          : 'Fashion Designer',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),

                    const SizedBox(height: 20),

                    // ── Stats Row ─────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HeaderStat(
                          value: a.rating > 0
                              ? a.rating.toStringAsFixed(1)
                              : 'New',
                          label: 'Rating',
                          icon: Icons.star_rounded,
                        ),
                        const _VerticalDivider(),
                        _HeaderStat(
                          value: '${a.totalOrders}+',
                          label: 'Orders',
                          icon: Icons.receipt_long_rounded,
                        ),
                        const _VerticalDivider(),
                        _HeaderStat(
                          value: '${a.totalReviews}',
                          label: 'Reviews',
                          icon: Icons.reviews_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // ─── Body ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Message + Book Buttons (equal width) ────────────
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _requireLoginAction(() => _openChat(
                                a.userId,
                                a.businessName,
                                a.portfolioImages.isNotEmpty
                                    ? a.portfolioImages.first
                                    : null,
                              )),
                          icon: const Icon(Icons.chat_bubble_rounded,
                              color: Colors.white, size: 18),
                          label: const Text('Message',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _requireLoginAction(() {
                            final bookingCtrl = Get.find<BookingController>();
                            bookingCtrl.setArtistDirectly(a);
                            Get.toNamed(AppRoutes.bookingCreate);
                          }),
                          icon: Icon(Icons.add_rounded,
                              color: theme.colorScheme.primary, size: 18),
                          label: Text('Book',
                              style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: theme.colorScheme.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── About ────────────────────────────────────────────
                  if (a.bio.isNotEmpty) ...[
                    Text('About',
                        style: AppTextStyles.h5.copyWith(
                            color: textPrimary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      a.bio,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: textSecondary, height: 1.6),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Specializations ──────────────────────────────────
                  Text('Specializations',
                      style: AppTextStyles.h5.copyWith(
                          color: textPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: a.specializations
                        .map((s) => _SpecChip(label: s))
                        .toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── Portfolio ────────────────────────────────────────
                  _PortfolioSection(
                      artistId: a.userId, isDark: isDark, artist: a),

                  const SizedBox(height: 24),

                  // ── Reviews ──────────────────────────────────────────
                  Text('Reviews',
                      style: AppTextStyles.h5.copyWith(
                          color: textPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('artistId', isEqualTo: a.id)
                        .orderBy('createdAt', descending: true)
                        .limit(10)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface2
                                : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.rate_review_outlined,
                                  size: 36,
                                  color: isDark
                                      ? AppColors.darkTextHint
                                      : AppColors.lightTextHint),
                              const SizedBox(height: 8),
                              Text(
                                'No reviews yet — be the first!',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextHint
                                      : AppColors.lightTextHint,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: snapshot.data!.docs
                            .map((doc) => _ReviewTile(
                                data: doc.data() as Map<String, dynamic>,
                                isDark: isDark))
                            .toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),

      // ─── Bottom Button ────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(top: BorderSide(color: borderColor, width: 1)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3))
                ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _requireLoginAction(() => _openChat(
                  a.userId,
                  a.businessName,
                  a.portfolioImages.isNotEmpty ? a.portfolioImages.first : null,
                )),
            icon: const Icon(Icons.chat_bubble_rounded,
                color: Colors.white, size: 20),
            label: const Text('Message Artist',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  void _requireLoginAction(VoidCallback action) {
    if (!AuthController.to.isLoggedIn.value) {
      Get.snackbar(
        'Login Required',
        'Please log in first to use this feature',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.92),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.lock_outline_rounded,
            color: Colors.white, size: 20),
      );
      Future.delayed(const Duration(milliseconds: 300),
          () => Get.toNamed(AppRoutes.login));
      return;
    }
    action();
  }

  Future<void> _openChat(
      String artistId, String artistName, String? artistImage) async {
    if (artistId.isEmpty) {
      Get.snackbar('Error', 'Artist ID is missing',
          backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }
    final controller = Get.find<ChatController>();
    await controller.openChat(artistId);
    Get.to(() => ChatRoomScreen(
          otherUserId: artistId,
          roomName: artistName,
          profileImageUrl: artistImage,
        ));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PORTFOLIO SECTION
// ═══════════════════════════════════════════════════════════════════════════
class _PortfolioSection extends StatelessWidget {
  final String artistId;
  final bool isDark;
  final ArtistModel artist;

  const _PortfolioSection(
      {required this.artistId, required this.isDark, required this.artist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Portfolio',
                style: AppTextStyles.h5
                    .copyWith(color: textPrimary, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => Get.toNamed(
                AppRoutes.artistPortfolio,
                arguments: {
                  'artistId': artistId,
                  'userId': artist.userId,
                  'artistName': artist.businessName,
                  'artistImage': artist.profileImageUrl.isNotEmpty
                      ? artist.profileImageUrl
                      : (artist.portfolioImages.isNotEmpty
                          ? artist.portfolioImages.first
                          : ''),
                },
              ),
              child: Row(
                children: [
                  Text('View All',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: theme.colorScheme.primary)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      color: theme.colorScheme.primary, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('services')
              .where('artistId', isEqualTo: artistId)
              .where('type', isEqualTo: 'artist')
              .where('status', isEqualTo: 'published')
              .orderBy('createdAt', descending: true)
              .limit(4)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 180,
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }
            if (snapshot.hasError) {
              debugPrint('❌ Portfolio query error: ${snapshot.error}');
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return _emptyPortfolio();
            }

            final items = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final gallery = <String>[];
              if (data['coverImageUrl'] != null &&
                  (data['coverImageUrl'] as String).isNotEmpty) {
                gallery.add(data['coverImageUrl'] as String);
              }
              if (data['galleryImageUrls'] is List) {
                for (final img in data['galleryImageUrls'] as List) {
                  if (img is String && img.isNotEmpty) gallery.add(img);
                }
              }
              return PortfolioItem(
                id: doc.id,
                title: data['serviceName'] as String? ?? '',
                description: data['shortDescription'] as String? ?? '',
                category: data['category'] as String? ?? '',
                price: (data['startingPrice'] as num?)?.toDouble() ?? 0,
                imageUrls: gallery,
                isTrending: false,
                createdAt: data['createdAt'] != null
                    ? DateTime.tryParse(data['createdAt'].toString())
                    : null,
              );
            }).toList();

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.78,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) => _PortfolioCard(
                  item: items[index], isDark: isDark, artist: artist),
            );
          },
        ),
      ],
    );
  }

  Widget _emptyPortfolio() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 32,
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
          const SizedBox(height: 6),
          Text('No portfolio items yet',
              style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextHint
                      : AppColors.lightTextHint)),
        ],
      ),
    );
  }
}

// ─── Portfolio Card ────────────────────────────────────────────────────────
class _PortfolioCard extends StatefulWidget {
  final PortfolioItem item;
  final bool isDark;
  final ArtistModel artist;

  const _PortfolioCard(
      {required this.item, required this.isDark, required this.artist});

  @override
  State<_PortfolioCard> createState() => _PortfolioCardState();
}

class _PortfolioCardState extends State<_PortfolioCard> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goToBooking() {
    final bookingCtrl = Get.find<BookingController>();
    bookingCtrl.setArtistDirectly(widget.artist);
    Get.toNamed(AppRoutes.bookingCreate);
  }

  // ✅ FIXED: Changed collection from 'design_reviews' to 'reviews'
  Future<void> _updateArtistRating(String artistId) async {
    try {
      final reviewsSnap = await FirebaseFirestore.instance
          .collection('reviews') // ✅ FIXED: Was 'design_reviews'
          .where('artistId', isEqualTo: artistId)
          .get();

      if (reviewsSnap.docs.isEmpty) {
        debugPrint('⚠️ No reviews found for artist: $artistId');
        return;
      }

      final ratings = reviewsSnap.docs
          .map((d) => (d.data()['rating'] as num?)?.toDouble() ?? 0)
          .toList();

      if (ratings.isEmpty) return;

      final avg = ratings.reduce((a, b) => a + b) / ratings.length;

      await FirebaseFirestore.instance
          .collection('artists')
          .doc(artistId)
          .update({
        'rating': double.parse(avg.toStringAsFixed(1)),
        'averageRating': double.parse(avg.toStringAsFixed(1)),
        'totalReviews': ratings.length,
      });

      debugPrint(
          '✅ Artist rating updated: $avg (from ${ratings.length} reviews)');
    } catch (e) {
      debugPrint('❌ Error updating artist rating: $e');
    }
  }

  void _showWriteReviewDialog(BuildContext context, PortfolioItem item) {
    if (!AuthController.to.isLoggedIn.value) {
      Get.snackbar(
        'Login Required',
        'Please log in to write a review',
        backgroundColor: AppColors.error.withValues(alpha: 0.92),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    final ratingRx = 5.obs;
    final commentCtrl = TextEditingController();
    final isSubmitting = false.obs;
    final isDark = widget.isDark;
    final dialogBg = isDark ? AppColors.darkSurface : Colors.white;
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    Get.dialog(
      Dialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Write a Review',
                  style: AppTextStyles.h5.copyWith(
                      color: titleColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(item.title,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary)),
              const SizedBox(height: 16),
              Obx(() => Row(
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return GestureDetector(
                        onTap: () => ratingRx.value = star,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            star <= ratingRx.value
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: AppColors.warning,
                            size: 32,
                          ),
                        ),
                      );
                    }),
                  )),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                maxLength: 300,
                style: AppTextStyles.bodyMedium.copyWith(color: titleColor),
                decoration: InputDecoration(
                  hintText: 'Share your thoughts about this design...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Obx(() => ElevatedButton(
                          onPressed: isSubmitting.value
                              ? null
                              : () async {
                                  isSubmitting.value = true;
                                  try {
                                    final user =
                                        AuthController.to.currentUser.value;

                                    // ✅ FIXED: Changed from 'design_reviews' to 'reviews'
                                    await FirebaseFirestore.instance
                                        .collection(
                                            'reviews') // ✅ FIXED: Was 'design_reviews'
                                        .add({
                                      'designId': item.id,
                                      'artistId': widget.artist.userId,
                                      'customerId': user?.id ?? '',
                                      'customerName': user?.name ?? 'Customer',
                                      'rating': ratingRx.value,
                                      'comment': commentCtrl.text.trim(),
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });

                                    // Now this will work correctly because both use 'reviews'
                                    await _updateArtistRating(
                                        widget.artist.userId);

                                    Get.back();
                                    Get.snackbar(
                                      'Success',
                                      'Review submitted! 🎉',
                                      backgroundColor: AppColors.primary,
                                      colorText: Colors.white,
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  } catch (e) {
                                    debugPrint('Error submitting review: $e');
                                    Get.snackbar(
                                      'Error',
                                      'Could not submit review: $e',
                                      backgroundColor: AppColors.error,
                                      colorText: Colors.white,
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  } finally {
                                    isSubmitting.value = false;
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: isSubmitting.value
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Submit',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;
    final images = item.imageUrls;

    return GestureDetector(
      onTap: () => _showPortfolioDetail(context, item, isDark),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // ── Image Slider ──
              images.isNotEmpty
                  ? PageView.builder(
                      controller: _pageCtrl,
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (_, i) => CachedNetworkImage(
                        imageUrl: images[i],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (_, __) => Container(
                            color: isDark
                                ? AppColors.darkSurface2
                                : AppColors.primarySoft),
                        errorWidget: (_, __, ___) => Container(
                          color: isDark
                              ? AppColors.darkSurface2
                              : AppColors.primarySoft,
                          child: const Icon(Icons.image_rounded,
                              color: AppColors.primary),
                        ),
                      ),
                    )
                  : Container(
                      color: isDark
                          ? AppColors.darkSurface2
                          : AppColors.primarySoft,
                      child: const Center(
                        child: Icon(Icons.image_outlined,
                            color: AppColors.primaryLight, size: 40),
                      ),
                    ),

              // ── Gradient overlay ──
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const [0.0, 0.40, 1.0],
                    ),
                  ),
                ),
              ),

              // ── Category badge (top left) ──
              if (item.category.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(item.category,
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w500)),
                  ),
                ),

              // ── Favorite button (top right) ──
              Positioned(
                top: 10,
                right: 10,
                child: Obx(() {
                  final isFavorited = WishlistController.to.favoriteDesigns
                      .any((d) => d.id == item.id);
                  return GestureDetector(
                    onTap: () => WishlistController.to
                        .toggleDesign(item.id, designTitle: item.title),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: Icon(
                        isFavorited
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                    ),
                  );
                }),
              ),

              // ── Left Arrow ──
              if (images.length > 1 && _currentPage > 0)
                Positioned(
                  left: 6,
                  top: 0,
                  bottom: 60,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _pageCtrl.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.chevron_left_rounded,
                            color: Theme.of(context).colorScheme.primary, size: 20),
                      ),
                    ),
                  ),
                ),

              // ── Right Arrow ──
              if (images.length > 1 && _currentPage < images.length - 1)
                Positioned(
                  right: 6,
                  top: 0,
                  bottom: 60,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _pageCtrl.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.chevron_right_rounded,
                            color: Theme.of(context).colorScheme.primary, size: 20),
                      ),
                    ),
                  ),
                ),

              // ── Page dots ──
              if (images.length > 1)
                Positioned(
                  bottom: 58,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: _currentPage == i ? 14 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Bottom overlay ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PKR ${item.price.toStringAsFixed(0)}',
                            style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () =>
                                _showPortfolioDetail(context, item, isDark),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.calendar_today_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPortfolioDetail(
      BuildContext context, PortfolioItem item, bool isDark) {
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final currentPage = 0.obs;
    final pageCtrl = PageController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.imageUrls.isNotEmpty)
                      Stack(
                        children: [
                          SizedBox(
                            height: 300,
                            child: PageView.builder(
                              controller: pageCtrl,
                              itemCount: item.imageUrls.length,
                              onPageChanged: (i) => currentPage.value = i,
                              itemBuilder: (_, i) => CachedNetworkImage(
                                imageUrl: item.imageUrls[i],
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    Container(color: AppColors.primarySoft),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.primarySoft,
                                  child: const Icon(Icons.image_rounded,
                                      color: AppColors.primary),
                                ),
                              ),
                            ),
                          ),
                          if (item.imageUrls.length > 1)
                            Positioned(
                              left: 12,
                              top: 0,
                              bottom: 0,
                              child: Obx(() {
                                if (currentPage.value <= 0)
                                  return const SizedBox.shrink();
                                return Center(
                                  child: GestureDetector(
                                    onTap: () => pageCtrl.previousPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.chevron_left_rounded,
                                          color: AppColors.primary,
                                          size: 24),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          if (item.imageUrls.length > 1)
                            Positioned(
                              right: 12,
                              top: 0,
                              bottom: 0,
                              child: Obx(() {
                                if (currentPage.value >=
                                    item.imageUrls.length - 1) {
                                  return const SizedBox.shrink();
                                }
                                return Center(
                                  child: GestureDetector(
                                    onTap: () => pageCtrl.nextPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppColors.primary,
                                          size: 24),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          if (item.imageUrls.length > 1)
                            Positioned(
                              top: 12,
                              right: 16,
                              child: Obx(() => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${currentPage.value + 1}/${item.imageUrls.length}',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )),
                            ),
                          if (item.imageUrls.length > 1)
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Obx(() => Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      item.imageUrls.length,
                                      (i) => AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        width: currentPage.value == i ? 20 : 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: currentPage.value == i
                                              ? Colors.white
                                              : Colors.white
                                                  .withValues(alpha: 0.5),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  )),
                            ),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(item.category,
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.primary)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(item.title,
                                    style: AppTextStyles.h4
                                        .copyWith(color: titleColor)),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'PKR ${item.price.toStringAsFixed(0)}',
                                  style: AppTextStyles.labelLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Divider(color: borderColor),
                            const SizedBox(height: 10),
                            Text('Description',
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: titleColor)),
                            const SizedBox(height: 6),
                            Text(item.description,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: subColor, height: 1.6)),
                          ],
                          const SizedBox(height: 18),
                          Divider(color: borderColor),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Reviews',
                                  style: AppTextStyles.labelLarge.copyWith(
                                      color: titleColor,
                                      fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: () =>
                                    _showWriteReviewDialog(context, item),
                                icon: const Icon(Icons.rate_review_outlined,
                                    size: 16, color: AppColors.primary),
                                label: Text('Write a Review',
                                    style: AppTextStyles.labelSmall
                                        .copyWith(color: AppColors.primary)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('reviews')
                                .where('designId', isEqualTo: item.id)
                                .orderBy('createdAt', descending: true)
                                .limit(10)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurface2
                                        : AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.rate_review_outlined,
                                          size: 28,
                                          color: isDark
                                              ? AppColors.darkTextHint
                                              : AppColors.lightTextHint),
                                      const SizedBox(height: 6),
                                      Text(
                                        'No reviews yet — be the first!',
                                        style: AppTextStyles.bodySmall.copyWith(
                                            color: isDark
                                                ? AppColors.darkTextHint
                                                : AppColors.lightTextHint),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return Column(
                                children: snapshot.data!.docs.map((doc) {
                                  return _DesignReviewTile(
                                      data: doc.data() as Map<String, dynamic>,
                                      isDark: isDark);
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Get.back();
                        _goToBooking();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Book Now',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

// ═══════════════════════════════════════════════════════════════════════════
// REVIEW TILE
// ═══════════════════════════════════════════════════════════════════════════
class _ReviewTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _ReviewTile({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final metaColor = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final softBg = isDark ? AppColors.darkSurface2 : AppColors.primarySoft;

    final String customerName = data['customerName'] as String? ?? 'Customer';
    final String comment = data['comment'] as String? ?? '';
    final int rating = (data['rating'] as num?)?.toInt() ?? 0;
    final bool isVerified = data['isVerifiedOrder'] as bool? ?? false;
    final String? adminReply = data['adminReply'] as String?;

    String timeAgo = '';
    final createdAtRaw = data['createdAt'];
    if (createdAtRaw != null) {
      DateTime? dt;
      if (createdAtRaw is Timestamp) {
        dt = createdAtRaw.toDate();
      } else if (createdAtRaw is String) {
        dt = DateTime.tryParse(createdAtRaw);
      }
      if (dt != null) timeAgo = _formatTimeAgo(dt);
    }

    final List<String> imageUrls = [];
    if (data['imageUrls'] is List) {
      for (final img in data['imageUrls'] as List) {
        if (img is String && img.isNotEmpty) imageUrls.add(img);
      }
    }

    final Map<String, dynamic>? subRatings =
        data['subRatings'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(customerName,
                            style: AppTextStyles.labelMedium
                                .copyWith(color: titleColor)),
                        if (isVerified) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified_rounded,
                              size: 13, color: AppColors.primary),
                        ],
                      ],
                    ),
                    if (timeAgo.isNotEmpty)
                      Text(timeAgo,
                          style:
                              AppTextStyles.caption.copyWith(color: metaColor)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(Icons.star_rounded,
                      size: 14,
                      color: i < rating
                          ? AppColors.warning
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder)),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(comment,
                style: AppTextStyles.bodySmall.copyWith(color: subColor)),
          ],
          if (subRatings != null && subRatings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: subRatings.entries.map((e) {
                final val = (e.value as num?)?.toInt() ?? 0;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: softBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.key,
                          style:
                              AppTextStyles.caption.copyWith(color: subColor)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded,
                          size: 11, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text('$val',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          if (imageUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[i],
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.primarySoft),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.primarySoft,
                      child: const Icon(Icons.image_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (adminReply != null && adminReply.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.reply_rounded,
                      size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Reply',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text(adminReply,
                            style: AppTextStyles.caption
                                .copyWith(color: subColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DESIGN REVIEW TILE
// ═══════════════════════════════════════════════════════════════════════════
class _DesignReviewTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _DesignReviewTile({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final metaColor = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final cardBg = isDark ? AppColors.darkSurface2 : Colors.white;

    final String customerName = data['customerName'] as String? ?? 'Customer';
    final String comment = data['comment'] as String? ?? '';
    final int rating = (data['rating'] as num?)?.toInt() ?? 0;

    String timeAgo = '';
    final createdAtRaw = data['createdAt'];
    if (createdAtRaw is Timestamp) {
      timeAgo = _formatTimeAgo(createdAtRaw.toDate());
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customerName,
                        style: AppTextStyles.labelMedium
                            .copyWith(color: titleColor)),
                    if (timeAgo.isNotEmpty)
                      Text(timeAgo,
                          style:
                              AppTextStyles.caption.copyWith(color: metaColor)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(Icons.star_rounded,
                      size: 13,
                      color: i < rating
                          ? AppColors.warning
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder)),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment,
                style: AppTextStyles.bodySmall.copyWith(color: subColor)),
          ],
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════
class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _HeaderStat(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(value,
                  style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 32, color: Colors.white.withValues(alpha: 0.3));
  }
}

class _SpecChip extends StatelessWidget {
  final String label;

  const _SpecChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Text(label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
    );
  }
}