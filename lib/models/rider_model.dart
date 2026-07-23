import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

class RiderModel {
  final String id;
  final String userId;
  final String name;
  final String imageUrl;
  final String cnicNumber;
  final String cnicImageUrl;
  final String drivingLicenseUrl;
  final String vehicleType;
  final String vehicleNumber;
  final double rating;
  final int totalDeliveries;
  final int activeDeliveries;
  final int completedDeliveries;
  final double totalEarnings;
  final double walletBalance;
  final bool isVerified;
  final bool isOnline;
  final LocationModel? currentLocation;
  final DateTime joinedAt;

  const RiderModel({
    required this.id,
    required this.userId,
    this.name = '',
    this.imageUrl = '',
    required this.cnicNumber,
    required this.cnicImageUrl,
    required this.drivingLicenseUrl,
    required this.vehicleType,
    required this.vehicleNumber,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.activeDeliveries = 0,
    this.completedDeliveries = 0,
    this.totalEarnings = 0.0,
    this.walletBalance = 0.0,
    this.isVerified = false,
    this.isOnline = false,
    this.currentLocation,
    required this.joinedAt,
  });

  RiderModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? imageUrl,
    String? cnicNumber,
    String? cnicImageUrl,
    String? drivingLicenseUrl,
    String? vehicleType,
    String? vehicleNumber,
    double? rating,
    int? totalDeliveries,
    int? activeDeliveries,
    int? completedDeliveries,
    double? totalEarnings,
    double? walletBalance,
    bool? isVerified,
    bool? isOnline,
    LocationModel? currentLocation,
    DateTime? joinedAt,
  }) {
    return RiderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      cnicImageUrl: cnicImageUrl ?? this.cnicImageUrl,
      drivingLicenseUrl: drivingLicenseUrl ?? this.drivingLicenseUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      activeDeliveries: activeDeliveries ?? this.activeDeliveries,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      walletBalance: walletBalance ?? this.walletBalance,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      currentLocation: currentLocation ?? this.currentLocation,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  factory RiderModel.fromJson(Map<String, dynamic> json) => RiderModel(
        id: json['id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString() ?? '',
        cnicNumber: json['cnicNumber']?.toString() ?? '',
        cnicImageUrl: json['cnicImageUrl']?.toString() ?? '',
        drivingLicenseUrl: json['drivingLicenseUrl']?.toString() ?? '',
        vehicleType: json['vehicleType']?.toString() ?? '',
        vehicleNumber: json['vehicleNumber']?.toString() ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        totalDeliveries: (json['totalDeliveries'] as num?)?.toInt() ?? 0,
        activeDeliveries: (json['activeDeliveries'] as num?)?.toInt() ?? 0,
        completedDeliveries:
            (json['completedDeliveries'] as num?)?.toInt() ?? 0,
        totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
        walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
        isVerified: json['isVerified'] as bool? ?? false,
        isOnline: json['isOnline'] as bool? ?? false,
        currentLocation: json['currentLocation'] != null
            ? LocationModel.fromJson(
                json['currentLocation'] as Map<String, dynamic>)
            : null,
        joinedAt: _parseDate(json['joinedAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'imageUrl': imageUrl,
        'cnicNumber': cnicNumber,
        'cnicImageUrl': cnicImageUrl,
        'drivingLicenseUrl': drivingLicenseUrl,
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber,
        'rating': rating,
        'totalDeliveries': totalDeliveries,
        'activeDeliveries': activeDeliveries,
        'completedDeliveries': completedDeliveries,
        'totalEarnings': totalEarnings,
        'walletBalance': walletBalance,
        'isVerified': isVerified,
        'isOnline': isOnline,
        'currentLocation': currentLocation?.toJson(),
        'joinedAt': joinedAt.toIso8601String(),
      };
}