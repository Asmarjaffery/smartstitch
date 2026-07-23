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