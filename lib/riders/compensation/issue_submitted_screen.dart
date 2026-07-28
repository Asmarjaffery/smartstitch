import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/routes/routes.dart';

/// Step 3 — final confirmation after a rider's report is written to
/// Firestore. Purely a "you're done" screen; no further actions besides
/// heading back to the order list.
class IssueSubmittedScreen extends StatelessWidget {
  const IssueSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 64),
              ),
              const SizedBox(height: 28),
              Text(
                'Delivery Issue Submitted',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Your report has been sent to admin for review.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: AppRadius.medium,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'You will be notified once the compensation is approved.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Back to Orders'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
