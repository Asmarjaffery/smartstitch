import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

/// A premium glass-morphic container: frosted blur, soft border, subtle glow,
/// and a gentle hover/press scale — the base building block for every
/// redesigned dashboard card (Stripe/Linear/Notion-style elevation).
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final Color? glowColor;
  final bool interactive;
  final Gradient? borderGradient;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadius.large,
    this.glowColor,
    this.interactive = true,
    this.borderGradient,
    this.onTap,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scale = _pressed ? 0.98 : (_hovering ? 1.012 : 1.0);

    final glow = widget.glowColor;

    return MouseRegion(
      onEnter: (_) => widget.interactive ? setState(() => _hovering = true) : null,
      onExit: (_) => widget.interactive ? setState(() => _hovering = false) : null,
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.onTap != null ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: widget.onTap != null ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: widget.radius,
              boxShadow: [
                ...AppShadows.card(isDark),
                if (glow != null)
                  ...AppShadows.glow(glow, alpha: _hovering ? 0.32 : 0.18, blur: _hovering ? 34 : 24),
              ],
              gradient: widget.borderGradient,
            ),
            padding: widget.borderGradient != null ? const EdgeInsets.all(1.2) : null,
            child: ClipRRect(
              borderRadius: widget.borderGradient != null
                  ? BorderRadius.all(Radius.circular(widget.radius.topLeft.x - 1.2))
                  : widget.radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    borderRadius: widget.borderGradient != null
                        ? BorderRadius.all(Radius.circular(widget.radius.topLeft.x - 1.2))
                        : widget.radius,
                    color: isDark ? AppColors.darkGlass : AppColors.lightGlass,
                    border: widget.borderGradient == null
                        ? Border.all(color: AppColors.glassBorder(isDark), width: 1)
                        : null,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tiny rounded pill badge — used for trend %, status labels, etc.
class TrendBadge extends StatelessWidget {
  final double value;
  final bool showSign;

  const TrendBadge({super.key, required this.value, this.showSign = true});

  @override
  Widget build(BuildContext context) {
    final up = value >= 0;
    final color = up ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            '${showSign ? (up ? '+' : '-') : ''}${value.abs().toStringAsFixed(1)}%',
            style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// A minimal animated sparkline, sits under a metric value on premium cards.
class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;

  const Sparkline({super.key, required this.values, required this.color, this.height = 32});

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(height: height);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _SparklinePainter(values: values, color: color, progress: t),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double progress;

  _SparklinePainter({required this.values, required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final stepX = size.width / (values.length - 1);

    final points = List.generate(values.length, (i) {
      final norm = (values[i] - minV) / range;
      return Offset(stepX * i, size.height - norm * size.height * 0.85 - size.height * 0.1);
    });

    final visibleCount = (points.length * progress).clamp(1, points.length).toInt();
    final visible = points.sublist(0, visibleCount);
    if (visible.length < 2) return;

    final fillPath = Path()..moveTo(visible.first.dx, size.height);
    for (final p in visible) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(visible.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final linePath = Path()..moveTo(visible.first.dx, visible.first.dy);
    for (final p in visible.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.values != values;
}

/// Animated count-up text — wraps any numeric metric for a "wow" first paint.
class AnimatedMetric extends StatelessWidget {
  final double value;
  final String Function(double) formatter;
  final TextStyle? style;

  const AnimatedMetric({super.key, required this.value, required this.formatter, this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(formatter(v), style: style),
    );
  }
}

String formatCurrency(double v) =>
    'Rs. ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';