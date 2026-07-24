import 'package:flutter/material.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

/// Small pill showing "Label: value cm". Extracted from the old
/// `_MeasurementChip` so both history and edit-preview UIs can share it.
class MeasurementChip extends StatelessWidget {
  final String label;
  final double value;

  const MeasurementChip({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadius.small,
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.lightTextSecondary),
            ),
            TextSpan(
              text: '${value.toStringAsFixed(1)} cm',
              style:
                  AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}