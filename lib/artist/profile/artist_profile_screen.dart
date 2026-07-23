import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/artist/profile/profile_controller.dart';

class ArtistProfileScreen extends StatefulWidget {
  const ArtistProfileScreen({super.key});

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  late ArtistProfileController ctrl;

  @override
  void initState() {
    super.initState();
    // IMPORTANT: don't blindly Get.put() here — if this screen remounts
    // (tab switch, navigate back, etc.) that creates a BRAND NEW
    // controller instance and disposes the old one, which is exactly
    // what caused "TextEditingController used after being disposed"
    // in the email/password dialogs and the edit sheet not opening.
    // Reuse the existing instance if one is already registered, and
    // mark it permanent so GetX never auto-disposes it mid-navigation.
    //
    // NOTE: because this controller is permanent, it must NEVER own
    // TextEditingControllers directly (see profile_controller.dart).
    // Each dialog/sheet below owns its own short-lived controllers.
    ctrl = Get.isRegistered<ArtistProfileController>()
        ? Get.find<ArtistProfileController>()
        : Get.put(ArtistProfileController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return _ProfileSkeleton(isDark: isDark);
        }
        if (ctrl.hasError.value && ctrl.artist.value == null) {
          return _ErrorState(
            message: ctrl.errorMessage.value,
            onRetry: () => ctrl.fetchArtistProfile(),
          );
        }
        final a = ctrl.artist.value;
        if (a == null) {
          return const _EmptyState();
        }

        final user = AuthController.to.currentUser.value;

        return RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: ctrl.refreshProfile,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ─── Header ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? AppColors.darkGradient
                        : AppColors.primaryGradient,
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Get.back(),
                                icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 20),
                              ),
                              const Spacer(),
                              Text('My Profile',
                                  style: AppTextStyles.h4
                                      .copyWith(color: Colors.white)),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  _showEditSheet(context, ctrl);
                                },
                                icon: const Icon(Icons.edit_rounded,
                                    color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  backgroundImage: a.profileImageUrl.isNotEmpty
                                      ? NetworkImage(a.profileImageUrl)
                                      : null,
                                  child: a.profileImageUrl.isEmpty
                                      ? Text(
                                          ((user?.name.isNotEmpty ?? false)
                                                  ? user!.name[0]
                                                  : 'A')
                                              .toUpperCase(),
                                          style: AppTextStyles.h1
                                              .copyWith(color: Colors.white),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Obx(() => GestureDetector(
                                      onTap: ctrl.isUploadingImage.value
                                          ? null
                                          : ctrl.uploadProfileImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: AppShadows.soft(
                                              theme.colorScheme.primary),
                                        ),
                                        child: ctrl.isUploadingImage.value
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: AppColors
                                                            .primary))
                                            : Icon(
                                                Icons.camera_alt_rounded,
                                                color:
                                                    theme.colorScheme.primary,
                                                size: 16),
                                      ),
                                    )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  (user?.name.isNotEmpty ?? false)
                                      ? user!.name
                                      : 'Artist',
                                  style: AppTextStyles.h3
                                      .copyWith(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (a.isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded,
                                    color: Colors.white, size: 18),
                              ],
                            ],
                          ),
                          if (a.businessName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(a.businessName,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: Colors.white70)),
                          ],
                          const SizedBox(height: 4),
                          Text(user?.email ?? '',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white70)),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _AvailabilityBadge(
                                isAvailable: a.isAvailable,
                                onTap: ctrl.toggleAvailability,
                              ),
                              _VerificationBadge(isVerified: a.isVerified),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Stats Row (dynamic) ────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  padding: const EdgeInsets.symmetric(
                      vertical: 18, horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppRadius.large,
                    border: Border.all(color: theme.colorScheme.outline),
                    boxShadow: AppShadows.card(isDark),
                  ),
                  child: Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                              icon: Icons.checklist_rounded,
                              label: 'Orders',
                              value: '${ctrl.totalCompletedOrders.value}',
                              loading: ctrl.isLoadingStats.value),
                          const _Divider(),
                          _StatItem(
                              icon: Icons.star_rounded,
                              label: 'Rating',
                              value: a.rating.toStringAsFixed(1),
                              loading: false),
                          const _Divider(),
                          _StatItem(
                              icon: Icons.reviews_rounded,
                              label: 'Reviews',
                              value: '${a.totalReviews}',
                              loading: false),
                        ],
                      )),
                ),
              ),

              // ─── Profile Completion ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Obx(() => _CompletionCard(
                        percent: ctrl.profileCompletionPercent,
                      )),
                ),
              ),

              // ─── Business Info ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _SectionCard(
                    title: 'Business Information',
                    icon: Icons.store_rounded,
                    child: Column(
                      children: [
                        _InfoRow(
                            icon: Icons.badge_outlined,
                            label: 'Business Name',
                            value: a.businessName.isEmpty
                                ? 'Not set'
                                : a.businessName),
                        const _InfoDivider(),
                        _InfoRow(
                            icon: Icons.description_outlined,
                            label: 'Bio',
                            value: a.bio.isEmpty ? 'No bio yet' : a.bio),
                        const _InfoDivider(),
                        _InfoRow(
                            icon: Icons.timeline_outlined,
                            label: 'Experience',
                            value: a.experienceYears == null
                                ? 'Not set'
                                : '${a.experienceYears} years'),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Specializations',
                              style: AppTextStyles.labelMedium.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7))),
                        ),
                        const SizedBox(height: 8),
                        a.specializations.isEmpty
                            ? Text('No specializations added yet',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5)))
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: a.specializations
                                    .map((spec) => _SpecChip(label: spec))
                                    .toList(),
                              ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Service Info (dynamic) ──────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _SectionCard(
                    title: 'Service Information',
                    icon: Icons.design_services_rounded,
                    child: Obx(() => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _MiniStat(
                                label: 'Total',
                                value: '${ctrl.totalServices.value}'),
                            _MiniStat(
                                label: 'Active',
                                value: '${ctrl.activeServices.value}',
                                color: AppColors.success),
                            _MiniStat(
                                label: 'Draft',
                                value: '${ctrl.draftServices.value}',
                                color: AppColors.warning),
                          ],
                        )),
                  ),
                ),
              ),

              // ─── CNIC Verification ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _SectionCard(
                    title: 'CNIC Verification',
                    icon: Icons.badge_rounded,
                    trailing: _VerificationBadge(
                        isVerified: a.isVerified, compact: true, onSurface: true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                            icon: Icons.credit_card_outlined,
                            label: 'CNIC Number',
                            value: a.cnicNumber.isEmpty
                                ? 'Not provided'
                                : a.cnicNumber),
                        const SizedBox(height: 14),

                        // ─── CNIC Image Preview ───────────────────────
                        if (a.cnicImageUrl.isNotEmpty) ...[
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.medium,
                              border: Border.all(
                                  color: theme.colorScheme.outline),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              a.cnicImageUrl,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 160,
                                  color: theme.colorScheme.surface,
                                  child: const Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ctrl.hasCnicUploaded
                                ? AppColors.success.withValues(alpha: 0.08)
                                : theme.colorScheme.surface,
                            borderRadius: AppRadius.medium,
                            border: Border.all(
                              color: ctrl.hasCnicUploaded
                                  ? AppColors.success.withValues(alpha: 0.3)
                                  : theme.colorScheme.outline,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                ctrl.hasCnicUploaded
                                    ? Icons.check_circle_rounded
                                    : Icons.error_outline_rounded,
                                size: 20,
                                color: ctrl.hasCnicUploaded
                                    ? AppColors.success
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ctrl.hasCnicUploaded
                                          ? 'CNIC image uploaded'
                                          : 'CNIC image not uploaded',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (!ctrl.hasCnicUploaded) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Upload to get verified by admin',
                                        style: AppTextStyles.caption.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ] else if (a.isVerified) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Verified by admin',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Pending admin review',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Obx(() => SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: ctrl.isUploadingImage.value
                                    ? null
                                    : ctrl.uploadCnicImage,
                                icon: ctrl.isUploadingImage.value
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.upload_rounded,
                                        size: 18),
                                label: Text(ctrl.hasCnicUploaded
                                    ? 'Replace CNIC Image'
                                    : 'Upload CNIC Image'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: AppRadius.medium),
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Account Settings ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _SectionCard(
                    title: 'Account Settings',
                    icon: Icons.security_rounded,
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.email_outlined,
                          title: 'Email Address',
                          subtitle: user?.email ?? 'No email',
                          onTap: () => _showChangeEmailDialog(context, ctrl),
                        ),
                        const _InfoDivider(),
                        _SettingsTile(
                          icon: Icons.lock_outlined,
                          title: 'Password',
                          subtitle: '••••••••',
                          onTap: () =>
                              _showChangePasswordDialog(context, ctrl),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Availability Settings ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _SectionCard(
                    title: 'Availability',
                    icon: Icons.tune_rounded,
                    child: Column(
                      children: [
                        _ToggleRow(
                          label: 'Available for Orders',
                          subtitle: 'Customers can book you right now',
                          value: a.isAvailable,
                          onChanged: (_) => ctrl.toggleAvailability(),
                        ),
                        const _InfoDivider(),
                        _ToggleRow(
                          label: 'Home Visit',
                          subtitle: 'Allow customers to book home visits',
                          value: a.offersHomeVisit,
                          onChanged: ctrl.toggleHomeVisit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Theme Settings ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _SectionCard(
                    title: 'Display',
                    icon: Icons.brightness_4_rounded,
                    child: _ThemeToggle(),
                  ),
                ),
              ),

              // ─── Logout ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: OutlinedButton.icon(
                    onPressed: () => AuthController.to.logout(),
                    icon: Icon(Icons.logout_rounded,
                        color: theme.colorScheme.error),
                    label: Text('Logout',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: theme.colorScheme.error)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.error),
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        );
      }),
    );
  }

  // ─── DIALOGS / SHEETS ────────────────────────────────────────────────
  // Each of these now delegates to a small StatefulWidget that owns its
  // own TextEditingControllers locally, so they're created fresh every
  // time the sheet/dialog opens and disposed when it closes — instead
  // of living on the permanent ArtistProfileController.

  void _showEditSheet(BuildContext context, ArtistProfileController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileSheet(ctrl: ctrl),
    );
  }

  void _showChangeEmailDialog(
      BuildContext context, ArtistProfileController ctrl) {
    showDialog(
      context: context,
      builder: (ctx) => _ChangeEmailDialog(ctrl: ctrl),
    );
  }

  void _showChangePasswordDialog(
      BuildContext context, ArtistProfileController ctrl) {
    showDialog(
      context: context,
      builder: (ctx) => _ChangePasswordDialog(ctrl: ctrl),
    );
  }
}

// ─── Edit Profile Sheet ──────────────────────────────────────────────────────
// Owns its own TextEditingControllers (local, short-lived) instead of
// reading them off the permanent ArtistProfileController.
class _EditProfileSheet extends StatefulWidget {
  final ArtistProfileController ctrl;
  const _EditProfileSheet({required this.ctrl});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController businessNameController;
  late final TextEditingController bioController;
  late final TextEditingController experienceController;
  late final TextEditingController cnicController;
  late final TextEditingController specializationController;

  @override
  void initState() {
    super.initState();
    final a = widget.ctrl.artist.value;
    businessNameController =
        TextEditingController(text: a?.businessName ?? '');
    bioController = TextEditingController(text: a?.bio ?? '');
    experienceController =
        TextEditingController(text: a?.experienceYears?.toString() ?? '');
    cnicController = TextEditingController(text: a?.cnicNumber ?? '');
    specializationController = TextEditingController();

    // Load current specializations into the controller's reactive list
    // so the Wrap of chips below reflects the artist's saved data.
    widget.ctrl.specializations.value =
        List<String>.from(a?.specializations ?? []);
  }

  @override
  void dispose() {
    businessNameController.dispose();
    bioController.dispose();
    experienceController.dispose();
    cnicController.dispose();
    specializationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Get.back();
      },
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('Edit Profile', style: AppTextStyles.h4),
                    const Spacer(),
                    IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: businessNameController,
                  maxLength: ArtistProfileController.businessNameMaxLength,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                    prefixIcon: Icon(Icons.store_outlined),
                    border: OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  maxLength: ArtistProfileController.bioMaxLength,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: experienceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Experience (years)',
                    prefixIcon: Icon(Icons.timeline_outlined),
                    border: OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cnicController,
                  decoration: const InputDecoration(
                    labelText: 'CNIC Number (12345-1234567-1)',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Specializations', style: AppTextStyles.h5),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: specializationController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Bridal, Formal Wear',
                          prefixIcon: Icon(Icons.auto_awesome_outlined),
                          border:
                              OutlineInputBorder(borderRadius: AppRadius.medium),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => ctrl.addSpecialization(
                        specializationController.text,
                        inputController: specializationController,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.medium),
                      ),
                      child:
                          const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(() {
                  if (ctrl.specializations.isEmpty) {
                    return Text(
                      'No specializations added yet',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.lightTextHint),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ctrl.specializations.map((spec) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: AppRadius.full,
                          border: Border.all(
                              color:
                                  AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(spec,
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.primary)),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => ctrl.removeSpecialization(spec),
                              child: const Icon(Icons.close_rounded,
                                  size: 14, color: AppColors.primary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }),
                const SizedBox(height: 24),
                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: ctrl.isSaving.value
                            ? null
                            : () => ctrl.saveProfile(
                                  businessName: businessNameController.text,
                                  bio: bioController.text,
                                  cnic: cnicController.text,
                                  experience: experienceController.text,
                                  specializations:
                                      List<String>.from(ctrl.specializations),
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.medium),
                        ),
                        child: ctrl.isSaving.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text('Save Changes',
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: Colors.white)),
                      ),
                    )),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Change Email Dialog ─────────────────────────────────────────────────────
// Owns its own local TextEditingController for the email field.
class _ChangeEmailDialog extends StatefulWidget {
  final ArtistProfileController ctrl;
  const _ChangeEmailDialog({required this.ctrl});

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  final newEmailController = TextEditingController();

  @override
  void dispose() {
    newEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.email_outlined,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          const Text('Change Email'),
        ],
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: newEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'New Email Address',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: AppRadius.medium),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A verification link will be sent to your new email address',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        Obx(() => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape:
                    const RoundedRectangleBorder(borderRadius: AppRadius.medium),
              ),
              onPressed: ctrl.isSaving.value
                  ? null
                  : () {
                      final email = newEmailController.text.trim();
                      if (!ctrl.validateEmail(email)) {
                        AppHelpers.showError('Invalid email address');
                        return;
                      }
                      ctrl.changeEmail(email);
                    },
              child: ctrl.isSaving.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Change Email',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white)),
            )),
      ],
    );
  }
}

// ─── Change Password Dialog ──────────────────────────────────────────────────
// Owns its own local TextEditingControllers for the password fields.
class _ChangePasswordDialog extends StatefulWidget {
  final ArtistProfileController ctrl;
  const _ChangePasswordDialog({required this.ctrl});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock_outline,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          const Text('Change Password'),
        ],
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: AppRadius.medium),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: AppRadius.medium),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: AppRadius.medium),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Password must be at least 6 characters',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        Obx(() => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape:
                    const RoundedRectangleBorder(borderRadius: AppRadius.medium),
              ),
              onPressed: ctrl.isSaving.value
                  ? null
                  : () {
                      final current =
                          currentPasswordController.text.trim();
                      final newPass = newPasswordController.text.trim();
                      final confirm =
                          confirmPasswordController.text.trim();

                      if (current.isEmpty) {
                        AppHelpers.showError('Enter current password');
                        return;
                      }
                      if (!ctrl.validatePassword(newPass)) {
                        AppHelpers.showError(
                            'New password must be at least 6 characters');
                        return;
                      }
                      if (newPass != confirm) {
                        AppHelpers.showError('Passwords do not match');
                        return;
                      }
                      ctrl.changePassword(current, newPass);
                    },
              child: ctrl.isSaving.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Change Password',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white)),
            )),
      ],
    );
  }
}

// ─── Availability Badge ─────────────────────────────────────────────────────
class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  final VoidCallback onTap;
  const _AvailabilityBadge({required this.isAvailable, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = isAvailable
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.red.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.full,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isAvailable ? 'Available for Orders' : 'Currently Offline',
              style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Verification Badge ─────────────────────────────────────────────────────
// onSurface=true -> used outside the teal header (e.g. inside a card),
// so it uses the theme's normal colors instead of white-on-teal.
class _VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final bool compact;
  final bool onSurface;
  const _VerificationBadge(
      {required this.isVerified, this.compact = false, this.onSurface = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color bgColor;
    final Color color;

    if (onSurface) {
      bgColor = isVerified
          ? AppColors.success.withValues(alpha: 0.1)
          : theme.colorScheme.surface;
      color = isVerified ? AppColors.success : theme.colorScheme.onSurface.withValues(alpha: 0.5);
    } else {
      bgColor = Colors.white.withValues(alpha: 0.2);
      color = Colors.white;
    }

    final icon =
        isVerified ? Icons.verified_rounded : Icons.error_outline_rounded;
    final label = isVerified ? 'Verified' : 'Unverified';

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14, vertical: compact ? 5 : 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.full,
        border: Border.all(color: color, width: compact ? 1 : 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.labelMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ─── Profile Completion Card ─────────────────────────────────────────────────
class _CompletionCard extends StatelessWidget {
  final int percent;
  const _CompletionCard({required this.percent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final complete = percent >= 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percent / 100,
                  strokeWidth: 5,
                  backgroundColor: AppColors.primarySoft,
                  valueColor: AlwaysStoppedAnimation(complete
                      ? AppColors.success
                      : theme.colorScheme.primary),
                ),
                Text('$percent%',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(complete ? 'Profile Complete' : 'Complete Your Profile',
                    style: AppTextStyles.h5),
                const SizedBox(height: 4),
                Text(
                  complete
                      ? 'Your profile looks great and ready for customers.'
                      : 'Add missing details to get more bookings.',
                  style: AppTextStyles.bodySmall.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Item (now with icon) ───────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool loading;
  const _StatItem(
      {required this.icon,
      required this.label,
      required this.value,
      this.loading = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary))
            : Text(value,
                style: AppTextStyles.h3.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.caption.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 44, color: Theme.of(context).colorScheme.outline);
  }
}

// Thin horizontal divider used between rows inside a section card.
class _InfoDivider extends StatelessWidget {
  const _InfoDivider();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
          height: 1, color: Theme.of(context).colorScheme.outline),
    );
  }
}

// ─── Mini Stat ────────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _MiniStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.h4.copyWith(
                color: color ?? theme.colorScheme.primary,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: AppTextStyles.caption.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }
}

// ─── Section Card (now supports an optional trailing widget) ────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  const _SectionCard(
      {required this.title,
      required this.icon,
      required this.child,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: AppRadius.small),
                child:
                    Icon(icon, color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppTextStyles.h5)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─── Settings Tile ────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.medium,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadius.small,
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.caption.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

// ─── Spec Chip ────────────────────────────────────────────────────────────────
class _SpecChip extends StatelessWidget {
  final String label;
  const _SpecChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadius.full,
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: AppTextStyles.labelSmall
              .copyWith(color: theme.colorScheme.primary)),
    );
  }
}

// ─── Info Row (now with a small leading icon) ───────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  const _InfoRow({this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
        ],
        SizedBox(
          width: icon != null ? 94 : 110,
          child: Text(label,
              style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ),
        Expanded(
          child: Text(value,
              style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

// ─── Toggle Row ───────────────────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.label,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelLarge),
              Text(subtitle,
                  style: AppTextStyles.caption.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
        Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: theme.colorScheme.primary),
      ],
    );
  }
}

// ─── Theme Toggle ─────────────────────────────────────────────────────────────
class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dark Mode', style: AppTextStyles.labelLarge),
              Text('Switch between light and dark theme',
                  style: AppTextStyles.caption.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
        Switch(
            value: isDark,
            onChanged: (value) {
              Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
            activeThumbColor: Colors.white,
            activeTrackColor: theme.colorScheme.primary),
      ],
    );
  }
}

// ─── Skeleton Loading ─────────────────────────────────────────────────────────
class _ProfileSkeleton extends StatelessWidget {
  final bool isDark;
  const _ProfileSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? AppColors.darkSurface2 : AppColors.lightBorder;
    Widget block({double h = 16, double w = double.infinity, double r = 8}) =>
        Container(
          height: h,
          width: w,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              color: base, borderRadius: BorderRadius.circular(r)),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration:
                    BoxDecoration(color: base, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(height: 20),
            block(h: 20, w: 160),
            const SizedBox(height: 8),
            block(h: 80, r: 20),
            const SizedBox(height: 16),
            block(h: 100, r: 20),
            const SizedBox(height: 16),
            block(h: 140, r: 20),
            const SizedBox(height: 16),
            block(h: 140, r: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message.isEmpty ? 'Something went wrong' : message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No profile data found',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: theme.colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}