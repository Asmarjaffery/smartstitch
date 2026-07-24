import 'package:flutter/material.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/measurement_chip.dart';
import 'package:smartstitch/models/body_measurement_model.dart';
import 'package:smartstitch/models/clothing_type.dart';
import 'package:smartstitch/models/measurement_field.dart';
import 'package:smartstitch/user/measurement/measurement_controller.dart';


/// One row in the measurement history list. Only ever shows the fields
/// that actually belong to the record's clothing type — e.g. a Trouser
/// entry never shows a Chest chip.
class MeasurementHistoryCard extends StatelessWidget {
  final BodyMeasurementModel measurement;
  final VoidCallback onEdit;

  const MeasurementHistoryCard({
    super.key,
    required this.measurement,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _TypeBadge(measurement: measurement)),
              Row(
                children: [
                  if (measurement.isAiGenerated)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: const BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: AppRadius.full,
                      ),
                      child: Text(
                        '${(measurement.aiAccuracyScore * 100).toInt()}% accuracy',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.success),
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onEdit,
                    child: const Icon(Icons.edit_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => MeasurementController.to
                        .deleteMeasurement(measurement.id),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(measurement.measuredAt),
            style: AppTextStyles.caption
                .copyWith(color: AppColors.lightTextSecondary),
          ),
          const Divider(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final field in measurement.activeFields)
                if (measurement.valueOf(field) != null)
                  MeasurementChip(
                    label: MeasurementFieldRegistry.specOf(field).label,
                    value: measurement.valueOf(field)!,
                  ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TypeBadge extends StatelessWidget {
  final BodyMeasurementModel measurement;
  const _TypeBadge({required this.measurement});

  @override
  Widget build(BuildContext context) {
    final type = measurement.clothingType;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color:
                measurement.isAiGenerated ? AppColors.primarySoft : AppColors.lightBorder,
            borderRadius: AppRadius.small,
          ),
          child: Icon(
            measurement.isAiGenerated ? Icons.auto_awesome : Icons.edit_outlined,
            color: measurement.isAiGenerated
                ? AppColors.primary
                : AppColors.lightTextSecondary,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '${type.emoji} ${type.label} (${measurement.isAiGenerated ? 'AI' : 'Manual'})',
            style: AppTextStyles.labelMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}