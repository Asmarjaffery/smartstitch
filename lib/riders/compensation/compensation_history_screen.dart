import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/enums.dart';
import 'compensation_controller.dart';

class CompensationHistoryScreen extends StatefulWidget {
  final String riderId;
  const CompensationHistoryScreen({super.key, required this.riderId});

  @override
  State<CompensationHistoryScreen> createState() =>
      _CompensationHistoryScreenState();
}

class _CompensationHistoryScreenState
    extends State<CompensationHistoryScreen> {
  final ctrl = CompensationController.to;
  CompensationStatus? _filter; // null == All

  @override
  void initState() {
    super.initState();
    ctrl.loadHistory(widget.riderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compensation History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == null,
                    onTap: () => _applyFilter(null),
                  ),
                  const SizedBox(width: 8),
                  for (final s in CompensationStatus.values) ...[
                    _FilterChip(
                      label: s.label,
                      selected: _filter == s,
                      onTap: () => _applyFilter(s),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ctrl.loadHistory(widget.riderId, filter: _filter),
              child: Obx(() {
                if (ctrl.isLoadingHistory.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = ctrl.history;
                if (items.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No compensation requests yet')),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _HistoryCard(item: items[i]),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilter(CompensationStatus? status) {
    setState(() => _filter = status);
    ctrl.loadHistory(widget.riderId, filter: status);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final dynamic item; // DeliveryExceptionModel
  const _HistoryCard({required this.item});

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = item.compensationStatus as CompensationStatus;
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Order #${item.orderId}',
                  style: AppTextStyles.h5),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.full,
                ),
                child: Text(
                  status.label,
                  style: AppTextStyles.labelSmall.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            (item.reason).label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(item.attemptTime),
            style: AppTextStyles.caption.copyWith(
              color: isDark
                  ? AppColors.darkTextHint
                  : AppColors.lightTextHint,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Rs. ${(item.compensationAmount as double).toStringAsFixed(0)}',
            style: AppTextStyles.h5.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}