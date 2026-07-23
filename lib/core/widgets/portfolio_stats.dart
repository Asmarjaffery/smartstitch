import 'package:flutter/material.dart';

import 'package:smartstitch/core/theme/app.theme.dart';

class PortfolioStats extends StatelessWidget {
  const PortfolioStats({
    super.key,
    required this.total,
    required this.published,
    required this.draft,
  });

  final int total;
  final int published;
  final int draft;

  @override
  Widget build(BuildContext context) {

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [

        Expanded(
          child: _statCard(
            context,
            icon: Icons.collections_outlined,
            title: "Total",
            value: total.toString(),
            color: AppColors.primary,
            isDark: isDark,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _statCard(
            context,
            icon: Icons.check_circle_outline,
            title: "Published",
            value: published.toString(),
            color: AppColors.success,
            isDark: isDark,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _statCard(
            context,
            icon: Icons.edit_note_outlined,
            title: "Draft",
            value: draft.toString(),
            color: AppColors.warning,
            isDark: isDark,
          ),
        ),

      ],
    );
  }


  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {

    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(

        color: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,

        borderRadius: AppRadius.medium,

        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
        ),

        boxShadow:
            AppShadows.card(isDark),

      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Container(
            padding:
                const EdgeInsets.all(8),

            decoration: BoxDecoration(
              color:
                  color.withValues(alpha: .12),

              borderRadius:
                  AppRadius.small,
            ),

            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),


          const SizedBox(height: 12),


          Text(
            value,

            style:
                AppTextStyles.h3.copyWith(
              fontWeight:
                  FontWeight.bold,

              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),


          const SizedBox(height: 2),


          Text(
            title,

            style:
                AppTextStyles.bodySmall
                    .copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),

        ],
      ),
    );
  }
}