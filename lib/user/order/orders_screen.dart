import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/widgets/booking_status_badge.dart';
import 'package:smartstitch/models/order_model.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/user/order/order_controller.dart';


class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(OrderController());
    final ctrl = OrderController.to;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Orders', style: AppTextStyles.h4),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ─── Filter Tabs ─────────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(label: 'All', value: 'all', ctrl: ctrl),
                _FilterChip(label: 'Pending', value: 'pending', ctrl: ctrl),
                _FilterChip(
                    label: 'In Progress', value: 'inProgress', ctrl: ctrl),
                _FilterChip(label: 'Delivered', value: 'delivered', ctrl: ctrl),
                _FilterChip(label: 'Cancelled', value: 'cancelled', ctrl: ctrl),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ─── Orders List ─────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // Reading filterStatus.value here forces Obx to rebuild
              // whenever the filter changes.
              final orders = ctrl.filteredOrders;
              // ignore: unused_local_variable
              final _ = ctrl.filterStatus.value;

              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 80,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('No orders found',
                          style: AppTextStyles.h4.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Text('Place an order to get started',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: ctrl.loadOrders,
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _OrderCard(order: orders[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final OrderController ctrl;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isSelected = ctrl.filterStatus.value == value;
      return GestureDetector(
        onTap: () => ctrl.setFilter(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 10, top: 2, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: 0.2,
            ),
          ),
        ),
      );
    });
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final ctrl = OrderController.to;
    final theme = Theme.of(context);
    final statusColor = _statusColor(order.status);

    return Dismissible(
      key: Key(order.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: AppRadius.large,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 28),
            SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(color: AppColors.error, fontSize: 12)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await Get.dialog<bool>(
              AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: const Text('Remove Order'),
                content: const Text('Is order ko history se hata dein?'),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('No'),
                  ),
                  ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error),
                    child: const Text('Haan, Hatao',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) {
        ctrl.removeOrderFromList(order.id);
      },
      child: GestureDetector(
        onTap: () {
          ctrl.selectedOrder.value = order;
          ctrl.loadOrderExtras(order);
          ctrl.listenToOrder(order.id);
          Get.toNamed(AppRoutes.orderDetail, arguments: order);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadius.large,
            border: Border.all(color: theme.colorScheme.outline),
            boxShadow: AppShadows.soft(theme.colorScheme.primary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ──────────────────────────────────────────
              // ─── Header ──────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: AppRadius.small,
                          ),
                          child: Icon(Icons.checkroom_rounded,
                              color: theme.colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.service.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelLarge.copyWith(
                                    color: theme.colorScheme.onSurface),
                              ),
                              Text(
                                '#${order.id.substring(0, 8).toUpperCase()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Builder(builder: (context) {
                    final displayStatus = resolveOrderDisplayStatus(order);
                    if (displayStatus != null) {
                      return BookingStatusBadge(status: displayStatus, dense: true);
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: AppRadius.full,
                      ),
                      child: Text(
                        _statusLabel(order.status),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: statusColor),
                      ),
                    );
                  }),
                ],
              ),

              const Divider(height: 20),

              // ─── Progress Bar ─────────────────────────────────────
              if (order.status != OrderStatus.cancelled) ...[
                _MiniProgressBar(status: order.status),
                const SizedBox(height: 16),
              ],

              // ─── Delivery Location ────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: AppRadius.small,
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: theme.colorScheme.primary, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${order.deliveryAddress.fullAddress}, ${order.deliveryAddress.city}',
                        style: AppTextStyles.caption.copyWith(
                            color: theme.colorScheme.onPrimaryContainer),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ─── Footer ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Amount',
                          style: AppTextStyles.caption.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      Text(
                        'Rs ${order.totalAmount.toInt()}',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Placed On',
                          style: AppTextStyles.caption.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      Text(
                        _formatDate(order.placedAt),
                        style: AppTextStyles.labelSmall
                            .copyWith(color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.accepted:
        return AppColors.primary;
      case OrderStatus.inProgress:
        return AppColors.primary;
      case OrderStatus.stitchingCompleted:
        return AppColors.success;
      case OrderStatus.riderAssigned:
        return AppColors.success;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  String _statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.stitchingCompleted:
        return 'Stitching Done';
      case OrderStatus.riderAssigned:
        return 'Rider Assigned';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Mini Progress Bar ────────────────────────────────────────────────────────
class _MiniProgressBar extends StatelessWidget {
  final OrderStatus status;
  const _MiniProgressBar({required this.status});

  @override
  Widget build(BuildContext context) {
    final ctrl = OrderController.to;
    final theme = Theme.of(context);
    final step = ctrl.statusStep(status);
    const totalSteps = 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(totalSteps, (i) {
            final isDone = i < step;
            final isActive = i == step;
            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone || isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
                  if (i < totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isDone
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          _stepLabel(status),
          style: AppTextStyles.caption
              .copyWith(color: theme.colorScheme.primary),
        ),
      ],
    );
  }

  String _stepLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 'Waiting for artist to accept';
      case OrderStatus.accepted:
        return 'Artist accepted your order';
      case OrderStatus.inProgress:
        return 'Stitching in progress';
      case OrderStatus.stitchingCompleted:
        return 'Stitching completed';
      case OrderStatus.riderAssigned:
        return 'Rider on the way';
      case OrderStatus.delivered:
        return 'Order delivered!';
      default:
        return '';
    }
  }
}
