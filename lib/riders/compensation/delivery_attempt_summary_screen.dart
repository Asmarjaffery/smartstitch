import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/enums.dart';

import 'compensation_controller.dart';
import 'issue_submitted_screen.dart';

/// Step 2 — rider confirms the captured details before submitting.
class DeliveryAttemptSummaryScreen extends StatelessWidget {
  final String orderId;
  final String customerId;
  final String riderId;
  final String? artistId;
  final double deliveryFee;
  final bool isCod;

  const DeliveryAttemptSummaryScreen({
    super.key,
    required this.orderId,
    required this.customerId,
    required this.riderId,
    this.artistId,
    required this.deliveryFee,
    this.isCod = false,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = CompensationController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Attempt Recorded')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: AppColors.tealGlow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.two_wheeler_rounded,
                            color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Please confirm the details\nbefore submitting',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: AppRadius.large,
                          boxShadow: AppShadows.card(isDark),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Obx(() {
                          final pos = ctrl.capturedPosition.value;
                          final time = ctrl.attemptTime.value;
                          return Column(
                            children: [
                              _SummaryRow(
                                  label: 'Reason',
                                  value: ctrl.selectedReason.value?.label ?? '—'),
                              _SummaryRow(
                                label: 'Attempt Time',
                                value: time != null
                                    ? DateFormat('dd MMM yyyy, hh:mm a')
                                        .format(time)
                                    : '—',
                              ),
                              _SummaryRow(
                                label: 'GPS Location',
                                value: pos != null
                                    ? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'
                                    : 'Not available',
                              ),
                              _SummaryRow(
                                label: 'GPS Accuracy',
                                value: pos != null
                                    ? '${pos.accuracy.toStringAsFixed(1)} m'
                                    : '—',
                              ),
                              _SummaryRow(
                                  label: 'Attempt Count',
                                  value: '${ctrl.attemptCount.value}'),
                              if (ctrl.notes.value.trim().isNotEmpty)
                                _SummaryRow(
                                    label: 'Notes',
                                    value: ctrl.notes.value.trim(),
                                    isLast: true),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                      onPressed: ctrl.isSubmitting.value
                          ? null
                          : () async {
                              final result = await ctrl.submitReport(
                                orderId: orderId,
                                customerId: customerId,
                                riderId: riderId,
                                artistId: artistId,
                                deliveryFee: deliveryFee,
                                isCod: isCod,
                              );
                              if (result != null) {
                                Get.off(() => const IssueSubmittedScreen());
                              }
                            },
                      child: ctrl.isSubmitting.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit'),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}