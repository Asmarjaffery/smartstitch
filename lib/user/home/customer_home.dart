import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/user/home/home_controller.dart';
import 'package:smartstitch/user/notification/notification_user_controller.dart';
import 'package:smartstitch/user/review/review_screen.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../core/theme/app.theme.dart';
import '../../models/artist_model.dart';
import '../../routes/routes.dart';
import '../../services/voice_service.dart';
import '../wishlist/wishlist_controller.dart';
import '../../core/widgets/app_logo.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ROOT SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const _HomeTab();
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN TAB
// ═══════════════════════════════════════════════════════════════════════════

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  void _requireLogin(VoidCallback action, ThemeData theme) {
    if (!AuthController.to.isLoggedIn.value) {
      Get.snackbar(
        'Login Required',
        'Yeh feature use karne ke liye pehle login karein',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: theme.colorScheme.error.withValues(alpha: 0.92),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 20),
      );
      Future.delayed(
          const Duration(milliseconds: 300), () => Get.toNamed(AppRoutes.login));
      return;
    }
    action();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.to;
    final homeCtrl = Get.find<HomeController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top Bar (logo + greeting + icons) ─────────────────
            SliverToBoxAdapter(child: _TopBar(auth: auth)),

            // ── Voice Search Bar ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: _VoiceSearchBar(),
              ),
            ),

            // ── Hero Slider ────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 22, 16, 0),
                child: _HeroSlider(),
              ),
            ),

            // ── Trust Badges ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: _TrustBadgesRow(),
              ),
            ),

            // ── Categories ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                child: _SectionHeader(
                  title: 'Categories',
                  onViewAll: () => Get.toNamed(AppRoutes.designExplore),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: Obx(() {
                  final ctrl = HomeController.to;
                  if (ctrl.isCategoriesLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (ctrl.categories.isEmpty) {
                    return const Center(child: Text('No categories found'));
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    itemCount: ctrl.categories.length,
                    itemBuilder: (context, i) {
                      final cat = ctrl.categories[i];
                      return _CategoryCard(
                        label: cat['name'] ?? '',
                        category: cat['categoryName'] ?? '',
                        imageUrl: cat['imageUrl'] as String?,
                      );
                    },
                  );
                }),
              ),
            ),

            // ── Top Rated Artists ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                child: _SectionHeader(
                  title: 'Top Rated Artists',
                  onViewAll: () => Get.toNamed(AppRoutes.artistList),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 254,
                child: Obx(() => homeCtrl.isLoadingArtists.value
                    ? const Center(child: CircularProgressIndicator())
                    : homeCtrl.topArtists.isEmpty
                        ? Center(
                            child: Text('No artists found',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                            itemCount: homeCtrl.topArtists.length,
                            itemBuilder: (_, i) => _ArtistCard(
                              artist: homeCtrl.topArtists[i],
                              requireLogin: _requireLogin,
                              isTopPick: i == 0,
                            ),
                          )),
              ),
            ),

            // ── Recent Orders (logged-in only) ─────────────────────
            Obx(() {
              if (!auth.isLoggedIn.value) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        title: 'Recent Orders',
                        trailingBadge: '3 Active',
                        onViewAll: () => Get.toNamed(AppRoutes.customerOrders),
                      ),
                      const SizedBox(height: 16),
                      const _OrderStatusSummary(),
                    ],
                  ),
                ),
              );
            }),
            Obx(() {
              if (!auth.isLoggedIn.value) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _OrderTile(index: i),
                    childCount: 3,
                  ),
                ),
              );
            }),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TOP BAR  —  flat white, logo left, icons right, greeting below
// ═══════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final AuthController auth;
  const _TopBar({required this.auth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ── Logo ────────────────────────────────────────
              AppLogo(size: 36),
              const Spacer(),

              // ── Chat / Notification / Complaint icons
              //    (sab sirf logged-in user ko dikhenge — guest
              //    ko sirf Login button nazar aayega) ───────────
              Obx(() {
                if (!auth.isLoggedIn.value) {
                  return const SizedBox.shrink();
                }

                final chatCtrl = Get.find<ChatController>();
                final unread = chatCtrl.totalUnread.value;
                final notifCount =
                    Get.find<NotificationUserController>().unreadCount.value;

                return Row(
                  children: [
                    // ── Chat icon ─────────────────────────────
                    _NavIconBtn(
                      onTap: () => Get.toNamed(AppRoutes.chatList),
                      icon: Icons.chat_bubble_outline_rounded,
                      badge: unread,
                      tooltip: 'Messages',
                    ),
                    // ── Notification bell ────────────────────
                    _NavIconBtn(
                      onTap: () => Get.toNamed(AppRoutes.notifications),
                      icon: Icons.notifications_outlined,
                      badge: notifCount,
                      tooltip: 'Notifications',
                    ),
                    // ── Tickets / Complaints ──────────────────
                    _NavIconBtn(
                      onTap: () => Get.toNamed(AppRoutes.complaintsCenter),
                      icon: Icons.confirmation_number_outlined,
                      tooltip: 'Complaints',
                    ),
                  ],
                );
              }),

              // ── Avatar / Login ───────────────────────────────
              Obx(() {
                if (!auth.isLoggedIn.value) {
                  return IconButton(
                    icon: const Icon(Icons.login_rounded),
                    onPressed: () => Get.toNamed(AppRoutes.login),
                    tooltip: 'Login',
                  );
                }
                final user = auth.currentUser.value;
                return GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.customerProfile),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, left: 4),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary,
                      backgroundImage: user?.profileImageUrl != null
                          ? NetworkImage(user!.profileImageUrl!)
                          : null,
                      child: user?.profileImageUrl == null
                          ? Text(
                              (user?.name ?? 'G')[0].toUpperCase(),
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          // ── Greeting ──────────────────────────────────────────
          Obx(() {
            final user = auth.currentUser.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assalam o Alaikum 👋',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.name ?? 'Guest',
                  style: AppTextStyles.h3.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _NavIconBtn extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final int badge;
  final String? tooltip;

  const _NavIconBtn({
    required this.onTap,
    required this.icon,
    this.badge = 0,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Badge(
        isLabelVisible: badge > 0,
        label: Text(badge > 99 ? '99+' : '$badge',
            style: const TextStyle(fontSize: 10)),
        backgroundColor: Theme.of(context).colorScheme.error,
        textColor: Colors.white,
        child: Icon(icon, size: 24),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VOICE SEARCH BAR
// ═══════════════════════════════════════════════════════════════════════════

class _VoiceSearchBar extends StatelessWidget {
  final VoiceService _voice = VoiceService.instance;
  _VoiceSearchBar();

  void _startVoice(BuildContext ctx) async {
    await _voice.init();
    Get.dialog(_VoiceDialog(voiceService: _voice), barrierDismissible: true);
    await _voice.startListening(
      language: 'ur-PK',
      onResult: (text) {
        Get.back();
        if (text.isNotEmpty) {
          Get.toNamed(AppRoutes.artistList, arguments: {'search': text});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.toNamed(AppRoutes.artistList),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded,
                  color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search for dresses, designers...',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.tune_rounded,
                    color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Obx(() => GestureDetector(
                    onTap: _voice.isListening.value
                        ? () => _voice.cancel()
                        : () => _startVoice(context),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _voice.isListening.value
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _voice.isListening.value
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        color: _voice.isListening.value
                            ? Colors.white
                            : theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceDialog extends StatelessWidget {
  final VoiceService voiceService;
  const _VoiceDialog({required this.voiceService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: voiceService.isListening.value ? 80 : 70,
                  height: voiceService.isListening.value ? 80 : 70,
                  decoration: BoxDecoration(
                    color: voiceService.isListening.value
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: voiceService.isListening.value
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    color: voiceService.isListening.value
                        ? Colors.white
                        : theme.colorScheme.primary,
                    size: 36,
                  ),
                )),
            const SizedBox(height: 22),
            Text('Listening...',
                style: AppTextStyles.h4
                    .copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Obx(() => Text(
                  voiceService.recognizedText.value.isEmpty
                      ? 'Bolein — Urdu ya English mein'
                      : '"${voiceService.recognizedText.value}"',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: voiceService.recognizedText.value.isEmpty
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.primary,
                    fontStyle: voiceService.recognizedText.value.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  textAlign: TextAlign.center,
                )),
            const SizedBox(height: 26),
            TextButton.icon(
              onPressed: () {
                voiceService.cancel();
                Get.back();
              },
              icon: Icon(Icons.close, color: theme.colorScheme.error),
              label: Text('Cancel', style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HERO SLIDER  —  auto-scrolling, dark-teal overlay left / fashion image right
// ═══════════════════════════════════════════════════════════════════════════

class _HeroSlider extends StatefulWidget {
  const _HeroSlider();

  @override
  State<_HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<_HeroSlider> {
  final PageController _page = PageController();
  int _current = 0;
  Timer? _timer;

  static const _slides = [
    _SlideData(
      badge: 'New Collection',
      title: 'Premium\nFashion',
      subtitle: 'Discover trending styles &\nelegant stitching',
      cta: 'Explore Now',
      overlayColor: Color(0xFF0A5F62),
      accentColor: Color(0xFFF59E0B),
      imageUrl:
          'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&q=80',
    ),
    _SlideData(
      badge: 'Exclusive Offer',
      title: 'Bridal\nCollection',
      subtitle: 'Handcrafted lehengas &\nbespoke stitching',
      cta: 'Shop Now',
      overlayColor: Color(0xFF4A1040),
      accentColor: Color(0xFFE91E8C),
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR7q3paLgyVsXmx_xqEsNLlsjPPHALq02U7GdmQDChxIA&s=10',
    ),
    _SlideData(
      badge: 'Limited Time',
      title: 'Fabric\nShowcase',
      subtitle: 'Premium lawn, chiffon\n& silk fabrics',
      cta: 'View Fabrics',
      overlayColor: Color(0xFF1A3A5C),
      accentColor: Color(0xFF22C55E),
      imageUrl:
          'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=600&q=80',
    ),
    _SlideData(
      badge: 'Custom Order',
      title: 'Your Style\nYour Way',
      subtitle: 'Tailored perfectly to\nyour measurements',
      cta: 'Order Now',
      overlayColor: Color(0xFF2D1B69),
      accentColor: Color(0xFF5ED6D9),
      imageUrl:
          'https://cdn.shopify.com/s/files/1/0250/8557/5222/files/TENCEL-COTTON-SATIN-280-GSM-Stretch-Dust-Pink-Fabric-fabricsight-Meters-0089-Dusty-Pink-2_5b1d4d83-8a32-4773-b578-340a62b90099_480x480.jpg?v=1641894038',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_current + 1) % _slides.length;
      _page.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // ── Slides ─────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 228,
            child: PageView.builder(
              controller: _page,
              onPageChanged: (i) => setState(() => _current = i),
              itemCount: _slides.length,
              itemBuilder: (_, i) => _SlideCard(slide: _slides[i]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── Dots ───────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            final active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SlideData {
  final String badge;
  final String title;
  final String subtitle;
  final String cta;
  final Color overlayColor;
  final Color accentColor;
  final String imageUrl;

  const _SlideData({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.overlayColor,
    required this.accentColor,
    required this.imageUrl,
  });
}

class _SlideCard extends StatelessWidget {
  final _SlideData slide;
  const _SlideCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Photo (right 55%) ─────────────────────────────────
        Positioned.fill(
          child: Image.network(
            slide.imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    slide.overlayColor,
                    slide.overlayColor.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Left teal/dark overlay panel ─────────────────────
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.58,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  slide.overlayColor,
                  slide.overlayColor.withValues(alpha: 0.96),
                  slide.overlayColor.withValues(alpha: 0.82),
                  slide.overlayColor.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.55, 0.78, 1.0],
              ),
            ),
          ),
        ),

        // ── Text content ──────────────────────────────────────
        Positioned(
          left: 20,
          top: 20,
          bottom: 20,
          width: MediaQuery.of(context).size.width * 0.50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: slide.accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  slide.badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                slide.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 9),
              // Subtitle
              Text(
                slide.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              // CTA button
              InkWell(
                onTap: () => Get.toNamed(AppRoutes.artistList),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        slide.cta,
                        style: TextStyle(
                          color: slide.overlayColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(Icons.arrow_forward_rounded,
                          size: 14, color: slide.overlayColor),
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

// ═══════════════════════════════════════════════════════════════════════════
// TRUST BADGES ROW  —  4-up row matching reference image
// ═══════════════════════════════════════════════════════════════════════════

class _TrustBadgesRow extends StatelessWidget {
  const _TrustBadgesRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: const [
          Expanded(
            child: _TrustBadge(
              icon: Icons.local_shipping_outlined,
              title: 'Free Shipping',
              subtitle: 'On orders above\nPKR 5000',
            ),
          ),
          _TrustDivider(),
          Expanded(
            child: _TrustBadge(
              icon: Icons.replay_rounded,
              title: 'Easy Returns',
              subtitle: '7 days return\npolicy',
            ),
          ),
          _TrustDivider(),
          Expanded(
            child: _TrustBadge(
              icon: Icons.verified_user_outlined,
              title: 'Secure Payment',
              subtitle: '100% secure\ncheckout',
            ),
          ),
          _TrustDivider(),
          Expanded(
            child: _TrustBadge(
              icon: Icons.headset_mic_outlined,
              title: '24/7 Support',
              subtitle: "We're here to\nhelp you",
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TrustBadge(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(height: 9),
        Text(
          title,
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            fontSize: 10.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 9.5,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TrustDivider extends StatelessWidget {
  const _TrustDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: Theme.of(context).colorScheme.outline,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailingBadge;
  final VoidCallback? onViewAll;

  const _SectionHeader({
    required this.title,
    this.trailingBadge,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.h4.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (trailingBadge != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailingBadge!,
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CATEGORY CARD  —  square image card with label underneath (ref image style)
// ═══════════════════════════════════════════════════════════════════════════

class _CategoryCard extends StatelessWidget {
  final String label;
  final String category;
  final String? imageUrl;

  const _CategoryCard({
    required this.label,
    required this.category,
    this.imageUrl,
  });

  static const _fallbackGradients = [
    LinearGradient(colors: [Color(0xFFE91E8C), Color(0xFFFF6FB5)]),
    LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
    LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFFA040)]),
    LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)]),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final idx = label.hashCode.abs() % 4;

    return GestureDetector(
      onTap: () =>
          Get.toNamed(AppRoutes.artistList, arguments: {'category': category}),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Square image area ─────────────────────────────
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _GradientFallback(idx: idx),
                    )
                  : _GradientFallback(idx: idx),
            ),
            const SizedBox(height: 10),
            // ── Label ─────────────────────────────────────────
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              'Explore',
              style: AppTextStyles.caption
                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientFallback extends StatelessWidget {
  final int idx;
  const _GradientFallback({required this.idx});

  static const _gradients = [
    LinearGradient(colors: [Color(0xFFFCE4F3), Color(0xFFFAC3E8)]),
    LinearGradient(colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)]),
    LinearGradient(colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)]),
    LinearGradient(colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)]),
  ];

  static const _icons = [
    _IconData(Icons.checkroom_rounded, Color(0xFFE91E8C)),
    _IconData(Icons.person_outline_rounded, Color(0xFF1976D2)),
    _IconData(Icons.layers_outlined, Color(0xFFE65100)),
    _IconData(Icons.content_cut_rounded, Color(0xFF6A1B9A)),
  ];

  @override
  Widget build(BuildContext context) {
    final d = _icons[idx % _icons.length];
    return Container(
      decoration: BoxDecoration(gradient: _gradients[idx % _gradients.length]),
      child: Center(child: Icon(d.icon, color: d.color, size: 42)),
    );
  }
}

class _IconData {
  final IconData icon;
  final Color color;
  const _IconData(this.icon, this.color);
}

// ═══════════════════════════════════════════════════════════════════════════
// ARTIST CARD  —  matches reference image: photo top, info bottom, Top Pick badge
// ═══════════════════════════════════════════════════════════════════════════

class _ArtistCard extends StatelessWidget {
  final ArtistModel artist;
  final void Function(VoidCallback, ThemeData) requireLogin;
  final bool isTopPick;

  const _ArtistCard({
    required this.artist,
    required this.requireLogin,
    this.isTopPick = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 168,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.artistDetail, arguments: artist),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image area ──────────────────────────────────
              Stack(
                children: [
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: _artistImage(),
                  ),
                  // Top Pick badge (amber, top-left — matches reference)
                  if (isTopPick)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium_rounded,
                                color: Colors.white, size: 11),
                            SizedBox(width: 4),
                            Text(
                              'Top Pick',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Heart button
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Obx(() {
                      final wCtrl = WishlistController.to;
                      final isFav = wCtrl.isArtistFavorite(artist.id);
                      return GestureDetector(
                        onTap: () => requireLogin(
                            () => wCtrl.toggleArtist(artist.id,
                                artistName: artist.businessName),
                            theme),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFav
                                ? theme.colorScheme.error
                                : const Color(0xFFCCCCCC),
                            size: 14,
                          ),
                        ),
                      );
                    }),
                  ),
                  // Star rating (bottom-left, matches reference image)
                  Positioned(
                    bottom: 9,
                    left: 9,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFD700), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            artist.rating > 0
                                ? artist.rating.toStringAsFixed(1)
                                : '0.0',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Review button (bottom-right)
                  Positioned(
                    bottom: 9,
                    right: 9,
                    child: GestureDetector(
                      onTap: () => requireLogin(() async {
                        await FirebaseFirestore.instance
                            .collection('orders')
                            .where('artistId', isEqualTo: artist.id)
                            .where('customerId',
                                isEqualTo: AuthController.to.currentUserId)
                            .limit(1)
                            .get();
                        Get.to(() => const WriteReviewScreen());
                      }, theme),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.rate_review_rounded,
                            color: Colors.white, size: 13),
                      ),
                    ),
                  ),
                ],
              ),
              // ── Info area ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            artist.businessName,
                            style: AppTextStyles.labelLarge
                                .copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (artist.isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified_rounded,
                                color: AppColors.primary, size: 14),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artist.specializations.isNotEmpty
                          ? artist.specializations.first
                          : 'Tailor',
                      style: AppTextStyles.caption
                          .copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 12, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${artist.totalOrders} orders',
                          style: AppTextStyles.caption
                              .copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const Spacer(),
                        Icon(Icons.people_outline_rounded,
                            size: 12, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${artist.totalReviews}',
                          style: AppTextStyles.caption
                              .copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _artistImage() {
    if (artist.portfolioImages.isNotEmpty) {
      return Image.network(
        artist.portfolioImages.first,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _profileFallback(),
      );
    }
    return _profileFallback();
  }

  Widget _profileFallback() {
    if (artist.profileImageUrl.isNotEmpty) {
      return Image.network(
        artist.profileImageUrl,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradientFallback(),
      );
    }
    return _gradientFallback();
  }

  Widget _gradientFallback() {
    return Container(
      height: 140,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Center(
        child: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white.withValues(alpha: 0.25),
          child: Text(
            artist.businessName.isNotEmpty
                ? artist.businessName[0].toUpperCase()
                : 'A',
            style: AppTextStyles.h2
                .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ORDER STATUS SUMMARY  —  3 colored chips (In Progress / Completed / Pending)
// ═══════════════════════════════════════════════════════════════════════════

class _OrderStatusSummary extends StatelessWidget {
  const _OrderStatusSummary();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const items = [
      _StatusItem('In Progress', 1, AppColors.primary, Icons.content_cut_rounded),
      _StatusItem('Completed', 1, AppColors.success, Icons.check_circle_rounded),
      _StatusItem('Pending', 1, AppColors.warning, Icons.hourglass_empty_rounded),
    ];

    return Row(
      children: List.generate(items.length, (i) {
        final item = items[i];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == items.length - 1 ? 0 : 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: item.color.withValues(alpha: 0.22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, size: 17, color: item.color),
                const SizedBox(height: 10),
                Text(
                  '${item.count}',
                  style: AppTextStyles.h4
                      .copyWith(fontWeight: FontWeight.bold, color: item.color),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: AppTextStyles.caption
                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _StatusItem {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _StatusItem(this.label, this.count, this.color, this.icon);
}

// ═══════════════════════════════════════════════════════════════════════════
// ORDER PROGRESS STEPPER  —  Placed → Stitching → Ready → Delivered
// ═══════════════════════════════════════════════════════════════════════════

class _OrderProgressStepper extends StatelessWidget {
  final int activeStep;
  final Color color;
  const _OrderProgressStepper({required this.activeStep, required this.color});

  static const _stages = ['Placed', 'Stitching', 'Ready', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(_stages.length * 2 - 1, (i) {
            if (i.isEven) {
              final s = i ~/ 2;
              final reached = s <= activeStep;
              return Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: reached ? color : Colors.transparent,
                  border: Border.all(
                    color: reached ? color : theme.colorScheme.outline,
                    width: reached ? 0 : 1.5,
                  ),
                ),
              );
            }
            final filled = (i ~/ 2) < activeStep;
            return Expanded(
              child: Container(height: 2,
                  color: filled ? color : theme.colorScheme.outline),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(_stages.length, (s) {
            final active = s <= activeStep;
            return Expanded(
              child: Text(
                _stages[s],
                textAlign: s == 0
                    ? TextAlign.left
                    : (s == _stages.length - 1
                        ? TextAlign.right
                        : TextAlign.center),
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: active ? color : theme.colorScheme.onSurfaceVariant,
                  fontWeight:
                      s == activeStep ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ORDER TILE  —  matches reference image: left accent bar + icon + stepper
// ═══════════════════════════════════════════════════════════════════════════

class _OrderTile extends StatelessWidget {
  final int index;
  const _OrderTile({required this.index});

  static const _statuses = ['in_progress', 'completed', 'pending'];
  static const _titles = [
    'Bridal Lehenga',
    'Casual Shalwar Kameez',
    'Party Wear Gown',
  ];
  static const _artists = ['Zara Designs', 'Noor Stitches', 'Hina Couture'];
  static const _dates = ['2 days ago', '1 week ago', '3 days ago'];
  static const _ids = ['order_1', 'order_2', 'order_3'];
  static const _icons = [
    Icons.auto_awesome_rounded,
    Icons.checkroom_rounded,
    Icons.style_rounded,
  ];

  int get _activeStep {
    switch (_statuses[index]) {
      case 'pending':
        return 0;
      case 'in_progress':
        return 1;
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'in_progress':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.lightTextSecondary;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'in_progress':
        return Icons.content_cut_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_empty_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _statuses[index];
    final color = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.orderDetail,
              arguments: {'orderId': _ids[index]}),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar
                Container(width: 4, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon tile
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_icons[index], color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _titles[index],
                                    style: AppTextStyles.labelLarge
                                        .copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.store_mall_directory_outlined,
                                        size: 12, color: AppColors.lightTextHint),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _artists[index],
                                        style: AppTextStyles.bodySmall.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 3),
                                  Row(children: [
                                    Icon(Icons.schedule_rounded,
                                        size: 11, color: theme.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text(
                                      _dates[index],
                                      style: AppTextStyles.caption
                                          .copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_statusIcon(status),
                                      size: 11, color: color),
                                  const SizedBox(width: 4),
                                  Text(
                                    _statusLabel(status),
                                    style: AppTextStyles.labelSmall.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _OrderProgressStepper(
                            activeStep: _activeStep, color: color),
                      ],
                    ),
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