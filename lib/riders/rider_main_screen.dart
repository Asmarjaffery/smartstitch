import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/riders/dashboard/rider_controller.dart';
import 'package:smartstitch/riders/dashboard/rider_home_screen.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/riders/notification/notification_center_controller.dart';

import 'package:smartstitch/riders/order/rider_order_controller.dart';
import 'package:smartstitch/riders/order/rider_screen.dart';
import 'package:smartstitch/riders/profile/rider_profile_screen.dart';
import 'package:smartstitch/riders/wallet/rider_wallet_screen.dart';
import 'package:smartstitch/riders/wallet/wallet_controller.dart';
import '../../controllers/chat_controller.dart';
import 'package:smartstitch/routes/routes.dart';

class RiderMainScreen extends StatefulWidget {
  const RiderMainScreen({super.key});

  @override
  State<RiderMainScreen> createState() => _RiderMainScreenState();
}

class _RiderMainScreenState extends State<RiderMainScreen> {
  final controller = Get.find<RiderController>();
  final chatController = Get.find<ChatController>();

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final riderId = AuthController.to.currentUserId ?? '';
    print("🔍 RiderMainScreen initState — riderId: $riderId");
    controller.loadProfile(riderId);
    if (riderId.isNotEmpty) {
      // ✅ NEW: start listening for "Ask AI to Call Rider" requests from
      // customers the moment the rider's dashboard is up. Without this,
      // RiderOrderController never actually watches Firestore for the
      // callRequestedByCustomer flag, so the chat card would never appear.
      RiderOrderController.to.listenForCallRequests(riderId);

      final user = AuthController.to.currentUser.value;
      if (Get.isRegistered<WalletController>()) {
        final walletCtrl = Get.find<WalletController>();
        walletCtrl.setRiderInfo(
          id: riderId,
          name: user?.name ?? 'Rider',
          email: user?.email ?? '',
        );
        print('✅ WalletController initialized: $riderId');
      }
    }
  }

  final pages = [
    const RiderHomeScreen(),
    const RiderScreen(),
    const RiderWalletScreen(), 
    const RiderProfileScreen(),
  ];

  void _logout() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      controller.isOnline.value = false;
      if (Get.isRegistered<RiderController>()) {
        Get.delete<RiderController>(force: true);
      }
      await AuthController.to.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: _buildAppBar(),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightTextSecondary,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_rounded),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: "Wallet",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return PreferredSize(
    preferredSize: const Size.fromHeight(72),
    child: Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.delivery_dining_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                "Rider ${_getTitle()}",
                style: AppTextStyles.h5.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const Spacer(),

              _TopBarIcon(
                icon: Icons.auto_awesome_rounded,
                onTap: () => Get.toNamed(AppRoutes.aiChat),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              // ── Notification icon + badge ──
              Stack(
  clipBehavior: Clip.none,
  children: [
    _TopBarIcon(
      icon: Icons.notifications_none_rounded,
      onTap: () => Get.toNamed("/notifications"),
      isDark: isDark,
    ),
    Positioned(
      right: -2,
      top: -2,
      child: Obx(() {
        if (!Get.isRegistered<NotificationCenterController>()) {
          return const SizedBox.shrink();
        }
        final count = NotificationCenterController.to.unreadCount.value;
        if (count == 0) return const SizedBox.shrink();
        return Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count > 9 ? '9+' : '$count',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
          ),
        );
      }),
    ),
  ],
),   

              const SizedBox(width: 8),
              _TopBarIcon(
                icon: Icons.logout_rounded,
                onTap: _logout,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  String _getTitle() {
    switch (currentIndex) {
      case 0: return "Dashboard";
      case 1: return "Orders";
      case 2: return "Earnings";
      case 3: return "Profile";
      default: return "";
    }
  }
}

class _TopBarIcon extends StatelessWidget {
  const _TopBarIcon({
    required this.icon,
    required this.onTap,
    required this.isDark, 
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;  

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
            color: isDark ? AppColors.darkSurface2 : AppColors.primarySoft, 
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }
}