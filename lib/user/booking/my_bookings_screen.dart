import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/user/booking/booking_controller.dart';

class BookingConfirmScreen extends StatelessWidget {
  const BookingConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = BookingController.to;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Confirm Booking', style: AppTextStyles.h4),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Step Indicator ──────────────────────────────────
            const _StepIndicator(currentStep: 2),
            const SizedBox(height: 28),

            // ─── Summary Card ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppRadius.large,
                border:
                    Border.all(color: Theme.of(context).colorScheme.outline),
                boxShadow: AppShadows.soft(AppColors.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: AppRadius.medium,
                        ),
                        child: const Icon(Icons.receipt_long_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text('Booking Summary', style: AppTextStyles.h4),
                    ],
                  ),
                  const Divider(height: 28),

                  // Service
                  Obx(() => _SummaryRow(
                        icon: Icons.checkroom_rounded,
                        label: 'Service',
                        value: ctrl.selectedService.value?.title ?? '-',
                      )),
                  const SizedBox(height: 12),

                  // Visit Type
                  Obx(() => _SummaryRow(
                        icon: ctrl.isHomeVisit.value
                            ? Icons.home_outlined
                            : Icons.store_outlined,
                        label: 'Visit Type',
                        value:
                            ctrl.isHomeVisit.value ? 'Home Visit' : 'Drop Off',
                      )),
                  const SizedBox(height: 12),

                  // Date
                  Obx(() => _SummaryRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: ctrl.selectedDate.value != null
                            ? _formatDate(ctrl.selectedDate.value!)
                            : '-',
                      )),
                  const SizedBox(height: 12),

                  // Time
                  Obx(() => _SummaryRow(
                        icon: Icons.access_time_rounded,
                        label: 'Time',
                        value: ctrl.selectedTimeSlot.value.isNotEmpty
                            ? ctrl.selectedTimeSlot.value
                            : '-',
                      )),

                  // Address
                  Obx(() {
                    if (!ctrl.isHomeVisit.value) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _SummaryRow(
                        icon: Icons.location_on_rounded,
                        label: 'Address',
                        value: ctrl.selectedAddress.value != null
                            ? '${ctrl.selectedAddress.value!.fullAddress}, ${ctrl.selectedAddress.value!.city}'
                            : '-',
                      ),
                    );
                  }),

                  // Design Image
                  // Design Images
                  Obx(() {
                    if (ctrl.designImageUrls.isEmpty) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Design(s)',
                              style: AppTextStyles.labelMedium.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: ctrl.designImageUrls.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) => ClipRRect(
                                borderRadius: AppRadius.medium,
                                child: Image.network(
                                  ctrl.designImageUrls[index],
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${ctrl.designImageUrls.length} image(s) • +Rs ${ctrl.designImageFee.toInt()}',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Special Instructions
                  Obx(() {
                    if (ctrl.specialInstructions.value.isEmpty) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _SummaryRow(
                        icon: Icons.notes_rounded,
                        label: 'Instructions',
                        value: ctrl.specialInstructions.value,
                      ),
                    );
                  }),

                  const Divider(height: 28),

                  // Price
                  Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Price',
                              style: AppTextStyles.labelLarge),
                          Text(
                            'Rs ${ctrl.selectedService.value?.basePrice.toInt() ?? 0}',
                            style: AppTextStyles.h4
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      )),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Note ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadius.medium,
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Final price may vary based on design complexity. Artist will confirm after review.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ─── Confirm Button ───────────────────────────────────
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: ctrl.isLoading.value ? null : ctrl.createBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium),
                    ),
                    child: ctrl.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  color: Colors.white),
                              const SizedBox(width: 8),
                              Text('Confirm Booking',
                                  style: AppTextStyles.labelLarge
                                      .copyWith(color: Colors.white)),
                            ],
                          ),
                  ),
                )),

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

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Summary Row ──────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color)),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.labelMedium),
          ],
        ),
      ],
    );
  }
}

// ─── Step Indicator (same as booking screen) ──────────────────────────────────
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
            label: 'Confirm',
            isActive: currentStep >= 2,
            isDone: currentStep > 2),
        _StepLine(isActive: currentStep > 2),
        _Step(
            number: 3,
            label: 'Done',
            isActive: currentStep >= 3,
            isDone: currentStep > 3),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isDone;
  const _Step(
      {required this.number,
      required this.label,
      required this.isActive,
      required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : Theme.of(context).colorScheme.outline,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text('$number',
                    style: AppTextStyles.labelMedium.copyWith(
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

class _StepLine extends StatelessWidget {
  final bool isActive;
  const _StepLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive
            ? AppColors.primary
            : Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
