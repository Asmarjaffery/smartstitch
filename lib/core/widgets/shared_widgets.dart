import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app.theme.dart';

/// Central place for theme-derived colors so every widget in this module
/// reads them the same way. Keeps the existing AppColors/AppTextStyles
/// tokens untouched — this is purely a convenience layer.
class ComplaintUI {
  static Color surface(bool d) => d ? AppColors.darkSurface : AppColors.lightSurface;
  static Color surface2(bool d) => d ? AppColors.darkSurface2 : AppColors.lightSurface2;
  static Color border(bool d) => d ? AppColors.darkBorder : AppColors.lightBorder;
  static Color textPrimary(bool d) => d ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  static Color textSecondary(bool d) => d ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  static Color textHint(bool d) => d ? AppColors.darkTextHint : AppColors.lightTextHint;
  static Color accent(bool d) => d ? AppColors.primaryLight : AppColors.primary;
  static LinearGradient avatarGradient(bool d) => d ? AppColors.darkGradient : AppColors.primaryGradient;

  static Color priority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return AppColors.error;
      case 'medium': return AppColors.warning;
      case 'low': return AppColors.success;
      default: return AppColors.primary;
    }
  }

  static _StatusStyle status(String status, bool isDark) {
    switch (status) {
      case 'resolved':
        return _StatusStyle(AppColors.success,
            isDark ? AppColors.successSoftDark : AppColors.successSoft, Icons.check_circle_rounded);
      case 'in_process':
      case 'in_progress':
        return _StatusStyle(AppColors.info,
            isDark ? AppColors.infoSoftDark : AppColors.infoSoft, Icons.autorenew_rounded);
      case 'closed':
        return _StatusStyle(textSecondary(isDark), surface2(isDark), Icons.lock_rounded);
      default:
        return _StatusStyle(AppColors.warning,
            isDark ? AppColors.warningSoftDark : AppColors.warningSoft, Icons.hourglass_top_rounded);
    }
  }

  static String formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final ampm = d.hour >= 12 ? 'PM' : 'AM';
      return '${d.day}/${d.month}/${d.year} • $hour:${d.minute.toString().padLeft(2, '0')} $ampm';
    }
    return 'Unknown';
  }
}

class _StatusStyle {
  final Color color;
  final Color soft;
  final IconData icon;
  const _StatusStyle(this.color, this.soft, this.icon);
}

// ─── GLASS CARD ───────────────────────────────────────────────────────────
// Reusable premium glassmorphism container used across the whole module.

class ComplaintGlassCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;
  final Color? selectedColor;
  final bool blur;

  const ComplaintGlassCard({
    super.key,
    required this.isDark,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.selected = false,
    this.selectedColor,
    this.blur = true,
  });

  @override
  Widget build(BuildContext context) {
    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        color: ComplaintUI.surface(isDark).withValues(alpha: isDark ? 0.6 : 0.78),
        borderRadius: AppRadius.large,
        border: Border.all(
          color: selected ? (selectedColor ?? ComplaintUI.accent(isDark)) : ComplaintUI.border(isDark),
          width: selected ? 1.6 : 1,
        ),
        boxShadow: AppShadows.card(isDark),
      ),
      child: child,
    );

    if (!blur) return ClipRRect(borderRadius: AppRadius.large, child: body);

    return ClipRRect(
      borderRadius: AppRadius.large,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: body,
      ),
    );
  }
}

/// Hover-aware wrapper for desktop/web — subtly lifts a card on mouse-over.
class ComplaintHoverLift extends StatefulWidget {
  final Widget child;
  const ComplaintHoverLift({super.key, required this.child});

  @override
  State<ComplaintHoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<ComplaintHoverLift> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovering ? -2 : 0, 0),
        child: widget.child,
      ),
    );
  }
}

// ─── BADGES / AVATAR ──────────────────────────────────────────────────────

class ComplaintStatusBadge extends StatelessWidget {
  final String status;
  final bool isDark;
  final bool glow;
  const ComplaintStatusBadge({super.key, required this.status, required this.isDark, this.glow = false});

  @override
  Widget build(BuildContext context) {
    final s = ComplaintUI.status(status, isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: s.soft,
        borderRadius: AppRadius.full,
        boxShadow: glow ? [BoxShadow(color: s.color.withValues(alpha: .45), blurRadius: 10, spreadRadius: 1)] : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(s.icon, size: 12, color: s.color),
        const SizedBox(width: 4),
        Text(status.replaceAll('_', ' '), style: AppTextStyles.labelSmall.copyWith(color: s.color)),
      ]),
    );
  }
}

class ComplaintMiniBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const ComplaintMiniBadge({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: AppRadius.full),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 11, color: color), const SizedBox(width: 4)],
        Text(label.toUpperCase(), style: AppTextStyles.labelSmall.copyWith(color: color)),
      ]),
    );
  }
}

class ComplaintTierBadge extends StatelessWidget {
  final String tier; // Premium / Regular / Artist
  const ComplaintTierBadge({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (tier.toLowerCase()) {
      case 'premium':
        color = const Color(0xFFB8860B);
        icon = Icons.workspace_premium_rounded;
        break;
      case 'artist':
        color = AppColors.info;
        icon = Icons.brush_rounded;
        break;
      default:
        color = AppColors.primary;
        icon = Icons.person_rounded;
    }
    return ComplaintMiniBadge(label: tier, color: color, icon: icon);
  }
}

class ComplaintCountPill extends StatelessWidget {
  final int count;
  final bool isDark;
  const ComplaintCountPill({super.key, required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = ComplaintUI.accent(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? accent.withValues(alpha: .16) : AppColors.primarySoft,
        borderRadius: AppRadius.full,
      ),
      child: Text('$count', style: AppTextStyles.labelLarge.copyWith(color: accent)),
    );
  }
}

class ComplaintAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final bool isDark;
  const ComplaintAvatar({super.key, required this.name, required this.isDark, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(gradient: ComplaintUI.avatarGradient(isDark), shape: BoxShape.circle),
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: AppTextStyles.h5.copyWith(color: Colors.white)),
    );
  }
}

// ─── EMPTY / LOADING STATES ───────────────────────────────────────────────

class ComplaintEmptyState extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;
  const ComplaintEmptyState({
    super.key,
    required this.isDark,
    this.title = 'No complaints available',
    this.subtitle = 'New customer support tickets will appear here.',
    this.icon = Icons.inbox_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        builder: (_, v, child) => Opacity(opacity: v, child: Transform.scale(scale: 0.9 + 0.1 * v, child: child)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [
                ComplaintUI.accent(isDark).withValues(alpha: .18),
                ComplaintUI.accent(isDark).withValues(alpha: .02),
              ]),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 52, color: ComplaintUI.accent(isDark)),
          ),
          const SizedBox(height: 20),
          Text(title, style: AppTextStyles.h4.copyWith(color: ComplaintUI.textPrimary(isDark))),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: ComplaintUI.textSecondary(isDark))),
        ]),
      ),
    );
  }
}

/// Shimmer skeleton block used for loading placeholders.
class ComplaintShimmerBlock extends StatefulWidget {
  final double height;
  final bool isDark;
  final BorderRadius? radius;
  const ComplaintShimmerBlock({super.key, required this.height, required this.isDark, this.radius});

  @override
  State<ComplaintShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ComplaintShimmerBlock> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(ComplaintUI.surface2(widget.isDark), ComplaintUI.border(widget.isDark), _c.value),
          borderRadius: widget.radius ?? AppRadius.large,
        ),
      ),
    );
  }
}

class ComplaintShimmerListPlaceholder extends StatelessWidget {
  final bool isDark;
  const ComplaintShimmerListPlaceholder({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => ComplaintShimmerBlock(height: 132, isDark: isDark),
    );
  }
}

class ComplaintShimmerDetailPlaceholder extends StatelessWidget {
  final bool isDark;
  const ComplaintShimmerDetailPlaceholder({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ComplaintShimmerBlock(height: 96, isDark: isDark), const SizedBox(height: 16),
        ComplaintShimmerBlock(height: 130, isDark: isDark), const SizedBox(height: 16),
        ComplaintShimmerBlock(height: 190, isDark: isDark), const SizedBox(height: 16),
        ComplaintShimmerBlock(height: 150, isDark: isDark),
      ],
    );
  }
}

// ─── CONFIRM DIALOG ───────────────────────────────────────────────────────

Future<bool> confirmComplaintAction(
  BuildContext context, {
  required bool isDark,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: ComplaintGlassCard(
        isDark: isDark,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(danger ? Icons.warning_rounded : Icons.help_outline_rounded,
                  color: danger ? AppColors.error : ComplaintUI.accent(isDark)),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppTextStyles.h5.copyWith(color: ComplaintUI.textPrimary(isDark)))),
            ]),
            const SizedBox(height: 12),
            Text(message, style: AppTextStyles.bodyMedium.copyWith(color: ComplaintUI.textSecondary(isDark))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: danger ? AppColors.error : ComplaintUI.accent(isDark),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}