import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/models/artist_model.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/user/wishlist/wishlist_controller.dart';

// ─── Explore Screen ────────────────────────────────────────────────────────
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Top Rated', 'Near Me', 'Popular', 'New'];

  List<ArtistModel> _artists = [];
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _artistsSub;

  // ── Hero slider ──────────────────────────────────────────────────────
  final PageController _heroController = PageController();
  Timer? _heroTimer;
  int _heroIndex = 0;

  final List<Map<String, String>> _heroSlides = const [
    {
      'tag': 'Handcrafted Elegance',
      'title': 'Find Your Perfect\nStitching Expert',
      'subtitle': 'Top artists. Trusted quality.\nStyles for every occasion.',
      'image':
          'https://www.nameerabyfarooq.com/cdn/shop/products/pakistani_designer_party_dress1_1080x.jpg?v=1564412883',
    },
    {
      'tag': 'Custom Made',
      'title': 'Bespoke Tailoring\nJust For You',
      'subtitle': 'From casual wear to couture,\ncrafted to your measurements.',
      'image':
          'https://deshibesh.com/cdn/shop/files/mariab-embroidered-pakistani-luxury-lehenga-suit-691315_1080x.jpg?v=1741429671',
    },
    {
      'tag': 'Skilled Hands',
      'title': 'Meet Our Master\nCraftsmen',
      'subtitle': 'Years of experience stitched\ninto every seam.',
      'image':
          'https://pakistanidesignerdresses.com/cdn/shop/files/0002087-kesarmahal.jpg?v=1738668403&width=800',
    },
    {
      'tag': 'Rich Fabrics',
      'title': 'Premium Threads\n& Textures',
      'subtitle': 'Quality materials for a\nflawless finish.',
      'image':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS-OKVyyq_uxyWq_rHkZAmQCmB_OE3XygSP1KN4ea0UHWdIDw-HC1o_l1Q&s=10',
    },
  ];

  // ── Auth-guard helper ──────────────────────────────────────────────────
  void _requireLogin(VoidCallback action) {
    final theme = Theme.of(context);
    if (!AuthController.to.isLoggedIn.value) {
      Get.snackbar(
        'Login Required',
        'You need to log in first to use this feature',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: theme.colorScheme.error.withValues(alpha: 0.92),
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

  @override
  void initState() {
    super.initState();
    _listenArtists();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_heroController.hasClients) return;
      final next = (_heroIndex + 1) % _heroSlides.length;
      _heroController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _artistsSub?.cancel();
    _heroTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  // ─── Firebase se artists fetch ─────────────────────────────────────────
  void _listenArtists() {
    setState(() => _isLoading = true);
    _artistsSub?.cancel();
    _artistsSub = FirebaseFirestore.instance
        .collection('artists')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .listen((snapshot) async {
      debugPrint(
          '[Explore] artists snapshot: ${snapshot.docs.length} doc(s) from Firestore');
      try {
        final results = await Future.wait(snapshot.docs.map((doc) async {
          try {
            final data = {...doc.data(), 'id': doc.id};
            if ((data['profileImageUrl'] as String? ?? '').isEmpty) {
              try {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(doc.id)
                    .get();
                final url =
                    userDoc.data()?['profileImageUrl'] as String? ?? '';
                if (url.isNotEmpty) data['profileImageUrl'] = url;
              } catch (_) {}
            }
            return ArtistModel.fromJson(data);
          } catch (e) {
            debugPrint('Skipping malformed artist doc ${doc.id}: $e');
            return null;
          }
        }));

        final artists = results.whereType<ArtistModel>().toList();

        if (mounted) {
          setState(() {
            _artists = artists;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Artists load error: $e');
        if (mounted) setState(() => _isLoading = false);
      }
    }, onError: (e) {
      debugPrint('Artists stream error: $e');
      if (mounted) setState(() => _isLoading = false);
    });
  }

  // ─── Filter logic ──────────────────────────────────────────────────────
  List<ArtistModel> get _filteredArtists {
    final query = _searchController.text.toLowerCase();
    return _artists.where((a) {
      final matchesSearch = query.isEmpty ||
          a.businessName.toLowerCase().contains(query) ||
          a.specializations.any((s) => s.toLowerCase().contains(query));

      if (!matchesSearch) return false;

      switch (_selectedFilter) {
        case 'Top Rated':
          return a.rating >= 4.5;
        case 'Near Me':
          return true;
        case 'Popular':
          return a.totalOrders >= 10;
        case 'New':
          return a.totalReviews == 0;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          _buildSearchBar(theme),
          _buildHeroSlider(theme),
          _buildFilterChips(theme),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back,
            color: theme.colorScheme.onSurface, size: 22),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'Explore',
        style: AppTextStyles.h4.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: AppTextStyles.bodySmall.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search artists, styles, outfits...',
          hintStyle: AppTextStyles.bodySmall.copyWith(
            color: theme.inputDecorationTheme.hintStyle?.color,
          ),
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant, size: 18),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Icon(Icons.tune_rounded, color: theme.colorScheme.onSurfaceVariant, size: 16),
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: theme.colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: theme.colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ─── Hero image slider ─────────────────────────────────────────────────
  Widget _buildHeroSlider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
      child: SizedBox(
        height: 210,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: PageView.builder(
                controller: _heroController,
                itemCount: _heroSlides.length,
                onPageChanged: (i) => setState(() => _heroIndex = i),
                itemBuilder: (context, index) {
                  final slide = _heroSlides[index];
                  return _HeroSlide(
                    tag: slide['tag']!,
                    title: slide['title']!,
                    subtitle: slide['subtitle']!,
                    image: slide['image']!,
                    onExplore: () => setState(() {
                      _selectedFilter = 'All';
                      _searchController.clear();
                    }),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 14,
              left: 20,
              child: Row(
                children: List.generate(_heroSlides.length, (i) {
                  final active = i == _heroIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 6),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    IconData iconFor(String filter) {
      switch (filter) {
        case 'Top Rated':
          return Icons.star_rounded;
        case 'Near Me':
          return Icons.location_on_rounded;
        case 'Popular':
          return Icons.local_fire_department_rounded;
        case 'New':
          return Icons.auto_awesome_rounded;
        default:
          return Icons.grid_view_rounded;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final isSelected = _selectedFilter == filter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.outline,
                    width: isSelected ? 0 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      iconFor(filter),
                      size: 14,
                      color: isSelected 
                          ? Colors.white 
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      filter,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSelected 
                            ? Colors.white 
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final artists = _filteredArtists;

    if (artists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 52,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Koi artist nahi mila',
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _listenArtists(),
      color: theme.colorScheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: artists.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == artists.length) {
            return _buildBottomBanner(theme);
          }
          return _ArtistCard(
            artist: artists[index],
            requireLogin: _requireLogin,
            onTap: () =>
                Get.toNamed(AppRoutes.artistDetail, arguments: artists[index]),
          );
        },
      ),
    );
  }

  // ─── Bottom trust banner ────────────────────────────────────────────────
  Widget _buildBottomBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Quality. Trusted Artists.',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Find the best fashion & stitching\nexperts near you',
                  style: AppTextStyles.caption.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() {
              _selectedFilter = 'All';
              _searchController.clear();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 14, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Slide ─────────────────────────────────────────────────────────────
class _HeroSlide extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;
  final String image;
  final VoidCallback onExplore;

  const _HeroSlide({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          image,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: theme.colorScheme.primary,
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: theme.colorScheme.primaryContainer,
            );
          },
        ),
        // Gradient overlay using theme primary
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.94),
                theme.colorScheme.primary.withValues(alpha: 0.65),
                Colors.black.withValues(alpha: 0.10),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 96, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.h4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onExplore,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore Now',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 13, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Artist Card ───────────────────────────────────────────────────────────
/// Reads a value from a possibly-throwing getter safely
T _safeRead<T>(T Function() getter, T fallback) {
  try {
    final value = getter();
    return value ?? fallback;
  } catch (_) {
    return fallback;
  }
}

class _ArtistCard extends StatelessWidget {
  final ArtistModel artist;
  final VoidCallback onTap;
  final void Function(VoidCallback) requireLogin;

  const _ArtistCard({
    required this.artist,
    required this.onTap,
    required this.requireLogin,
  });

  @override
  Widget build(BuildContext context) {
    final businessName = _safeRead(() => artist.businessName, 'Artist');
    final rating = _safeRead(() => artist.rating, 0.0);
    final totalReviews = _safeRead(() => artist.totalReviews, 0);
    final totalOrders = _safeRead(() => artist.totalOrders, 0);
    final specializations =
        _safeRead(() => artist.specializations, const <String>[]);
    final city = _safeRead(() => artist.shopAddress?.city, null) ?? 'Pakistan';
    final portfolioImages =
        _safeRead(() => artist.portfolioImages, const <String>[]);
    final profileImageUrl = _safeRead(() => artist.profileImageUrl, '');
    final artistId = _safeRead(() => artist.id, '');

    final theme = Theme.of(context);
    final hasImage = portfolioImages.isNotEmpty;
    final isNew = rating <= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outline, width: 1),
          boxShadow: theme.brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Image with overlays ─────────────────────────────────
              SizedBox(
                width: 118,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                      child: hasImage
                          ? Image.network(
                              portfolioImages.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarFallback(profileImageUrl, businessName, theme),
                            )
                          : _avatarFallback(profileImageUrl, businessName, theme),
                    ),

                    // Rating / New badge — top-left
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isNew
                                  ? Icons.auto_awesome_rounded
                                  : Icons.star_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isNew ? 'New' : rating.toStringAsFixed(1),
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Wishlist heart — top-right
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Builder(builder: (context) {
                        WishlistController? wishCtrl;
                        try {
                          wishCtrl = WishlistController.to;
                        } catch (_) {
                          wishCtrl = null;
                        }
                        if (wishCtrl == null || artistId.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.favorite_border_rounded,
                                size: 14, color: theme.colorScheme.primary),
                          );
                        }
                        final ctrl = wishCtrl;
                        return Obx(() {
                          final isFav = _safeRead(
                              () => ctrl.isArtistFavorite(artistId), false);
                          return GestureDetector(
                            onTap: () => requireLogin(() => ctrl.toggleArtist(
                                artistId,
                                artistName: businessName)),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 14,
                                color:
                                    isFav ? theme.colorScheme.error : theme.colorScheme.primary,
                              ),
                            ),
                          );
                        });
                      }),
                    ),

                    // Orders badge — bottom, fading gradient
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(18)),
                        ),
                        alignment: Alignment.centerRight,
                        child: Text(
                          '$totalOrders orders',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Info ──────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              businessName,
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (totalReviews > 0)
                            Text(
                              '($totalReviews)',
                              style: AppTextStyles.caption
                                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      Text(
                        specializations.isNotEmpty
                            ? specializations.join(', ')
                            : 'Fashion Designer',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 12, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              city,
                              style: AppTextStyles.caption
                                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Starting at',
                              style: AppTextStyles.caption.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              'PKR 1,500',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
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

  Widget _avatarFallback(String profileImageUrl, String businessName, ThemeData theme) {
    return profileImageUrl.isNotEmpty
        ? Image.network(
            profileImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _letterFallback(businessName, theme),
          )
        : _letterFallback(businessName, theme);
  }

  Widget _letterFallback(String businessName, ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Text(
          businessName.isNotEmpty ? businessName[0].toUpperCase() : '?',
          style: AppTextStyles.h2.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}