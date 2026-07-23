import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smartstitch/artist/order/order_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/order_model.dart';
import 'package:smartstitch/models/enums.dart';

class ArtistOrdersScreen extends StatelessWidget {
  const ArtistOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ArtistOrderController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: Column(
        children: [
          _buildFilterBar(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final list = controller.filteredOrders;

              if (list.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) =>
                    _OrderCard(order: list[i], controller: controller),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Filter Bar ─────────────────────────────────────────────────────────
  Widget _buildFilterBar(BuildContext context, ArtistOrderController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'new', 'label': 'New'},
      {'key': 'active', 'label': 'Active'},
      {'key': 'completed', 'label': 'Completed'},
      {'key': 'cancelled', 'label': 'Cancelled'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = filters[i];
            return Obx(() {
              final selected = controller.filterStatus.value == f['key'];
              return ChoiceChip(
                label: Text(f['label']!),
                selected: selected,
                onSelected: (_) => controller.setFilter(f['key']!),
                showCheckmark: false,
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: selected
                      ? Colors.white
                      : (isDark ? AppColors.darkTextPrimary : AppColors.primaryDark),
                ),
                selectedColor: isDark ? AppColors.primaryLight : AppColors.primary,
                backgroundColor:
                    isDark ? AppColors.darkSurface2 : AppColors.primarySoft,
                shape: const StadiumBorder(),
              );
            });
          },
        ),
      ),
    );
  }

  // ─── Empty State ────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
          ),
          const SizedBox(height: 12),
          Text(
            'No orders found',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order Card ─────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final ArtistOrderController controller;

  const _OrderCard({required this.order, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accentColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final noteBg = isDark
        ? AppColors.primaryDark.withValues(alpha: 0.25)
        : AppColors.primarySoft;
    final noteText = isDark ? AppColors.primaryLight : AppColors.primaryDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.medium,
        border: Border.all(color: borderColor),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Service name + Status badge ──
          Row(
            children: [
              Expanded(
                child: Text(
                  order.service.title,
                  style: AppTextStyles.h5.copyWith(color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 6),

          // ── Customer name ──
          Obx(() => Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    controller.getCustomerName(order.customerId),
                    style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
                  ),
                ],
              )),
          const SizedBox(height: 4),

          // ── Date ──
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: textSecondary),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(order.placedAt),
                style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
              ),
            ],
          ),

          // ── Home visit / address ──
          if (order.isHomeVisit) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.home_outlined, size: 16, color: textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.deliveryAddress.fullAddress,
                    style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // ── Special instructions ──
          if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: noteBg,
                borderRadius: AppRadius.small,
              ),
              child: Text(
                order.specialInstructions!,
                style: AppTextStyles.bodySmall.copyWith(color: noteText),
              ),
            ),
          ],

          Divider(height: 20, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),

          // ── Amount + Actions ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Earning', style: AppTextStyles.caption.copyWith(color: textSecondary)),
                    Text(
                      'Rs. ${order.artistAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.h5.copyWith(color: accentColor),
                    ),
                  ],
                ),
              ),
              ..._buildActions(isDark),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Action Buttons based on status ────────────────────────────────────
  List<Widget> _buildActions(bool isDark) {
    switch (order.status) {
      case OrderStatus.pending:
        return [
          OutlinedButton(
            onPressed: () => controller.rejectOrder(order.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Reject'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => controller.acceptOrder(order.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Accept'),
          ),
        ];

      case OrderStatus.accepted:
        return [
          ElevatedButton(
            onPressed: () => controller.startWork(order.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Start Work'),
          ),
        ];

      case OrderStatus.inProgress:
        return [
          ElevatedButton(
            onPressed: () => controller.markStitchingCompleted(order.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Mark Completed'),
          ),
        ];

      default:
        return [];
    }
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (label, color) = switch (status) {
      OrderStatus.pending => ('Pending', AppColors.warning),
      OrderStatus.accepted => ('Accepted', AppColors.info),
      OrderStatus.inProgress => ('In Progress', isDark ? AppColors.primaryLight : AppColors.primary),
      OrderStatus.stitchingCompleted => ('Completed', AppColors.success),
      OrderStatus.riderAssigned => ('Rider Assigned', AppColors.primaryLight),
      OrderStatus.delivered => ('Delivered', AppColors.success),
      OrderStatus.cancelled => ('Cancelled', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: AppRadius.full,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}