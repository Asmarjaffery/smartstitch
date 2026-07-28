import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartstitch/models/order_model.dart';
import 'package:smartstitch/models/refund_model.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/user/order/order_controller.dart';
import 'package:smartstitch/routes/routes.dart';
// ✅ needed to notify the rider when customer taps "Ask AI to Call Rider"
import 'package:smartstitch/services/notification_service.dart';
// ✅ opens the device dialer directly on the rider's number
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _reviewShown = false;
  String? _lastOrderId;
  bool _reviewCheckComplete = false;

  @override
  void initState() {
    super.initState();
    final order = OrderController.to.selectedOrder.value;
    if (order != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        OrderController.to.loadOrderExtras(order);
        OrderController.to.listenToOrder(order.id);
      });
    }
  }

  void _checkAndShowReview() {
    final order = OrderController.to.selectedOrder.value;
    if (order != null &&
        order.status == OrderStatus.delivered &&
        _lastOrderId != order.id &&
        !_reviewCheckComplete) {
      _lastOrderId = order.id;
      _reviewShown = false;
      _reviewCheckComplete = true;

      // ✅ FIXED: Handle nullable riderId with null coalescing
      _checkIfReviewExists(order.id, order.riderId ?? '');
    }
  }

  Future<void> _checkIfReviewExists(String orderId, String riderId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      // ✅ Skip the check if riderId is empty (rider not assigned yet)
      if (riderId.isEmpty) {
        debugPrint('⚠️ Rider not assigned yet for order: $orderId');
        return;
      }

      // ✅ Check if user already reviewed THIS ORDER with THIS RIDER
      final existingReview = await FirebaseFirestore.instance
          .collection('reviews')
          .where('orderId', isEqualTo: orderId)
          .where('customerId', isEqualTo: userId)
          .where('riderId', isEqualTo: riderId)
          .limit(1)
          .get();

      // ✅ Don't show the popup if a review already exists
      if (existingReview.docs.isNotEmpty) {
        debugPrint('✅ Review already exists for order: $orderId with rider: $riderId');
        _reviewShown = true;
        return;
      }

      // ✅ Show the popup if no review exists
      if (mounted && !_reviewShown) {
        _showReviewPopup(OrderController.to.selectedOrder.value!);
      }
    } catch (e) {
      debugPrint('❌ Error checking review: $e');
    }
  }

  void _showReviewPopup(OrderModel order) {
    if (_reviewShown) return;
    _reviewShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReviewPopup(order: order),
    ).then((_) {
      _reviewShown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = OrderController.to;
    final theme = Theme.of(context);

    // Check for delivered status to show review
    _checkAndShowReview();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Order Details', style: AppTextStyles.h4),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Obx(() {
        final order = ctrl.selectedOrder.value;
        if (order == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final isSelfPickup = order.deliveryAddress.label == 'Drop Off';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderHeader(order: order),
              const SizedBox(height: 16),
              // Delivery Exception (rider-reported failed delivery) —
              // shown above everything else so it's impossible to miss.
              // `status` stays `riderAssigned` while this is pending admin
              // review, so this card is the only signal the customer gets.
              if (order.isDeliveryFailed) ...[
                _DeliveryFailedCard(order: order),
                const SizedBox(height: 16),
              ],
              // Custom Design Quote Flow — shown above everything else
              // while this booking is waiting on the artist, or waiting
              // on the customer to accept/decline a price.
              if (order.quoteStatus != QuoteStatus.notRequired) ...[
                _QuoteStatusCard(order: order),
                const SizedBox(height: 16),
              ],
              _SectionCard(
                title: 'Order Summary',
                icon: Icons.receipt_long_rounded,
                child: Column(
                  children: [
                    _InfoRow(label: 'Service', value: order.service.title),
                    _InfoRow(
                      label: 'Placed On',
                      value: _formatDateTime(order.placedAt),
                    ),
                    _InfoRow(
                      label: 'Base Price',
                      value: 'Rs ${order.service.basePrice.toInt()}',
                    ),
                    _InfoRow(
                      label: 'Total Amount',
                      value: 'Rs ${order.totalAmount.toInt()}',
                    ),
                    _InfoRow(
                        label: 'Status', value: _statusLabel(order.status)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (order.status != OrderStatus.cancelled) ...[
                const Text('Order Tracking', style: AppTextStyles.h4),
                const SizedBox(height: 16),
                // pass orderId + riderId so the "Ask AI to Call Rider"
                // button can write the call-request flag to Firestore
                // and notify the rider directly.
                Obx(() => _OrderTracker(
                      orderId: order.id,
                      riderId: order.riderId,
                      status: order.status,
                      isSelfPickup: isSelfPickup,
                      riderPhone: OrderController.to.selectedRiderPhone.value,
                      riderLocationWidget: (!isSelfPickup &&
                              order.status == OrderStatus.riderAssigned)
                          ? _RiderLiveLocation(
                              riderLocation: ctrl.riderLocation.value,
                              timeAgo: _timeAgo,
                            )
                          : null,
                    )),
                const SizedBox(height: 24),
              ],
              _SectionCard(
                title: 'Service Details',
                icon: Icons.checkroom_rounded,
                child: Column(
                  children: [
                    _InfoRow(label: 'Service', value: order.service.title),
                    _InfoRow(
                      label: 'Base Price',
                      value: 'Rs ${order.service.basePrice.toInt()}',
                    ),
                    if (order.specialInstructions != null)
                      _InfoRow(
                        label: 'Instructions',
                        value: order.specialInstructions!,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Measurements collection docs are keyed by a random UUID +
              // `userId` field (per-user profile data), NOT by order.id.
              // The order already carries its own snapshot of the
              // measurements used at checkout time (order.measurements),
              // so just render that directly.
              _SectionCard(
                title: 'Measurements',
                icon: Icons.straighten_rounded,
                child: Builder(
                  builder: (context) {
                    final data = order.measurements;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MeasChip(label: 'Height', value: data.height),
                        _MeasChip(label: 'Chest', value: data.chest),
                        _MeasChip(label: 'Waist', value: data.waist),
                        _MeasChip(label: 'Shoulder', value: data.shoulder),
                        _MeasChip(label: 'Hips', value: data.hips),
                        _MeasChip(label: 'Sleeve', value: data.sleevLength),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (order.designImages.isNotEmpty) ...[
                _SectionCard(
                  title: 'Design Images',
                  icon: Icons.image_outlined,
                  child: SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: order.designImages.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ClipRRect(
                          borderRadius: AppRadius.medium,
                          child: Image.network(
                            order.designImages[i],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 100,
                              height: 100,
                              color: AppColors.primarySoft,
                              child: const Icon(
                                Icons.image_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _SectionCard(
                title: 'Delivery / Pickup Address',
                icon: isSelfPickup
                    ? Icons.storefront_outlined
                    : Icons.location_on_outlined,
                child: Column(
                  children: [
                    _InfoRow(
                        label: 'Label', value: order.deliveryAddress.label),
                    _InfoRow(
                      label: 'Address',
                      value: order.deliveryAddress.fullAddress,
                    ),
                    _InfoRow(
                      label: 'City',
                      value:
                          '${order.deliveryAddress.city}, ${order.deliveryAddress.province}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Artist',
                icon: Icons.person_outline_rounded,
                child: Obx(() => Column(
                      children: [
                        _InfoRow(
                          label: 'Name',
                          value: OrderController.to.selectedOrderArtistName.value.isEmpty
                              ? 'Loading...'
                              : OrderController.to.selectedOrderArtistName.value,
                        ),
                        if (OrderController.to.selectedOrderArtistPhone.value.isNotEmpty)
                          _InfoRow(
                            label: 'Phone',
                            value: OrderController.to.selectedOrderArtistPhone.value,
                          ),
                      ],
                    )),
              ),
              const SizedBox(height: 16),
              if (OrderController.to.selectedRiderName.value.isNotEmpty ||
                  order.status == OrderStatus.riderAssigned ||
                  order.status == OrderStatus.delivered) ...[
                _SectionCard(
                  title: 'Rider',
                  icon: Icons.delivery_dining_rounded,
                  // "Ask AI to Call Rider" button lives under the "Rider
                  // Assigned" step inside the Order Tracking card above —
                  // this section just shows rider info.
                  child: Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            label: 'Name',
                            value: OrderController.to.selectedRiderName.value.isEmpty
                                ? 'Not assigned'
                                : OrderController.to.selectedRiderName.value,
                          ),
                          if (OrderController.to.selectedRiderPhone.value.isNotEmpty)
                            _InfoRow(
                              label: 'Phone',
                              value: OrderController.to.selectedRiderPhone.value,
                            ),
                        ],
                      )),
                ),
                const SizedBox(height: 16),
              ],

              // ── Payment Breakdown ─────────────────────────────────
              _SectionCard(
                title: 'Payment Breakdown',
                icon: Icons.payment_rounded,
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Service Price',
                      value: 'Rs ${order.servicePrice.toInt()}',
                    ),
                    if (order.deliveryFee > 0)
                      _InfoRow(
                        label: 'Delivery Fee',
                        value: 'Rs ${order.deliveryFee.toInt()}',
                      ),
                    const Divider(height: 16),
                    _InfoRow(
                      label: 'Total Amount',
                      value: 'Rs ${order.totalAmount.toInt()}',
                    ),
                    const Divider(height: 16),
                    // Show proper payment breakdown with three components
                    _AmountChipsRow(order: order),
                    if (order.payment != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Payment Method',
                        value: order.payment!.method.name,
                      ),
                      _InfoRow(
                        label: 'Payment Status',
                        value: order.payment!.status.name,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Normal cancel / refund / reschedule actions only make
              // sense once there's an actual fixed price on the booking —
              // while a custom-design quote is pending or awaiting the
              // customer's decision, the dedicated Accept/Decline card
              // above (see _QuoteStatusCard) is the only relevant action.
              if (order.quoteStatus == QuoteStatus.notRequired ||
                  order.quoteStatus == QuoteStatus.accepted) ...[
                if (OrderController.to.canCancel(order.status))
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: OrderController.to.isLoading.value
                              ? null
                              : () => _confirmCancel(order.id),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.medium,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel Order',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )),
                // If a refund request already exists for this order, show
                // its status card instead of the "Request Refund" button.
                //
                // Refund + Reschedule also show up when the rider has
                // reported a failed delivery — not just when
                // `status == cancelled` — since a failed delivery leaves
                // `status` stuck at `riderAssigned`.
                if (order.status == OrderStatus.cancelled ||
                    order.isDeliveryFailed) ...[
                  const SizedBox(height: 12),
                  Obx(() {
                    final refund = OrderController.to.selectedRefundRequest.value;

                    if (refund != null) {
                      return _RefundRequestCard(refund: refund);
                    }

                    // ✅ NEW: "Request Refund" is only ever shown for
                    // card/Stripe payments. COD, wallet, or any other
                    // payment method never had money captured through
                    // Stripe/card in a way this refund flow can process,
                    // so the button — and everything it would take up —
                    // simply doesn't render for those orders.
                    final isCardPayment =
                        OrderController.to.isCardPayment(order.id);

                    if (!isCardPayment) {
                      return const SizedBox.shrink();
                    }

                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: OrderController.to.isLoading.value
                            ? null
                            : () => _confirmRefund(order.id),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.primary),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.medium,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Request Refund',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    );
                  }),
                  // Reschedule Order — lets the customer put a cancelled
                  // OR delivery-failed order back in front of the artist
                  // with a new date instead of starting a brand new
                  // booking. Available regardless of payment method.
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Obx(() => ElevatedButton.icon(
                          onPressed: OrderController.to.isLoading.value
                              ? null
                              : () => _confirmReschedule(order.id),
                          icon: const Icon(Icons.event_repeat_rounded),
                          label: const Text('Reschedule Order'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.medium,
                            ),
                          ),
                        )),
                  ),
                ],
              ],
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  // Reschedule flow — pick a new date, then confirm before writing.
  Future<void> _confirmReschedule(String orderId) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null || !mounted) return;

    final newDate = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Reschedule Order?'),
        content: Text(
          'The order will be rescheduled to ${newDate.day}/${newDate.month}/${newDate.year} '
          '${TimeOfDay.fromDateTime(newDate).format(context)} and sent back to the artist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              OrderController.to.rescheduleOrder(orderId, newDate);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(String orderId) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // close the confirm dialog only
              await OrderController.to.cancelOrder(orderId);
              // Order stays on detail screen so user sees updated
              // "Cancelled" status instead of being kicked back.
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // OrderController.requestRefund expects (orderId, CancellationReason
  // reason, String description) — lets the customer pick a proper reason
  // from a dropdown plus an optional free-text description.
  void _confirmRefund(String orderId) {
    final descCtrl = TextEditingController();
    CancellationReason selectedReason = CancellationReason.changedMind;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Request Refund'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select a reason for the refund:'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CancellationReason>(
                    initialValue: selectedReason,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: CancellationReason.values
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.label),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedReason = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('If you would like to add more details...'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Provide additional details (optional)...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Get.back(); // close the dialog only
                  await OrderController.to.requestRefund(
                    orderId,
                    selectedReason,
                    descCtrl.text.trim(),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary),
                child: const Text(
                  'Submit Request',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
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

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $ampm';
  }
}

// ─── Delivery Failed Card ──────────────────────────────────────────────────
// The only signal the customer gets that a delivery attempt was reported
// as failed by the rider — `status` stays `riderAssigned` until admin
// resolves the exception, so this card has to surface it directly.

class _DeliveryFailedCard extends StatelessWidget {
  final OrderModel order;
  const _DeliveryFailedCard({required this.order});

  String _reasonLabel(String? reason) {
    switch (reason) {
      case 'customerDidNotAnswer':
        return 'You did not answer the call or door.';
      case 'wrongAddress':
        return 'The address was incorrect or could not be found.';
      case 'customerRefused':
        return 'Delivery was refused.';
      default:
        return 'The rider could not complete the delivery.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: AppRadius.large,
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Failed',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _reasonLabel(order.deliveryExceptionReason),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.orange.shade800),
                ),
                const SizedBox(height: 4),
                Text(
                  'This is under admin review. You can request a refund or reschedule the order below.',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.orange.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom Design Quote Status Card ───────────────────────────────────────
// Shown at the top of the detail screen for any booking that's part of the
// design-image/instructions quote flow (see QuoteStatus). Three states:
// waiting on the artist, waiting on the customer's decision, or accepted.

class _QuoteStatusCard extends StatelessWidget {
  final OrderModel order;
  const _QuoteStatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = AppColors.primary;
    final primarySoft = isDark ? AppColors.darkSurface2 : AppColors.primarySoft;

    switch (order.quoteStatus) {
      case QuoteStatus.pendingQuote:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primarySoft,
            borderRadius: AppRadius.large,
            border: Border.all(color: primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Waiting for Artist',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: primary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'The artist is reviewing your design/instructions and will send a price soon.',
                      style: AppTextStyles.bodySmall.copyWith(color: primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case QuoteStatus.quoted:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadius.large,
            border: Border.all(color: primary.withValues(alpha: 0.3)),
            boxShadow: AppShadows.soft(primary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_offer_rounded, color: primary, size: 22),
                  const SizedBox(width: 10),
                  Text('Artist Sent a Price',
                      style: AppTextStyles.labelLarge.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quoted Price',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)),
                  Text('Rs ${(order.quotedPrice ?? 0).toInt()}',
                      style: AppTextStyles.h4.copyWith(color: primary)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _confirmDecline(context, order),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.medium),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Decline',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => OrderController.to.acceptQuote(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.medium),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Accept & Pay',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case QuoteStatus.accepted:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: isDark ? 0.18 : 0.1),
            borderRadius: AppRadius.medium,
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Quote accepted — Rs ${(order.quotedPrice ?? order.servicePrice).toInt()} paid.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.success),
                ),
              ),
            ],
          ),
        );

      case QuoteStatus.declined:
      case QuoteStatus.notRequired:
        return const SizedBox();
    }
  }

  void _confirmDecline(BuildContext context, OrderModel order) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Decline Quote'),
        content: const Text(
          'Are you sure you want to decline this price? The booking will be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await OrderController.to.declineQuote(order);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Decline',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Review Popup ─────────────────────────────────────────────────────────────

class _ReviewPopup extends StatefulWidget {
  final OrderModel order;
  const _ReviewPopup({required this.order});

  @override
  State<_ReviewPopup> createState() => _ReviewPopupState();
}

class _ReviewPopupState extends State<_ReviewPopup> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      Get.snackbar('Rating Required', 'Please select a rating');
      return;
    }

    _isLoading = true;
    setState(() {});

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final riderId = widget.order.riderId;

      // Resolve rider name at submission time so it's always saved with
      // the review itself, instead of relying on a fallback lookup later.
      String? riderName = OrderController.to.selectedRiderName.value;
      if (riderName.isEmpty && riderId != null && riderId.isNotEmpty) {
        try {
          final riderDoc = await FirebaseFirestore.instance
              .collection('riders')
              .doc(riderId)
              .get();
          riderName = riderDoc.data()?['name'] ??
              riderDoc.data()?['fullName'] ??
              riderDoc.data()?['displayName'];
        } catch (_) {
          riderName = null;
        }
      }

      // Review data to save
      final reviewData = {
        'orderId': widget.order.id,
        'customerId': userId,
        'riderId': riderId,
        'riderName': (riderName == null || riderName.isEmpty) ? null : riderName,
        'artistId': widget.order.artistId,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'type': 'rider_delivery',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to reviews collection
      await FirebaseFirestore.instance
          .collection('reviews')
          .add(reviewData);

      // Null check for riderId
      if (riderId != null && riderId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('riders')
            .doc(riderId)
            .update({
          'totalReviews': FieldValue.increment(1),
          'totalRating': FieldValue.increment(_rating),
          'averageRating': FieldValue.increment(_rating / 5.0),
        });
      }

      Get.back();
      Get.snackbar('Success', 'Review submitted successfully!',
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit review: $e');
    } finally {
      _isLoading = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rate Your Delivery',
                    style: AppTextStyles.h4.copyWith(
                        color: theme.colorScheme.onSurface)),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? theme.colorScheme.outline
                          : theme.colorScheme.outline,
                    ),
                    child: Icon(Icons.close,
                        size: 20, color: theme.colorScheme.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'How was your delivery experience?',
              style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final isFilled = i < _rating;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        isFilled ? Icons.star_rounded : Icons.star_outline,
                        size: 40,
                        color: isFilled
                            ? Colors.amber
                            : theme.colorScheme.outline,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 300,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Share your feedback (optional)...',
                hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide:
                      BorderSide(color: theme.colorScheme.outline, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide(
                      color: theme.colorScheme.primary, width: 1.5),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Skip',
                        style: TextStyle(
                            color: theme.colorScheme.onSurface)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('Submit Review',
                            style: TextStyle(
                                color: theme.colorScheme.onPrimary)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Amount Chips Row ─────────────────────────────────────────────────────────

class _AmountChipsRow extends StatelessWidget {
  final OrderModel order;
  const _AmountChipsRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Combine Artist + Platform (user/artist share) and show Delivery separate
    final artistShare = order.artistAmount.toInt() + order.platformCommission.toInt();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _AmountChip(
          label: 'Artist Share',
          value: artistShare,  // Artist + Platform combined
          color: theme.colorScheme.primary,
          icon: Icons.palette_rounded,
        ),
        if (order.deliveryFee > 0)
          _AmountChip(
            label: 'Delivery',
            value: order.deliveryFee.toInt(),
            color: Colors.orange,
            icon: Icons.delivery_dining_rounded,
          ),
      ],
    );
  }
}

class _AmountChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _AmountChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.small,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: Rs $value',
            style: AppTextStyles.caption
                .copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Order Header ─────────────────────────────────────────────────────────────

class _OrderHeader extends StatelessWidget {
  final OrderModel order;
  const _OrderHeader({required this.order});

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $ampm';
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

  @override
  Widget build(BuildContext context) {
    final ctrl = OrderController.to;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order ID',
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.white70)),
                  Text(
                    '#${order.id.substring(0, 8).toUpperCase()}',
                    style: AppTextStyles.h4.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(order.placedAt),
                    style:
                        AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: AppRadius.full,
                ),
                child: Text(
                  _statusLabel(order.status),
                  style:
                      AppTextStyles.labelMedium.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Artist: ${ctrl.selectedOrderArtistName.value.isEmpty ? "Loading..." : ctrl.selectedOrderArtistName.value}',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                  ),
                  Text(
                    'Rider: ${ctrl.selectedRiderName.value.isEmpty ? "Not assigned" : ctrl.selectedRiderName.value}',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}

// ─── Order Tracker ────────────────────────────────────────────────────────────

class _OrderTracker extends StatelessWidget {
  // needed to write the call-request flag to the right booking doc and to
  // know which rider to notify.
  final String orderId;
  final String? riderId;
  final OrderStatus status;
  final bool isSelfPickup;
  // rider phone, used to show the "Ask AI to Call Rider" button directly
  // under the "Rider Assigned" step.
  final String? riderPhone;
  // the rider live-location map, rendered directly under the "Rider
  // Assigned" step instead of floating in its own card below.
  final Widget? riderLocationWidget;
  const _OrderTracker({
    required this.orderId,
    this.riderId,
    required this.status,
    required this.isSelfPickup,
    this.riderPhone,
    this.riderLocationWidget,
  });

  // Opens the device dialer on the rider's number directly, and still
  // logs the request + notifies the rider so they see a missed-call
  // context even if the call doesn't connect.
  Future<void> _askAiToCallRider(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(orderId)
          .update({
        'callRequestedByCustomer': true,
        'callRequestedAt': FieldValue.serverTimestamp(),
      });

      if (riderId != null && riderId!.isNotEmpty) {
        await NotificationService.instance.sendNotification(
          recipientId: riderId!,
          recipientRole: UserRole.rider,
          type: NotificationType.orderUpdate,
          title: 'Customer Calling',
          body: 'A customer would like to contact you.',
          data: {'orderId': orderId, 'action': 'callRequest'},
        );
      }
    } catch (e) {
      debugPrint('Call request notify error: $e');
    }

    // Actually place the call.
    if (riderPhone != null && riderPhone!.isNotEmpty) {
      final callUri = Uri(scheme: 'tel', path: riderPhone);
      final canCall = await canLaunchUrl(callUri);
      if (canCall) {
        await launchUrl(callUri);
        return;
      }
    }

    // Fallback: if we somehow can't dial (no phone number, or simulator/
    // web build without a dialer), keep the old AI-chat hand-off so the
    // customer still has a way to reach the rider.
    if (context.mounted) {
      Get.toNamed(
        AppRoutes.aiChat,
        arguments: {
          'type': 'callRider',
          'phone': riderPhone,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = OrderController.to;
    final theme = Theme.of(context);
    final absoluteStep = ctrl.statusStep(status);

    final steps = isSelfPickup
        ? const [
            _TrackStep(icon: Icons.pending_outlined, label: 'Pending'),
            _TrackStep(icon: Icons.check_circle_outline, label: 'Accepted'),
            _TrackStep(icon: Icons.content_cut_rounded, label: 'In Progress'),
            _TrackStep(icon: Icons.done_all_rounded, label: 'Stitching Done'),
            _TrackStep(
                icon: Icons.storefront_rounded, label: 'Ready / Picked Up'),
          ]
        : const [
            _TrackStep(icon: Icons.pending_outlined, label: 'Pending'),
            _TrackStep(icon: Icons.check_circle_outline, label: 'Accepted'),
            _TrackStep(icon: Icons.content_cut_rounded, label: 'In Progress'),
            _TrackStep(icon: Icons.done_all_rounded, label: 'Stitching Done'),
            _TrackStep(
                icon: Icons.delivery_dining_rounded, label: 'Rider Assigned'),
            _TrackStep(icon: Icons.home_rounded, label: 'Delivered'),
          ];

    final currentStep =
        isSelfPickup && absoluteStep >= 4 ? absoluteStep - 1 : absoluteStep;

    // Show the call button only when the order is currently sitting at
    // the "Rider Assigned" step and we actually have a phone number.
    final showCallRiderButton = !isSelfPickup &&
        status == OrderStatus.riderAssigned &&
        riderPhone != null &&
        riderPhone!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: List.generate(steps.length, (i) {
          final isDone = i < currentStep;
          final isActive = i == currentStep;
          final isLast = i == steps.length - 1;
          final isRiderAssignedStep = steps[i].label == 'Rider Assigned';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? AppColors.success
                              : isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                        ),
                        child: Icon(
                          isDone ? Icons.check_rounded : steps[i].icon,
                          color: isDone || isActive
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 32,
                          color: isDone
                              ? AppColors.success
                              : theme.colorScheme.outline,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      steps[i].label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isDone
                            ? AppColors.success
                            : isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              // "Ask AI to Call Rider" rendered right here, directly
              // under the Rider Assigned step, so it's unambiguous which
              // rider the button refers to.
              if (isRiderAssignedStep && showCallRiderButton)
                Padding(
                  padding: const EdgeInsets.only(left: 50, top: 8, bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _askAiToCallRider(context),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: const Text('Ask AI to Call Rider'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
              // rider live-location map, also pinned directly under the
              // "Rider Assigned" step so everything about the rider is
              // grouped in one clear place.
              if (isRiderAssignedStep && riderLocationWidget != null)
                Padding(
                  padding: const EdgeInsets.only(left: 50, top: 4, bottom: 16),
                  child: riderLocationWidget!,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _TrackStep {
  final IconData icon;
  final String label;
  const _TrackStep({required this.icon, required this.label});
}

// ─── Rider Live Location (embedded under the "Rider Assigned" step) ──────

class _RiderLiveLocation extends StatelessWidget {
  final Map<String, dynamic>? riderLocation;
  final String Function(DateTime) timeAgo;

  const _RiderLiveLocation({
    required this.riderLocation,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = riderLocation;

    if (loc == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text('Locating rider...',
                style: TextStyle(color: theme.colorScheme.onSurface)),
          ],
        ),
      );
    }

    final lat = (loc['lat'] as num).toDouble();
    final lng = (loc['lng'] as num).toDouble();
    final updatedAt = (loc['updatedAt'] as Timestamp?)?.toDate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.delivery_dining_rounded,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text('Rider Live Location',
                style: AppTextStyles.labelMedium.copyWith(
                    color: theme.colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(lat, lng),
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
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
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.delivery_dining_rounded,
                        color: theme.colorScheme.primary,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (updatedAt != null)
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                'Last updated: ${timeAgo(updatedAt)}',
                style: AppTextStyles.caption.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: AppTextStyles.labelLarge.copyWith(
                      color: theme.colorScheme.onSurface)),
            ],
          ),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.labelSmall.copyWith(
                    color: theme.colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }
}

// ─── Meas Chip ────────────────────────────────────────────────────────────────

class _MeasChip extends StatelessWidget {
  final String label;
  final double value;
  const _MeasChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppRadius.small,
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(1)}cm',
        style: AppTextStyles.labelSmall.copyWith(
            color: theme.colorScheme.onPrimaryContainer),
      ),
    );
  }
}

// ─── Refund Request Info Card ──────────────────────────────────────────────
// Shows which order a refund request belongs to, plus its reason, status,
// amount and date — so it's never ambiguous which order the customer
// requested a refund for.

class _RefundRequestCard extends StatelessWidget {
  final RefundRequestModel refund;
  const _RefundRequestCard({required this.refund});

  Color _statusColor(RefundStatus s) {
    switch (s) {
      case RefundStatus.requested:
        return Colors.orange;
      case RefundStatus.approved:
        return AppColors.success;
      case RefundStatus.rejected:
        return AppColors.error;
    }
  }

  String _statusLabel(RefundStatus s) {
    switch (s) {
      case RefundStatus.requested:
        return 'Under Review';
      case RefundStatus.approved:
        return 'Approved';
      case RefundStatus.rejected:
        return 'Rejected';
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(refund.refundStatus);
    final idLen = refund.orderId.length >= 8 ? 8 : refund.orderId.length;

    return _SectionCard(
      title: 'Refund Request',
      icon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // This clearly shows which order this refund request belongs to
          _InfoRow(
            label: 'Order ID',
            value: '#${refund.orderId.substring(0, idLen).toUpperCase()}',
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Builder(
                    builder: (context) => Text(
                      'Status',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.small,
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _statusLabel(refund.refundStatus),
                    style: AppTextStyles.labelSmall.copyWith(
                        color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          _InfoRow(label: 'Reason', value: refund.cancellationReason.label),
          if (refund.cancellationDescription.isNotEmpty)
            _InfoRow(label: 'Details', value: refund.cancellationDescription),
          _InfoRow(
            label: 'Amount',
            value: 'Rs ${refund.paidAmount.toInt()}',
          ),
          _InfoRow(
            label: 'Requested On',
            value: _formatDate(refund.requestedAt),
          ),
          if (refund.refundStatus == RefundStatus.rejected &&
              refund.rejectionReason != null &&
              refund.rejectionReason!.isNotEmpty)
            _InfoRow(
              label: 'Rejection Note',
              value: refund.rejectionReason!,
            ),
        ],
      ),
    );
  }
}