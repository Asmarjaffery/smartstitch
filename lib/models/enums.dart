enum UserRole { customer, artist, rider, admin }

enum AuthProvider { email, google, facebook, phone }

enum OrderStatus {
  pending,
  accepted,
  inProgress,
  stitchingCompleted,
  riderAssigned,
  delivered,
  cancelled,
}

enum AppointmentStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
}

enum BookingType { dropOff, homeVisit }

enum PaymentMethod {
  jazzCash,
  easyPaisa,
  stripe,
  debitCard,
  creditCard,
  wallet,
}

enum PaymentStatus { pending, completed, failed, refunded }

enum WithdrawStatus { pending, approved, rejected }

enum ComplaintStatus { pending, inProgress, resolved }

enum NotificationType {
  orderUpdate,
  paymentReceived,
  newMessage,
  promotional,
  event,
  systemAlert,
  emergency,
  withdrawUpdate,
  newDelivery,
  reviewReceived,
  general,
  account,
  order,
  wallet,
  withdrawal,
  system,
  promotion,
}

enum DeliveryStatus { assigned, pickedUp, onTheWay, delivered, failed }

enum MessageType { text, image, voice, location }

enum AnalyticsFilter {
  today,
  last7Days,
  last30Days,
  last6Months,
  lastYear,
  custom,
}

// ─── Booking Cancellation & Refund Management ──────────────────────────────
enum RefundStatus { requested, approved, rejected }

enum CancellationReason {
  tailorNotResponding,
  orderNotStarted,
  excessiveDelay,
  changedMind,
  duplicatePayment,
  other,
}

extension CancellationReasonX on CancellationReason {
  String get label {
    switch (this) {
      case CancellationReason.tailorNotResponding:
        return 'Tailor not responding';
      case CancellationReason.orderNotStarted:
        return 'Order not started';
      case CancellationReason.excessiveDelay:
        return 'Excessive delay';
      case CancellationReason.changedMind:
        return 'Changed my mind';
      case CancellationReason.duplicatePayment:
        return 'Duplicate payment';
      case CancellationReason.other:
        return 'Other';
    }
  }
}

// ─── Custom Design Quote Flow ──────────────────────────────────────────────
enum QuoteStatus {
  notRequired,
  pendingQuote,
  quoted,
  accepted,
  declined,
}

// ─── Rider Compensation & Delivery Exception Management ────────────────────
// Shared enums used across rider/, customer/ and admin/ compensation screens.
// Mirrors the style of the enums above: plain enum + a `label` extension
// for anything shown directly in the UI.

/// Why a rider couldn't complete a delivery.
/// Drives the radio list on the rider's "Report Delivery Issue" bottom sheet.
enum DeliveryExceptionReason {
  customerUnavailable,
  customerDidNotAnswer,
  customerRefusedDelivery,
  wrongAddress,
  other,
}

extension DeliveryExceptionReasonX on DeliveryExceptionReason {
  String get label {
    switch (this) {
      case DeliveryExceptionReason.customerUnavailable:
        return 'Customer Unavailable';
      case DeliveryExceptionReason.customerDidNotAnswer:
        return "Customer Didn't Answer";
      case DeliveryExceptionReason.customerRefusedDelivery:
        return 'Customer Refused Delivery';
      case DeliveryExceptionReason.wrongAddress:
        return 'Wrong Address';
      case DeliveryExceptionReason.other:
        return 'Other';
    }
  }

  /// Only "Other" requires the rider to type a free-text note to proceed.
  bool get requiresNote => this == DeliveryExceptionReason.other;
}

/// Lifecycle of a single delivery-exception report, end to end —
/// from the moment a rider submits it to admin closing it out.
enum DeliveryExceptionStatus {
  submitted,
  underReview,
  resolved,
}

extension DeliveryExceptionStatusX on DeliveryExceptionStatus {
  String get label {
    switch (this) {
      case DeliveryExceptionStatus.submitted:
        return 'Submitted';
      case DeliveryExceptionStatus.underReview:
        return 'Under Review';
      case DeliveryExceptionStatus.resolved:
        return 'Resolved';
    }
  }
}

/// Admin's decision on the rider's compensation claim for a given report.
/// Kept distinct from WithdrawStatus above even though the values match,
/// since compensation review and wallet withdrawals are different
/// workflows that may diverge later (e.g. partial approval).
enum CompensationStatus {
  pending,
  approved,
  rejected,
}

extension CompensationStatusX on CompensationStatus {
  String get label {
    switch (this) {
      case CompensationStatus.pending:
        return 'Pending';
      case CompensationStatus.approved:
        return 'Approved';
      case CompensationStatus.rejected:
        return 'Rejected';
    }
  }
}

enum OutstandingChargeAction {
  none,
  waived,
  paid,
}

extension OutstandingChargeActionX on OutstandingChargeAction {
  String get label {
    switch (this) {
      case OutstandingChargeAction.none:
        return 'Outstanding';
      case OutstandingChargeAction.waived:
        return 'Waived';
      case OutstandingChargeAction.paid:
        return 'Paid';
    }
  }
}

/// Type discriminator for entries in the `wallet_transactions` collection,
/// extended (additively) to cover compensation payouts alongside the
/// existing 'earning' transactions written by markDelivered().
enum WalletTransactionType {
  earning,
  compensation,
  payout,
  adjustment,
}

extension WalletTransactionTypeX on WalletTransactionType {
  String get label {
    switch (this) {
      case WalletTransactionType.earning:
        return 'Delivery Earnings';
      case WalletTransactionType.compensation:
        return 'Compensation';
      case WalletTransactionType.payout:
        return 'Payout';
      case WalletTransactionType.adjustment:
        return 'Adjustment';
    }
  }
}

// ─── Customer Reschedule Requests (delivery-failed orders) ─────────────────
// When a rider reports a failed delivery, the customer is NOT allowed to
// reschedule the order directly — it's a dispute/exception case, so an
// admin (neutral party) must review and approve/reject it. This is
// distinct from the direct self-service reschedule a customer gets when
// THEY cancelled the order themselves (no dispute involved there).
enum RescheduleRequestStatus {
  none,
  pending,
  approved,
  rejected,
}

extension RescheduleRequestStatusX on RescheduleRequestStatus {
  String get label {
    switch (this) {
      case RescheduleRequestStatus.none:
        return 'None';
      case RescheduleRequestStatus.pending:
        return 'Pending Admin Approval';
      case RescheduleRequestStatus.approved:
        return 'Approved';
      case RescheduleRequestStatus.rejected:
        return 'Rejected';
    }
  }
}