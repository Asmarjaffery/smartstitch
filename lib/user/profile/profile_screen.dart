import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/models/address_model.dart';
import 'package:smartstitch/models/body_measurement_model.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/user/profile/profile_controller.dart';
import 'package:uuid/uuid.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ProfileController());
    final auth = AuthController.to;
    final profile = ProfileController.to;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Profile', style: AppTextStyles.h4),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showAccountSettingsSheet(context),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Profile Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(() {
                final user = auth.currentUser.value;
                return Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: user?.profileImageUrl != null
                              ? NetworkImage(user!.profileImageUrl!)
                              : null,
                          child: user?.profileImageUrl == null
                              ? Text(
                                  (user?.name ?? 'U')[0].toUpperCase(),
                                  style: AppTextStyles.h2
                                      .copyWith(color: theme.colorScheme.primary),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Obx(() => GestureDetector(
                                onTap: profile.isUploadingImage.value
                                    ? null
                                    : profile.uploadProfileImage,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: profile.isUploadingImage.value
                                      ? const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.camera_alt_rounded,
                                          color: Colors.white, size: 16),
                                ),
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() => Text(
                                auth.currentUser.value?.name ?? '',
                                style: AppTextStyles.h3,
                              )),
                          const SizedBox(height: 2),
                          Obx(() => Text(
                                auth.currentUser.value?.email ?? '',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              )),
                          const SizedBox(height: 2),
                          Obx(() => Text(
                                auth.currentUser.value?.phone ?? '',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              )),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),

            const SizedBox(height: 20),

            // ─── Premium Member Banner ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: AppRadius.medium,
                ),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded,
                        color: theme.colorScheme.primary, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Premium Member',
                              style: AppTextStyles.labelLarge
                                  .copyWith(color: theme.colorScheme.primary)),
                          Text('Member since May 2024',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ─── My Orders Section (LIVE FIRESTORE FETCH) ────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Orders', style: AppTextStyles.h4),
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.customerOrders),
                    child: Text('View All',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: theme.colorScheme.primary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('customerId', isEqualTo: auth.currentUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  int pending = 0, processing = 0, shipped = 0, delivered = 0;

                  if (snapshot.hasData) {
                    for (final doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status =
                          (data['status'] as String? ?? '').toLowerCase();
                      switch (status) {
                        // ── Order abhi tak accept nahi hui ──
                        case 'pending':
                        case 'awaitingconfirmation':
                        case 'awaiting_confirmation':
                          pending++;
                          break;

                        // ── Artist ke pass kaam ho raha hai ──
                        case 'confirmed':
                        case 'accepted':
                        case 'inprogress':
                        case 'in_progress':
                        case 'processing':
                        case 'stitchingcompleted':
                        case 'stitching_completed':
                          processing++;
                          break;

                        // ── Order rider ke sath / raste mein hai ──
                        case 'riderassigned':
                        case 'rider_assigned':
                        case 'shipped':
                        case 'outfordelivery':
                        case 'out_for_delivery':
                        case 'ontheway':
                        case 'on_the_way':
                        case 'dispatched':
                          shipped++;
                          break;

                        // ── Order mukammal ho chuki hai ──
                        case 'delivered':
                        case 'completed':
                          delivered++;
                          break;
                      }
                    }
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: AppRadius.medium,
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: !snapshot.hasData
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _OrderStatusItem(
                                icon: Icons.receipt_outlined,
                                count: '$pending',
                                label: 'Pending',
                                color: Colors.orange,
                              ),
                              _OrderStatusItem(
                                icon: Icons.inventory_2_outlined,
                                count: '$processing',
                                label: 'Processing',
                                color: Colors.blue,
                              ),
                              _OrderStatusItem(
                                icon: Icons.local_shipping_outlined,
                                count: '$shipped',
                                label: 'Shipped',
                                color: Colors.purple,
                              ),
                              _OrderStatusItem(
                                icon: Icons.check_circle_outline_rounded,
                                count: '$delivered',
                                label: 'Delivered',
                                color: Colors.green,
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ─── My Account Section ──────────────────────────────────
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
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  children: [
                    _AccountMenuItem(
                      title: 'Personal Information',
                      icon: Icons.person_outline_rounded,
                      onTap: () => _showEditProfileSheet(context),
                      showDivider: true,
                    ),
                    _AccountMenuItem(
                      title: 'My Addresses',
                      icon: Icons.location_on_outlined,
                      onTap: () => _showAddressesSheet(context),
                      showDivider: true,
                    ),
                    _AccountMenuItem(
                      title: 'Body Measurements',
                      icon: Icons.straighten_rounded,
                      onTap: () => Get.toNamed(AppRoutes.measurementScreen),
                      showDivider: true,
                    ),
                    _AccountMenuItem(
                      title: 'My Wishlist',
                      icon: Icons.favorite_outline_rounded,
                      onTap: () => Get.toNamed(AppRoutes.wishlist),
                      showDivider: true,
                    ),
                    _AccountMenuItem(
                      title: 'Order Reviews',
                      icon: Icons.star_outline_rounded,
                      onTap: () => Get.toNamed(AppRoutes.myReviews),
                      showDivider: true,
                    ),
                    _AccountMenuItem(
                      title: 'Payment Methods',
                      icon: Icons.credit_card_outlined,
                      onTap: () {},
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── Settings Section (Language removed) ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: AppRadius.medium,
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Obx(() {
                  final isDark = auth.currentUser.value?.isDarkMode ?? false;
                  return _AccountMenuToggle(
                    title: 'Dark Mode',
                    icon: Icons.dark_mode_outlined,
                    value: isDark,
                    onChanged: (val) =>
                        ProfileController.to.toggleDarkMode(val),
                    showDivider: false,
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),

            // ─── Logout ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: auth.logout,
                  icon: Icon(Icons.logout_rounded,
                      color: theme.colorScheme.error, size: 20),
                  label: Text('Log Out',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: theme.colorScheme.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.error),
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.medium),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── Account Settings Sheet (Change Email / Password) ────────────────────
  void _showAccountSettingsSheet(BuildContext context) {
    final theme = Theme.of(context);
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Settings', style: AppTextStyles.h4),
            const SizedBox(height: 20),
            _AccountMenuItem(
              title: 'Change Email',
              icon: Icons.email_outlined,
              onTap: () {
                Get.back();
                _showChangeEmailSheet(context);
              },
              showDivider: true,
            ),
            _AccountMenuItem(
              title: 'Change Password',
              icon: Icons.lock_outline_rounded,
              onTap: () {
                Get.back();
                _showChangePasswordSheet(context);
              },
              showDivider: false,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ─── Change Email Sheet ────────────────────────────────────────────────────
  void _showChangeEmailSheet(BuildContext context) {
    final theme = Theme.of(context);
    final newEmailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final isLoading = false.obs;
    final obscurePassword = true.obs;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change Email', style: AppTextStyles.h4),
            const SizedBox(height: 6),
            Text(
              'Current: ${FirebaseAuth.instance.currentUser?.email ?? ''}',
              style: AppTextStyles.bodySmall
                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: newEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'New Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: AppRadius.medium),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => TextField(
                  controller: passwordCtrl,
                  obscureText: obscurePassword.value,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          obscurePassword.value = !obscurePassword.value,
                    ),
                    border:
                        const OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                )),
            const SizedBox(height: 8),
            Text(
              'We need your current password to confirm this change.',
              style: AppTextStyles.caption
                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading.value
                        ? null
                        : () async {
                            final newEmail = newEmailCtrl.text.trim();
                            final password = passwordCtrl.text.trim();

                            if (newEmail.isEmpty || !newEmail.contains('@')) {
                              Get.snackbar('Invalid Email',
                                  'Please enter a valid email address',
                                  backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1));
                              return;
                            }
                            if (password.isEmpty) {
                              Get.snackbar('Password Required',
                                  'Please enter your current password',
                                  backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1));
                              return;
                            }

                            isLoading.value = true;
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null || user.email == null) {
                                throw Exception('No signed-in user found');
                              }

                              final cred = EmailAuthProvider.credential(
                                email: user.email!,
                                password: password,
                              );
                              await user.reauthenticateWithCredential(cred);
                              await user.verifyBeforeUpdateEmail(newEmail);

                              Get.back();
                              Get.snackbar(
                                'Verification Sent',
                                'Check your new email inbox to confirm the change.',
                                backgroundColor: AppColors.success.withValues(alpha: 0.1),
                                duration: const Duration(seconds: 4),
                              );
                            } on FirebaseAuthException catch (e) {
                              Get.snackbar(
                                'Error',
                                e.message ?? 'Could not update email',
                                backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
                              );
                            } catch (e) {
                              Get.snackbar('Error', e.toString(),
                                  backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1));
                            } finally {
                              isLoading.value = false;
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium),
                    ),
                    child: isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Update Email',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: Colors.white)),
                  ),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ─── Change Password Sheet ─────────────────────────────────────────────────
  void _showChangePasswordSheet(BuildContext context) {
    final theme = Theme.of(context);
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    final isLoading = false.obs;
    final obscureCurrent = true.obs;
    final obscureNew = true.obs;
    final obscureConfirm = true.obs;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change Password', style: AppTextStyles.h4),
            const SizedBox(height: 20),
            Obx(() => TextField(
                  controller: currentPasswordCtrl,
                  obscureText: obscureCurrent.value,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          obscureCurrent.value = !obscureCurrent.value,
                    ),
                    border:
                        const OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                )),
            const SizedBox(height: 16),
            Obx(() => TextField(
                  controller: newPasswordCtrl,
                  obscureText: obscureNew.value,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => obscureNew.value = !obscureNew.value,
                    ),
                    border:
                        const OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                )),
            const SizedBox(height: 16),
            Obx(() => TextField(
                  controller: confirmPasswordCtrl,
                  obscureText: obscureConfirm.value,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          obscureConfirm.value = !obscureConfirm.value,
                    ),
                    border:
                        const OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                )),
            const SizedBox(height: 8),
            Text(
              'Password must be at least 6 characters.',
              style: AppTextStyles.caption
                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading.value
                        ? null
                        : () async {
                            final current = currentPasswordCtrl.text.trim();
                            final newPass = newPasswordCtrl.text.trim();
                            final confirm = confirmPasswordCtrl.text.trim();

                            if (current.isEmpty) {
                              Get.snackbar('Password Required',
                                  'Please enter your current password',
                                  backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1));
                              return;
                            }
                            if (newPass.length < 6) {
                              Get.snackbar('Weak Password',
                                  'New password must be at least 6 characters',
                                  backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1));
                              return;
                            }
                            if (newPass != confirm) {
                              Get.snackbar('Mismatch',
                                  'New password and confirmation do not match',
                                  backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1));
                              return;
                            }

                            isLoading.value = true;
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null || user.email == null) {
                                throw Exception('No signed-in user found');
                              }

                              final cred = EmailAuthProvider.credential(
                                email: user.email!,
                                password: current,
                              );
                              await user.reauthenticateWithCredential(cred);
                              await user.updatePassword(newPass);

                              Get.back();
                              Get.snackbar(
                                'Success',
                                'Your password has been updated.',
                                backgroundColor: AppColors.success.withValues(alpha: 0.1),
                              );
                            } on FirebaseAuthException catch (e) {
                              Get.snackbar(
                                'Error',
                                e.message ?? 'Could not update password',
                                backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
                              );
                            } catch (e) {
                              Get.snackbar('Error', e.toString(),
                                  backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1));
                            } finally {
                              isLoading.value = false;
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium),
                    ),
                    child: isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Update Password',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: Colors.white)),
                  ),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ─── Edit Profile Sheet ───────────────────────────────────────────────────
  void _showEditProfileSheet(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AuthController.to;
    final nameCtrl = TextEditingController(text: auth.currentUser.value?.name);
    final phoneCtrl =
        TextEditingController(text: auth.currentUser.value?.phone);

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Profile', style: AppTextStyles.h4),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(borderRadius: AppRadius.medium),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: AppRadius.medium),
              ),
            ),
            const SizedBox(height: 24),
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: ProfileController.to.isLoading.value
                        ? null
                        : () {
                            ProfileController.to.updateProfile(
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                            );
                            Get.back();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium),
                    ),
                    child: ProfileController.to.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Save Changes',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: Colors.white)),
                  ),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ─── Addresses Sheet ──────────────────────────────────────────────────────
  void _showAddressesSheet(BuildContext context) {
    final theme = Theme.of(context);
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Addresses', style: AppTextStyles.h4),
                IconButton(
                  onPressed: () => _showAddAddressSheet(context),
                  icon: Icon(Icons.add_circle_outline_rounded,
                      color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                final addresses =
                    AuthController.to.currentUser.value?.addresses ?? [];
                if (addresses.isEmpty) {
                  return Center(
                    child: Text('No addresses added yet',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  );
                }
                return ListView.builder(
                  itemCount: addresses.length,
                  itemBuilder: (_, i) {
                    final addr = addresses[i];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: AppRadius.small,
                        ),
                        child: Icon(Icons.location_on_rounded,
                            color: theme.colorScheme.primary, size: 20),
                      ),
                      title: Text(addr.label, style: AppTextStyles.labelLarge),
                      subtitle: Text('${addr.fullAddress}, ${addr.city}',
                          style: AppTextStyles.bodySmall),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (addr.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: AppRadius.full,
                              ),
                              child: Text('Default',
                                  style: AppTextStyles.labelSmall
                                      .copyWith(color: theme.colorScheme.primary)),
                            ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: theme.colorScheme.error, size: 20),
                            onPressed: () =>
                                ProfileController.to.deleteAddress(i),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ─── Add Address Sheet ────────────────────────────────────────────────────
  void _showAddAddressSheet(BuildContext context) {
    final theme = Theme.of(context);
    final labelCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final provinceCtrl = TextEditingController();
    final isDefault = false.obs;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Address', style: AppTextStyles.h4),
              const SizedBox(height: 16),
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Label (Home/Work/Other)',
                  border: OutlineInputBorder(borderRadius: AppRadius.medium),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Address',
                  border: OutlineInputBorder(borderRadius: AppRadius.medium),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border:
                            OutlineInputBorder(borderRadius: AppRadius.medium),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: provinceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Province',
                        border:
                            OutlineInputBorder(borderRadius: AppRadius.medium),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() => SwitchListTile(
                    value: isDefault.value,
                    onChanged: (val) => isDefault.value = val,
                    title: const Text('Set as Default',
                        style: AppTextStyles.labelMedium),
                    activeThumbColor: theme.colorScheme.primary,
                    contentPadding: EdgeInsets.zero,
                  )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final address = AddressModel(
                      id: const Uuid().v4(),
                      label: labelCtrl.text.trim(),
                      fullAddress: addressCtrl.text.trim(),
                      city: cityCtrl.text.trim(),
                      province: provinceCtrl.text.trim(),
                      latitude: 0.0,
                      longitude: 0.0,
                      isDefault: isDefault.value,
                    );
                    ProfileController.to.addAddress(address);
                    Get.back();
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape:
                        const RoundedRectangleBorder(borderRadius: AppRadius.medium),
                  ),
                  child: Text('Add Address',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ─── Measurements Sheet ───────────────────────────────────────────────────
  void _showMeasurementsSheet(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AuthController.to;
    final saved = auth.currentUser.value?.savedMeasurements;

    final heightCtrl =
        TextEditingController(text: saved?.height.toString() ?? '');
    final chestCtrl =
        TextEditingController(text: saved?.chest.toString() ?? '');
    final waistCtrl =
        TextEditingController(text: saved?.waist.toString() ?? '');
    final shoulderCtrl =
        TextEditingController(text: saved?.shoulder.toString() ?? '');
    final hipsCtrl = TextEditingController(text: saved?.hips.toString() ?? '');
    final sleeveCtrl =
        TextEditingController(text: saved?.sleevLength.toString() ?? '');
    final inseamCtrl =
        TextEditingController(text: saved?.inseam.toString() ?? '');
    final neckCtrl = TextEditingController(text: saved?.neck.toString() ?? '');

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Body Measurements', style: AppTextStyles.h4),
            Text('All measurements in cm',
                style: AppTextStyles.bodySmall
                    .copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _MeasurementField(ctrl: heightCtrl, label: 'Height'),
                    _MeasurementField(ctrl: chestCtrl, label: 'Chest'),
                    _MeasurementField(ctrl: waistCtrl, label: 'Waist'),
                    _MeasurementField(ctrl: shoulderCtrl, label: 'Shoulder'),
                    _MeasurementField(ctrl: hipsCtrl, label: 'Hips'),
                    _MeasurementField(ctrl: sleeveCtrl, label: 'Sleeve Length'),
                    _MeasurementField(ctrl: inseamCtrl, label: 'Inseam'),
                    _MeasurementField(ctrl: neckCtrl, label: 'Neck'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final m = BodyMeasurementModel(
                    id: const Uuid().v4(),
                    userId: auth.currentUserId!,
                    height: double.tryParse(heightCtrl.text) ?? 0,
                    chest: double.tryParse(chestCtrl.text) ?? 0,
                    waist: double.tryParse(waistCtrl.text) ?? 0,
                    shoulder: double.tryParse(shoulderCtrl.text) ?? 0,
                    hips: double.tryParse(hipsCtrl.text) ?? 0,
                    sleevLength: double.tryParse(sleeveCtrl.text) ?? 0,
                    inseam: double.tryParse(inseamCtrl.text) ?? 0,
                    neck: double.tryParse(neckCtrl.text) ?? 0,
                    aiAccuracyScore: 0,
                    measuredAt: DateTime.now(),
                  );
                  ProfileController.to.saveMeasurements(m);
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
                ),
                child: Text('Save Measurements',
                    style:
                        AppTextStyles.labelLarge.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

// ─── Order Status Item ────────────────────────────────────────────────────────

class _OrderStatusItem extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color color;

  const _OrderStatusItem({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: AppRadius.small,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(count,
            style: AppTextStyles.h4.copyWith(fontSize: 18, color: color)),
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// ─── Account Menu Item ────────────────────────────────────────────────────────

class _AccountMenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool showDivider;
  final Widget? trailing;

  const _AccountMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.showDivider,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: AppRadius.small,
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(title, style: AppTextStyles.labelLarge)),
                trailing ??
                    Icon(Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 66,
            endIndent: 16,
            color: theme.colorScheme.outline,
          ),
      ],
    );
  }
}

// ─── Account Menu Toggle ──────────────────────────────────────────────────────

class _AccountMenuToggle extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _AccountMenuToggle({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: AppRadius.small,
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: AppTextStyles.labelLarge)),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 66,
            endIndent: 16,
            color: theme.colorScheme.outline,
          ),
      ],
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _MeasurementField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;

  const _MeasurementField({required this.ctrl, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: 'cm',
          border: const OutlineInputBorder(borderRadius: AppRadius.medium),
        ),
      ),
    );
  }
}