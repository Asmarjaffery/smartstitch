import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/admin/complaint/admin_complaint_screen.dart';
import 'package:smartstitch/admin/order/admin_order_controller.dart';
import 'package:smartstitch/models/order_model.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = AdminOrderController.to;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: Column(
        children: [
          _FilterTabs(ctrl: ctrl),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final list = ctrl.filteredOrders;

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
                        child: const Icon(Icons.receipt_long_rounded,
                            size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: 20),
                      Text('No Orders Found',
                          style: AppTextStyles.h4
                              .copyWith(color: AppColors.lightTextPrimary)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _OrderCard(order: list[i], ctrl: ctrl),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Tabs ─────────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  final AdminOrderController ctrl;
  const _FilterTabs({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('all', 'All'),
      ('pending', 'Pending'),
      ('inProgress', 'In Progress'),
      ('delivered', 'Delivered'),
      ('cancelled', 'Cancelled'),
      ('complaints', 'Complaints'),
    ];

    return Obx(() => Container(
          height: 44,
          color: AppColors.lightSurface,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: tabs.map((tab) {
              final isActive = ctrl.filterStatus.value == tab.$1;
              return GestureDetector(
                onTap: () {
                  if (tab.$1 == 'complaints') {
                    Get.to(() => const AdminComplaintScreen());
                  } else {
                    ctrl.setFilter(tab.$1);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.primarySoft,
                    borderRadius: AppRadius.full,
                  ),
                  child: Text(
                    tab.$2,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isActive ? Colors.white : AppColors.primary,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ));
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final AdminOrderController ctrl;

  const _OrderCard({required this.order, required this.ctrl});

  bool get _isSelfPickup => order.deliveryAddress.label == 'Drop Off';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (order.status == OrderStatus.riderAssigned) {
          ctrl.listenToOrderLocation(order.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: AppRadius.medium,
          border: Border.all(color: AppColors.lightBorder),
          boxShadow: AppShadows.soft(AppColors.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Order ID + Status ────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.lightTextPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(order.placedAt),
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.lightTextSecondary),
                        ),
                        const SizedBox(height: 4),
                        Obx(() {
                          final name =
                              ctrl.customerNames[order.customerId] ?? '...';
                          return Row(
                            children: [
                              const Icon(Icons.person_outline_rounded,
                                  size: 13, color: AppColors.lightTextHint),
                              const SizedBox(width: 4),
                              Text(name,
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.lightTextSecondary)),
                            ],
                          );
                        }),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 13, color: AppColors.lightTextHint),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${order.deliveryAddress.fullAddress}, ${order.deliveryAddress.city}',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.lightTextSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              order.isHomeVisit
                                  ? Icons.home_outlined
                                  : Icons.store_outlined,
                              size: 13,
                              color: order.isHomeVisit
                                  ? AppColors.primary
                                  : AppColors.lightTextHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.isHomeVisit ? 'Home Visit' : 'Shop Visit',
                              style: AppTextStyles.caption.copyWith(
                                color: order.isHomeVisit
                                    ? AppColors.primary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ctrl.showStatusDialog(context, order),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(order.status)
                            .withValues(alpha: 0.12),
                        borderRadius: AppRadius.full,
                        border: Border.all(
                            color: _statusColor(order.status)
                                .withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _statusLabel(order.status),
                            style: AppTextStyles.labelSmall
                                .copyWith(color: _statusColor(order.status)),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.expand_more_rounded,
                              size: 14, color: _statusColor(order.status)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.lightBorder),

            // ── Service + Amount ─────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order.service.title,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.lightTextPrimary)),
                      Text('Total: Rs ${order.totalAmount.toStringAsFixed(0)}',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      _BreakdownChip(
                          label: 'Artist',
                          value: order.artistAmount.toInt(),
                          color: AppColors.primary),
                      if (order.deliveryFee > 0)
                        _BreakdownChip(
                            label: 'Delivery',
                            value: order.deliveryFee.toInt(),
                            color: Colors.orange),
                      _BreakdownChip(
                          label: 'Platform',
                          value: order.platformCommission.toInt(),
                          color: Colors.purple),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.lightBorder),

            // ── Assign Artist + Rider ────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: AppRadius.medium,
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.palette_rounded,
                              size: 15, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              order.artistId.isNotEmpty
                                  ? _shortName(ctrl.artists, order.artistId)
                                  : 'No Artist',
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isSelfPickup
                        ? const _SelfPickupBadge()
                        : _AssignButton(
                            icon: Icons.delivery_dining_rounded,
                            label: order.riderId != null &&
                                    order.riderId!.isNotEmpty
                                ? _shortName(ctrl.riders, order.riderId!)
                                : 'Assign Rider',
                            isAssigned: order.riderId != null &&
                                order.riderId!.isNotEmpty,
                            locked: order.status == OrderStatus.delivered,
                            onTap: () =>
                                ctrl.showAssignRiderDialog(context, order),
                          ),
                  ),
                ],
              ),
            ),

            // ── Live Rider Location Map ──────────────────────────────────
            if (order.status == OrderStatus.riderAssigned && !_isSelfPickup)
              Obx(() {
                final loc = ctrl.riderLocation.value;
                if (loc == null) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: AppRadius.medium,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.delivery_dining_rounded,
                              color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Tap card to see live location',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _RiderLocationMiniMap(location: loc),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _shortName(List<SimpleUser> users, String id) {
    final user = users.firstWhereOrNull((u) => u.id == id);
    if (user == null) return 'Assigned';
    final parts = user.name.split(' ');
    return parts.length > 1 ? '${parts[0]} ${parts[1][0]}.' : parts[0];
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}';

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
        return 'On Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.inProgress:
        return Colors.indigo;
      case OrderStatus.stitchingCompleted:
        return Colors.teal;
      case OrderStatus.riderAssigned:
        return Colors.cyan;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}

// ─── Rider Location Mini Map ──────────────────────────────────────────────────

class _RiderLocationMiniMap extends StatelessWidget {
  final Map<String, dynamic> location;
  const _RiderLocationMiniMap({required this.location});

  @override
  Widget build(BuildContext context) {
    final lat = (location['lat'] as num).toDouble();
    final lng = (location['lng'] as num).toDouble();
    final updatedAt = (location['updatedAt'] as Timestamp?)?.toDate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.delivery_dining_rounded,
                color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            Text('Rider Live Location',
                style:
                    AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
            if (updatedAt != null) ...[
              const Spacer(),
              Text(
                _timeAgo(updatedAt),
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.lightTextHint),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: AppRadius.medium,
          child: SizedBox(
            height: 160,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(lat, lng),
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.smartstitch.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(lat, lng),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ─── Self Pickup Badge ────────────────────────────────────────────────────────

class _SelfPickupBadge extends StatelessWidget {
  const _SelfPickupBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightTextHint.withValues(alpha: 0.08),
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: AppColors.lightTextHint.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_rounded,
              size: 15, color: AppColors.lightTextSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Self Pickup',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.lightTextSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Assign Button ────────────────────────────────────────────────────────────

class _AssignButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isAssigned;
  final VoidCallback onTap;
  final bool locked;

  const _AssignButton({
    required this.icon,
    required this.label,
    required this.isAssigned,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isAssigned
            ? Colors.green.withValues(alpha: 0.08)
            : AppColors.primarySoft,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isAssigned
              ? Colors.green.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 15,
              color: isAssigned ? Colors.green : AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isAssigned ? Colors.green : AppColors.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!locked) ...[
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded,
                size: 14,
                color: isAssigned ? Colors.green : AppColors.primary),
          ],
        ],
      ),
    );

    if (locked) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

// ─── Breakdown Chip ───────────────────────────────────────────────────────────

class _BreakdownChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _BreakdownChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.small,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: Rs $value',
        style: AppTextStyles.caption
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}