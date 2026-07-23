import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/riders/profile/profile_rider_controller.dart';
import 'package:smartstitch/riders/dashboard/rider_controller.dart';

class RiderProfileScreen extends StatelessWidget {
  const RiderProfileScreen({super.key});

  RiderProfileController get profile =>
      Get.isRegistered<RiderProfileController>()
          ? RiderProfileController.to
          : Get.put(RiderProfileController());

  AuthController get auth => AuthController.to;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ DEBUG: Check RiderController status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔍 RiderController registered: ${Get.isRegistered<RiderController>()}');
      if (Get.isRegistered<RiderController>()) {
        final riderCtrl = RiderController.to;
        debugPrint('💰 RiderController walletBalance: ${riderCtrl.walletBalance.value}');
        debugPrint('💵 RiderController totalEarnings: ${riderCtrl.totalEarnings.value}');
        debugPrint('📦 RiderController totalDeliveries: ${riderCtrl.totalDeliveries.value}');
      } else {
        debugPrint('❌ RiderController NOT registered!');
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Obx(() {
        if (profile.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final user = auth.currentUser.value;
        final img = user?.profileImageUrl ?? '';
        final name = user?.name ?? 'R';
        final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'R';

        // ✅ Try to access RiderController
        final riderCtrlExists = Get.isRegistered<RiderController>();
        final riderCtrl = riderCtrlExists ? RiderController.to : null;

        debugPrint('🎯 Profile screen rendering - RiderController exists: $riderCtrlExists');
        if (riderCtrl != null) {
          debugPrint('   walletBalance: ${riderCtrl.walletBalance.value}');
          debugPrint('   totalEarnings: ${riderCtrl.totalEarnings.value}');
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // ── Profile Header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primarySoft,
                          backgroundImage:
                              img.isNotEmpty ? NetworkImage(img) : null,
                          child: img.isEmpty
                              ? Text(
                                  firstLetter,
                                  style: AppTextStyles.h2.copyWith(
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Obx(
                            () => GestureDetector(
                              onTap: profile.isUploadingImage.value
                                  ? null
                                  : profile.uploadProfileImage,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: profile.isUploadingImage.value
                                    ? const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? '', style: AppTextStyles.h3),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.phone ?? '',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Online Status ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Obx(
                  () => GestureDetector(
                    onTap: profile.toggleOnlineStatus,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: profile.isOnline.value
                            ? Colors.green.withValues(alpha: 0.08)
                            : Colors.red.withValues(alpha: 0.08),
                        borderRadius: AppRadius.medium,
                        border: Border.all(
                          color: profile.isOnline.value
                              ? Colors.green
                              : Colors.red,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: profile.isOnline.value
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            profile.isOnline.value
                                ? 'Online — Ready for Delivery'
                                : 'Offline — Tap to go Online',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: profile.isOnline.value
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Stats ── 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Obx(
                  () {
                    // ✅ Debug print har bar render hote time
                    if (riderCtrl != null) {
                      debugPrint('📊 Stats rendering - wallet: ${riderCtrl.walletBalance.value}, earnings: ${riderCtrl.totalEarnings.value}');
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: AppRadius.medium,
                        border: Border.all(color: AppColors.lightBorder),
                        boxShadow: AppShadows.soft(AppColors.primary),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: Icons.local_shipping_rounded,
                            value: riderCtrl != null
                                ? '${riderCtrl.totalDeliveries.value}'
                                : '0',
                            label: 'Deliveries',
                            color: AppColors.primary,
                          ),
                          Container(
                              width: 1,
                              height: 40,
                              color: AppColors.lightBorder),
                          _StatItem(
                            icon: Icons.star_rounded,
                            value: riderCtrl != null
                                ? riderCtrl.rating.toStringAsFixed(1)
                                : '0.0',
                            label: 'Rating',
                            color: Colors.orange,
                          ),
                          Container(
                              width: 1,
                              height: 40,
                              color: AppColors.lightBorder),
                          _StatItem(
                            icon: Icons.account_balance_wallet_rounded,
                            value: riderCtrl != null
                                ? 'Rs ${riderCtrl.totalEarnings.value.toInt()}'
                                : 'Rs 0',
                            label: 'Earnings',
                            color: Colors.green,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ── Wallet ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Obx(
                  () {
                    if (riderCtrl != null) {
                      debugPrint('💳 Wallet rendering - balance: ${riderCtrl.walletBalance.value}');
                    }

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: AppRadius.medium,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: AppRadius.small,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Wallet',
                                  style: AppTextStyles.labelLarge
                                      .copyWith(color: Colors.white70),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Available Balance',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: Colors.white60),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  riderCtrl != null
                                      ? 'Rs ${riderCtrl.walletBalance.value.toInt()}'
                                      : 'Rs 0',
                                  style: AppTextStyles.h3
                                      .copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Get.toNamed('/withdraw'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.25),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.medium,
                              ),
                            ),
                            child: Text(
                              'Withdraw',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── My Account Section ──
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('My Account', style: AppTextStyles.h4),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppRadius.medium,
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Column(
                    children: [
                      _AccountMenuItem(
                        title: 'Personal Information',
                        icon: Icons.person_outline_rounded,
                        onTap: () => _showEditProfileSheet(context, profile),
                      ),
                      _AccountMenuItem(
                        title: 'Vehicle Information',
                        icon: Icons.two_wheeler_rounded,
                        onTap: () => _showEditVehicleSheet(context, profile),
                      ),
                      _AccountMenuItem(
                        title: 'Dark Mode',
                        icon: Icons.dark_mode_outlined,
                        onTap: () {},
                        showDivider: false,
                        trailing: Switch(
                          value: theme.brightness == Brightness.dark,
                          activeThumbColor: AppColors.primary,
                          onChanged: (value) => profile.toggleDarkMode(value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Logout ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: auth.logout,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    label: Text(
                      'Log Out',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  void _showEditProfileSheet(
    BuildContext context,
    RiderProfileController profile,
  ) {
    final auth = AuthController.to;
    final nameCtrl =
        TextEditingController(text: auth.currentUser.value?.name ?? '');
    final phoneCtrl =
        TextEditingController(text: auth.currentUser.value?.phone ?? '');

    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personal Information', style: AppTextStyles.h4),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border:
                      OutlineInputBorder(borderRadius: AppRadius.medium),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border:
                      OutlineInputBorder(borderRadius: AppRadius.medium),
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: profile.isSaving.value
                        ? null
                        : () async {
                            await profile.updatePersonalInfo(
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                            );
                            Get.back();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                    child: profile.isSaving.value
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : Text(
                            'Save Changes',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: Colors.white),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showEditVehicleSheet(
    BuildContext context,
    RiderProfileController profile,
  ) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vehicle Information', style: AppTextStyles.h4),
                const SizedBox(height: 20),
                TextField(
                  controller: profile.vehicleTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Type (e.g. Bike, Car)',
                    prefixIcon: Icon(Icons.two_wheeler_outlined),
                    border:
                        OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: profile.vehicleNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Number',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                    border:
                        OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: profile.cnicController,
                  decoration: const InputDecoration(
                    labelText: 'CNIC Number',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border:
                        OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: profile.isSaving.value
                          ? null
                          : profile.saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                      ),
                      child: profile.isSaving.value
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : Text(
                              'Save Changes',
                              style: AppTextStyles.labelLarge
                                  .copyWith(color: Colors.white),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

// ─── _StatItem ────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.h4.copyWith(color: color)),
        Text(
          label,
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.lightTextSecondary),
        ),
      ],
    );
  }
}

// ─── _AccountMenuItem ─────────────────────────────────────────────────────────
class _AccountMenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showDivider;

  const _AccountMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.trailing,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            leading: Icon(icon, color: AppColors.primary, size: 22),
            title: Text(title, style: AppTextStyles.bodyMedium),
            trailing: trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.lightTextSecondary,
                ),
            onTap: onTap,
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 56, endIndent: 16),
      ],
    );
  }
}