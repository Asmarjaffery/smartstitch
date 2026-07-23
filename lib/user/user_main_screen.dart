import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/user/artist/artist_screen.dart';
import 'package:smartstitch/user/complaint/complaint_screen.dart';
import 'package:smartstitch/user/home/customer_home.dart';
import 'package:smartstitch/user/order/orders_screen.dart';
import 'package:smartstitch/user/profile/profile_screen.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const CustomerHomeScreen(),
      const ExploreScreen(),
      const OrdersScreen(),
      const ComplaintCenterScreen(),
      const ProfileScreen(),
    ];
  }

  // ✅ Login restriction
  void _onTabTapped(int index) {
    final restrictedTabs = [2, 3, 4]; // Orders, Complaint, Profile

    if (restrictedTabs.contains(index)) {
      final user = AuthController.to.currentUser.value;
      if (user == null) {
        Get.toNamed(AppRoutes.login);
        return;
      }
    }
    setState(() => _currentIndex = index);
  }

  // ✅ Login restriction — AI Assistant
  void _onAiChatTapped() {
    final user = AuthController.to.currentUser.value;
    if (user == null) {
      Get.toNamed(AppRoutes.login);
      return;
    }
    Get.toNamed(AppRoutes.aiChat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // ℹ️ The Messages FAB has moved up next to the notification bell /
      // login-logout icons on the Home screen (login-only, see
      // customer_home.dart). Only the AI Assistant shortcut stays here now.
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'ai_fab',
        onPressed: _onAiChatTapped,
        backgroundColor: AppColors.primary,
        elevation: 4,
        tooltip: 'AI Assistant',
        child: const Icon(Icons.auto_awesome_rounded,
            color: Colors.white, size: 20),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped, 
        indicatorColor: AppColors.primarySoft,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem_rounded),
            label: 'Complaint',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}