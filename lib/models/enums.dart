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

/// Lifecycle of a refund request. `null` on an OrderModel/booking means no
/// refund has ever been requested for it.
enum RefundStatus { requested, approved, rejected }

/// Reasons a customer can pick when cancelling a paid booking.
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