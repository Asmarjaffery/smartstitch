import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app.theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../routes/routes.dart';

class PostLoginWelcomeScreen extends StatefulWidget {
  const PostLoginWelcomeScreen({super.key});

  @override
  State<PostLoginWelcomeScreen> createState() => _PostLoginWelcomeScreenState();
}

class _PostLoginWelcomeScreenState extends State<PostLoginWelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _contentCtrl;
  late Animation<double> _imgFade;
  late Animation<Offset> _imgSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _btnFade;
  late Animation<Offset> _btnSlide;

  @override
  void initState() {
    super.initState();

    debugPrint('🔍 PostLogin role: ${AuthController.to.currentUser.value?.role.name}');
    debugPrint('🔍 PostLogin user: ${AuthController.to.currentUser.value?.toJson()}');

    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    _imgFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _imgSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic)));

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut)));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic)));

    _btnFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut)));
    _btnSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic)));

    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  _RoleConfig get _config {
    final role = AuthController.to.currentUser.value?.role.name ?? 'customer';
    return _RoleConfig.forRole(role);
  }

  void _navigateToDashboard() {
    final role = AuthController.to.currentUser.value?.role.name ?? 'customer';
    debugPrint('🚀 Navigating with role: $role');

    switch (role) {
      case 'artist':
        Get.offAllNamed(AppRoutes.artistDashboard);
        break;
      case 'admin':
        Get.offAllNamed(AppRoutes.adminDashboard);
        break;
      case 'rider':
        Get.offAllNamed(AppRoutes.riderDashboard);
        break;
      default:
        Get.offAllNamed(AppRoutes.customerHome);
    }
  }

  void _navigateToSecondary() {
    final role = AuthController.to.currentUser.value?.role.name ?? 'customer';
    debugPrint('🔍 Secondary navigation with role: $role');

    switch (role) {
      case 'artist':
        Get.offAllNamed(AppRoutes.customerOrders);
        break;
      case 'admin':
        Get.offAllNamed(AppRoutes.adminReviews);
        break;
      case 'rider':
        Get.offAllNamed(AppRoutes.riderDashboard);
        break;
      default:
        Get.toNamed(AppRoutes.artistList);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Theme-aware colors
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFFDF8F5);
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    const primary = AppColors.primary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bgColor, // ✅ Theme-aware
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // ── Logo + App name (Centered) ──────────────────────────────────
              FadeTransition(
                opacity: _titleFade,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppLogo(
                      size: 36,
                      isDark: isDark,
                      borderRadius: BorderRadius.circular(10),
                      glow: false,
                      sheen: false,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SmartStitch',
                      style: AppTextStyles.h4.copyWith(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Main heading (Centered) — Obx se reactive ──────────────────
              Obx(() {
                final role = AuthController.to.currentUser.value?.role.name ?? 'customer';
                final cfg = _RoleConfig.forRole(role);
                return SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          cfg.heading,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h1.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            fontSize: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          cfg.subheading,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // ── Illustration (Centered) — Theme-aware Sewing Images ────────
              SlideTransition(
                position: _imgSlide,
                child: FadeTransition(
                  opacity: _imgFade,
                  child: Center(
                    child: Container(
                      height: size.height * 0.32,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.transparent,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          isDark 
                            ? 'assets/images/sewing_dark_mode.png'
                            : 'assets/images/sewing_light_mode.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.transparent,
                              child: Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 100,
                                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ── Buttons (Centered) — Obx se reactive ────────────────────────
              Obx(() {
                final role = AuthController.to.currentUser.value?.role.name ?? 'customer';
                final cfg = _RoleConfig.forRole(role);
                return SlideTransition(
                  position: _btnSlide,
                  child: FadeTransition(
                    opacity: _btnFade,
                    child: Column(
                      children: [
                        // Dots (Centered)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (i) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: i == 0 ? 20 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == 0 ? primary : borderColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 24),

                        // Primary CTA button (Full width)
                        _AnimatedButton(
                          label: cfg.ctaLabel,
                          color: primary,
                          onTap: _navigateToDashboard,
                        ),

                        const SizedBox(height: 12),

                        // Secondary button (Full width)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _navigateToSecondary,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primary, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              cfg.secondaryLabel,
                              style: AppTextStyles.labelLarge.copyWith(color: primary),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ROLE CONFIG
// ═══════════════════════════════════════════════════════════════════════════

class _RoleConfig {
  final String heading;
  final String subheading;
  final String ctaLabel;
  final String secondaryLabel;

  const _RoleConfig({
    required this.heading,
    required this.subheading,
    required this.ctaLabel,
    required this.secondaryLabel,
  });

  factory _RoleConfig.forRole(String role) {
    switch (role) {
      case 'artist':
        return const _RoleConfig(
          heading: 'Showcase Your\nArtistry',
          subheading: 'Manage orders, showcase your portfolio\nand grow your fashion business.',
          ctaLabel: 'Go to Dashboard',
          secondaryLabel: 'View My Orders',
        );
      case 'admin':
        return const _RoleConfig(
          heading: 'Welcome Back,\nAdministrator',
          subheading: 'Full control over users, orders,\npayments and platform analytics.',
          ctaLabel: 'Open Admin Panel',
          secondaryLabel: 'View Reports',
        );
      case 'rider':
        return const _RoleConfig(
          heading: 'Ready For\nDeliveries?',
          subheading: 'View your delivery tasks, track earnings\nand manage your active routes.',
          ctaLabel: 'View My Deliveries',
          secondaryLabel: 'Check Earnings',
        );
      default:
        return const _RoleConfig(
          heading: 'Custom Stitching\nMade Just For You',
          subheading: 'Find talented artists and get\nperfect outfits tailored for you.',
          ctaLabel: 'Get Started',
          secondaryLabel: 'Explore Artists',
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}