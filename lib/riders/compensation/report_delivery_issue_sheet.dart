import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/enums.dart';
// ✅ FIX: "Call Now" previously only logged a timestamp — it never
// actually placed a call to the customer's phone.
import 'package:url_launcher/url_launcher.dart';
import 'compensation_controller.dart';
import 'delivery_attempt_summary_screen.dart';

/// Step 1 — "Report Delivery Issue" bottom sheet.
/// Call [ReportDeliveryIssueSheet.show] from the rider's Order Details
/// screen (secondary button under "Mark as Delivered").
class ReportDeliveryIssueSheet extends StatelessWidget {
  final String orderId;
  final String customerId;
  final String riderId;
  final String? artistId;
  final double deliveryFee;
  final bool isCod;
  final int attemptCount;
  final String customerPhone;

  const ReportDeliveryIssueSheet({
    super.key,
    required this.orderId,
    required this.customerId,
    required this.riderId,
    this.artistId,
    required this.deliveryFee,
    this.isCod = false,
    this.attemptCount = 1,
    required this.customerPhone,
  });

  static Future<void> show(
    BuildContext context, {
    required String orderId,
    required String customerId,
    required String riderId,
    String? artistId,
    required double deliveryFee,
    bool isCod = false,
    int attemptCount = 1,
    required String customerPhone,
  }) {
    CompensationController.to.resetReportForm();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportDeliveryIssueSheet(
        orderId: orderId,
        customerId: customerId,
        riderId: riderId,
        artistId: artistId,
        deliveryFee: deliveryFee,
        isCod: isCod,
        attemptCount: attemptCount,
        customerPhone: customerPhone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = CompensationController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    borderRadius: AppRadius.full,
                  ),
                ),
              ),
              Row(
                children: [
                  Text('Report Delivery Issue', style: AppTextStyles.h4),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Why couldn't you complete the delivery?",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => Column(
                    children: DeliveryExceptionReason.values.map((reason) {
                      final selected = ctrl.selectedReason.value == reason;
                      return _ReasonTile(
                        label: reason.label,
                        selected: selected,
                        onTap: () => ctrl.selectedReason.value = reason,
                      );
                    }).toList(),
                  )),
              const SizedBox(height: 8),
              Obx(() {
                final needsNote =
                    ctrl.selectedReason.value?.requiresNote ?? false;
                return TextField(
                  minLines: 2,
                  maxLines: 4,
                  onChanged: (v) => ctrl.notes.value = v,
                  decoration: InputDecoration(
                    hintText: needsNote
                        ? 'Please describe the issue (required)'
                        : 'Additional Notes (optional)',
                  ),
                );
              }),
              const SizedBox(height: 12),
              Obx(() {
                if (ctrl.selectedReason.value !=
                    DeliveryExceptionReason.customerDidNotAnswer) {
                  return const SizedBox.shrink();
                }
                final called = ctrl.callAttemptedAt.value != null;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: called
                        ? AppColors.successSoft
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: AppRadius.medium,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        called
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        color: called ? AppColors.success : AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          called
                              ? 'Call logged at ${DateFormat('hh:mm a').format(ctrl.callAttemptedAt.value!)}'
                              : 'Please call the customer before continuing',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                      if (!called)
                        TextButton.icon(
                          // ✅ FIX: open the phone dialer on the customer's
                          // number first, then log the attempt — previously
                          // this only recorded a timestamp with no call
                          // ever placed.
                          onPressed: () async {
                            final callUri =
                                Uri(scheme: 'tel', path: customerPhone);
                            if (await canLaunchUrl(callUri)) {
                              await launchUrl(callUri);
                            }
                            ctrl.logCallAttempt(customerPhone);
                          },
                          icon: const Icon(Icons.call_rounded, size: 16),
                          label: const Text('Call Now'),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => ElevatedButton(
                          onPressed: ctrl.canContinue && !ctrl.isCapturingGps.value
                              ? () async {
                                  ctrl.attemptCount.value = attemptCount;
                                  final ok = await ctrl.captureAttemptDetails();
                                  if (ok) {
                                    Get.back(); // close sheet
                                    Get.to(() => DeliveryAttemptSummaryScreen(
                                          orderId: orderId,
                                          customerId: customerId,
                                          riderId: riderId,
                                          artistId: artistId,
                                          deliveryFee: deliveryFee,
                                          isCod: isCod,
                                        ));
                                  }
                                }
                              : null,
                          child: ctrl.isCapturingGps.value
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Continue'),
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.medium,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08)
              : Colors.transparent,
          borderRadius: AppRadius.medium,
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.darkTextHint
                      : AppColors.lightTextHint),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          ],
        ),
      ),
    );
  }
}