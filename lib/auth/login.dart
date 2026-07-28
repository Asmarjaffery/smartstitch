import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../core/theme/app.theme.dart';
import '../core/widgets/app_logo.dart';
import '../routes/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _logoCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _fadeSlide;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _fadeSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 350), () => _fadeCtrl.forward());
    Future.delayed(const Duration(milliseconds: 500), () => _slideCtrl.forward());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _logoCtrl.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = AuthController.to;

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background decorative blobs
          Positioned(
            top: -100,
            right: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.primary.withValues(alpha: 0.05) : AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 160,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.primaryDark.withValues(alpha: 0.03) : AppColors.primaryDark.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ BACK BUTTON
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    child: GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.customerHome),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: AppRadius.medium,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // ─── Logo / Title (Animated) ───────────────────────────────────────
                  FadeTransition(
                    opacity: _logoFade,
                    child: SlideTransition(
                      position: _fadeSlide,
                      child: Center(
                        child: Column(
                          children: [
                            ScaleTransition(
                              scale: _logoScale,
                              child: AnimatedBuilder(
                                animation: _pulseCtrl,
                                builder: (_, child) => ScaleTransition(scale: _pulse, child: child),
                                child: AppLogo(
                                  size: 90,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Smart Stitch',
                              style: AppTextStyles.h2.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Welcome back!',
                              style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ─── Form (Animated Slide) ───────────────────────────────────────
                  SlideTransition(
                    position: _fadeSlide,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── Email Field ────────────────────────────────────────
                          Text(
                            'Email',
                            style: AppTextStyles.labelLarge.copyWith(color: textPrimary),
                          ),
                          const SizedBox(height: 8),
                          _LoginField(
                            controller: _emailController,
                            hint: 'Enter your email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            isDark: isDark,
                          ),

                          const SizedBox(height: 20),

                          // ─── Password Field ─────────────────────────────────────
                          Text(
                            'Password',
                            style: AppTextStyles.labelLarge.copyWith(color: textPrimary),
                          ),
                          const SizedBox(height: 8),
                          _LoginField(
                            controller: _passwordController,
                            hint: 'Enter your password',
                            icon: Icons.lock_outlined,
                            obscureText: _obscurePassword,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: textSecondary,
                                size: 20,
                              ),
                            ),
                            isDark: isDark,
                          ),

                          const SizedBox(height: 12),

                          // ─── Forgot Password ────────────────────────────────────
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                              child: Text(
                                'Forgot Password?',
                                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ─── Login Button ───────────────────────────────────────
                          Obx(() => _LoginButton(
                            label: 'Login',
                            icon: Icons.login_rounded,
                            isLoading: auth.isLoading.value,
                            onPressed: () => auth.login(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            ),
                            isDark: isDark,
                          )),

                          const SizedBox(height: 16),

                          // ─── Google Sign In ─────────────────────────────────────
                          Obx(() => _GoogleButton(
                            isLoading: auth.isGoogleLoading.value,
                            onPressed: auth.signInWithGoogle,
                            isDark: isDark,
                          )),

                          const SizedBox(height: 32),

                          // ─── Signup Link ────────────────────────────────────────
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
                                ),
                                GestureDetector(
                                  onTap: () => Get.toNamed(AppRoutes.register),
                                  child: Text(
                                    'Sign Up',
                                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Login Field (Theme-aware + Animated) ─────────────────────────────────────────────────────
class _LoginField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool isDark;

  const _LoginField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    required this.isDark,
  });

  @override
  State<_LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primarySoft = isDark ? AppColors.darkSurface2 : AppColors.primarySoft;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: AppRadius.medium,
        boxShadow: _focused ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.14), blurRadius: 12, offset: const Offset(0, 4))] : [],
      ),
      child: Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          style: AppTextStyles.bodyMedium.copyWith(color: textPrimary, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: textHint),
            prefixIcon: Icon(widget.icon, color: textHint, size: 20),
            suffixIcon: widget.suffixIcon != null
                ? Padding(padding: const EdgeInsets.only(right: 4), child: widget.suffixIcon)
                : null,
            filled: true,
            fillColor: _focused ? primarySoft : bgColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide(color: borderColor, width: 1.2)),
            enabledBorder: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide(color: borderColor, width: 1.2)),
            focusedBorder: const OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide(color: AppColors.primary, width: 1.8)),
          ),
        ),
      ),
    );
  }
}

// ─── Login Button (Theme-aware + Animated) ────────────────────────────────────────────────────
class _LoginButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;
  final bool isDark;

  const _LoginButton({required this.label, required this.icon, required this.isLoading, required this.onPressed, required this.isDark});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_pressCtrl);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: AppRadius.medium,
            boxShadow: AppShadows.primary,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(widget.label, style: AppTextStyles.button.copyWith(color: Colors.white)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Google Button (Theme-aware + Animated) ───────────────────────────────────────────────────
class _GoogleButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final bool isDark;

  const _GoogleButton({required this.isLoading, required this.onPressed, required this.isDark});

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_pressCtrl);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: AppRadius.medium,
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: AppShadows.soft(AppColors.primary),
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.g_mobiledata_rounded, color: isDark ? AppColors.primaryLight : AppColors.primary, size: 28),
                      const SizedBox(width: 8),
                      Text('Continue with Google', style: AppTextStyles.labelLarge.copyWith(color: textPrimary)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}