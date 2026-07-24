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
// ✅ NEW: needed to notify the rider when customer taps "Ask AI to Call Rider"
import 'package:smartstitch/services/notification_service.dart';

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

      // ✅ Agar riderId empty hai tou don't check (rider not assigned yet)
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

      // ✅ Agar review pehle se exist karta hai tou popup na dikha
      if (existingReview.docs.isNotEmpty) {
        debugPrint('✅ Review already exists for order: $orderId with rider: $riderId');
        _reviewShown = true;
        return;
      }

      // ✅ Agar review nahi hai tou popup dikha
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
                // ✅ UPDATED: pass orderId + riderId so the "Ask AI to Call
                // Rider" button can write the call-request flag to Firestore
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
              // ✅ FIXED: Measurements collection docs are keyed by a random
              // UUID + `userId` field (per-user profile data), NOT by
              // order.id. Looking them up by order.id always returned "not
              // found". The order already carries its own snapshot of the
              // measurements used at checkout time (order.measurements), so
              // just render that directly — no extra Firestore round trip
              // needed, and it always matches what the order was placed with.
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
                  // ✅ UPDATED: "Ask AI to Call Rider" button removed from
                  // here — it now lives directly under the "Rider Assigned"
                  // step inside the Order Tracking card above, so it's
                  // unambiguous which rider it refers to. This section now
                  // just shows rider info.
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
                    // ✅ FIXED: Show proper payment breakdown with three components
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
              // ✅ UPDATED: If a refund request already exists for this
              // order, show its status card (with the Order ID clearly
              // visible) instead of the "Request Refund" button, so it's
              // never ambiguous which order a refund request belongs to
              // and the customer can't submit a duplicate request.
              if (order.status == OrderStatus.cancelled) ...[
                const SizedBox(height: 12),
                Obx(() {
                  final refund = OrderController.to.selectedRefundRequest.value;

                  if (refund != null) {
                    return _RefundRequestCard(refund: refund);
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

  // ✅ FIXED: OrderController.requestRefund expects
  // (orderId, CancellationReason reason, String description) — this now
  // lets the customer pick a proper reason from a dropdown plus an
  // optional free-text description, instead of passing a raw String
  // where an enum was expected (which didn't compile before).
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
                  const Text('Refund ki wajah select karein:'),
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

      // ✅ FIXED: resolve rider name at submission time so it's always
      // saved with the review itself, instead of relying on a fallback
      // Firestore lookup later (which was returning empty/'Rider').
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

      // ✅ Review data to save
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

      // ✅ Save to reviews collection
      await FirebaseFirestore.instance
          .collection('reviews')
          .add(reviewData);

      // ✅ FIXED: Null check for riderId
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
    // ✅ FIXED: Combine Artist + Platform (user/artist share) and show Delivery separate
    final artistShare = order.artistAmount.toInt() + order.platformCommission.toInt();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _AmountChip(
          label: 'Artist Share',
          value: artistShare,  // ✅ Artist + Platform combined
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
  // ✅ NEW: needed to write the call-request flag to the right booking doc
  // and to know which rider to notify.
  final String orderId;
  final String? riderId;
  final OrderStatus status;
  final bool isSelfPickup;
  // ✅ rider phone, used to show the "Ask AI to Call Rider" button
  // directly under the "Rider Assigned" step.
  final String? riderPhone;
  // ✅ the rider live-location map, rendered directly under the
  // "Rider Assigned" step instead of floating in its own card below.
  final Widget? riderLocationWidget;
  const _OrderTracker({
    required this.orderId,
    this.riderId,
    required this.status,
    required this.isSelfPickup,
    this.riderPhone,
    this.riderLocationWidget,
  });

  // ✅ NEW: writes the call-request flag on the booking doc + sends a
  // notification to the rider, then opens the AI chat screen exactly as
  // before.
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

    Get.toNamed(
      AppRoutes.aiChat,
      arguments: {
        'type': 'callRider',
        'phone': riderPhone,
      },
    );
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

    // ✅ show the call button only when the order is currently sitting
    // at the "Rider Assigned" step and we actually have a phone number.
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
                      onPressed: () => _askAiToCallRider(context), // ✅ UPDATED
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
              // rider live-location map, also pinned directly under
              // the "Rider Assigned" step (moved out of its own separate
              // card below the tracker) so everything about the rider is
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

// ─── Rider Live Location (now embedded under the "Rider Assigned" step) ──────

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
// ✅ NEW: Shows which order a refund request belongs to, plus its reason,
// status, amount and date — so it's never ambiguous which order the
// customer requested a refund for.

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
          // ✅ Ye clearly dikhata hai ke ye refund request KIS order ke liye hai
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