import 'package:flutter/material.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/models/order_model.dart';

/// The five customer-facing states from the Cancellation & Refund spec.
enum BookingDisplayStatus {
  paid,
  cancelled,
  refundRequested,
  refunded,
  refundRejected,
}

extension BookingDisplayStatusX on BookingDisplayStatus {
  String get label {
    switch (this) {
      case BookingDisplayStatus.paid:
        return 'Paid';
      case BookingDisplayStatus.cancelled:
        return 'Cancelled';
      case BookingDisplayStatus.refundRequested:
        return 'Refund Requested';
      case BookingDisplayStatus.refunded:
        return 'Refunded';
      case BookingDisplayStatus.refundRejected:
        return 'Refund Rejected';
    }
  }

  Color get color {
    switch (this) {
      case BookingDisplayStatus.paid:
        return const Color(0xFF2563EB); // Blue
      case BookingDisplayStatus.cancelled:
        return const Color(0xFF6B7280); // Grey
      case BookingDisplayStatus.refundRequested:
        return const Color(0xFFF59E0B); // Orange
      case BookingDisplayStatus.refunded:
        return const Color(0xFF16A34A); // Green
      case BookingDisplayStatus.refundRejected:
        return const Color(0xFFDC2626); // Red
    }
  }

  IconData get icon {
    switch (this) {
      case BookingDisplayStatus.paid:
        return Icons.verified_rounded;
      case BookingDisplayStatus.cancelled:
        return Icons.cancel_outlined;
      case BookingDisplayStatus.refundRequested:
        return Icons.hourglass_top_rounded;
      case BookingDisplayStatus.refunded:
        return Icons.check_circle_rounded;
      case BookingDisplayStatus.refundRejected:
        return Icons.error_outline_rounded;
    }
  }
}

/// Derives which of the 5 badges to show for a given [OrderModel]. Returns
/// `null` when the booking isn't paid yet and hasn't been cancelled — in
/// that case just show the normal in-progress `OrderStatus` label instead.
BookingDisplayStatus? resolveOrderDisplayStatus(OrderModel order) {
  final isRefunded =
      order.paymentStatus == PaymentStatus.refunded ||
      order.refundStatus == RefundStatus.approved;

  if (isRefunded) return BookingDisplayStatus.refunded;
  if (order.refundStatus == RefundStatus.rejected) {
    return BookingDisplayStatus.refundRejected;
  }
  if (order.refundStatus == RefundStatus.requested) {
    return BookingDisplayStatus.refundRequested;
  }
  if (order.status == OrderStatus.cancelled) {
    return BookingDisplayStatus.cancelled;
  }
  if (order.isPaid) return BookingDisplayStatus.paid;
  return null;
}

/// A small rounded Material 3 status chip. Works in light and dark mode by
/// deriving its background from the status color at low opacity rather than
/// a fixed light/white fill.
class BookingStatusBadge extends StatelessWidget {
  final BookingDisplayStatus status;
  final bool dense;

  const BookingStatusBadge({
    super.key,
    required this.status,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = status.color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 12,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.22 : 0.12),
        borderRadius: AppRadius.small,
        border: Border.all(color: color.withOpacity(isDark ? 0.5 : 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: dense ? 12 : 14, color: color),
          SizedBox(width: dense ? 4 : 6),
          Text(
            status.label,
            style: (dense ? AppTextStyles.caption : AppTextStyles.labelMedium)
                .copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
