import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/enums.dart';

import 'customer_compensation_controller.dart';
import 'reschedule_delivery_screen.dart';

/// Shown to the customer once a rider reports a failed delivery attempt.
/// Wire this up as a route pushed from a notification tap, or shown inline
/// on Order Detail when order.status indicates a failed attempt.
class DeliveryFailedScreen extends StatefulWidget {
  final String orderId;
  final double previousDeliveryFee;
  final VoidCallback? onCancelOrder;

  const DeliveryFailedScreen({
    super.key,
    required this.orderId,
    required this.previousDeliveryFee,
    this.onCancelOrder,
  });

  @override
  State<DeliveryFailedScreen> createState() => _DeliveryFailedScreenState();
}

class _DeliveryFailedScreenState extends State<DeliveryFailedScreen> {
  final ctrl = CustomerCompensationController.to;

  @override
  void initState() {
    super.initState();
    ctrl.loadForOrder(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final ex = ctrl.exception.value;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.errorSoft,
                            borderRadius: AppRadius.large,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppColors.error, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Delivery Attempt Failed',
                                        style: AppTextStyles.h5.copyWith(
                                            color: AppColors.error)),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Our rider reached your address but '
                                      'could not complete the delivery.',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: AppRadius.large,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Row(
                                  label: 'Reason',
                                  value: ex?.reason.label ?? '—'),
                              const SizedBox(height: 12),
                              _Row(
                                label: 'Attempt Time',
                                value: ex != null
                                    ? DateFormat('dd MMM yyyy, hh:mm a')
                                        .format(ex.attemptTime)
                                    : '—',
                              ),
                              if (ex?.notes != null) ...[
                                const SizedBox(height: 12),
                                _Row(label: 'Notes', value: ex!.notes!),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCancelOrder,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: const Text('Cancel Order'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.to(() => RescheduleDeliveryScreen(
                              orderId: widget.orderId,
                              previousDeliveryFee: widget.previousDeliveryFee,
                            )),
                        child: const Text('Reschedule Delivery'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary)),
        ),
        Expanded(
          child: Text(value,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}