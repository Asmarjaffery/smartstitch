import 'package:flutter/material.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/glass_card.dart';

class RevenueCard extends StatelessWidget {
  final String title;
  final double value;
  final double? percentageChange;
  final IconData icon;
  final Color accentColor;
  final List<double>? sparklineData;

  const RevenueCard({
    Key? key,
    required this.title,
    required this.value,
    this.percentageChange,
    required this.icon,
    required this.accentColor,
    this.sparklineData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final spark = sparklineData ?? _fallbackSparkline(value);

    return GlassCard(
      glowColor: accentColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(color: textSecondary),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor.withValues(alpha: 0.22), accentColor.withValues(alpha: 0.08)],
                  ),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedMetric(
            value: value,
            formatter: (v) => formatCurrency(v),
            style: AppTextStyles.metricValue.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 6),
          if (percentageChange != null)
            Row(
              children: [
                TrendBadge(value: percentageChange!),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'vs last period',
                    style: AppTextStyles.caption.copyWith(color: textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          Sparkline(values: spark, color: accentColor, height: 28),
        ],
      ),
    );
  }

  List<double> _fallbackSparkline(double v) {
    final base = v <= 0 ? 1.0 : v;
    return [base * 0.6, base * 0.7, base * 0.65, base * 0.85, base * 0.78, base * 0.95, base];
  }
}