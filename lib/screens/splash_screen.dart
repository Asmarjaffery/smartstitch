import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/app_logo.dart';
import 'package:smartstitch/routes/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _bgController;
  late AnimationController _orbController;
  late AnimationController _logoRevealCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _needleCtrl;
  late AnimationController _textCtrl;
  late AnimationController _taglineCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _progressCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _exitCtrl;

  late Animation<double> _bgOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _ringScale1;
  late Animation<double> _ringOpacity1;
  late Animation<double> _ringScale2;
  late Animation<double> _ringOpacity2;
  late Animation<double> _ringScale3;
  late Animation<double> _ringOpacity3;
  late Animation<double> _needleDraw;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _shimmer;
  late Animation<double> _floatY;
  late Animation<double> _progress;
  late Animation<double> _exitScale;
  late Animation<double> _exitOpacity;
  late Animation<double> _orbDrift;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ));
    _initControllers();
    _initAnimations();
    _startSequence();
  }

  void _initControllers() {
    _bgController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _orbController = AnimationController(vsync: this, duration: const Duration(milliseconds: 8000))..repeat();
    _logoRevealCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _needleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _taglineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000))..repeat();
    _exitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _orbDrift = CurvedAnimation(parent: _orbController, curve: Curves.easeInOut)
        .drive(Tween(begin: 0.0, end: 1.0));
  }

  void _initAnimations() {
    _bgOpacity = CurvedAnimation(parent: _bgController, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));

    _logoScale = CurvedAnimation(parent: _logoRevealCtrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _logoOpacity = CurvedAnimation(parent: _logoRevealCtrl, curve: const Interval(0.0, 0.4))
        .drive(Tween(begin: 0.0, end: 1.0));

    _ringScale1 = CurvedAnimation(parent: _ringCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut))
        .drive(Tween(begin: 0.8, end: 2.8));
    _ringOpacity1 = CurvedAnimation(parent: _ringCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut))
        .drive(Tween(begin: 0.7, end: 0.0));
    _ringScale2 = CurvedAnimation(parent: _ringCtrl, curve: const Interval(0.2, 0.8, curve: Curves.easeOut))
        .drive(Tween(begin: 0.8, end: 2.4));
    _ringOpacity2 = CurvedAnimation(parent: _ringCtrl, curve: const Interval(0.2, 0.8, curve: Curves.easeOut))
        .drive(Tween(begin: 0.6, end: 0.0));
    _ringScale3 = CurvedAnimation(parent: _ringCtrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOut))
        .drive(Tween(begin: 0.8, end: 2.0));
    _ringOpacity3 = CurvedAnimation(parent: _ringCtrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOut))
        .drive(Tween(begin: 0.5, end: 0.0));

    _ringCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _ringCtrl.reset();
        _ringCtrl.forward();
      }
    });

    _needleDraw = CurvedAnimation(parent: _needleCtrl, curve: Curves.easeInOutCubic)
        .drive(Tween(begin: 0.0, end: 1.0));

    _textOpacity = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _textSlide = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic)
        .drive(Tween(begin: const Offset(0, 0.5), end: Offset.zero));

    _taglineOpacity = CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _taglineSlide = CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOutCubic)
        .drive(Tween(begin: const Offset(0, 0.6), end: Offset.zero));

    _shimmer = CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut)
        .drive(Tween(begin: -1.2, end: 2.2));

    _floatY = CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut)
        .drive(Tween(begin: -8.0, end: 8.0));

    _progress = CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut)
        .drive(Tween(begin: 0.0, end: 1.0));

    _exitScale = CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 1.0, end: 1.2));
    _exitOpacity = CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 1.0, end: 0.0));
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 80));
    _bgController.forward();

    await Future.delayed(const Duration(milliseconds: 350));
    _logoRevealCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _ringCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _needleCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _textCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 220));
    _taglineCtrl.forward();
    _progressCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 250));
    _shimmerCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 2200));
    _ringCtrl.stop();
    await _exitCtrl.forward();
    Get.offAllNamed(AppRoutes.customerHome);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _orbController.dispose();
    _logoRevealCtrl.dispose();
    _ringCtrl.dispose();
    _needleCtrl.dispose();
    _textCtrl.dispose();
    _taglineCtrl.dispose();
    _shimmerCtrl.dispose();
    _floatCtrl.dispose();
    _progressCtrl.dispose();
    _particleCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // ✅ Theme-aware colors
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;

    return AnimatedBuilder(
      animation: _exitCtrl,
      builder: (context, _) => Opacity(
        opacity: _exitOpacity.value,
        child: Transform.scale(
          scale: _exitScale.value,
          child: Scaffold(
            backgroundColor: bgColor,
            body: Stack(
              children: [
                // ── 1. BACKGROUND (Theme-aware gradient) ────────────────────────────
                AnimatedBuilder(
                  animation: _bgController,
                  builder: (_, __) => Opacity(
                    opacity: _bgOpacity.value,
                    child: Container(
                      width: size.width,
                      height: size.height,
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? const RadialGradient(
                                center: Alignment(0, -0.2),
                                radius: 1.4,
                                colors: [
                                  AppColors.primaryDark,
                                  AppColors.primary,
                                  AppColors.darkBackground,
                                ],
                                stops: [0.0, 0.5, 1.0],
                              )
                            : const RadialGradient(
                                center: Alignment(0, -0.2),
                                radius: 1.2,
                                colors: [
                                  AppColors.primarySoft,
                                  AppColors.primaryLight,
                                  AppColors.lightBackground,
                                ],
                                stops: [0.0, 0.5, 1.0],
                              ),
                      ),
                    ),
                  ),
                ),

                // ── 2. FLOATING ORBS (Theme-aware) ───────────────────────────
                AnimatedBuilder(
                  animation: _orbController,
                  builder: (_, __) {
                    final t = _orbDrift.value;
                    final sin1 = math.sin(t * math.pi * 2);
                    final cos1 = math.cos(t * math.pi * 2);
                    final sin2 = math.sin(t * math.pi * 2 + 1.0);
                    final cos2 = math.cos(t * math.pi * 2 + 1.0);
                    
                    final orbColor1 = isDark ? AppColors.primaryLight : AppColors.primary;
                    final orbColor2 = isDark ? AppColors.accent : AppColors.primarySoft;
                    
                    return Stack(
                      children: [
                        Positioned(
                          left: size.width * 0.05 + sin1 * 20,
                          top: size.height * 0.08 + cos1 * 25,
                          child: _GlowOrb(size: 180, color: orbColor1, opacity: 0.18),
                        ),
                        Positioned(
                          right: size.width * 0.05 + cos1 * 18,
                          bottom: size.height * 0.1 + sin1 * 22,
                          child: _GlowOrb(size: 220, color: orbColor2, opacity: 0.15),
                        ),
                        Positioned(
                          left: size.width * 0.1 + sin2 * 15,
                          top: size.height * 0.45 + cos2 * 20,
                          child: _GlowOrb(size: 100, color: orbColor1, opacity: 0.12),
                        ),
                        Positioned(
                          right: size.width * 0.08 + cos2 * 12,
                          top: size.height * 0.2 + sin2 * 18,
                          child: const _GlowOrb(size: 130, color: AppColors.accent, opacity: 0.14),
                        ),
                      ],
                    );
                  },
                ),

                // ── 3. PARTICLE CONSTELLATION
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _particleCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _ConstellationPainter(
                        progress: _particleCtrl.value,
                        bgOpacity: _bgOpacity.value,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),

                // ── 4. DIAGONAL LINES
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _bgController,
                    builder: (_, __) => Opacity(
                      opacity: _bgOpacity.value * 0.12,
                      child: CustomPaint(
                        painter: _GridLinePainter(isDark: isDark),
                      ),
                    ),
                  ),
                ),

                // ── 5. PULSE RINGS
                Center(
                  child: AnimatedBuilder(
                    animation: _ringCtrl,
                    builder: (_, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        _Ring(scale: _ringScale1.value, opacity: _ringOpacity1.value, size: 130, color: AppColors.accent, strokeWidth: 1.0),
                        _Ring(scale: _ringScale2.value, opacity: _ringOpacity2.value, size: 130, color: AppColors.primaryLight, strokeWidth: 1.5),
                        _Ring(scale: _ringScale3.value, opacity: _ringOpacity3.value, size: 130, color: AppColors.primary, strokeWidth: 2.0),
                      ],
                    ),
                  ),
                ),

                // ── 6. MAIN LOGO + CONTENT
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge([_logoRevealCtrl, _floatCtrl, _shimmerCtrl]),
                        builder: (_, __) => Transform.translate(
                          offset: Offset(0, _floatY.value),
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: _LogoContainer(shimmer: _shimmer.value, isDark: isDark),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      AnimatedBuilder(
                        animation: _textCtrl,
                        builder: (_, __) => FadeTransition(
                          opacity: _textOpacity,
                          child: SlideTransition(
                            position: _textSlide,
                            child: _AppNameText(isDark: isDark),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      AnimatedBuilder(
                        animation: _taglineCtrl,
                        builder: (_, __) => FadeTransition(
                          opacity: _taglineOpacity,
                          child: SlideTransition(
                            position: _taglineSlide,
                            child: _TaglinePill(isDark: isDark),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      AnimatedBuilder(
                        animation: _progressCtrl,
                        builder: (_, __) => FadeTransition(
                          opacity: _taglineOpacity,
                          child: _ProgressBar(progress: _progress.value, isDark: isDark),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── 7. BOTTOM BRAND
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _taglineCtrl,
                    builder: (_, __) => FadeTransition(
                      opacity: _taglineOpacity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 1,
                            color: textSecondary.withValues(alpha: 0.2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SMART STITCH © 2025',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: textSecondary.withValues(alpha: 0.5),
                              letterSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 24,
                            height: 1,
                            color: textSecondary.withValues(alpha: 0.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Glow Orb ──────────────────────────────────────────────────────────────
class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowOrb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

// ─── Ring ──────────────────────────────────────────────────────────────
class _Ring extends StatelessWidget {
  final double scale, opacity, size, strokeWidth;
  final Color color;
  const _Ring({
    required this.scale, required this.opacity,
    required this.size, required this.color, required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: opacity),
            width: strokeWidth,
          ),
        ),
      ),
    );
  }
}

// ─── Logo Container ─────────────────────────────────────────────────────
class _LogoContainer extends StatelessWidget {
  final double shimmer;
  final bool isDark;
  const _LogoContainer({required this.shimmer, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.35),
                (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: isDark ? AppColors.darkGradient : AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.7),
                blurRadius: 50,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    stops: [
                      (shimmer - 0.4).clamp(0.0, 1.0),
                      (shimmer - 0.1).clamp(0.0, 1.0),
                      (shimmer + 0.1).clamp(0.0, 1.0),
                      (shimmer + 0.4).clamp(0.0, 1.0),
                    ],
                  ).createShader(bounds),
                  child: Container(color: Colors.white),
                ),
              ),
              Center(
                child: AppLogo.bare(
                  size: 80,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── App Name Text ──────────────────────────────────────────────────────
class _AppNameText extends StatelessWidget {
  final bool isDark;
  const _AppNameText({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          isDark ? AppColors.primarySoft : AppColors.primaryLight,
          AppColors.primary,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bounds),
      child: Text(
        'Smart Stitch',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 38,
          fontWeight: FontWeight.w800,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          letterSpacing: -1.0,
          height: 1.0,
        ),
      ),
    );
  }
}

// ─── Tagline Pill ──────────────────────────────────────────────────────
class _TaglinePill extends StatelessWidget {
  final bool isDark;
  const _TaglinePill({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        gradient: LinearGradient(
          colors: [
            AppColors.primarySoft.withValues(alpha: isDark ? 0.08 : 0.12),
            AppColors.primarySoft.withValues(alpha: isDark ? 0.04 : 0.06),
          ],
        ),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: isDark ? 0.15 : 0.3),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.8),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Tailored for Perfection',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark 
                  ? AppColors.darkTextPrimary.withValues(alpha: 0.88)
                  : AppColors.lightTextPrimary.withValues(alpha: 0.88),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Progress Bar ──────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double progress;
  final bool isDark;
  const _ProgressBar({required this.progress, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 160,
          child: Stack(
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isDark 
                      ? AppColors.darkSurface2.withValues(alpha: 0.3)
                      : AppColors.primarySoft.withValues(alpha: 0.3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: isDark ? AppColors.darkGradient : AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryLight.withValues(alpha: 0.7),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Loading${_dots(progress)}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: isDark
                ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                : AppColors.lightTextHint.withValues(alpha: 0.5),
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  String _dots(double p) {
    if (p < 0.33) return '.';
    if (p < 0.66) return '..';
    return '...';
  }
}

// ─── Constellation Painter ────────────────────────────────────────────
class _ConstellationPainter extends CustomPainter {
  final double progress;
  final double bgOpacity;
  final bool isDark;
  const _ConstellationPainter({required this.progress, required this.bgOpacity, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (bgOpacity < 0.1) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.4;

    final stars = [
      [0.08, 0.12], [0.88, 0.08], [0.15, 0.88], [0.82, 0.82],
      [0.45, 0.06], [0.55, 0.94], [0.04, 0.52], [0.96, 0.48],
    ];

    final connections = [[0, 4], [4, 1], [1, 5], [5, 3]];

    for (final conn in connections) {
      final a = stars[conn[0]];
      final b = stars[conn[1]];
      final twinkle = math.sin(progress * math.pi * 2 + conn[0].toDouble()) * 0.5 + 0.5;
      linePaint.color = isDark 
          ? AppColors.darkTextSecondary.withValues(alpha: 0.06 * twinkle * bgOpacity)
          : AppColors.primarySoft.withValues(alpha: 0.06 * twinkle * bgOpacity);
      canvas.drawLine(Offset(size.width * a[0], size.height * a[1]), Offset(size.width * b[0], size.height * b[1]), linePaint);
    }

    for (int i = 0; i < stars.length; i++) {
      final star = stars[i];
      final twinkle = math.sin((progress + i * 0.618) * math.pi * 2) * 0.5 + 0.5;
      paint.color = isDark
          ? AppColors.darkTextSecondary.withValues(alpha: 0.06 * twinkle * bgOpacity)
          : AppColors.primarySoft.withValues(alpha: 0.06 * twinkle * bgOpacity);
      canvas.drawCircle(Offset(size.width * star[0], size.height * star[1]), 1.8 * 3, paint);
      paint.color = isDark
          ? AppColors.darkTextPrimary.withValues(alpha: (0.4 + 0.5 * twinkle) * bgOpacity)
          : AppColors.lightTextPrimary.withValues(alpha: (0.4 + 0.5 * twinkle) * bgOpacity);
      canvas.drawCircle(Offset(size.width * star[0], size.height * star[1]), 1.8, paint);
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter old) => old.progress != progress || old.bgOpacity != bgOpacity;
}

// ─── Grid Line Painter ─────────────────────────────────────────────────
class _GridLinePainter extends CustomPainter {
  final bool isDark;
  const _GridLinePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark 
          ? AppColors.darkTextSecondary.withValues(alpha: 0.05)
          : AppColors.primarySoft.withValues(alpha: 0.05)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 60.0;
    const angle = math.pi / 6;

    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height / math.tan(math.pi / 2 - angle), 0), paint);
    }
  }

  @override
  bool shouldRepaint(_GridLinePainter old) => false;
}