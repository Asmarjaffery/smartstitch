import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

import 'customer_compensation_controller.dart';
import 'payment_successful_screen.dart';

/// Shown when a COD customer has an unpaid delivery charge left over from
/// a previously failed attempt, before a new delivery can be scheduled.
class OutstandingChargeScreen extends StatelessWidget {
  final String orderId;
  final double outstandingAmount;

  const OutstandingChargeScreen({
    super.key,
    required this.orderId,
    required this.outstandingAmount,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = CustomerCompensationController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Outstanding Charge')),
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
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.warningSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded,
                            color: AppColors.warning, size: 44),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warningSoft,
                          borderRadius: AppRadius.large,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You have an unpaid delivery charge from your '
                              'previous failed delivery.',
                              style: AppTextStyles.bodyMedium,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Outstanding Delivery Charge',
                                style: AppTextStyles.bodyMedium),
                            Text(
                              'Rs. ${outstandingAmount.toStringAsFixed(0)}',
                              style: AppTextStyles.h4
                                  .copyWith(color: AppColors.error),
                            ),
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
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => ElevatedButton(
                          onPressed: ctrl.isProcessingPayment.value
                              ? null
                              : () async {
                                  final ok = await ctrl.payOutstandingCharge(
                                    orderId: orderId,
                                    paymentMethod: 'jazzCash',
                                  );
                                  if (ok) {
                                    Get.off(() => PaymentSuccessfulScreen(
                                          amount: outstandingAmount,
                                          paymentMethod: 'jazzCash',
                                        ));
                                  }
                                },
                          child: ctrl.isProcessingPayment.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Pay & Continue'),
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