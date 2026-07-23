import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/models/body_measurement_model.dart';
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

  void _showManualEntrySheet(BuildContext context) {
    final heightCtrl = TextEditingController();
    final chestCtrl = TextEditingController();
    final waistCtrl = TextEditingController();
    final shoulderCtrl = TextEditingController();
    final hipsCtrl = TextEditingController();
    final sleeveCtrl = TextEditingController();
    final inseamCtrl = TextEditingController();
    final neckCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
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
              const Text('Manual Measurements', style: AppTextStyles.h4),
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
                      _Field(ctrl: heightCtrl, label: 'Height'),
                      _Field(ctrl: chestCtrl, label: 'Chest'),
                      _Field(ctrl: waistCtrl, label: 'Waist'),
                      _Field(ctrl: shoulderCtrl, label: 'Shoulder'),
                      _Field(ctrl: hipsCtrl, label: 'Hips'),
                      _Field(ctrl: sleeveCtrl, label: 'Sleeve Length'),
                      _Field(ctrl: inseamCtrl, label: 'Inseam'),
                      _Field(ctrl: neckCtrl, label: 'Neck'),
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
                                height: double.tryParse(heightCtrl.text) ?? 0,
                                chest: double.tryParse(chestCtrl.text) ?? 0,
                                waist: double.tryParse(waistCtrl.text) ?? 0,
                                shoulder: double.tryParse(shoulderCtrl.text) ?? 0,
                                hips: double.tryParse(hipsCtrl.text) ?? 0,
                                sleevLength: double.tryParse(sleeveCtrl.text) ?? 0,
                                inseam: double.tryParse(inseamCtrl.text) ?? 0,
                                neck: double.tryParse(neckCtrl.text) ?? 0,
                              );
                              Navigator.pop(ctx);
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
                        style: AppTextStyles.h4.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use your camera to automatically detect body measurements with 90%+ accuracy.',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _showManualEntrySheet(context),
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
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
            const SizedBox(height: 28),
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
                itemBuilder: (_, i) =>
                    _MeasurementCard(measurement: ctrl.history[i]),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final BodyMeasurementModel measurement;
  const _MeasurementCard({required this.measurement});

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: measurement.isAiGenerated
                          ? AppColors.primarySoft
                          : AppColors.lightBorder,
                      borderRadius: AppRadius.small,
                    ),
                    child: Icon(
                      measurement.isAiGenerated
                          ? Icons.auto_awesome
                          : Icons.edit_outlined,
                      color: measurement.isAiGenerated
                          ? AppColors.primary
                          : AppColors.lightTextSecondary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    measurement.isAiGenerated ? 'AI Scan' : 'Manual',
                    style: AppTextStyles.labelMedium,
                  ),
                ],
              ),
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
                    onTap: () => _showEditSheet(context, measurement),
                    child: const Icon(Icons.edit_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        MeasurementController.to.deleteMeasurement(measurement.id),
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
              _MeasurementChip(label: 'Height', value: measurement.height),
              _MeasurementChip(label: 'Chest', value: measurement.chest),
              _MeasurementChip(label: 'Waist', value: measurement.waist),
              _MeasurementChip(label: 'Shoulder', value: measurement.shoulder),
              _MeasurementChip(label: 'Hips', value: measurement.hips),
              _MeasurementChip(label: 'Sleeve', value: measurement.sleevLength),
              _MeasurementChip(label: 'Inseam', value: measurement.inseam),
              _MeasurementChip(label: 'Neck', value: measurement.neck),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showEditSheet(BuildContext context, BodyMeasurementModel m) {
    final heightCtrl = TextEditingController(text: m.height.toString());
    final chestCtrl = TextEditingController(text: m.chest.toString());
    final waistCtrl = TextEditingController(text: m.waist.toString());
    final shoulderCtrl = TextEditingController(text: m.shoulder.toString());
    final hipsCtrl = TextEditingController(text: m.hips.toString());
    final sleeveCtrl = TextEditingController(text: m.sleevLength.toString());
    final inseamCtrl = TextEditingController(text: m.inseam.toString());
    final neckCtrl = TextEditingController(text: m.neck.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
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
              const Text('Edit Measurements', style: AppTextStyles.h4),
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
                      _Field(ctrl: heightCtrl, label: 'Height'),
                      _Field(ctrl: chestCtrl, label: 'Chest'),
                      _Field(ctrl: waistCtrl, label: 'Waist'),
                      _Field(ctrl: shoulderCtrl, label: 'Shoulder'),
                      _Field(ctrl: hipsCtrl, label: 'Hips'),
                      _Field(ctrl: sleeveCtrl, label: 'Sleeve Length'),
                      _Field(ctrl: inseamCtrl, label: 'Inseam'),
                      _Field(ctrl: neckCtrl, label: 'Neck'),
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
                              final updated = BodyMeasurementModel(
                                id: m.id,
                                userId: m.userId,
                                height: double.tryParse(heightCtrl.text) ?? m.height,
                                chest: double.tryParse(chestCtrl.text) ?? m.chest,
                                waist: double.tryParse(waistCtrl.text) ?? m.waist,
                                shoulder:
                                    double.tryParse(shoulderCtrl.text) ?? m.shoulder,
                                hips: double.tryParse(hipsCtrl.text) ?? m.hips,
                                sleevLength:
                                    double.tryParse(sleeveCtrl.text) ?? m.sleevLength,
                                inseam: double.tryParse(inseamCtrl.text) ?? m.inseam,
                                neck: double.tryParse(neckCtrl.text) ?? m.neck,
                                aiAccuracyScore: m.aiAccuracyScore,
                                isAiGenerated: m.isAiGenerated,
                                measuredAt: m.measuredAt,
                              );
                              await MeasurementController.to.updateMeasurement(updated);
                              Navigator.pop(ctx);
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
}

class _MeasurementChip extends StatelessWidget {
  final String label;
  final double value;
  const _MeasurementChip({required this.label, required this.value});

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