import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/glass_card.dart';

class PremiumDashboardHeader extends StatelessWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onSearch;
  final VoidCallback? onNotifications;
  final int notificationCount;
  final String? avatarUrl;

  const PremiumDashboardHeader({
    super.key,
    this.onRefresh,
    this.onSearch,
    this.onNotifications,
    this.notificationCount = 0,
    this.avatarUrl,
  });

  String get _today {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // NOTE: the refresh / search / notifications / profile icon row (the
    // `_actions` row that used to live here) has been removed on purpose —
    // that row is now the only thing shown by the top teal app bar, so
    // repeating it in this white "Dashboard" card was redundant and made
    // the header look cluttered. Only the title block + date chip remain.
    return GlassCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      interactive: false,
      glowColor: AppColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 560;

          final titleBlock = Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.tealGlow,
                  borderRadius: AppRadius.medium,
                  boxShadow: AppShadows.glow(AppColors.primary, alpha: 0.35, blur: 18),
                ),
                child: const Icon(Icons.insights_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard',
                        style: AppTextStyles.h2.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        )),
                    const SizedBox(height: 2),
                    Text("Today's Business Insights",
                        style: AppTextStyles.sectionSubtitle.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        )),
                  ],
                ),
              ),
            ],
          );

          if (isMobile) {
            return titleBlock;
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: titleBlock),
              _DateChip(label: _today, isDark: isDark),
            ],
          );
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _DateChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
        borderRadius: AppRadius.full,
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded,
              size: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          const SizedBox(width: 8),
          Text(label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              )),
        ],
      ),
    );
  }
}