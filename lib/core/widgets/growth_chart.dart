import 'package:flutter/material.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/glass_card.dart';

class GrowthChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color barColor;
  final String title;
  final String? subtitle;

  const GrowthChart({
    Key? key,
    required this.values,
    required this.labels,
    required this.barColor,
    required this.title,
    this.subtitle,
  }) : super(key: key);

  double get _growthPercent {
    if (values.length < 2) return 0;
    final first = values.first == 0 ? 1 : values.first;
    return ((values.last - values.first) / first) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final growth = _growthPercent;
    final maxVal = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 1.0;

    return GlassCard(
      glowColor: barColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.sectionTitle.copyWith(color: textPrimary)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppTextStyles.sectionSubtitle.copyWith(color: textSecondary)),
                    ],
                  ],
                ),
              ),
              TrendBadge(value: growth),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            // A little taller than before, and — more importantly — the bar
            // itself now grows inside an Expanded/LayoutBuilder region below,
            // so it always sizes to whatever room is actually left after the
            // two text labels are laid out. That's what actually fixes the
            // "BOTTOM OVERFLOWED" error: previously the bar had a hardcoded
            // max height (120) that didn't account for real text heights.
            height: 172,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(values.length, (i) {
                final val = values[i];
                final label = i < labels.length ? labels[i] : '';
                final ratio = maxVal == 0 ? 0.0 : val / maxVal;
                final isLast = i == values.length - 1;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        val.toStringAsFixed(0),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isLast ? barColor : textSecondary,
                          fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Bar now claims whatever vertical space remains after
                      // the two text rows + spacing, instead of assuming a
                      // fixed 120px. This is the part that eliminates the
                      // overflow regardless of font scaling or label length.
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxBarHeight = constraints.maxHeight;
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: ratio),
                                duration: Duration(milliseconds: 700 + i * 80),
                                curve: Curves.easeOutCubic,
                                builder: (context, t, _) => Container(
                                  height: (t * maxBarHeight).clamp(4.0, maxBarHeight),
                                  margin: const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [barColor, barColor.withValues(alpha: 0.55)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow:
                                        isLast ? AppShadows.glow(barColor, alpha: 0.35, blur: 12) : null,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: AppTextStyles.caption.copyWith(color: textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}