import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smartstitch/artist/dashboard/artist_dashboard.dart';
import 'package:smartstitch/artist/design/artist_services_screen.dart';
import 'package:smartstitch/artist/design/service_publish_success_screen.dart';
import 'package:smartstitch/artist/earning/earnings_screen.dart';
import 'package:smartstitch/artist/order/artist_orders_screen.dart';
import 'package:smartstitch/artist/order/order_controller.dart';
import 'package:smartstitch/artist/design/design_screen.dart';
import 'package:smartstitch/artist/portfolio/artist_portfolio_screen.dart';
import 'package:smartstitch/artist/profile/artist_profile_screen.dart';
import 'package:smartstitch/artist/wallet/artist_wallet_screen.dart';
import 'package:smartstitch/artist/wallet/artist_wallet_controller.dart';
import 'package:smartstitch/artist/review/artist_review_screen.dart';
import 'package:smartstitch/artist/complaint/artist_complaint_screen.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/controllers/chat_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/routes/routes.dart';

class ArtistMainScreen extends StatefulWidget {
  // 🆕 Lets callers land directly on a specific tab (e.g. Portfolio = 1)
  // instead of always opening on the Dashboard tab.
  final int initialIndex;

  const ArtistMainScreen({super.key, this.initialIndex = 0});

  @override
  State<ArtistMainScreen> createState() => _ArtistMainScreenState();
}

class _ArtistMainScreenState extends State<ArtistMainScreen> {
  late int _currentIndex = widget.initialIndex;

  static const _navItems = [
    _NavItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    _NavItem(
      icon: Icons.collections_rounded,
      label: 'Portfolio',
    ),
    _NavItem(
      icon: Icons.add_box_rounded,
      label: 'Create',
    ),
    _NavItem(
      icon: Icons.savings_rounded,
      label: 'Wallet',
    ),
    _NavItem(
      icon: Icons.receipt_long_rounded,
      label: 'Orders',
    ),
    // 🆕 Reviews left by customers.
    _NavItem(
      icon: Icons.star_rounded,
      label: 'Reviews',
    ),
    // 🆕 Complaints raised against/about the artist.
    _NavItem(
      icon: Icons.report_problem_rounded,
      label: 'Complaints',
    ),
    _NavItem(
      icon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  final List<Widget> _pages = const [
    ArtistDashboard(),
    ArtistPortfolioScreen(),
    CreateServiceScreen(),
    ArtistWalletScreen(),
    ArtistOrdersScreen(),
    ArtistReviewScreen(),      // 🆕
    ArtistComplaintScreen(),   // 🆕
    ArtistProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Get.put<ArtistOrderController>(ArtistOrderController());
    final walletCtrl = Get.find<ArtistWalletController>();
    final auth = Get.find<AuthController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = auth.currentUser.value;
      if (user != null) {
        walletCtrl.setArtistInfo(
          id: user.id,
          name: user.name,
          email: user.email,
        );
      }
    });

    ever(auth.currentUser, (u) {
      if (u != null && walletCtrl.artistId.isEmpty) {
        walletCtrl.setArtistInfo(
          id: u.id,
          name: u.name,
          email: u.email,
        );
      }
    });
  }

  Future<void> _logout() async {
    try {
      await Get.find<AuthController>().logout();
    } catch (_) {
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _buildAppBar(context, isDark),
      drawer: _buildDrawer(context, isDark),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    final auth = Get.find<AuthController>();
    final chatController = Get.find<ChatController>();

    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final iconBg = isDark ? AppColors.darkSurface2 : AppColors.primarySoft;
    final iconColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border(
            bottom: BorderSide(color: border, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                Builder(
                  builder: (ctx) => _TopBarIcon(
                    icon: Icons.menu_rounded,
                    iconBg: iconBg,
                    iconColor: iconColor,
                    onTap: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                const SizedBox(width: 12),
                // Expanded so long labels ("Complaints") never push the
                // trailing action icons off-screen on narrow devices.
                Expanded(
                  child: Text(
                    _navItems[_currentIndex].label,
                    style: AppTextStyles.h5.copyWith(
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Obx(() {
                  final unread = chatController.totalUnread.value;
                  return _TopBarIcon(
                    icon: Icons.chat_bubble_outline_rounded,
                    iconBg: iconBg,
                    iconColor: iconColor,
                    badge: unread > 0 ? '$unread' : null,
                    onTap: () => Get.toNamed(AppRoutes.chatList),
                  );
                }),
                const SizedBox(width: 8),
                _TopBarIcon(
                  icon: Icons.auto_awesome_rounded,
                  iconBg: iconBg,
                  iconColor: iconColor,
                  onTap: () => Get.toNamed(AppRoutes.aiChat),
                ),
                const SizedBox(width: 8),
                _TopBarIcon(
                  icon: Icons.notifications_outlined,
                  iconBg: iconBg,
                  iconColor: iconColor,
                  onTap: () => Get.toNamed(AppRoutes.notifications),
                ),
                const SizedBox(width: 8),
                _TopBarIcon(
                  icon: Icons.logout_rounded,
                  iconBg: iconBg,
                  iconColor: iconColor,
                  onTap: () => auth.logout(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    final auth = Get.find<AuthController>();

    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final drawerGradient = isDark
        ? AppColors.darkGradient
        : AppColors.primaryGradient;

    return Drawer(
      backgroundColor: surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: drawerGradient,
              ),
              child: Row(
                children: [
                  Obx(() {
                    final imageUrl = auth.currentUser.value?.profileImageUrl;
                    return Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withValues(alpha: 0.2),
                        image: imageUrl != null && imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imageUrl == null || imageUrl.isEmpty
                          ? const Icon(Icons.person_rounded,
                              color: Colors.white, size: 26)
                          : null,
                    );
                  }),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() {
                      final user = auth.currentUser.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Artist',
                            style:
                                AppTextStyles.h5.copyWith(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user?.email ?? '',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Scrollable so adding more nav items (like Reviews and
            // Complaints) never overflows the drawer vertically on
            // shorter phone screens — it just scrolls instead.
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: _navItems.length,
                itemBuilder: (_, i) => _DrawerTile(
                  item: _navItems[i],
                  isSelected: _currentIndex == i,
                  isDark: isDark,
                  onTap: () {
                    setState(() => _currentIndex = i);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            Divider(color: divider, height: 1),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 22,
              ),
              title: Text(
                'Logout',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: _logout,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Drawer Tile ──────────────────────────────────────────
class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unselectedColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final selectedGradient =
        isDark ? AppColors.darkGradient : AppColors.primaryGradient;
    final hoverColor =
        isDark ? AppColors.darkSurface2 : AppColors.primarySoft;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: isSelected ? selectedGradient : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          item.icon,
          color: isSelected ? Colors.white : unselectedColor,
          size: 22,
        ),
        title: Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Colors.white : unselectedColor,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        tileColor: Colors.transparent,
        hoverColor: hoverColor,
        onTap: onTap,
      ),
    );
  }
}

// ─── Nav Item Model ───────────────────────────────────────
class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

// ─── Top Bar Icon ─────────────────────────────────────────
class _TopBarIcon extends StatelessWidget {
  const _TopBarIcon({
    required this.icon,
    required this.onTap,
    required this.iconBg,
    required this.iconColor,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconBg;
  final Color iconColor;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Badge(
            label: Text(badge ?? ''),
            backgroundColor: AppColors.error,
            textColor: Colors.white,
            isLabelVisible: badge != null,
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }
}