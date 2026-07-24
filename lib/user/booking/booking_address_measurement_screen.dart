import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/core/widgets/clothing_type_selector.dart';
import 'package:smartstitch/models/address_model.dart';
import 'package:smartstitch/models/clothing_type.dart';
import 'package:smartstitch/models/measurement_field.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/user/booking/booking_controller.dart';
import 'package:smartstitch/user/measurement/measurement_controller.dart';
import 'package:smartstitch/user/profile/profile_controller.dart';
import 'package:uuid/uuid.dart';

class BookingAddressMeasurementScreen extends StatelessWidget {
  const BookingAddressMeasurementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(MeasurementController());
    final ctrl = BookingController.to;
    final measCtrl = MeasurementController.to;
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AuthController.to.reloadCurrentUser();
      await measCtrl.loadHistory();
      if (ctrl.selectedMeasurement.value == null &&
          measCtrl.history.isNotEmpty) {
        ctrl.selectedMeasurement.value = measCtrl.history.first;
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Address & Measurements', style: AppTextStyles.h4),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepIndicator(currentStep: 2),
            const SizedBox(height: 28),

            // ─── Address Section ────
            Obx(() {
              if (!ctrl.isHomeVisit.value) return const SizedBox();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: AppRadius.small,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text('Your Address', style: AppTextStyles.h4),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Artist will come to this address.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Add New Address Button ──
                  OutlinedButton.icon(
                    onPressed: () => _showAddAddressSheet(context),
                    icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                    label: Text(
                      'Add New Address',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Obx(() {
                    final addresses =
                        AuthController.to.currentUser.value?.addresses ?? [];

                    if (addresses.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                        color: AppColors.warningSoft,
                          borderRadius: AppRadius.medium,
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppColors.warning),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No address found. Please add address in Profile first.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: addresses
                          .map(
                            (addr) => Obx(
                              () => GestureDetector(
                                onTap: () => ctrl.selectedAddress.value = addr,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: ctrl.selectedAddress.value?.id ==
                                            addr.id
                                        ? AppColors.primarySoft
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: AppRadius.medium,
                                    border: Border.all(
                                      color: ctrl.selectedAddress.value?.id ==
                                              addr.id
                                          ? AppColors.primary
                                          : Theme.of(context).colorScheme.outline,
                                      width: ctrl.selectedAddress.value?.id ==
                                              addr.id
                                          ? 1.5
                                          : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        color: ctrl.selectedAddress.value?.id ==
                                                addr.id
                                            ? AppColors.primary
                                            : Theme.of(context).textTheme.bodySmall?.color,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(addr.label,
                                                style:
                                                    AppTextStyles.labelLarge),
                                            Text(
                                              '${addr.fullAddress}, ${addr.city}',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: AppColors
                                                    .lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (ctrl.selectedAddress.value?.id ==
                                          addr.id)
                                        const Icon(Icons.check_circle_rounded,
                                            color: AppColors.primary, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }),

                  const SizedBox(height: 32),
                ],
              );
            }),

            // ─── Measurements Section ────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: AppRadius.small,
                  ),
                  child: const Icon(Icons.straighten_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('Measurements', style: AppTextStyles.h4),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: AppRadius.full,
                  ),
                  child: Text(
                    'Optional',
                    style: AppTextStyles.caption
                        .copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select a saved measurement or add a new one. You can also skip this step.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () => _showManualEntrySheet(context, measCtrl),
              icon: const Icon(Icons.add_rounded, color: AppColors.primary),
              label: Text('Add New Measurement',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.primary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape:
                    const RoundedRectangleBorder(borderRadius: AppRadius.medium),
              ),
            ),
            const SizedBox(height: 16),

            Obx(() {
              if (measCtrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (measCtrl.history.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppRadius.medium,
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Center(
                    child: Text(
                      'No measurements saved yet.\nAdd one above or skip this step.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  // "Skip / None" option
                  Obx(() {
                    final isNoneSelected =
                        ctrl.selectedMeasurement.value == null;
                    return GestureDetector(
                      onTap: () => ctrl.selectedMeasurement.value = null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isNoneSelected
                              ? AppColors.primarySoft
                              : theme.colorScheme.surface,
                          borderRadius: AppRadius.medium,
                          border: Border.all(
                            color: isNoneSelected
                                ? AppColors.primary
                                : Theme.of(context).colorScheme.outline,
                            width: isNoneSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.do_not_disturb_alt_outlined,
                              color: isNoneSelected
                                  ? AppColors.primary
                                  : Theme.of(context).textTheme.bodySmall?.color,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Skip Measurement',
                                      style: AppTextStyles.labelLarge.copyWith(
                                          color: isNoneSelected
                                              ? AppColors.primary
                                              : null)),
                                  Text(
                                    'Artist will take measurements manually',
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: Theme.of(context).textTheme.bodySmall?.color),
                                  ),
                                ],
                              ),
                            ),
                            if (isNoneSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Saved measurements
                  ...measCtrl.history.map((m) => Obx(() {
                        final isSelected =
                            ctrl.selectedMeasurement.value?.id == m.id;
                        return GestureDetector(
                          onTap: () => ctrl.selectedMeasurement.value = m,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primarySoft
                                  : theme.colorScheme.surface,
                              borderRadius: AppRadius.medium,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Theme.of(context).colorScheme.outline,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          m.isAiGenerated
                                              ? Icons.auto_awesome
                                              : Icons.edit_outlined,
                                          color: isSelected
                                              ? AppColors.primary
                                              : Theme.of(context).textTheme.bodySmall?.color,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${m.clothingType.emoji} ${m.clothingType.label} '
                                          '(${m.isAiGenerated ? 'AI' : 'Manual'})',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : null),
                                        ),
                                      ],
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle_rounded,
                                          color: AppColors.primary, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    for (final field in m.activeFields)
                                      if (m.valueOf(field) != null)
                                        _MeasChip(
                                          label: MeasurementFieldRegistry
                                              .specOf(field)
                                              .label,
                                          value: m.valueOf(field)!,
                                        ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      })),
                ],
              );
            }),

            const SizedBox(height: 32),

            // ─── Continue Button ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  if (ctrl.isHomeVisit.value &&
                      ctrl.selectedAddress.value == null) {
                    AppHelpers.showError(
                        'Please select an address for home visit.');
                    return;
                  }
                  Get.toNamed(AppRoutes.bookingConfirm);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.medium),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continue',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: Colors.white)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.medium),
                ),
                child: Text('Go Back',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ✅ Properly placed as a method of BookingAddressMeasurementScreen
  void _showAddAddressSheet(BuildContext context) {
    final labelCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final provinceCtrl = TextEditingController();
    final isDefault = false.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Address', style: AppTextStyles.h4),
                const SizedBox(height: 16),
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Label (Home/Work/Other)',
                    border: OutlineInputBorder(
                        borderRadius: AppRadius.medium),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Address',
                    border: OutlineInputBorder(
                        borderRadius: AppRadius.medium),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(
                              borderRadius: AppRadius.medium),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: provinceCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Province',
                          border: OutlineInputBorder(
                              borderRadius: AppRadius.medium),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(() => SwitchListTile(
                      value: isDefault.value,
                      onChanged: (val) => isDefault.value = val,
                      title: const Text('Set as Default',
                          style: AppTextStyles.labelMedium),
                      activeThumbColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (labelCtrl.text.isEmpty ||
                          addressCtrl.text.isEmpty ||
                          cityCtrl.text.isEmpty) {
                        AppHelpers.showError('Please fill all fields.');
                        return;
                      }
                      final address = AddressModel(
                        id: const Uuid().v4(),
                        label: labelCtrl.text.trim(),
                        fullAddress: addressCtrl.text.trim(),
                        city: cityCtrl.text.trim(),
                        province: provinceCtrl.text.trim(),
                        latitude: 0.0,
                        longitude: 0.0,
                        isDefault: isDefault.value,
                      );
                      await ProfileController.to.addAddress(address);
                      await AuthController.to.reloadCurrentUser();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium),
                    ),
                    child: Text('Save Address',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Properly placed as a method of BookingAddressMeasurementScreen
  //
  // Now includes a garment picker (matching the full Measurements screen),
  // so shirt / trouser / shalwar kameez / full dress / custom all ask the
  // right measurements instead of the old fixed 6-field set.
  void _showManualEntrySheet(
      BuildContext context, MeasurementController measCtrl) {
    ClothingType? selectedType;
    Set<MeasurementField> customFields = {};
    Map<MeasurementField, TextEditingController> controllers = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final fields = selectedType == null
              ? <MeasurementField>[]
              : selectedType == ClothingType.custom
                  ? customFields.toList()
                  : ClothingMeasurementRegistry.of(selectedType!).displayFields;
          final requiredFields = selectedType == null
              ? <MeasurementField>{}
              : selectedType == ClothingType.custom
                  ? customFields
                  : ClothingMeasurementRegistry.of(selectedType!).required;

          // Ensure a controller exists for every currently-visible field.
          for (final f in fields) {
            controllers.putIfAbsent(f, () => TextEditingController());
          }

          return Padding(
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
                  const Text('Add Measurements', style: AppTextStyles.h4),
                  Text('All values in cm',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color)),
                  const SizedBox(height: 16),
                  Text('What would you like to stitch?',
                      style: AppTextStyles.labelMedium),
                  const SizedBox(height: 10),
                  ClothingTypeSelector(
                    selected: selectedType,
                    onSelect: (type) async {
                      if (type == ClothingType.custom) {
                        final picked = await _showCustomFieldPickerForBooking(ctx);
                        if (picked == null || picked.isEmpty) return;
                        customFields = picked;
                      }
                      controllers = {};
                      setSheetState(() {
                        selectedType = type;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (selectedType == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Select a garment above to continue.',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final field in fields)
                              _Field(
                                ctrl: controllers[field]!,
                                label: MeasurementFieldRegistry.specOf(field).label,
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
                          onPressed: (measCtrl.isLoading.value || selectedType == null)
                              ? null
                              : () async {
                                  final type = selectedType!;
                                  final errs = _validateBookingFields(
                                      fields, requiredFields, controllers);
                                  if (errs.isNotEmpty) {
                                    AppHelpers.showError(errs.first);
                                    return;
                                  }
                                  await measCtrl.saveManualMeasurement(
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
                                borderRadius: AppRadius.medium),
                          ),
                          child: measCtrl.isLoading.value
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text('Save',
                                  style: AppTextStyles.labelLarge
                                      .copyWith(color: Colors.white)),
                        ),
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Checklist for [ClothingType.custom] inside the booking flow's manual
  /// entry sheet. Mirrors the picker on the full Measurements screen.
  Future<Set<MeasurementField>?> _showCustomFieldPickerForBooking(
      BuildContext context) async {
    final selected = <MeasurementField>{};

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
                  style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color),
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
                      shape:
                          const RoundedRectangleBorder(borderRadius: AppRadius.medium),
                    ),
                    child: Text('Continue',
                        style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Validates the booking flow's manual entry fields — same rules used by
  /// the full Measurements screen's edit sheet (required check, numeric
  /// check, min/max range check).
  List<String> _validateBookingFields(
    List<MeasurementField> fields,
    Set<MeasurementField> requiredFields,
    Map<MeasurementField, TextEditingController> controllers,
  ) {
    final errors = <String>[];
    for (final field in fields) {
      final spec = MeasurementFieldRegistry.specOf(field);
      final text = controllers[field]?.text.trim() ?? '';
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
}

// ─── Measurement Chip ─────────────────────────────────────────────────────────
class _MeasChip extends StatelessWidget {
  final String label;
  final double value;
  const _MeasChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadius.small,
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(0)}cm',
        style: AppTextStyles.caption.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// ─── Input Field ──────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  const _Field({required this.ctrl, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: 'cm',
          border: const OutlineInputBorder(borderRadius: AppRadius.medium),
        ),
      ),
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Step(
            number: 1,
            label: 'Details',
            isActive: currentStep >= 1,
            isDone: currentStep > 1),
        _StepLine(isActive: currentStep > 1),
        _Step(
            number: 2,
            label: 'Address',
            isActive: currentStep >= 2,
            isDone: currentStep > 2),
        _StepLine(isActive: currentStep > 2),
        _Step(
            number: 3,
            label: 'Confirm',
            isActive: currentStep >= 3,
            isDone: currentStep > 3),
        _StepLine(isActive: currentStep > 3),
        _Step(
            number: 4,
            label: 'Done',
            isActive: currentStep >= 4,
            isDone: currentStep > 4),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isDone;
  const _Step({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Theme.of(context).colorScheme.outline,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text('$number',
                    style: AppTextStyles.caption.copyWith(
                        color: isActive
                            ? Colors.white
                            : Theme.of(context).textTheme.bodySmall?.color)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: AppTextStyles.caption.copyWith(
                color: isActive
                    ? AppColors.primary
                    : Theme.of(context).textTheme.bodySmall?.color)),
      ],
    );
  }
}

// ✅ _StepLine is clean — no extra methods inside it
class _StepLine extends StatelessWidget {
  final bool isActive;
  const _StepLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? AppColors.primary : Theme.of(context).colorScheme.outline,
      ),
    );
  }
}