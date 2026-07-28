import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/auth/signup_screen.dart'; 

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String role;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.role,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  static const int _otpLength = 6;

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  late AnimationController _headerCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _headerSlide;

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorText;

  Timer? _resendTimer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _headerCtrl.forward();

    _startResendTimer();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _resendTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _secondsRemaining = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() => _errorText = null);

    if (_otpCode.length == _otpLength) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != _otpLength) {
      setState(() => _errorText = 'Please enter the full 6-digit code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    final bool success = await AuthController.to.verifyOtp(
      email: widget.email,
      otp: _otpCode,
    );

    setState(() => _isVerifying = false);

    if (success) {
      Get.snackbar(
        'Verified',
        'Your email has been verified successfully',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
      );
    } else {
      setState(() => _errorText = 'Invalid or expired code. Please try again.');
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    if (_secondsRemaining > 0) return;

    setState(() => _isResending = true);

    // ⚠️ Requires AuthController.resendOtp(email) -> Future<bool>
    // Should trigger sendRegistrationOtp again on the backend.
    await AuthController.to.resendOtp(email: widget.email);

    setState(() => _isResending = false);
    _startResendTimer();

    Get.snackbar(
      'Code Sent',
      'A new verification code has been sent to your email',
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      snackPosition: SnackPosition.TOP,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final fillColor = isDark ? AppColors.darkSurface2 : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -70,
            child: _BlurBlob(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : AppColors.primary.withValues(alpha: 0.08),
              size: 280,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () {

                          Get.off(() => const SignupScreen());
                        },
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Header ──────────────────────────────
                    SlideTransition(
                      position: _headerSlide,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: Column(
                          children: [
                            ScaleTransition(
                              scale: _logoScale,
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                  boxShadow: AppShadows.primary,
                                ),
                                child: const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 38),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text('Verify Your Email', style: AppTextStyles.h1.copyWith(color: textPrimary)),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                "We've sent a 6-digit code to",
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.email,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── OTP Card ────────────────────────────
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: AppRadius.large,
                        boxShadow: AppShadows.soft(AppColors.primary),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // ✅ Responsive OTP boxes: har box "Expanded" mein hai,
                          // isliye ye kabhi bhi fixed width (46px) nahi lete —
                          // available card width ko barabar hisson mein baant
                          // lete hain. Choti screen (BlackBerry Z30, 360px) se
                          // bari tablet tak, kabhi overflow nahi hoga.
                          Row(
                            children: List.generate(_otpLength, (index) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: SizedBox(
                                    height: 56,
                                    child: TextField(
                                      controller: _controllers[index],
                                      focusNode: _focusNodes[index],
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      maxLength: 1,
                                      style: AppTextStyles.h5.copyWith(color: textPrimary),
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: InputDecoration(
                                        counterText: '',
                                        filled: true,
                                        fillColor: fillColor,
                                        contentPadding: EdgeInsets.zero,
                                        border: OutlineInputBorder(
                                          borderRadius: AppRadius.medium,
                                          borderSide: BorderSide(
                                            color: _errorText != null ? AppColors.error : borderColor,
                                            width: 1.2,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: AppRadius.medium,
                                          borderSide: BorderSide(color: borderColor, width: 1.2),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: AppRadius.medium,
                                          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                                        ),
                                      ),
                                      onChanged: (v) => _onDigitChanged(index, v),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          if (_errorText != null) ...[
                            const SizedBox(height: 14),
                            Text(_errorText!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                          ],
                          const SizedBox(height: 24),
                          _VerifyButton(isLoading: _isVerifying, onPressed: _verifyOtp),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Resend ──────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Didn't receive the code? ", style: AppTextStyles.bodyMedium.copyWith(color: textSecondary)),
                        GestureDetector(
                          onTap: _secondsRemaining == 0 && !_isResending ? _resendOtp : null,
                          child: _isResending
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                )
                              : Text(
                                  _secondsRemaining == 0 ? 'Resend' : 'Resend in ${_secondsRemaining}s',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: _secondsRemaining == 0 ? AppColors.primary : textSecondary,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _VerifyButton({required this.isLoading, required this.onPressed});

  @override
  State<_VerifyButton> createState() => _VerifyButtonState();
}

class _VerifyButtonState extends State<_VerifyButton> with SingleTickerProviderStateMixin {
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
                : Text('Verify Email', style: AppTextStyles.button.copyWith(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _BlurBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}