import 'package:smartstitch/models/enums.dart';
import 'address_model.dart';

class BookingModel {
  final String id;
  final String customerId;
  final String artistId;
  final String serviceId;
  final String serviceTitle;
  final double servicePrice;

  final BookingType bookingType;
  final AppointmentStatus status;

  final DateTime appointmentDate;
  final String timeSlot;

  final AddressModel? address;
  final String? designImageUrl;
  final String? specialInstructions;

  final bool isHomeVisit;
  final String? measurementId;

  final PaymentMethod? paymentMethod;

  final DateTime createdAt;
  final DateTime updatedAt;

  final double deliveryFee;
  final double totalAmount;

  final String paymentStatus;
  final String? transactionId;
  final String? orderId;
  final double artistAmount;
  final double platformCommission;
  final DateTime? paidAt;

  // ─── Custom Design Quote Flow ─────────────────────────────────────
  final QuoteStatus quoteStatus;
  final double? quotedPrice;
  final DateTime? quotedAt;

  const BookingModel({
    required this.id,
    required this.customerId,
    required this.artistId,
    required this.serviceId,
    required this.serviceTitle,
    required this.servicePrice,
    required this.bookingType,
    this.status = AppointmentStatus.pending,
    required this.appointmentDate,
    required this.timeSlot,
    this.address,
    this.designImageUrl,
    this.specialInstructions,
    this.isHomeVisit = false,
    this.measurementId,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.deliveryFee = 0,
    required this.totalAmount,
    this.paymentStatus = 'pending',
    this.transactionId,
    this.orderId,
    this.artistAmount = 0,
    this.platformCommission = 0,
    this.paidAt,
    this.quoteStatus = QuoteStatus.notRequired,
    this.quotedPrice,
    this.quotedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // ─── Safe bookingType parse ───────────────────────────
    BookingType bookingType = BookingType.dropOff;
    try {
      final raw = json['bookingType'] as String? ?? 'dropOff';
      bookingType = BookingType.values.byName(raw);
    } catch (_) {}

    // ─── Safe status parse ────────────────────────────────
    AppointmentStatus status = AppointmentStatus.pending;
    try {
      final raw = json['status'] as String? ?? 'pending';
      status = AppointmentStatus.values.byName(raw);
    } catch (_) {}

    // ─── Safe paymentMethod parse ─────────────────────────
    PaymentMethod? paymentMethod;
    try {
      final raw = json['paymentMethod'] as String?;
      if (raw != null && raw.isNotEmpty) {
        paymentMethod = PaymentMethod.values.byName(raw);
      }
    } catch (_) {}

    // ─── Safe quoteStatus parse ────────────────────────────
    QuoteStatus quoteStatus = QuoteStatus.notRequired;
    try {
      final raw = json['quoteStatus'] as String?;
      if (raw != null && raw.isNotEmpty) {
        quoteStatus = QuoteStatus.values.byName(raw);
      }
    } catch (_) {}

    // ─── Safe address parse ───────────────────────────────
    AddressModel? address;
    try {
      if (json['address'] != null) {
        address =
            AddressModel.fromJson(json['address'] as Map<String, dynamic>);
      }
    } catch (_) {}

    // ─── Safe dates parse ─────────────────────────────────
    DateTime appointmentDate = DateTime.now();
    DateTime createdAt = DateTime.now();
    DateTime updatedAt = DateTime.now();
    try {
      appointmentDate = DateTime.parse(json['appointmentDate'] as String);
    } catch (_) {}
    try {
      createdAt = DateTime.parse(json['createdAt'] as String);
    } catch (_) {}
    try {
      updatedAt = DateTime.parse(json['updatedAt'] as String);
    } catch (_) {}

    return BookingModel(
      id: json['id'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      artistId: json['artistId'] as String? ?? '',
      serviceId: json['serviceId'] as String? ?? '',
      serviceTitle: json['serviceTitle'] as String? ?? '',
      servicePrice: (json['servicePrice'] as num?)?.toDouble() ?? 0.0,
      bookingType: bookingType,
      status: status,
      appointmentDate: appointmentDate,
      timeSlot: json['timeSlot'] as String? ?? '',
      address: address,
      designImageUrl: json['designImageUrl'] as String?,
      specialInstructions: json['specialInstructions'] as String?,
      isHomeVisit: json['isHomeVisit'] as bool? ?? false,
      measurementId: json['measurementId'] as String?,
      paymentMethod: paymentMethod,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ??
          ((json['servicePrice'] as num?)?.toDouble() ?? 0),
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      transactionId: json['transactionId'] as String?,
      orderId: json['orderId'] as String?,
      artistAmount: (json['artistAmount'] as num?)?.toDouble() ?? 0,
      platformCommission: (json['platformCommission'] as num?)?.toDouble() ?? 0,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      quoteStatus: quoteStatus,
      quotedPrice: (json['quotedPrice'] as num?)?.toDouble(),
      quotedAt:
          json['quotedAt'] != null ? DateTime.parse(json['quotedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'artistId': artistId,
        'serviceId': serviceId,
        'serviceTitle': serviceTitle,
        'servicePrice': servicePrice,
        'bookingType': bookingType.name,
        'status': status.name,
        'appointmentDate': appointmentDate.toIso8601String(),
        'timeSlot': timeSlot,
        'address': address?.toJson(),
        'designImageUrl': designImageUrl,
        'specialInstructions': specialInstructions,
        'isHomeVisit': isHomeVisit,
        'measurementId': measurementId,
        'paymentMethod': paymentMethod?.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deliveryFee': deliveryFee,
        'totalAmount': totalAmount,
        'paymentStatus': paymentStatus,
        'transactionId': transactionId,
        'orderId': orderId,
        'artistAmount': artistAmount,
        'platformCommission': platformCommission,
        'paidAt': paidAt?.toIso8601String(),
        'quoteStatus': quoteStatus.name,
        'quotedPrice': quotedPrice,
        'quotedAt': quotedAt?.toIso8601String(),
      };

  BookingModel copyWith({
    AppointmentStatus? status,
    String? designImageUrl,
    String? specialInstructions,
    String? measurementId,
    PaymentMethod? paymentMethod,
    double? servicePrice,
    double? deliveryFee,
    double? totalAmount,
    String? paymentStatus,
    String? transactionId,
    String? orderId,
    double? artistAmount,
    double? platformCommission,
    DateTime? paidAt,
    QuoteStatus? quoteStatus,
    double? quotedPrice,
    DateTime? quotedAt,
  }) =>
      BookingModel(
        id: id,
        customerId: customerId,
        artistId: artistId,
        serviceId: serviceId,
        serviceTitle: serviceTitle,
        servicePrice: servicePrice ?? this.servicePrice,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        totalAmount: totalAmount ?? this.totalAmount,
        bookingType: bookingType,
        status: status ?? this.status,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
        address: address,
        designImageUrl: designImageUrl ?? this.designImageUrl,
        specialInstructions: specialInstructions ?? this.specialInstructions,
        isHomeVisit: isHomeVisit,
        measurementId: measurementId ?? this.measurementId,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        paymentStatus: paymentStatus ?? this.paymentStatus,
        transactionId: transactionId ?? this.transactionId,
        orderId: orderId ?? this.orderId,
        artistAmount: artistAmount ?? this.artistAmount,
        platformCommission: platformCommission ?? this.platformCommission,
        paidAt: paidAt ?? this.paidAt,
        quoteStatus: quoteStatus ?? this.quoteStatus,
        quotedPrice: quotedPrice ?? this.quotedPrice,
        quotedAt: quotedAt ?? this.quotedAt,
      );
}