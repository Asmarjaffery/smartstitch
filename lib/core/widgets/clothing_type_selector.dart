import 'package:flutter/material.dart';
import 'package:smartstitch/models/clothing_type.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

/// Horizontal chip selector for choosing a [ClothingType].
/// Used at the top of the Measurement screen.
class ClothingTypeSelector extends StatelessWidget {
  final ClothingType? selected;
  final void Function(ClothingType) onSelect;

  const ClothingTypeSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final type in ClothingType.values)
          _ClothingTypeChip(
            type: type,
            isSelected: type == selected,
            onTap: () => onSelect(type),
          ),
      ],
    );
  }
}

class _ClothingTypeChip extends StatelessWidget {
  final ClothingType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClothingTypeChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.medium,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.lightBorder.withOpacity(0.2),
          borderRadius: AppRadius.medium,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              type.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.lightTextSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}