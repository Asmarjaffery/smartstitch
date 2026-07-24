import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/widgets/clothing_type_selector.dart';
import 'package:smartstitch/core/widgets/measurement_field_input.dart';
import 'package:smartstitch/core/widgets/measurement_history_card.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/models/body_measurement_model.dart';
import 'package:smartstitch/models/clothing_type.dart';
import 'package:smartstitch/models/measurement_field.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/user/measurement/measurement_controller.dart';


class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({super.key});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  Future<void> _launchAiScanner(BuildContext context) async {
    final type = MeasurementController.to.selectedClothingType.value;
    if (type == null) {
      AppHelpers.showError('Please select what you\'d like to stitch first.');
      return;
    }
    if (type == ClothingType.custom &&
        MeasurementController.to.customSelectedFields.isEmpty) {
      final fields = await _showCustomFieldPicker(context);
      if (fields == null || fields.isEmpty) return;
      MeasurementController.to.setCustomFields(fields);
    }

    final ctrl = TextEditingController();
    final height = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
        title: const Text('Your Height', style: AppTextStyles.h4),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Height (cm)',
            suffixText: 'cm',
            hintText: 'e.g. 170',
            border: OutlineInputBorder(borderRadius: AppRadius.medium),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val == null || val < 50 || val > 250) {
                AppHelpers.showError('Enter a valid height between 50–250 cm');
                return;
              }
              Navigator.pop(ctx, val);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
            ),
            child: Text('Start Scan',
                style: AppTextStyles.button.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
    if (height != null) {
      Get.toNamed(AppRoutes.aiScanner, arguments: height);
    }
  }

  /// Checklist shown only for [ClothingType.custom] so the customer picks
  /// exactly which measurements they want to provide.
  Future<Set<MeasurementField>?> _showCustomFieldPicker(
      BuildContext context) async {
    final selected = <MeasurementField>{...MeasurementController.to.customSelectedFields};

    return showModalBottomSheet<Set<MeasurementField>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints:
                BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choose Your Measurements', style: AppTextStyles.h4),
                Text(
                  'Pick every measurement you want to provide',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.lightTextSecondary),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final field in ClothingMeasurementRegistry.allFields)
                          CheckboxListTile(
                            value: selected.contains(field),
                            title: Text(MeasurementFieldRegistry.specOf(field).label),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (checked) {
                              setSheetState(() {
                                if (checked == true) {
                                  selected.add(field);
                                } else {
                                  selected.remove(field);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.pop(ctx, selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium),
                    ),
                    child: Text('Continue',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showManualEntrySheet(BuildContext context) async {
    final type = MeasurementController.to.selectedClothingType.value;
    if (type == null) {
      AppHelpers.showError('Please select what you\'d like to stitch first.');
      return;
    }

    Set<MeasurementField> customFields = {...MeasurementController.to.customSelectedFields};
    if (type == ClothingType.custom) {
      final picked = await _showCustomFieldPicker(context);
      if (picked == null || picked.isEmpty) return;
      customFields = picked;
      MeasurementController.to.setCustomFields(picked);
    }

    final fields = type == ClothingType.custom
        ? customFields.toList()
        : ClothingMeasurementRegistry.of(type).displayFields;
    final requiredFields = type == ClothingType.custom
        ? customFields
        : ClothingMeasurementRegistry.of(type).required;

    final controllers = <MeasurementField, TextEditingController>{
      for (final f in fields) f: TextEditingController(),
    };

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(type.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text('${type.label} Measurements', style: AppTextStyles.h4),
                ],
              ),
              Text(
                'All values in cm',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final field in fields)
                        MeasurementFieldInput(
                          controller: controllers[field]!,
                          field: field,
                          required: requiredFields.contains(field),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: MeasurementController.to.isLoading.value
                          ? null
                          : () async {
                              await MeasurementController.to.saveManualMeasurement(
                                clothingType: type,
                                rawValues: {
                                  for (final f in fields) f: controllers[f]!.text,
                                },
                                customFields: customFields,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                      ),
                      child: MeasurementController.to.isLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Save',
                              style: AppTextStyles.labelLarge
                                  .copyWith(color: Colors.white),
                            ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, BodyMeasurementModel m) {
    final fields = m.activeFields;
    final requiredFields = m.clothingType == ClothingType.custom
        ? fields.toSet()
        : ClothingMeasurementRegistry.of(m.clothingType).required;

    final controllers = <MeasurementField, TextEditingController>{
      for (final f in fields)
        f: TextEditingController(text: (m.valueOf(f) ?? 0).toString()),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(m.clothingType.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text('Edit ${m.clothingType.label} Measurements',
                      style: AppTextStyles.h4),
                ],
              ),
              Text(
                'All values in cm',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final field in fields)
                        MeasurementFieldInput(
                          controller: controllers[field]!,
                          field: field,
                          required: requiredFields.contains(field),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: MeasurementController.to.isLoading.value
                          ? null
                          : () async {
                              final errors = _validateEditFields(
                                m.clothingType,
                                fields,
                                requiredFields,
                                controllers,
                              );
                              if (errors.isNotEmpty) {
                                AppHelpers.showError(errors.first);
                                return;
                              }
                              final updated = _applyFieldValues(m, controllers);
                              await MeasurementController.to
                                  .updateMeasurement(updated);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                      ),
                      child: MeasurementController.to.isLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Update',
                              style: AppTextStyles.labelLarge
                                  .copyWith(color: Colors.white),
                            ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Get.put(MeasurementController());
    final ctrl = MeasurementController.to;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Body Measurements', style: AppTextStyles.h4),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What would you like to stitch?', style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(
              'We\'ll only ask for the measurements that garment needs.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 14),
            Obx(() => ClothingTypeSelector(
                  selected: ctrl.selectedClothingType.value,
                  onSelect: ctrl.selectClothingType,
                )),
            const SizedBox(height: 24),
            Obx(() {
              final type = ctrl.selectedClothingType.value;
              if (type == null) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightBorder.withOpacity(0.3),
                    borderRadius: AppRadius.large,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.lightTextSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Select a garment above to unlock AI scan and manual entry.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.lightTextSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppRadius.large,
                      boxShadow: AppShadows.primary,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              'AI Body Scan',
                              style:
                                  AppTextStyles.h4.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use your camera to automatically detect ${type.label.toLowerCase()} measurements with 90%+ accuracy.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () => _launchAiScanner(context),
                            icon: const Icon(Icons.auto_awesome,
                                color: AppColors.primary),
                            label: Text(
                              'Start AI Scan',
                              style: AppTextStyles.labelLarge
                                  .copyWith(color: AppColors.primary),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.medium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _showManualEntrySheet(context),
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.primary),
                      label: Text(
                        'Enter Manually',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: ctrl.resetClothingTypeSelection,
                    child: const Text('Change garment'),
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            const Text('History', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (ctrl.history.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.straighten_rounded,
                            size: 60, color: AppColors.lightTextSecondary),
                        const SizedBox(height: 12),
                        Text(
                          'No measurements yet',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ctrl.history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => MeasurementHistoryCard(
                  measurement: ctrl.history[i],
                  onEdit: () => _showEditSheet(context, ctrl.history[i]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<String> _validateEditFields(
    ClothingType type,
    List<MeasurementField> fields,
    Set<MeasurementField> requiredFields,
    Map<MeasurementField, TextEditingController> controllers,
  ) {
    final errors = <String>[];
    for (final field in fields) {
      final spec = MeasurementFieldRegistry.specOf(field);
      final text = controllers[field]!.text.trim();
      final required = requiredFields.contains(field);
      if (text.isEmpty) {
        if (required) errors.add('${spec.label} is required');
        continue;
      }
      final value = double.tryParse(text);
      if (value == null) {
        errors.add('${spec.label} must be a number');
      } else if (value <= 0) {
        errors.add('${spec.label} must be greater than zero');
      } else if (value < spec.min || value > spec.max) {
        errors.add(
            '${spec.label} must be between ${spec.min.toStringAsFixed(0)}-${spec.max.toStringAsFixed(0)} cm');
      }
    }
    return errors;
  }

  /// Applies edited text values on top of the original record, keeping
  /// every field that wasn't in this record's active set untouched.
  BodyMeasurementModel _applyFieldValues(
    BodyMeasurementModel original,
    Map<MeasurementField, TextEditingController> controllers,
  ) {
    double? val(MeasurementField f) {
      final c = controllers[f];
      if (c == null) return original.valueOf(f);
      final parsed = double.tryParse(c.text.trim());
      return parsed ?? original.valueOf(f);
    }

    return original.copyWith(
      height: val(MeasurementField.height),
      chest: val(MeasurementField.chest),
      waist: val(MeasurementField.waist),
      shoulder: val(MeasurementField.shoulder),
      hips: val(MeasurementField.hips),
      sleevLength: val(MeasurementField.sleeveLength),
      inseam: val(MeasurementField.inseam),
      neck: val(MeasurementField.neck),
      wrist: val(MeasurementField.wrist),
      shirtLength: val(MeasurementField.shirtLength),
      outseam: val(MeasurementField.outseam),
      thigh: val(MeasurementField.thigh),
      knee: val(MeasurementField.knee),
      bottomWidth: val(MeasurementField.bottomWidth),
      trouserLength: val(MeasurementField.trouserLength),
    );
  }
}