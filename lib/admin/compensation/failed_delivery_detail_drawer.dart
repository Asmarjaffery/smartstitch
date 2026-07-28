import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/delivery_exception_model.dart';
import 'package:smartstitch/models/enums.dart';
import 'admin_compensation_controller.dart';

/// The "Details Drawer" from the Figma spec, implemented as a scrollable
/// bottom sheet (works the same whether the admin view is rendered on
/// mobile or a wide web viewport — no separate desktop-only widget needed).
class FailedDeliveryDetailDrawer extends StatelessWidget {
  final DeliveryExceptionModel item;
  const FailedDeliveryDetailDrawer({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final ctrl = AdminCompensationController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: AppRadius.full,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Text('Request Details', style: AppTextStyles.h4),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: [
                    _Section(title: 'Booking Information', children: [
                      _Field('Booking ID', item.orderId),
                      _Field('Reason', item.reason.label),
                      _Field('Attempt Time',
                          DateFormat('dd MMM yyyy, hh:mm a').format(item.attemptTime)),
                      _Field('Attempt Count', '${item.attemptCount}'),
                      if (item.notes != null) _Field('Notes', item.notes!),
                    ]),
                    _Section(title: 'Customer Information', children: [
                      _Field('Name', ctrl.nameFor(item.customerId)),
                      _Field('Phone', ctrl.phoneFor(item.customerId)),
                    ]),
                    _Section(title: 'Rider Information', children: [
                      _Field('Name', ctrl.nameFor(item.riderId)),
                      _Field('Phone', ctrl.phoneFor(item.riderId)),
                      if (item.newRiderId != null)
                        _Field('Reassigned To', ctrl.nameFor(item.newRiderId!)),
                    ]),
                    _Section(title: 'Location', children: [
                      _Field(
                        'GPS Location',
                        item.hasGpsData
                            ? '${item.gpsLat!.toStringAsFixed(5)}, ${item.gpsLng!.toStringAsFixed(5)}'
                            : 'Not available',
                      ),
                      _Field(
                        'GPS Accuracy',
                        item.gpsAccuracyMeters != null
                            ? '${item.gpsAccuracyMeters!.toStringAsFixed(1)} m'
                            : '—',
                      ),
                    ]),
                    _Section(title: 'Compensation', children: [
                      _Field('Compensation Amount',
                          'Rs. ${item.compensationAmount.toStringAsFixed(0)}'),
                      _Field('Status', item.compensationStatus.label),
                      if (item.isCod)
                        _Field('Outstanding Charge',
                            'Rs. ${item.outstandingCharge.toStringAsFixed(0)} (${item.outstandingChargeAction.label})'),
                      if (item.adminNote != null)
                        _Field('Admin Note', item.adminNote!),
                    ]),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _ActionButtons(item: item),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final DeliveryExceptionModel item;
  const _ActionButtons({required this.item});

  @override
  Widget build(BuildContext context) {
    final ctrl = AdminCompensationController.to;
    final pending = item.compensationStatus == CompensationStatus.pending;
    final canWaive = item.isCod &&
        item.outstandingChargeAction == OutstandingChargeAction.none;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (pending)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              ctrl.approveCompensation(item);
              Get.back();
            },
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            label: const Text('Approve Compensation',
                style: TextStyle(color: Colors.white)),
          ),
        if (pending)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error)),
            onPressed: () => _rejectDialog(context, item),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Reject'),
          ),
        OutlinedButton.icon(
          onPressed: () => _assignRiderDialog(context, item),
          icon: const Icon(Icons.person_add_alt_rounded),
          label: const Text('Assign New Rider'),
        ),
        if (canWaive)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning)),
            onPressed: () {
              ctrl.waiveCharges(item);
              Get.back();
            },
            icon: const Icon(Icons.money_off_rounded),
            label: const Text('Waive Charges'),
          ),
      ],
    );
  }

  void _rejectDialog(BuildContext context, DeliveryExceptionModel item) {
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
            Get.back(); // dialog
            Get.back(); // drawer
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

  void _assignRiderDialog(BuildContext context, DeliveryExceptionModel item) {
    final ctrl = AdminCompensationController.to;
    final riderIdCtrl = TextEditingController();
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Assign New Rider'),
      content: TextField(
        controller: riderIdCtrl,
        decoration: const InputDecoration(
            hintText: 'Rider ID (swap for your rider picker)'),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (riderIdCtrl.text.trim().isEmpty) return;
            Get.back(); // dialog
            Get.back(); // drawer
            ctrl.assignNewRider(item, riderIdCtrl.text.trim());
          },
          child: const Text('Assign'),
        ),
      ],
    ));
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary)),
          ),
          Expanded(
              child: Text(value,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}