import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

/// ─── Step Progress Header ─────────────────────────────────────
class StepProgressHeader extends StatelessWidget {
  final int currentStep;
  final bool isDark;

  static const List<String> _labels = [
    'Images',
    'Basic Info',
    'Details',
    'Pricing',
    'Publish'
  ];
  static const List<IconData> _icons = [
    Icons.photo_library_outlined,
    Icons.info_outline,
    Icons.checklist_outlined,
    Icons.sell_outlined,
    Icons.rocket_launch_outlined,
  ];

  const StepProgressHeader(
      {super.key, required this.currentStep, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final Color active = AppColors.primary;
    final Color inactive = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final Color textActive =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final Color textInactive =
        isDark ? AppColors.darkTextHint : AppColors.lightTextHint;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Row(
        children: List.generate(_labels.length, (i) {
          final bool isActive = i == currentStep;
          final bool isDone = i < currentStep;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i != 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isDone || isActive ? active : inactive,
                        ),
                      ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? active
                            : isActive
                                ? active.withValues(alpha: 0.15)
                                : Colors.transparent,
                        border: Border.all(
                            color: isActive || isDone ? active : inactive,
                            width: 1.5),
                      ),
                      child: Icon(
                        isDone ? Icons.check : _icons[i],
                        size: 16,
                        color: isDone
                            ? Colors.white
                            : (isActive ? active : textInactive),
                      ),
                    ),
                    if (i != _labels.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isDone ? active : inactive,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _labels[i],
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isActive || isDone ? textActive : textInactive,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// ─── Section Card Wrapper ──────────────────────────────────────
class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool isDark;

  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.large,
        border:
            Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.sectionTitle.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: AppTextStyles.sectionSubtitle.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary)),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// ─── Choice Chip Group (Single / Multi Select) ──────────────────
class ChipGroup extends StatelessWidget {
  final List<String> options;
  final bool Function(String) isSelected;
  final void Function(String) onTap;
  final bool isDark;

  const ChipGroup({
    super.key,
    required this.options,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final bool selected = isSelected(opt);
        return GestureDetector(
          onTap: () => onTap(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkSurface2 : AppColors.primarySoft),
              borderRadius: AppRadius.full,
              border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            child: Text(
              opt,
              style: AppTextStyles.labelMedium.copyWith(
                color: selected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextSecondary : AppColors.primaryDark),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// ─── Toggle Setting Tile ─────────────────────────────────────────
class ToggleSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const ToggleSettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.small,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.labelLarge.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }
}

/// ─── Image Thumbnail (Web-safe via bytes, works on Android/iOS/Web) ───
class XFileThumb extends StatelessWidget {
  final XFile file;
  final double size;
  final VoidCallback? onRemove;
  final BorderRadius radius;

  const XFileThumb({
    super.key,
    required this.file,
    this.size = 100,
    this.onRemove,
    this.radius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: radius,
          child: FutureBuilder<Uint8List>(
            future: file.readAsBytes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  width: size,
                  height: size,
                  color: Colors.grey.withValues(alpha: 0.2),
                );
              }
              return Image.memory(snapshot.data!,
                  width: size, height: size, fit: BoxFit.cover);
            },
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration:
                    const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }
}

/// ─── Bottom Navigation Footer ─────────────────────────────────────
class ServiceBottomNav extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isDark;
  final bool isBusy;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback? onSaveDraft;

  const ServiceBottomNav({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.isDark,
    required this.isBusy,
    required this.onBack,
    required this.onNext,
    this.onSaveDraft,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLast = currentStep == totalSteps - 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: AppShadows.card(isDark),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : onBack,
                  child: const Text('Back'),
                ),
              ),
            if (currentStep > 0) const SizedBox(width: 12),
            if (!isLast && onSaveDraft != null)
              Expanded(
                child: TextButton(
                  onPressed: isBusy ? null : onSaveDraft,
                  child: const Text('Save Draft'),
                ),
              ),
            if (!isLast && onSaveDraft != null) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isBusy ? null : onNext,
                child: isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(isLast ? 'Publish Service' : 'Next Step'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Searchable Predefined-Service Dropdown ─────────────────────
/// Tap to open a searchable bottom sheet listing services fetched from
/// the existing 'services' collection (filtered by the artist's locked
/// category). Selecting one auto-fills Name / Description / Price.
class SearchableServiceDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final bool isDark;
  final bool isLoading;

  const SearchableServiceDropdown({
    super.key,
    required this.services,
    required this.selected,
    required this.onSelect,
    required this.isDark,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : () => _openPicker(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
          borderRadius: AppRadius.medium,
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.checklist_rtl_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isLoading
                    ? 'Loading services...'
                    : (selected != null ? (selected!['name'] ?? '') : 'Select a service'),
                style: AppTextStyles.bodyMedium.copyWith(
                    color: selected != null
                        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                        : (isDark ? AppColors.darkTextHint : AppColors.lightTextHint)),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ],
        ),
      ),
    );
  }

  void _openPicker(BuildContext context) {
    if (services.isEmpty) {
      Get.snackbar(
        'No Services Found',
        'No predefined services exist for your category yet. Contact admin.',
        backgroundColor: const Color(0xFFF59E0B),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ServicePickerSheet(
        services: services,
        isDark: isDark,
        onSelect: onSelect,
      ),
    );
  }
}

class _ServicePickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> services;
  final bool isDark;
  final ValueChanged<Map<String, dynamic>> onSelect;

  const _ServicePickerSheet({
    required this.services,
    required this.isDark,
    required this.onSelect,
  });

  @override
  State<_ServicePickerSheet> createState() => _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<_ServicePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.trim().isEmpty
        ? widget.services
        : widget.services
            .where((s) =>
                (s['name'] ?? '').toString().toLowerCase().contains(_query.toLowerCase()))
            .toList();

    final Color textPrimary =
        widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final Color textSecondary =
        widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Select a Service', style: AppTextStyles.h4.copyWith(color: textPrimary)),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search services...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: widget.isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
              border: OutlineInputBorder(
                  borderRadius: AppRadius.medium, borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                        child: Text('No matching services',
                            style: AppTextStyles.bodyMedium.copyWith(color: textSecondary))),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: widget.isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    itemBuilder: (context, i) {
                      final s = filtered[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(s['name'] ?? '',
                            style: AppTextStyles.labelLarge.copyWith(color: textPrimary)),
                        subtitle: Text(
                          s['description'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(color: textSecondary),
                        ),
                        trailing: Text('Rs. ${s['price'] ?? 0}',
                            style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                        onTap: () {
                          widget.onSelect(s);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}