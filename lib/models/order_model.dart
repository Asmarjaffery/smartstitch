import 'enums.dart';
import 'address_model.dart';
import 'body_measurement_model.dart';
import 'service_model.dart';
import 'payment_model.dart';

class OrderModel {
  final String id;
  final String customerId;
  final String artistId;
  final String? riderId;
  final ServiceModel service;
  final BodyMeasurementModel measurements;
  final List<String> designImages;
  final String? specialInstructions;
  final AddressModel deliveryAddress;
  final bool isHomeVisit;
  final DateTime? appointmentDate;
  final OrderStatus status;
  final double servicePrice;   // ✅ artist ki service ki price
  final double deliveryFee;    // ✅ rider ka charge
  final double totalAmount;    // servicePrice + deliveryFee
  final double platformCommission;
  final double artistAmount;
  final PaymentModel? payment;
  final DateTime? estimatedDelivery;
  final DateTime placedAt;
  final DateTime updatedAt;
  final String? measurementId;
  final Map<String, dynamic>? riderLocation;

  // ─── Cancellation & Refund Management ─────────────────────────────────
  final PaymentStatus paymentStatus;
  final String? paymentIntentId;
  final RefundStatus? refundStatus;
  final String? rejectionReason;
  final CancellationReason? cancellationReason;
  final String? cancellationDescription;
  final DateTime? refundedAt;

  // ─── Custom Design Quote Flow ──────────────────────────────────────────
  // Mirrors BookingModel's quote fields so order list/detail screens (both
  // customer and artist) can show the quote state without needing to
  // re-fetch the raw booking doc.
  final QuoteStatus quoteStatus;
  final double? quotedPrice;
  final DateTime? quotedAt;

  // ─── Delivery Exception (rider-reported failed delivery) ──────────────
  // ✅ rider side sets `riderStatus`/`deliveryExceptionReason` on the
  // booking doc when a delivery attempt fails (customer didn't answer,
  // wrong address, etc). These are independent of `status`, which stays
  // stuck at `riderAssigned` until an admin resolves the exception — so
  // the customer-facing UI needs these fields to know something's wrong.
  final String? riderStatus;
  final String? deliveryExceptionReason;
  final String? lastDeliveryExceptionId;

  // ─── Customer Reschedule Requests ───────────────────────────────────────
  // ✅ NEW: for delivery-failed orders, the customer can only *request* a
  // new date — an admin has to approve it (see RescheduleRequestStatus).
  // For customer-cancelled orders, this stays `none` and the existing
  // direct self-service reschedule flow is used instead.
  final RescheduleRequestStatus rescheduleRequestStatus;
  final DateTime? requestedRescheduleDate;
  final String? rescheduleRejectionReason;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.artistId,
    this.riderId,
    required this.service,
    required this.measurements,
    this.designImages = const [],
    this.specialInstructions,
    required this.deliveryAddress,
    this.isHomeVisit = false,
    this.appointmentDate,
    this.status = OrderStatus.pending,
    this.servicePrice = 0,
    this.deliveryFee = 0,
    required this.totalAmount,
    required this.platformCommission,
    required this.artistAmount,
    this.payment,
    this.estimatedDelivery,
    required this.placedAt,
    required this.updatedAt,
    this.measurementId,
    this.riderLocation,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentIntentId,
    this.refundStatus,
    this.rejectionReason,
    this.cancellationReason,
    this.cancellationDescription,
    this.refundedAt,
    this.quoteStatus = QuoteStatus.notRequired,
    this.quotedPrice,
    this.quotedAt,
    this.riderStatus,
    this.deliveryExceptionReason,
    this.lastDeliveryExceptionId,
    this.rescheduleRequestStatus = RescheduleRequestStatus.none,
    this.requestedRescheduleDate,
    this.rescheduleRejectionReason,
  });

  /// True only for bookings the Cancellation & Refund feature considers
  /// "paid" — i.e. eligible to auto-create a refund request on cancel.
  bool get isPaid => paymentStatus == PaymentStatus.completed;

  /// True while this order is sitting with the artist for a custom-design
  /// price quote (no fixed price yet, no payment taken).
  bool get isAwaitingQuote => quoteStatus == QuoteStatus.pendingQuote;

  /// True once the artist has sent a price and it's waiting on the
  /// customer to accept or decline.
  bool get hasPendingQuoteDecision => quoteStatus == QuoteStatus.quoted;

  /// True when the rider has reported this delivery as failed and it's
  /// sitting with admin for review — regardless of what `status` still
  /// says (it stays `riderAssigned` until admin resolves it).
  bool get isDeliveryFailed => riderStatus == 'deliveryFailed';

  /// ✅ NEW: True while a reschedule request (for a delivery-failed order)
  /// is sitting with admin, awaiting approval/rejection.
  bool get hasPendingRescheduleRequest =>
      rescheduleRequestStatus == RescheduleRequestStatus.pending;

  static double calcCommission(double total) => total * 0.10;
  static double calcArtistAmount(double total) => total * 0.90;

  AddressModel get address => deliveryAddress;

  OrderModel copyWith({
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    RefundStatus? refundStatus,
    String? rejectionReason,
    CancellationReason? cancellationReason,
    String? cancellationDescription,
    DateTime? refundedAt,
    QuoteStatus? quoteStatus,
    double? quotedPrice,
    DateTime? quotedAt,
    String? riderStatus,
    String? deliveryExceptionReason,
    String? lastDeliveryExceptionId,
    RescheduleRequestStatus? rescheduleRequestStatus,
    DateTime? requestedRescheduleDate,
    String? rescheduleRejectionReason,
  }) {
    return OrderModel(
      id: id,
      customerId: customerId,
      artistId: artistId,
      riderId: riderId,
      service: service,
      measurements: measurements,
      designImages: designImages,
      specialInstructions: specialInstructions,
      deliveryAddress: deliveryAddress,
      isHomeVisit: isHomeVisit,
      appointmentDate: appointmentDate,
      status: status ?? this.status,
      servicePrice: servicePrice,
      deliveryFee: deliveryFee,
      totalAmount: totalAmount,
      platformCommission: platformCommission,
      artistAmount: artistAmount,
      payment: payment,
      estimatedDelivery: estimatedDelivery,
      placedAt: placedAt,
      updatedAt: updatedAt,
      measurementId: measurementId,
      riderLocation: riderLocation,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentIntentId: paymentIntentId,
      refundStatus: refundStatus ?? this.refundStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancellationDescription:
          cancellationDescription ?? this.cancellationDescription,
      refundedAt: refundedAt ?? this.refundedAt,
      quoteStatus: quoteStatus ?? this.quoteStatus,
      quotedPrice: quotedPrice ?? this.quotedPrice,
      quotedAt: quotedAt ?? this.quotedAt,
      riderStatus: riderStatus ?? this.riderStatus,
      deliveryExceptionReason:
          deliveryExceptionReason ?? this.deliveryExceptionReason,
      lastDeliveryExceptionId:
          lastDeliveryExceptionId ?? this.lastDeliveryExceptionId,
      rescheduleRequestStatus:
          rescheduleRequestStatus ?? this.rescheduleRequestStatus,
      requestedRescheduleDate:
          requestedRescheduleDate ?? this.requestedRescheduleDate,
      rescheduleRejectionReason:
          rescheduleRejectionReason ?? this.rescheduleRejectionReason,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        customerId: json['customerId'] as String,
        artistId: json['artistId'] as String,
        riderId: json['riderId'] as String?,
        service: ServiceModel.fromJson(json['service'] as Map<String, dynamic>),
        measurements: BodyMeasurementModel.fromJson(
          json['measurements'] as Map<String, dynamic>,
        ),
        designImages: List<String>.from(json['designImages'] as List? ?? []),
        specialInstructions: json['specialInstructions'] as String?,
        deliveryAddress: AddressModel.fromJson(
          json['deliveryAddress'] as Map<String, dynamic>,
        ),
        isHomeVisit: json['isHomeVisit'] as bool? ?? false,
        appointmentDate: json['appointmentDate'] != null
            ? DateTime.parse(json['appointmentDate'] as String)
            : null,
        status: OrderStatus.values.byName(json['status'] as String),
        servicePrice: (json['servicePrice'] as num?)?.toDouble() ?? 0,
        deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        platformCommission: (json['platformCommission'] as num).toDouble(),
        artistAmount: (json['artistAmount'] as num).toDouble(),
        payment: json['payment'] != null
            ? PaymentModel.fromJson(json['payment'] as Map<String, dynamic>)
            : null,
        estimatedDelivery: json['estimatedDelivery'] != null
            ? DateTime.parse(json['estimatedDelivery'] as String)
            : null,
        placedAt: DateTime.parse(json['placedAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        measurementId: json['measurementId'] as String?,
        riderLocation: json['riderLocation'] as Map<String, dynamic>?,
        paymentStatus: _parsePaymentStatus(json['paymentStatus']),
        paymentIntentId: json['paymentIntentId'] as String?,
        refundStatus: _parseRefundStatus(json['refundStatus']),
        rejectionReason: json['rejectionReason'] as String?,
        cancellationReason: _parseCancellationReason(json['cancellationReason']),
        cancellationDescription: json['cancellationDescription'] as String?,
        refundedAt: json['refundedAt'] != null
            ? DateTime.tryParse(json['refundedAt'].toString())
            : null,
        quoteStatus: _parseQuoteStatus(json['quoteStatus']),
        quotedPrice: (json['quotedPrice'] as num?)?.toDouble(),
        quotedAt: json['quotedAt'] != null
            ? DateTime.tryParse(json['quotedAt'].toString())
            : null,
        riderStatus: json['riderStatus'] as String?,
        deliveryExceptionReason: json['deliveryExceptionReason'] as String?,
        lastDeliveryExceptionId: json['lastDeliveryExceptionId'] as String?,
        rescheduleRequestStatus:
            _parseRescheduleRequestStatus(json['rescheduleRequestStatus']),
        requestedRescheduleDate: json['requestedRescheduleDate'] != null
            ? DateTime.tryParse(json['requestedRescheduleDate'].toString())
            : null,
        rescheduleRejectionReason:
            json['rescheduleRejectionReason'] as String?,
      );

  static PaymentStatus _parsePaymentStatus(dynamic value) {
    if (value is String) {
      try {
        return PaymentStatus.values.byName(value);
      } catch (_) {}
    }
    return PaymentStatus.pending;
  }

  static RefundStatus? _parseRefundStatus(dynamic value) {
    if (value is String) {
      try {
        return RefundStatus.values.byName(value);
      } catch (_) {}
    }
    return null;
  }

  static CancellationReason? _parseCancellationReason(dynamic value) {
    if (value is String) {
      try {
        return CancellationReason.values.byName(value);
      } catch (_) {}
    }
    return null;
  }

  static QuoteStatus _parseQuoteStatus(dynamic value) {
    if (value is String) {
      try {
        return QuoteStatus.values.byName(value);
      } catch (_) {}
    }
    return QuoteStatus.notRequired;
  }

  static RescheduleRequestStatus _parseRescheduleRequestStatus(dynamic value) {
    if (value is String) {
      try {
        return RescheduleRequestStatus.values.byName(value);
      } catch (_) {}
    }
    return RescheduleRequestStatus.none;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'artistId': artistId,
        'riderId': riderId,
        'service': service.toJson(),
        'measurements': measurements.toJson(),
        'designImages': designImages,
        'specialInstructions': specialInstructions,
        'deliveryAddress': deliveryAddress.toJson(),
        'isHomeVisit': isHomeVisit,
        'appointmentDate': appointmentDate?.toIso8601String(),
        'status': status.name,
        'servicePrice': servicePrice,
        'deliveryFee': deliveryFee,
        'totalAmount': totalAmount,
        'platformCommission': platformCommission,
        'artistAmount': artistAmount,
        'payment': payment?.toJson(),
        'estimatedDelivery': estimatedDelivery?.toIso8601String(),
        'placedAt': placedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'measurementId': measurementId,
        'riderLocation': riderLocation,
        'paymentStatus': paymentStatus.name,
        'paymentIntentId': paymentIntentId,
        'refundStatus': refundStatus?.name,
        'rejectionReason': rejectionReason,
        'cancellationReason': cancellationReason?.name,
        'cancellationDescription': cancellationDescription,
        'refundedAt': refundedAt?.toIso8601String(),
        'quoteStatus': quoteStatus.name,
        'quotedPrice': quotedPrice,
        'quotedAt': quotedAt?.toIso8601String(),
        'riderStatus': riderStatus,
        'deliveryExceptionReason': deliveryExceptionReason,
        'lastDeliveryExceptionId': lastDeliveryExceptionId,
        'rescheduleRequestStatus': rescheduleRequestStatus.name,
        'requestedRescheduleDate': requestedRescheduleDate?.toIso8601String(),
        'rescheduleRejectionReason': rescheduleRejectionReason,
      };
}