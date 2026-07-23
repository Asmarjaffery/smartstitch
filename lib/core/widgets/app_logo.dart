import 'package:flutter/material.dart';
import '../theme/app.theme.dart';

/// ─── SmartStitch Brand Mark ──────────────────────────────────────────────
/// A single, reusable, 100% code-drawn logo — no external image/PNG/SVG
/// asset required. This guarantees the exact same mark (shape, gradient,
/// icon, proportions) appears everywhere in the app — splash, login,
/// signup, welcome screen, etc. — and it automatically adapts to light
/// and dark themes.
///
/// Two ways to use it:
///
/// 1. `AppLogo(size: 90)` → full "filled" mark: rounded gradient tile +
///    soft glow + subtle glass sheen + icon. Use this as a standalone
///    logo (login, signup, welcome header).
///
/// 2. `AppLogo.bare(size: 80)` → icon only, no container/gradient/glow.
///    Use this when you're embedding the mark inside a shell you've
///    already styled yourself (e.g. splash screen's animated shimmer
///    container).
class AppLogo extends StatelessWidget {
  final double size;
  final BorderRadius? borderRadius;
  final bool? isDark;
  final bool glow;
  final bool sheen;
  final IconData icon;
  final bool _bare;

  const AppLogo({
    super.key,
    this.size = 90,
    this.borderRadius,
    this.isDark,
    this.glow = true,
    this.sheen = true,
    this.icon = Icons.content_cut_rounded,
  }) : _bare = false;

  const AppLogo.bare({
    super.key,
    this.size = 80,
    this.isDark,
    this.icon = Icons.content_cut_rounded,
  })  : borderRadius = null,
        glow = false,
        sheen = false,
        _bare = true;

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;
    final iconSize = size * 0.46;

    if (_bare) {
      return Icon(icon, size: iconSize, color: Colors.white);
    }

    final radius = borderRadius ?? BorderRadius.circular(size * 0.28);
    final glowColor = dark ? AppColors.primaryLight : AppColors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: dark ? AppColors.darkGradient : AppColors.primaryGradient,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: dark ? 0.55 : 0.4),
                  blurRadius: size * 0.5,
                  spreadRadius: size * 0.02,
                  offset: Offset(0, size * 0.09),
                ),
              ]
            : const [],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (sheen)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: radius,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.24),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.55],
                    ),
                  ),
                ),
              ),
            ),
          Icon(icon, size: iconSize, color: Colors.white),
        ],
      ),
    );
  }
}