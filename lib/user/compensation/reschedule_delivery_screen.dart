import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

import 'customer_compensation_controller.dart';
import 'payment_successful_screen.dart';

class RescheduleDeliveryScreen extends StatefulWidget {
  final String orderId;
  final double previousDeliveryFee;
  final double? newDeliveryFee; // defaults to same fee if not overridden

  const RescheduleDeliveryScreen({
    super.key,
    required this.orderId,
    required this.previousDeliveryFee,
    this.newDeliveryFee,
  });

  @override
  State<RescheduleDeliveryScreen> createState() =>
      _RescheduleDeliveryScreenState();
}

class _RescheduleDeliveryScreenState extends State<RescheduleDeliveryScreen> {
  final ctrl = CustomerCompensationController.to;
  String _paymentMethod = 'jazzCash';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final newFee = widget.newDeliveryFee ?? widget.previousDeliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Reschedule Delivery')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          gradient: AppColors.tealGlow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.event_repeat_rounded,
                            color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'A new delivery charge will apply\nfor rescheduling.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 24),
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
                          children: [
                            _PriceRow(
                                label: 'Previous Delivery Fee',
                                amount: widget.previousDeliveryFee),
                            const SizedBox(height: 10),
                            _PriceRow(
                                label: 'New Delivery Fee', amount: newFee),
                            const Divider(height: 24),
                            _PriceRow(
                              label: 'Total Payable',
                              amount: newFee,
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Payment Method', style: AppTextStyles.h5),
                      ),
                      const SizedBox(height: 10),
                      _PaymentOption(
                        label: 'JazzCash',
                        value: 'jazzCash',
                        groupValue: _paymentMethod,
                        onChanged: (v) => setState(() => _paymentMethod = v),
                      ),
                      const SizedBox(height: 8),
                      _PaymentOption(
                        label: 'EasyPaisa',
                        value: 'easyPaisa',
                        groupValue: _paymentMethod,
                        onChanged: (v) => setState(() => _paymentMethod = v),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                      onPressed: ctrl.isProcessingPayment.value
                          ? null
                          : () async {
                              final ok = await ctrl.confirmReschedule(
                                orderId: widget.orderId,
                                newDeliveryFee: newFee,
                                paymentMethod: _paymentMethod,
                              );
                              if (ok) {
                                Get.off(() => PaymentSuccessfulScreen(
                                      amount: newFee,
                                      paymentMethod: _paymentMethod,
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
                          : Text('Pay Rs. ${newFee.toStringAsFixed(0)}'),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;
  const _PriceRow(
      {required this.label, required this.amount, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? AppTextStyles.h5.copyWith(color: AppColors.primary)
        : AppTextStyles.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text('Rs. ${amount.toStringAsFixed(0)}', style: style),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _PaymentOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: AppRadius.medium,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08)
              : Colors.transparent,
          borderRadius: AppRadius.medium,
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.lightTextHint,
            ),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodyMedium),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}