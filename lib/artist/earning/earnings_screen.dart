import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smartstitch/artist/earning/earnings_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EarningsController());

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.fetchEarningsData,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Total Earnings Card ──────────────────
              _TotalEarningsCard(controller: controller),
              const SizedBox(height: 16),

              // ─── Balance Row ──────────────────────────
              Row(children: [
                Expanded(child: _BalanceTile(
                  label: 'Available',
                  value: controller.formattedAvailable,
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.success,
                )),
                const SizedBox(width: 10),
                Expanded(child: _BalanceTile(
                  label: 'Pending',
                  value: controller.formattedPending,
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.warning,
                )),
                const SizedBox(width: 10),
                Expanded(child: _BalanceTile(
                  label: 'Withdrawn',
                  value: controller.formattedWithdrawn,
                  icon: Icons.history_rounded,
                  color: AppColors.info,
                )),
              ]),
              const SizedBox(height: 16),

              // ─── Monthly Earnings ─────────────────────
              _MonthlyEarningsCard(controller: controller),
              const SizedBox(height: 16),

              // ─── Withdraw Button ──────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.canWithdraw
                      ? () => _showWithdrawSheet(context, controller)
                      : () => _showCantWithdrawDialog(context, controller),
                  icon: const Icon(Icons.account_balance_rounded),
                  label: const Text('Withdraw Funds'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: controller.canWithdraw
                        ? AppColors.primary
                        : AppColors.lightTextHint,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  controller.withdrawHintText,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.lightTextSecondary),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Pending Bookings ─────────────────────
              Text('Pending Orders',
                  style: AppTextStyles.h5
                      .copyWith(color: AppColors.lightTextPrimary)),
              const SizedBox(height: 10),
              if (controller.isTransactionLoading.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (controller.pendingBookings.isEmpty)
                const _EmptyHistory(
                  icon: Icons.hourglass_empty_rounded,
                  text: 'No pending orders',
                )
              else
                ...controller.pendingBookings
                    .map((b) => _BookingTile(booking: b))
                    ,

              const SizedBox(height: 24),

              // ─── Withdraw History ─────────────────────
              Text('Withdraw History',
                  style: AppTextStyles.h5
                      .copyWith(color: AppColors.lightTextPrimary)),
              const SizedBox(height: 10),
              if (controller.withdrawHistory.isEmpty)
                const _EmptyHistory(
                  icon: Icons.account_balance_wallet_outlined,
                  text: 'No withdraw requests yet',
                )
              else
                ...controller.withdrawHistory
                    .map((w) => _WithdrawTile(data: w))
                    ,

              const SizedBox(height: 24),

              // ─── Completed Bookings (Transactions) ────
              Text('Completed Orders',
                  style: AppTextStyles.h5
                      .copyWith(color: AppColors.lightTextPrimary)),
              const SizedBox(height: 10),
              if (controller.completedBookings.isEmpty)
                const _EmptyHistory(
                  icon: Icons.receipt_long_outlined,
                  text: 'No completed orders yet',
                )
              else
                ...controller.completedBookings
                    .map((b) => _BookingTile(booking: b, showAsEarning: true))
                    ,

              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  // ─── Withdraw Bottom Sheet ────────────────────────────
  void _showWithdrawSheet(BuildContext context, EarningsController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFFFAF8FF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: const BoxDecoration(
                        color: AppColors.lightBorder,
                        borderRadius: AppRadius.full),
                  ),
                ),
                Row(children: [
                  Text('Withdraw Funds',
                      style: AppTextStyles.h4
                          .copyWith(color: AppColors.lightTextPrimary)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close_rounded)),
                ]),
                Text('Available: ${controller.formattedAvailable}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.lightTextSecondary)),
                const SizedBox(height: 16),

                // ─── Payment Method Selector ──────────
                const _Label('Payment Method'),
                Obx(() => Row(
                  children: PaymentMethod.values.map((method) {
                    final isSelected =
                        controller.selectedPaymentMethod.value == method;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          controller.selectedPaymentMethod.value = method;
                          controller.accountNumberController.clear();
                          controller.bankNameController.clear();
                        },
                        child: Container(
                          margin: EdgeInsets.only(
                              right: method != PaymentMethod.bankTransfer ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.lightBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                            borderRadius: AppRadius.small,
                          ),
                          child: Column(children: [
                            Icon(
                              method == PaymentMethod.bankTransfer
                                  ? Icons.account_balance_rounded
                                  : Icons.phone_android_rounded,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.lightTextSecondary,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(method.label,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.lightTextSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center),
                          ]),
                        ),
                      ),
                    );
                  }).toList(),
                )),
                const SizedBox(height: 16),

                // ─── Amount ───────────────────────────
                const _Label('Amount (PKR)'),
                TextField(
                  controller: controller.withdrawAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 5000',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                // ─── Account Title ────────────────────
                const _Label('Account Title'),
                TextField(
                  controller: controller.accountTitleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Ayesha Khan',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),

                // ─── Bank Name (Bank Transfer only) ───
                Obx(() => controller.selectedPaymentMethod.value ==
                        PaymentMethod.bankTransfer
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('Bank Name'),
                          TextField(
                            controller: controller.bankNameController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Meezan Bank',
                              prefixIcon:
                                  Icon(Icons.account_balance_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      )
                    : const SizedBox.shrink()),

                // ─── Account / Mobile Number ──────────
                Obx(() =>
                    _Label(controller.selectedPaymentMethod.value.accountLabel)),
                Obx(() => TextField(
                      controller: controller.accountNumberController,
                      keyboardType:
                          controller.selectedPaymentMethod.value ==
                                  PaymentMethod.bankTransfer
                              ? TextInputType.text
                              : TextInputType.phone,
                      decoration: InputDecoration(
                        hintText:
                            controller.selectedPaymentMethod.value.hint,
                        prefixIcon: Icon(
                          controller.selectedPaymentMethod.value ==
                                  PaymentMethod.bankTransfer
                              ? Icons.numbers_rounded
                              : Icons.phone_android_rounded,
                        ),
                      ),
                    )),
                const SizedBox(height: 22),

                // ─── Submit Button ────────────────────
                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: controller.isWithdrawLoading.value
                            ? null
                            : controller.submitWithdrawRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.medium),
                        ),
                        child: controller.isWithdrawLoading.value
                            ? const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)
                            : Text('Submit Request',
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: Colors.white)),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCantWithdrawDialog(
      BuildContext context, EarningsController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Not Available'),
        content: Text(controller.withdrawHintText),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')),
        ],
      ),
    );
  }
}

// ─── Total Earnings Card ──────────────────────────────────
class _TotalEarningsCard extends StatelessWidget {
  final EarningsController controller;
  const _TotalEarningsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(children: [
            const Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text('Total Earnings',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: Colors.white70)),
          ]),
          const SizedBox(height: 8),
          Obx(() => Text(controller.formattedTotal,
              style: AppTextStyles.display.copyWith(color: Colors.white))),
        ],
      ),
    );
  }
}

// ─── Balance Tile ─────────────────────────────────────────
class _BalanceTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _BalanceTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.small,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value,
            style:
                AppTextStyles.h5.copyWith(color: AppColors.lightTextPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.lightTextSecondary)),
      ]),
    );
  }
}

// ─── Monthly Earnings Card ────────────────────────────────
class _MonthlyEarningsCard extends StatelessWidget {
  final EarningsController controller;
  const _MonthlyEarningsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: AppRadius.small,
          ),
          child: const Icon(Icons.calendar_month_rounded,
              color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() => Text(
                    DateFormat('MMMM yyyy')
                        .format(controller.selectedMonth.value),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.lightTextSecondary),
                  )),
              const SizedBox(height: 2),
              Obx(() => Text(controller.formattedMonthly,
                  style:
                      AppTextStyles.h4.copyWith(color: AppColors.primary))),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () {
            final m = controller.selectedMonth.value;
            controller.changeMonth(DateTime(m.year, m.month - 1));
          },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () {
            final m = controller.selectedMonth.value;
            final next = DateTime(m.year, m.month + 1);
            if (next.isBefore(DateTime.now().add(const Duration(days: 31)))) {
              controller.changeMonth(next);
            }
          },
        ),
      ]),
    );
  }
}

// ─── Booking Tile (Pending + Completed) ──────────────────
class _BookingTile extends StatelessWidget {
  final BookingModel booking;
  final bool showAsEarning;
  const _BookingTile({required this.booking, this.showAsEarning = false});

  @override
  Widget build(BuildContext context) {
    final color = showAsEarning ? AppColors.success : AppColors.warning;
    final icon  = showAsEarning
        ? Icons.check_circle_outline_rounded
        : Icons.hourglass_top_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.small,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(booking.serviceTitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 2),
              Text(
                DateFormat('dd MMM yyyy').format(booking.appointmentDate),
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.lightTextSecondary),
              ),
            ],
          ),
        ),
        Text(
          '+Rs ${booking.servicePrice.toStringAsFixed(0)}',
          style: AppTextStyles.h5.copyWith(color: color),
        ),
      ]),
    );
  }
}

// ─── Withdraw Tile ────────────────────────────────────────
class _WithdrawTile extends StatelessWidget {
  final WithdrawRequestModel data;
  const _WithdrawTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: data.status.color.withValues(alpha: 0.12),
            borderRadius: AppRadius.small,
          ),
          child: Icon(Icons.account_balance_rounded,
              color: data.status.color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rs ${data.amount.toStringAsFixed(0)}',
                  style: AppTextStyles.h5
                      .copyWith(color: AppColors.lightTextPrimary)),
              const SizedBox(height: 2),
              Text(
                '${data.paymentMethod} • ${DateFormat('dd MMM yyyy').format(data.date)}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.lightTextSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: data.status.color.withValues(alpha: 0.12),
            borderRadius: AppRadius.full,
          ),
          child: Text(data.status.label,
              style:
                  AppTextStyles.labelSmall.copyWith(color: data.status.color)),
        ),
      ]),
    );
  }
}

// ─── Empty Placeholder ────────────────────────────────────
class _EmptyHistory extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHistory({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(children: [
        Icon(icon, size: 40, color: AppColors.lightTextHint),
        const SizedBox(height: 8),
        Text(text,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.lightTextSecondary)),
      ]),
    );
  }
}

// ─── Field Label ──────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: AppTextStyles.labelMedium
              .copyWith(color: AppColors.lightTextSecondary)),
    );
  }
}