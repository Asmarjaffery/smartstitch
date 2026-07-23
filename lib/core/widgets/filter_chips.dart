import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/admin/analytics/analytics_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/glass_card.dart';
import 'package:smartstitch/models/enums.dart';

class FilterChips extends StatelessWidget {
  final AnalyticsController controller;

  const FilterChips({Key? key, required this.controller}) : super(key: key);

  String _labelFor(AnalyticsFilter filter) {
    switch (filter) {
      case AnalyticsFilter.today:
        return 'Today';
      case AnalyticsFilter.last7Days:
        return 'This Week';
      case AnalyticsFilter.last30Days:
        return 'Last 30 Days';
      case AnalyticsFilter.last6Months:
        return 'Last 6 Months';
      case AnalyticsFilter.lastYear:
        return 'This Year';
      case AnalyticsFilter.custom:
        return 'Custom Range';
    }
  }

  IconData _iconFor(AnalyticsFilter filter) {
    switch (filter) {
      case AnalyticsFilter.today:
        return Icons.today_rounded;
      case AnalyticsFilter.last7Days:
        return Icons.view_week_rounded;
      case AnalyticsFilter.last30Days:
        return Icons.date_range_rounded;
      case AnalyticsFilter.last6Months:
        return Icons.calendar_view_month_rounded;
      case AnalyticsFilter.lastYear:
        return Icons.history_rounded;
      case AnalyticsFilter.custom:
        return Icons.tune_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final selected = controller.selectedFilter.value;

      return GlassCard(
        radius: AppRadius.full,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        interactive: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: AnalyticsFilter.values.map((filter) {
              final isSelected = filter == selected;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.tealGlow : null,
                    borderRadius: AppRadius.full,
                    boxShadow: isSelected ? AppShadows.glow(AppColors.primary, alpha: 0.32, blur: 16) : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: AppRadius.full,
                      onTap: () => controller.setFilter(filter),
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _iconFor(filter),
                              size: 15,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              _labelFor(filter),
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }
}