import 'package:flutter/material.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/glass_card.dart';

class BookingStatsCard extends StatelessWidget {
  final int totalBookings;
  final int completedBookings;
  final int activeBookings;
  final int cancelledBookings;
  final double successRate;
  final double cancellationRate;

  const BookingStatsCard({
    Key? key,
    required this.totalBookings,
    required this.completedBookings,
    required this.activeBookings,
    required this.cancelledBookings,
    required this.successRate,
    required this.cancellationRate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GlassCard(
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Booking Analytics', style: AppTextStyles.sectionTitle.copyWith(color: textPrimary)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _kpiPill(
                  label: 'Total',
                  value: totalBookings,
                  color: AppColors.info,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kpiPill(
                  label: 'Completed',
                  value: completedBookings,
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _kpiPill(
                  label: 'Active',
                  value: activeBookings,
                  color: AppColors.warning,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kpiPill(
                  label: 'Cancelled',
                  value: cancelledBookings,
                  color: AppColors.error,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _circularRate(
                  label: 'Success Rate',
                  rate: successRate,
                  color: AppColors.success,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              Expanded(
                child: _circularRate(
                  label: 'Cancellation Rate',
                  rate: cancellationRate,
                  color: AppColors.error,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiPill({required String label, required int value, required Color color, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.10 : 0.08),
        borderRadius: AppRadius.medium,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedMetric(
            value: value.toDouble(),
            formatter: (v) => v.toStringAsFixed(0),
            style: AppTextStyles.h4.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ],
      ),
    );
  }

  Widget _circularRate({
    required String label,
    required double rate,
    required Color color,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 84,
          height: 84,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (rate / 100).clamp(0, 1)),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: CircularProgressIndicator(
                    value: t,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Text('${(t * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.labelLarge.copyWith(color: textPrimary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.caption.copyWith(color: textSecondary), textAlign: TextAlign.center),
      ],
    );
  }
}