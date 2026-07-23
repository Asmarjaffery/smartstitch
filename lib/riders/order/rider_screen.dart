import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/routes/routes.dart';
import 'rider_order_controller.dart';

class RiderScreen extends StatelessWidget {
  const RiderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<RiderOrderController>()
        ? Get.find<RiderOrderController>()
        : Get.put(RiderOrderController());

    final riderId = AuthController.to.currentUserId ?? '';
    ctrl.loadAssignedOrders(riderId);
    ctrl.listenForCallRequests(riderId); // ✅ NEW: real-time "Ask AI to Call Rider" banner

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Obx(() => _OnlinePill(isOnline: ctrl.isOnline.value)),
                  const Spacer(),
                  Obx(() => ctrl.isTracking.value
                      ? const _LiveBadge()
                      : const SizedBox()),
                ],
              ),
            ),

            // ── Tab Bar ──
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                borderRadius: AppRadius.full,
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.full,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                labelStyle: AppTextStyles.labelMedium,
                unselectedLabelStyle: AppTextStyles.labelMedium,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'History'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: _RiderTabBody(
                ctrl: ctrl,
                riderId: riderId,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Body — Obx aur TabBarView alag widgets mein ─────────────────────────
// Yeh fix karta hai: [Get] improper use of GetX detected
// Wajah: TabBarView ke andar Obx nahi honi chahiye — scope mismatch hoti hai
class _RiderTabBody extends StatelessWidget {
  final RiderOrderController ctrl;
  final String riderId;
  final bool isDark;

  const _RiderTabBody({
    required this.ctrl,
    required this.riderId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Obx sirf loading check ke liye — TabBarView iske BAHAR hai
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
      }
      // Reactive list values nikal lo — ab TabBarView ke andar safely pass hongi
      final allOrders = ctrl.assignedOrders.toList();
      final activeOrders = allOrders
          .where((o) =>
              o['status'] != 'delivered' && o['status'] != 'cancelled')
          .toList();
      final historyOrders = allOrders
          .where((o) =>
              o['status'] == 'delivered' || o['status'] == 'cancelled')
          .toList();

      return TabBarView(
        children: [
          _OrderList(
            orders: activeOrders,
            ctrl: ctrl,
            riderId: riderId,
            emptyIcon: Icons.delivery_dining_outlined,
            emptyTitle: 'No active deliveries',
            emptySubtitle: 'New orders will appear here',
            isDark: isDark,
          ),
          _OrderList(
            orders: historyOrders,
            ctrl: ctrl,
            riderId: riderId,
            emptyIcon: Icons.history_rounded,
            emptyTitle: 'No order history yet',
            emptySubtitle: 'Delivered & cancelled orders appear here',
            isDark: isDark,
          ),
        ],
      );
    });
  }
}

// ─── Online Pill ──────────────────────────────────────────────────────────────
class _OnlinePill extends StatelessWidget {
  final bool isOnline;
  const _OnlinePill({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(isOnline ? 'Online' : 'Offline',
              style: AppTextStyles.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ─── Live Badge ───────────────────────────────────────────────────────────────
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text('Live',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.success)),
        ],
      ),
    );
  }
}

// ─── Order List ───────────────────────────────────────────────────────────────
class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final RiderOrderController ctrl;
  final String riderId;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final bool isDark;

  const _OrderList({
    required this.orders,
    required this.ctrl,
    required this.riderId,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface2 : AppColors.primarySoft,
                borderRadius: AppRadius.large,
              ),
              child: Icon(emptyIcon,
                  size: 36,
                  color: isDark
                      ? AppColors.darkTextHint
                      : AppColors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            Text(emptyTitle,
                style: AppTextStyles.h4.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary)),
            const SizedBox(height: 6),
            Text(emptySubtitle,
                style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ctrl.loadAssignedOrders(riderId),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) =>
            _RiderOrderCard(order: orders[i], ctrl: ctrl, isDark: isDark),
      ),
    );
  }
}

// ─── Rider Order Card ─────────────────────────────────────────────────────────
// NOTE: StatefulWidget — taake initState mein data set ho
// aur Obx ke baghair bhi reactive rahe
class _RiderOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final RiderOrderController ctrl;
  final bool isDark;

  const _RiderOrderCard({
    required this.order,
    required this.ctrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final String orderId = order['id'] ?? '';
    final String status = order['status'] ?? '';
    final String riderStatus = order['riderStatus'] ?? 'pending';
    final String serviceTitle = order['serviceTitle'] ?? 'Service';
    final double amount =
        (order['servicePrice'] as num?)?.toDouble() ?? 0;

    // ── Customer info (enriched in controller) ──
    final String customerId = order['customerId'] ?? '';
    final String customerName = order['customerName'] ?? 'Customer';
    final String customerPhone = order['customerPhone'] ?? '';

    // ── Artist info ──
    final String artistName = order['artistName'] ?? 'Artist';
    final String artistPhone = order['artistPhone'] ?? '';
    final String shopFullAddress =
        order['shopFullAddress'] ?? 'Tailor Shop';

    // ── Customer address (AddressModel fields stored as nested map) ──
    final addrRaw = order['address'];
    String deliverAddress = '';
    String deliverCity = '';
    if (addrRaw is Map) {
      deliverAddress = addrRaw['fullAddress'] as String? ?? '';
      deliverCity = addrRaw['city'] as String? ?? '';
    }
    final String fullDeliveryLine = [deliverAddress, deliverCity]
        .where((s) => s.isNotEmpty)
        .join(', ');

    final String appointmentDate = order['appointmentDate'] ?? '';
    final bool isActiveOrder = status != 'delivered' && status != 'cancelled';

    final Color statusColor = _statusColor(status, riderStatus);
    final String statusLabel = _statusLabel(status, riderStatus);
    final IconData statusIcon = _statusIcon(status, riderStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppRadius.large,
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow:
            AppShadows.soft(isDark ? Colors.black : AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: service + status badge ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: AppRadius.small,
                    ),
                    child: const Icon(Icons.delivery_dining_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(serviceTitle,
                          style: AppTextStyles.labelLarge.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary)),
                      Text(
                        '#${orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}',
                        style: AppTextStyles.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint),
                      ),
                    ],
                  ),
                ],
              ),
              _StatusBadge(
                  label: statusLabel,
                  icon: statusIcon,
                  color: statusColor),
            ],
          ),

          const SizedBox(height: 12),
          Divider(
              color:
                  isDark ? AppColors.darkDivider : AppColors.lightDivider,
              thickness: 1,
              height: 1),
          const SizedBox(height: 12),

          // ── Step indicator (only for active orders) ──
          if (isActiveOrder) ...[
            _StepIndicator(riderStatus: riderStatus, isDark: isDark),
            const SizedBox(height: 12),
          ],

          // ── Customer info ──
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Customer',
            value: customerName,
            isDark: isDark,
          ),
          if (customerPhone.isNotEmpty)
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: customerPhone,
              isDark: isDark,
            ),

          // ── Call + Ask AI (only for active orders) ──
          if (isActiveOrder && customerPhone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _OutlinedPillButton(
                    label: 'Call',
                    icon: Icons.call_rounded,
                    color: AppColors.success,
                    onTap: () => _callNumber(customerPhone),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OutlinedPillButton(
                    label: 'Ask AI',
                    icon: Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    onTap: () => ctrl.askAiToCallCustomer(order),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // ── Artist info ──
          _InfoRow(
            icon: Icons.storefront_outlined,
            label: 'Artist',
            value: artistName,
            isDark: isDark,
          ),
          if (artistPhone.isNotEmpty)
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Artist Ph',
              value: artistPhone,
              isDark: isDark,
            ),

          const SizedBox(height: 8),

          // ── Pickup address ──
          _AddressRow(
            dot: AppColors.primary,
            label: 'Pickup',
            text: shopFullAddress,
            isDark: isDark,
          ),
          const SizedBox(height: 6),

          // ── Delivery address ──
          _AddressRow(
            dot: AppColors.success,
            label: 'Deliver',
            text: fullDeliveryLine.isNotEmpty
                ? fullDeliveryLine
                : 'Address not set',
            isDark: isDark,
          ),

          if (appointmentDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint,
                    size: 13),
                const SizedBox(width: 5),
                Text(_formatDate(appointmentDate),
                    style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary)),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // ── Footer: earning + actions ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Earning',
                      style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.lightTextSecondary)),
                  Text('Rs ${amount.toInt()}',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.primary)),
                ],
              ),
              // ── Flexible + Obx — always reads an observable so GetX
              // never throws "improper use of Obx", aur footer overflow
              // bhi nahi hota chhoti screens par ──
              Flexible(
                child: Obx(() {
                  final tracking = ctrl.isTracking.value;
                  final activeId = ctrl.activeOrderId.value;
                  return _buildActions(
                      orderId, status, riderStatus, tracking, activeId);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Call customer via device dialer ──
  Future<void> _callNumber(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        Get.snackbar('Error', 'Call nahi ho saka',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (_) {
      Get.snackbar('Error', 'Call nahi ho saka',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Open customer address in Google Maps ──
  Future<void> _openMap(String address) async {
    final query = Uri.encodeComponent(address);
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Error', 'Location open nahi ho saki',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (_) {
      Get.snackbar('Error', 'Location open nahi ho saki',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Widget _buildActions(String orderId, String status, String riderStatus,
      bool tracking, String activeId) {
    if (status == 'delivered') {
      return const _StatusPillChip(
        label: 'Completed',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
    }
    if (status == 'cancelled') {
      return const _StatusPillChip(
        label: 'Cancelled',
        icon: Icons.cancel_rounded,
        color: AppColors.error,
      );
    }

    // Step 1 — New order
    if (riderStatus == 'pending' || riderStatus.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: _OutlinedPillButton(
              label: 'Reject',
              icon: Icons.close_rounded,
              color: AppColors.error,
              onTap: () => _confirmReject(orderId),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: _GradientPillButton(
              label: 'Accept',
              onTap: () => ctrl.acceptOrder(orderId),
            ),
          ),
        ],
      );
    }

    // Step 2 — Accepted, pickup karo
    if (riderStatus == 'accepted') {
      return _GradientPillButton(
        label: 'Start Delivery',
        icon: Icons.delivery_dining_rounded,
        onTap: () => ctrl.startDelivery(orderId),
      );
    }

    // Step 3 — Delivering
    if (riderStatus == 'delivering') {
      final isTrackingThis = tracking && activeId == orderId;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: _OutlinedPillButton(
              label: isTrackingThis ? 'Stop' : 'Location',
              icon: isTrackingThis
                  ? Icons.location_off_rounded
                  : Icons.location_on_rounded,
              color: isTrackingThis ? AppColors.error : AppColors.primary,
              onTap: () => isTrackingThis
                  ? ctrl.stopTracking()
                  : ctrl.startDelivery(orderId),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: _GradientPillButton(
              label: 'Delivered',
              onTap: () => _confirmDelivered(orderId),
            ),
          ),
        ],
      );
    }

    if (riderStatus == 'rejected') {
      return const _StatusPillChip(
        label: 'Rejected',
        icon: Icons.cancel_rounded,
        color: AppColors.error,
      );
    }

    return const SizedBox();
  }

  void _confirmReject(String orderId) {
    Get.dialog(AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Order Reject Karo?'),
      content: const Text(
          'Kya aap sure hain? Admin ko dobara rider assign karna hoga.'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        OutlinedButton(
          onPressed: () {
            Get.back();
            ctrl.rejectOrder(orderId);
          },
          style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error)),
          child: const Text('Reject'),
        ),
      ],
    ));
  }

  void _confirmDelivered(String orderId) {
    Get.dialog(AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Mark as Delivered?'),
      content: const Text('Confirm karo ke order deliver ho gaya?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Get.back();
            ctrl.markDelivered(orderId);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary),
          child:
              const Text('Confirm', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  Color _statusColor(String status, String riderStatus) {
    if (status == 'delivered') return AppColors.success;
    if (status == 'cancelled') return AppColors.error;
    switch (riderStatus) {
      case 'accepted':
        return AppColors.info;
      case 'delivering':
        return AppColors.primary;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData _statusIcon(String status, String riderStatus) {
    if (status == 'delivered') return Icons.check_circle_rounded;
    if (status == 'cancelled') return Icons.cancel_rounded;
    switch (riderStatus) {
      case 'accepted':
        return Icons.thumb_up_rounded;
      case 'delivering':
        return Icons.delivery_dining_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  String _statusLabel(String status, String riderStatus) {
    if (status == 'delivered') return 'Delivered';
    if (status == 'cancelled') return 'Cancelled';
    switch (riderStatus) {
      case 'accepted':
        return 'Accepted';
      case 'delivering':
        return 'Delivering';
      case 'rejected':
        return 'Rejected';
      default:
        return 'New Order';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final String riderStatus;
  final bool isDark;

  const _StepIndicator({required this.riderStatus, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const steps = ['Accept', 'Pickup', 'Delivered'];
    int activeStep = 0;
    if (riderStatus == 'accepted') activeStep = 1;
    if (riderStatus == 'delivering') activeStep = 2;

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final filled = (i ~/ 2) < activeStep;
          return Expanded(
            child: Container(
              height: 2,
              color: filled
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final done = stepIndex < activeStep;
        final active = stepIndex == activeStep;

        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done || active
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkSurface2
                        : AppColors.primarySoft),
                border: Border.all(
                  color: done || active
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : Text('${stepIndex + 1}',
                        style: AppTextStyles.caption.copyWith(
                          color: active
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextHint
                                  : AppColors.lightTextHint),
                          fontWeight: FontWeight.bold,
                        )),
              ),
            ),
            const SizedBox(height: 4),
            Text(steps[stepIndex],
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: done || active
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextHint
                          : AppColors.lightTextHint),
                )),
          ],
        );
      }),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: isDark
                  ? AppColors.darkTextHint
                  : AppColors.lightTextHint),
          const SizedBox(width: 6),
          Text('$label: ',
              style: AppTextStyles.caption.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontWeight: FontWeight.w600,
              )),
          Expanded(
            child: Text(value,
                style: AppTextStyles.caption.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ─── Address Row ──────────────────────────────────────────────────────────────
class _AddressRow extends StatelessWidget {
  final Color dot;
  final String label;
  final String text;
  final bool isDark;

  const _AddressRow({
    required this.dot,
    required this.label,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: ',
            style: AppTextStyles.caption.copyWith(
              color: dot,
              fontWeight: FontWeight.w600,
            )),
        Expanded(
          child: Text(text,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusBadge(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.full),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ─── Status Pill Chip ─────────────────────────────────────────────────────────
class _StatusPillChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusPillChip(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.full),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ─── Outlined Pill Button ─────────────────────────────────────────────────────
class _OutlinedPillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OutlinedPillButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.full,
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  style: AppTextStyles.labelSmall.copyWith(color: color),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gradient Pill Button ─────────────────────────────────────────────────────
class _GradientPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _GradientPillButton(
      {required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppRadius.full,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: AppTextStyles.labelSmall
                    .copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}