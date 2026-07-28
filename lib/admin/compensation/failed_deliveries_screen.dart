import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/delivery_exception_model.dart';
import 'package:smartstitch/models/enums.dart';
import 'admin_compensation_controller.dart';
import 'failed_delivery_detail_drawer.dart';

class FailedDeliveriesScreen extends StatelessWidget {
  const FailedDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = AdminCompensationController.to;

    return Scaffold(
      appBar: AppBar(title: const Text('Failed Deliveries')),
      body: Column(
        children: [
          _FilterTabs(ctrl: ctrl),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // TEMP SAFEGUARD: dedupe by orderId so the same booking
              // doesn't render twice while the root cause in loadAll() is fixed.
              final seen = <String>{};
              final list = ctrl.items
                  .where((i) => seen.add(i.orderId))
                  .toList();

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_shipping_outlined,
                            size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: 20),
                      Text('No Failed Deliveries', style: AppTextStyles.h4),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => ctrl.loadAll(status: ctrl.filter.value),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _FailedDeliveryCard(item: list[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final AdminCompensationController ctrl;
  const _FilterTabs({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final tabs = <(CompensationStatus?, String)>[
      (null, 'All'),
      (CompensationStatus.pending, 'Pending'),
      (CompensationStatus.approved, 'Approved'),
      (CompensationStatus.rejected, 'Rejected'),
    ];

    return Obx(() {
      final currentFilter = ctrl.filter.value;

      return Container(
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final (status, label) = tabs[i];
            final selected = currentFilter == status;
            return ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => ctrl.loadAll(status: status),
            );
          },
        ),
      );
    });
  }
}

class _FailedDeliveryCard extends StatelessWidget {
  final DeliveryExceptionModel item;
  const _FailedDeliveryCard({required this.item});

  Color _statusColor(CompensationStatus s) {
    switch (s) {
      case CompensationStatus.approved:
        return AppColors.success;
      case CompensationStatus.rejected:
        return AppColors.error;
      case CompensationStatus.pending:
        return AppColors.warning;
    }
  }

  String get _shortId => item.orderId.length > 8
      ? '#${item.orderId.substring(0, 8).toUpperCase()}'
      : '#${item.orderId}';

  @override
  Widget build(BuildContext context) {
    final ctrl = AdminCompensationController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _statusColor(item.compensationStatus);
    final pending = item.compensationStatus == CompensationStatus.pending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.large,
        boxShadow: AppShadows.card(isDark),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Booking $_shortId',
                  style: AppTextStyles.h5,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.full,
                ),
                child: Text(item.compensationStatus.label,
                    style: AppTextStyles.labelSmall.copyWith(color: color)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoLine(
              icon: Icons.person_outline_rounded,
              label: 'Customer',
              value: ctrl.nameFor(item.customerId)),
          const SizedBox(height: 6),
          _InfoLine(
              icon: Icons.two_wheeler_rounded,
              label: 'Rider',
              value: ctrl.nameFor(item.riderId)),
          const SizedBox(height: 6),
          _InfoLine(
              icon: Icons.report_gmailerrorred_rounded,
              label: 'Reason',
              value: item.reason.label),
          const SizedBox(height: 6),
          _InfoLine(
            icon: Icons.schedule_rounded,
            label: 'Attempt Time',
            value: DateFormat('dd MMM yyyy, hh:mm a').format(item.attemptTime),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Rs. ${item.compensationAmount.toStringAsFixed(0)}',
                style: AppTextStyles.h5.copyWith(color: AppColors.primary),
              ),
              if (item.isCod) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: AppRadius.full,
                  ),
                  child: Text(
                    'COD ${item.outstandingChargeAction.label}',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (pending) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => ctrl.approveCompensation(item),
                    icon: const Icon(Icons.check_rounded,
                        size: 18, color: Colors.white),
                    label: const Text('Approve',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _confirmReject(context, item),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => FailedDeliveryDetailDrawer(item: item),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmReject(BuildContext context, DeliveryExceptionModel item) {
    final ctrl = AdminCompensationController.to;
    final reasonCtrl = TextEditingController();
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Reject Compensation'),
      content: TextField(
        controller: reasonCtrl,
        decoration: const InputDecoration(hintText: 'Reason for rejection'),
        minLines: 2,
        maxLines: 4,
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () {
            Get.back();
            ctrl.rejectCompensation(
              item,
              reasonCtrl.text.trim().isEmpty
                  ? 'Not eligible for compensation'
                  : reasonCtrl.text.trim(),
            );
          },
          child: const Text('Reject', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoLine(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
        const SizedBox(width: 6),
        Text('$label: ',
            style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary)),
        Expanded(
          child: Text(value,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}