import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/routes/routes.dart';

class PaymentSuccessfulScreen extends StatelessWidget {
  final double amount;
  final String paymentMethod;
  final String? transactionId;

  const PaymentSuccessfulScreen({
    super.key,
    required this.amount,
    required this.paymentMethod,
    this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: AppColors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 58),
              ),
              const SizedBox(height: 24),
              Text('Payment Successful!', style: AppTextStyles.h2),
              const SizedBox(height: 6),
              Text(
                'Your payment has been received.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
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
                    _Row(label: 'Amount', value: 'Rs. ${amount.toStringAsFixed(0)}'),
                    const SizedBox(height: 10),
                    _Row(
                        label: 'Date',
                        value: DateFormat('dd MMM yyyy, hh:mm a').format(now)),
                    const SizedBox(height: 10),
                    _Row(label: 'Payment Method', value: paymentMethod),
                    if (transactionId != null) ...[
                      const SizedBox(height: 10),
                      _Row(label: 'Transaction ID', value: transactionId!),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.customerOrders),
                  child: const Text('Continue Shopping'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}