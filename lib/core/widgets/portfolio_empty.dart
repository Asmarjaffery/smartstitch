import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smartstitch/core/theme/app.theme.dart';

class PortfolioEmpty extends StatelessWidget {
  const PortfolioEmpty({
    super.key,
    required this.onCreate,
  });

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                size: 60,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 28),

            Text(
              "No Portfolio Yet",
              textAlign: TextAlign.center,
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Start showcasing your tailoring work.\nCreate your first service and it will automatically appear here.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: 220,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text(
                  "Create Service",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}