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
  });

  static double calcCommission(double total) => total * 0.10;
  static double calcArtistAmount(double total) => total * 0.90;

  AddressModel get address => deliveryAddress;

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
      );

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
      };
}