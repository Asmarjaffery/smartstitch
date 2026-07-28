import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/admin/analytics/analytics_dashboard_screen.dart';

import 'package:smartstitch/admin/dashboard/admin_dashboard.dart';
import 'package:smartstitch/admin/notification/admin_notification_controller.dart';
import 'package:smartstitch/admin/payment/admin_payment_screen.dart';
import 'package:smartstitch/admin/report/reports.dart';
import 'package:smartstitch/admin/services/admin_services_screen.dart';
import 'package:smartstitch/admin/order/admin_order_screen.dart';
import 'package:smartstitch/admin/complaint/admin_complaint_screen.dart';
import 'package:smartstitch/admin/users/admin_user_screen.dart';
import 'package:smartstitch/admin/notification/admin_notification_screen.dart';
import 'package:smartstitch/admin/review/admin_review_screen.dart';
import 'package:smartstitch/admin/refunds/refund_requests_screen.dart';

import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/app_logo.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/admin/wallet/admin_withdrawal_screen.dart';
import 'package:smartstitch/services/performance_screen.dart';
import 'package:smartstitch/admin/compensation/failed_deliveries_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;
  bool _isDarkMode = false;

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.analytics_rounded, label: 'Analytics'),
    _NavItem(icon: Icons.design_services_rounded, label: 'Services'),
    _NavItem(icon: Icons.people_alt_rounded, label: 'Users'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Performance'),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Orders'),
    _NavItem(icon: Icons.report_problem_rounded, label: 'Complaints'),
    _NavItem(icon: Icons.star_rounded, label: 'Reviews'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Withdrawals'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Report'),
    _NavItem(icon: Icons.currency_exchange_rounded, label: 'Refunds'),
    _NavItem(
        icon: Icons.local_shipping_rounded, label: 'Failed Deliveries'),
  ];

  final List<Widget> _pages = const [
    AdminDashboardScreen(),
    AnalyticsDashboardScreen(),
    AdminCategoriesScreen(),
    AdminOrdersScreen(),
    PerformanceScreen(),
    AdminComplaintScreen(),
    AdminUsersScreen(),
    AdminReviewScreen(),
    AdminCombinedWithdrawalScreen(),
    ReportsScreen(),
    RefundRequestsScreen(),
    FailedDeliveriesScreen(),
  ];

  Future<void> _logout() async {
    try {
      await Get.find<AuthController>().logout();
    } catch (_) {}

    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
    );
  }

  // ─── AppBar (single gradient banner — menu, title, search, dark mode,
  //     notification, profile) ───────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(96),
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: Row(
              children: [
                Builder(
                  builder: (context) => _TopBarIcon(
                    icon: Icons.menu_rounded,
                    onTap: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SmartStitch',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white60),
                      ),
                      Text(
                        _navItems[_currentIndex].label,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h5.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                _TopBarIcon(
                  icon: Icons.auto_awesome_rounded,
                  onTap: () => Get.toNamed(AppRoutes.aiChat),
                ),
                const SizedBox(width: 8),
                _TopBarIcon(icon: Icons.search_rounded, onTap: () {}),
                const SizedBox(width: 8),
                _TopBarIcon(
                  icon: _isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_outlined,
                  onTap: () => setState(() => _isDarkMode = !_isDarkMode),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  final controller = Get.put(AdminNotificationController());
                  return _TopBarIcon(
                    icon: Icons.notifications_outlined,
                    badgeCount: controller.unreadCount.value,
                    onTap: () => Get.to(() => const AdminNotificationScreen()),
                  );
                }),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  child:
                      Icon(Icons.person_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Drawer ────────────────────────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.lightSurface, // white drawer
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient, // purple gradient header
              ),
              child: Row(
                children: [
                  AppLogo(
                    size: 42,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SmartStitch',
                        style: AppTextStyles.h5.copyWith(color: Colors.white),
                      ),
                      Text(
                        'Admin Panel',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Nav Items ────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: _navItems.length,
                itemBuilder: (_, i) => _DrawerTile(
                  item: _navItems[i],
                  isSelected: _currentIndex == i,
                  onTap: () {
                    setState(() => _currentIndex = i);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),

            // ── Logout ───────────────────────────────────────────────────
            const Divider(
              color: AppColors.lightDivider, // 0xFFEDE7FA — soft purple divider
              height: 1,
            ),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: AppColors.error, // 0xFFEF4444 — red
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

// ─── Drawer Tile ──────────────────────────────────────────────────────────────
class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: isSelected ? AppColors.primaryGradient : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          item.icon,
          color: isSelected ? Colors.white : AppColors.lightTextSecondary,
          size: 22,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.lightTextSecondary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        tileColor: Colors.transparent,
        hoverColor: AppColors.primarySoft,
        onTap: onTap,
      ),
    );
  }
}

// ─── Nav Item Model ───────────────────────────────────────────────────────────
class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

// ─── Top Bar Icon ─────────────────────────────────────────────────────────────
class _TopBarIcon extends StatelessWidget {
  const _TopBarIcon({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              if (badgeCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5C5C),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}