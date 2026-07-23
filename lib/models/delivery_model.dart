import 'enums.dart';
import 'address_model.dart';
import 'location_model.dart';

class DeliveryModel {
  final String id;
  final String orderId;
  final String riderId;
  final String customerId;
  final AddressModel pickupAddress;
  final AddressModel dropAddress;
  final DeliveryStatus status;
  final String? otpCode;
  final bool isOtpVerified;
  final LocationModel? riderCurrentLocation;
  final String? estimatedTime; // e.g. "25 mins"
  final DateTime assignedAt;
  final DateTime? deliveredAt;

  const DeliveryModel({
    required this.id,
    required this.orderId,
    required this.riderId,
    required this.customerId,
    required this.pickupAddress,
    required this.dropAddress,
    this.status = DeliveryStatus.assigned,
    this.otpCode,
    this.isOtpVerified = false,
    this.riderCurrentLocation,
    this.estimatedTime,
    required this.assignedAt,
    this.deliveredAt,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) => DeliveryModel(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        riderId: json['riderId'] as String,
        customerId: json['customerId'] as String,
        pickupAddress: AddressModel.fromJson(
            json['pickupAddress'] as Map<String, dynamic>),
        dropAddress:
            AddressModel.fromJson(json['dropAddress'] as Map<String, dynamic>),
        status: DeliveryStatus.values.byName(json['status'] as String),
        otpCode: json['otpCode'] as String?,
        isOtpVerified: json['isOtpVerified'] as bool? ?? false,
        riderCurrentLocation: json['riderCurrentLocation'] != null
            ? LocationModel.fromJson(
                json['riderCurrentLocation'] as Map<String, dynamic>)
            : null,
        estimatedTime: json['estimatedTime'] as String?,
        assignedAt: DateTime.parse(json['assignedAt'] as String),
        deliveredAt: json['deliveredAt'] != null
            ? DateTime.parse(json['deliveredAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'riderId': riderId,
        'customerId': customerId,
        'pickupAddress': pickupAddress.toJson(),
        'dropAddress': dropAddress.toJson(),
        'status': status.name,
        'otpCode': otpCode,
        'isOtpVerified': isOtpVerified,
        'riderCurrentLocation': riderCurrentLocation?.toJson(),
        'estimatedTime': estimatedTime,
        'assignedAt': assignedAt.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
      };
}