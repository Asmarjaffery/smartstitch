import 'package:flutter/material.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import '../../models/wallet_models.dart';


// ─── COLOR TOKENS (now mapped to the app's single source of truth: AppColors) ─

class WalletColors {
  WalletColors._();

  static const teal900 = AppColors.primaryDark;
  static const teal700 = AppColors.primary;
  static const teal400 = AppColors.primaryLight;
  static const teal100 = AppColors.primarySoft;

  // Aliases used by the withdraw screen — kept alongside the teal* tokens
  // above so both naming schemes work without breaking existing callers.
  static const primary = AppColors.primary;
  static const primaryDark = AppColors.primaryDark;
  static const primaryLight = AppColors.primaryLight;

  // Screen/page backgrounds
  static const lightBg = Color(0xFFF7F9FA);
  static const darkBg = Color(0xFF0F1115);

  // Card surfaces
  static const cardLight = Colors.white;
  static const cardDark = Color(0xFF1B1E24);

  static const amber = AppColors.warning;
  static const amberBg = AppColors.warningSoft;
  static const amberText = Color(0xFF92400E);

  static const green = AppColors.success;
  static const greenBg = AppColors.successSoft;

  static const red = AppColors.error;
  static const redBg = AppColors.errorSoft;

  static const purple = Color(0xFF8B5CF6);
  static const purpleBg = Color(0xFFEDE9FE);

  static const blue = AppColors.info;
  static const blueBg = AppColors.infoSoft;

  /// Dark-mode aware soft background for a status color.
  static Color softBg(BuildContext context, Color base) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) return base;
    if (base == greenBg) return AppColors.successSoftDark;
    if (base == amberBg) return AppColors.warningSoftDark;
    if (base == redBg) return AppColors.errorSoftDark;
    if (base == blueBg) return AppColors.infoSoftDark;
    return base;
  }
}

// ─── SHIMMER BOX ──────────────────────────────────────────────────────────────

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1 + 2 * _anim.value, 0),
            end: Alignment(1 + 2 * _anim.value, 0),
            colors: const [
              Color(0x22FFFFFF),
              Color(0x55FFFFFF),
              Color(0x22FFFFFF),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SECTION HEADER ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── WALLET STAT CARD ─────────────────────────────────────────────────────────

class WalletStatCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const WalletStatCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withValues(alpha: 0.15) : iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(height: 12),
          Text(
            _fmt(amount),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      'Rs. ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

// ─── STATUS BADGE ─────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
  });

  factory StatusBadge.fromTransactionStatus(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return const StatusBadge(
          label: 'Completed',
          color: WalletColors.green,
          bg: WalletColors.greenBg,
          icon: Icons.check_circle_rounded,
        );
      case TransactionStatus.pending:
        return const StatusBadge(
          label: 'Pending',
          color: WalletColors.amber,
          bg: WalletColors.amberBg,
          icon: Icons.access_time_rounded,
        );
      case TransactionStatus.cancelled:
        return const StatusBadge(
          label: 'Cancelled',
          color: WalletColors.red,
          bg: WalletColors.redBg,
          icon: Icons.cancel_rounded,
        );
      case TransactionStatus.failed:
        return const StatusBadge(
          label: 'Failed',
          color: WalletColors.red,
          bg: WalletColors.redBg,
          icon: Icons.error_rounded,
        );
    }
  }

  factory StatusBadge.fromWithdrawalStatus(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.pending:
        return const StatusBadge(
          label: 'Pending Review',
          color: WalletColors.amber,
          bg: WalletColors.amberBg,
          icon: Icons.hourglass_top_rounded,
        );
      case WithdrawalStatus.approved:
        return const StatusBadge(
          label: 'Approved',
          color: WalletColors.blue,
          bg: WalletColors.blueBg,
          icon: Icons.verified_rounded,
        );
      case WithdrawalStatus.paid:
        return const StatusBadge(
          label: 'Paid',
          color: WalletColors.green,
          bg: WalletColors.greenBg,
          icon: Icons.check_circle_rounded,
        );
      case WithdrawalStatus.rejected:
        return const StatusBadge(
          label: 'Rejected',
          color: WalletColors.red,
          bg: WalletColors.redBg,
          icon: Icons.cancel_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBg = WalletColors.softBg(context, bg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WALLET STATUS VISUAL (lightweight enum used by withdrawal history UI) ────
// Mirrors WithdrawalStatus so screens can render a badge without importing
// the raw model enum directly.

enum WalletStatusVisual { pending, approved, paid, rejected }

extension WalletStatusVisualX on WalletStatusVisual {
  WithdrawalStatus get toWithdrawalStatus {
    switch (this) {
      case WalletStatusVisual.pending:
        return WithdrawalStatus.pending;
      case WalletStatusVisual.approved:
        return WithdrawalStatus.approved;
      case WalletStatusVisual.paid:
        return WithdrawalStatus.paid;
      case WalletStatusVisual.rejected:
        return WithdrawalStatus.rejected;
    }
  }
}

class WalletStatusBadge extends StatelessWidget {
  final WalletStatusVisual status;

  const WalletStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StatusBadge.fromWithdrawalStatus(status.toWithdrawalStatus);
  }
}

// ─── PREMIUM BUTTON ───────────────────────────────────────────────────────────
// onTap is nullable: pass null to render the button in a disabled state
// (dimmed, no tap handler) instead of forcing callers to supply a no-op.

class PremiumButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const PremiumButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final disabled = onTap == null;

    return GestureDetector(
      onTap: (isLoading || disabled) ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primary.withValues(alpha: 0.85),
                primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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

// ─── WALLET CARD ──────────────────────────────────────────────────────────────
// Generic themed card surface reused across wallet screens (history items,
// confirm sheets, empty states, etc).

class WalletCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const WalletCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? WalletColors.cardDark : WalletColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── WALLET EMPTY STATE ───────────────────────────────────────────────────────

class WalletEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const WalletEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WALLET SKELETON LOADER ───────────────────────────────────────────────────

class WalletSkeletonLoader extends StatefulWidget {
  const WalletSkeletonLoader({super.key});

  @override
  State<WalletSkeletonLoader> createState() => _WalletSkeletonLoaderState();
}

class _WalletSkeletonLoaderState extends State<WalletSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.onSurface.withValues(alpha: 0.06);
    final highlight = theme.colorScheme.onSurface.withValues(alpha: 0.12);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final color = Color.lerp(base, highlight, _anim.value)!;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(w: 200, h: 14, color: color),
              const SizedBox(height: 10),
              _SkeletonBox(w: 150, h: 36, color: color),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _SkeletonBox(h: 80, color: color)),
                  const SizedBox(width: 12),
                  Expanded(child: _SkeletonBox(h: 80, color: color)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _SkeletonBox(h: 80, color: color)),
                  const SizedBox(width: 12),
                  Expanded(child: _SkeletonBox(h: 80, color: color)),
                ],
              ),
              const SizedBox(height: 24),
              _SkeletonBox(w: 160, h: 16, color: color),
              const SizedBox(height: 12),
              _SkeletonBox(h: 72, color: color),
              const SizedBox(height: 10),
              _SkeletonBox(h: 72, color: color),
              const SizedBox(height: 10),
              _SkeletonBox(h: 72, color: color),
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? w;
  final double h;
  final Color color;

  const _SkeletonBox({this.w, required this.h, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

// ─── INFO CHIP ────────────────────────────────────────────────────────────────

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = WalletColors.softBg(context, bg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DETAIL ROW ───────────────────────────────────────────────────────────────

class WalletDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const WalletDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon,
              size: 17,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}