import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../core/theme/app.theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  bool _emailSent = false;
  String _sentEmail = '';

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _successCtrl;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _successScale;
  late Animation<double> _successFade;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _successScale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
    _successFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _successCtrl, curve: Curves.easeOut));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset(AuthController auth) async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      Get.snackbar("Error", "Please enter your email",
        backgroundColor: AppColors.error, colorText: Colors.white,
        borderRadius: 12, margin: const EdgeInsets.all(16), snackPosition: SnackPosition.TOP);
      return;
    }

    try {
      await auth.forgotPasswordSilent(email);
      setState(() {
        _sentEmail = email;
        _emailSent = true;
      });
      _successCtrl.forward();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = AuthController.to;

    // ✅ Theme-aware colors
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primarySoft = isDark ? AppColors.darkSurface2 : AppColors.primarySoft;
    final blobColor = isDark ? AppColors.primary.withValues(alpha: 0.05) : AppColors.primary.withValues(alpha: 0.07);
    final blobColor2 = isDark ? AppColors.primaryDark.withValues(alpha: 0.03) : AppColors.primaryDark.withValues(alpha: 0.05);

    return Scaffold(
      backgroundColor: bgColor, // ✅ Theme-aware
      body: Stack(
        children: [
          // Background decorative blobs (Theme-aware)
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle, color: blobColor), // ✅
            ),
          ),
          Positioned(
            top: 100,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: blobColor2), // ✅
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // ── Back Button ──────────────────────────────
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: surfaceColor, // ✅ Theme-aware
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.10),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: isDark ? AppColors.darkTextPrimary : Colors.black87, // ✅
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Top Icon ─────────────────────────────────
                        Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: AppShadows.primary,
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Title ────────────────────────────────────
                        Text(
                          'Forgot Password?',
                          style: AppTextStyles.h2.copyWith(color: textPrimary), // ✅
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No worries! Enter your email and\nwe\'ll send you reset instructions.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(color: textSecondary), // ✅
                        ),

                        const SizedBox(height: 36),

                        // ── Main Content ─────────────────────────────
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _emailSent ? _buildSuccessState(isDark) : _buildFormState(auth, isDark), // ✅
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form State (Theme-aware) ─────────────────────────────────────────────────────────────
  Widget _buildFormState(AuthController auth, bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primarySoft = isDark ? AppColors.darkSurface2 : AppColors.primarySoft;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Container(
      key: const ValueKey('form'),
      decoration: BoxDecoration(
        color: surfaceColor, // ✅ Theme-aware
        borderRadius: AppRadius.large,
        boxShadow: AppShadows.soft(AppColors.primary),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Text(
                'Reset via Email',
                style: AppTextStyles.h5.copyWith(color: textPrimary), // ✅
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 13),
            child: Text(
              'Enter the email linked to your account',
              style: AppTextStyles.bodySmall.copyWith(color: textSecondary), // ✅
            ),
          ),

          const SizedBox(height: 22),

          // Email label
          Text(
            'EMAIL ADDRESS',
            style: AppTextStyles.bodySmall.copyWith(
              color: textSecondary, // ✅
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          // Email field
          _FocusField(
            controller: _emailController,
            hint: 'Enter your email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            isDark: isDark, // ✅
          ),

          const SizedBox(height: 22),

          // Send Reset Link Button
          Obx(() => _ActionButton(
            label: 'Send Reset Link',
            icon: Icons.send_rounded,
            isLoading: auth.isLoading.value,
            onPressed: () => _sendReset(auth),
            isDark: isDark, // ✅
          )),

          const SizedBox(height: 16),

          // Back to Login
          Center(
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Back to Login',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Success State (Theme-aware) ──────────────────────────────────────────────────────────
  Widget _buildSuccessState(bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return ScaleTransition(
      scale: _successScale,
      child: FadeTransition(
        opacity: _successFade,
        child: Column(
          key: const ValueKey('success'),
          children: [
            // Green check icon (Theme-aware)
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF0D3320) : const Color(0xFFE8F5E9), // ✅ Dark/Light
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32), // ✅
                size: 44,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Email Sent!',
              style: AppTextStyles.h2.copyWith(color: textPrimary), // ✅
            ),
            const SizedBox(height: 8),
            Text(
              'Password reset instructions sent to',
              style: AppTextStyles.bodyMedium.copyWith(color: textSecondary), // ✅
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: AppRadius.full,
              ),
              child: Text(
                _sentEmail,
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
              ),
            ),

            const SizedBox(height: 24),

            // Info card (Theme-aware)
            Container(
              decoration: BoxDecoration(
                color: surfaceColor, // ✅
                borderRadius: AppRadius.large,
                boxShadow: AppShadows.soft(AppColors.primary),
              ),
              child: Column(
                children: [
                  _InfoTile(icon: Icons.inbox_outlined, text: 'Check your inbox and spam folder', showDivider: true, isDark: isDark), // ✅
                  _InfoTile(icon: Icons.timer_outlined, text: 'Reset link expires in 1 hour', showDivider: true, isDark: isDark), // ✅
                  _InfoTile(icon: Icons.refresh_rounded, text: "Didn't receive it? Resend below", showDivider: false, isDark: isDark), // ✅
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Back to Login button
            _ActionButton(
              label: 'Back to Login',
              icon: Icons.login_rounded,
              isLoading: false,
              onPressed: () => Get.back(),
              isDark: isDark, // ✅
            ),

            const SizedBox(height: 16),

            // Resend (Theme-aware)
            Obx(() => TextButton(
              onPressed: AuthController.to.isLoading.value ? null : () {
                setState(() => _emailSent = false);
                _successCtrl.reset();
              },
              child: Text(
                'Resend Email',
                style: AppTextStyles.labelMedium.copyWith(color: textSecondary), // ✅
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ─── Info Tile (Theme-aware) ────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool showDivider;
  final bool isDark; // ✅

  const _InfoTile({required this.icon, required this.text, required this.showDivider, required this.isDark}); // ✅

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder, // ✅
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

// ─── Focus Field (Theme-aware) ──────────────────────────────────────────────────────────────
class _FocusField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool isDark; // ✅

  const _FocusField({required this.controller, required this.hint, required this.icon, this.keyboardType, required this.isDark}); // ✅

  @override
  State<_FocusField> createState() => _FocusFieldState();
}

class _FocusFieldState extends State<_FocusField> {
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
          style: AppTextStyles.bodyMedium.copyWith(color: textPrimary, fontWeight: FontWeight.w500), // ✅
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: textHint), // ✅
            prefixIcon: Icon(widget.icon, color: textHint, size: 20), // ✅
            filled: true,
            fillColor: _focused ? primarySoft : bgColor, // ✅
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide(color: borderColor, width: 1.2)), // ✅
            enabledBorder: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide(color: borderColor, width: 1.2)), // ✅
            focusedBorder: const OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide(color: AppColors.primary, width: 1.8)),
          ),
        ),
      ),
    );
  }
}

// ─── Action Button (Theme-aware) ────────────────────────────────────────────────────────────
class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;
  final bool isDark; // ✅

  const _ActionButton({required this.label, required this.icon, required this.isLoading, required this.onPressed, required this.isDark}); // ✅

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> with SingleTickerProviderStateMixin {
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
            gradient: AppColors.primaryGradient, // ✅ Same gradient (premium)
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
                      Text(
                        widget.label,
                        style: AppTextStyles.button.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
