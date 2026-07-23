import 'package:cloud_firestore/cloud_firestore.dart';
import 'address_model.dart';

class ArtistModel {
  final String id;
  final String userId;
  final String businessName;
  final String bio;
  final String cnicNumber;
  final String cnicImageUrl;
  final List<String> portfolioImages;
  final List<String> specializations;
  final double rating;
  final int totalReviews;
  final int totalOrders;
  final double totalEarnings;
  final double walletBalance;
  final bool isVerified;
  final bool isAvailable;
  final bool hasTrendingBadge;
  final AddressModel? shopAddress;
  final bool offersHomeVisit;
  final DateTime joinedAt;
  final String profileImageUrl;
  final int? experienceYears; // ── ADDED: years of tailoring experience

  const ArtistModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.bio,
    required this.cnicNumber,
    required this.cnicImageUrl,
    this.portfolioImages = const [],
    this.specializations = const [],
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalOrders = 0,
    this.totalEarnings = 0.0,
    this.walletBalance = 0.0,
    this.isVerified = false,
    this.isAvailable = true,
    this.hasTrendingBadge = false,
    this.shopAddress,
    this.offersHomeVisit = false,
    this.profileImageUrl = '',
    this.experienceYears, // ── ADDED
    required this.joinedAt,
  });

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    DateTime joinedAt = DateTime.now();
    final rawDate = json['joinedAt'];
    if (rawDate is String) {
      joinedAt = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is Timestamp) {
      joinedAt = rawDate.toDate();
    }

    final double rating = (json['averageRating'] as num?)?.toDouble() ??
        (json['rating'] as num?)?.toDouble() ??
        0.0;

    return ArtistModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? json['id'] as String? ?? '',
      businessName: json['businessName'] as String,
      bio: json['bio'] as String,
      cnicNumber: json['cnicNumber'] as String,
      cnicImageUrl: json['cnicImageUrl'] as String,
      portfolioImages:
          List<String>.from(json['portfolioImages'] as List? ?? []),
      specializations:
          List<String>.from(json['specializations'] as List? ?? []),
      rating: rating,
      totalReviews: json['totalReviews'] as int? ?? 0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      isVerified: json['isVerified'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      hasTrendingBadge: json['hasTrendingBadge'] as bool? ?? false,
      shopAddress: json['shopAddress'] != null
          ? AddressModel.fromJson(json['shopAddress'] as Map<String, dynamic>)
          : null,
      offersHomeVisit: json['offersHomeVisit'] as bool? ?? false,
      joinedAt: joinedAt,
      profileImageUrl: json['profileImageUrl'] as String? ?? '',
      experienceYears: json['experienceYears'] as int?, // ── ADDED
    );
  }

  get startingPrice => null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'businessName': businessName,
        'bio': bio,
        'cnicNumber': cnicNumber,
        'cnicImageUrl': cnicImageUrl,
        'portfolioImages': portfolioImages,
        'specializations': specializations,
        'rating': rating,
        'averageRating': rating,
        'totalReviews': totalReviews,
        'totalOrders': totalOrders,
        'totalEarnings': totalEarnings,
        'walletBalance': walletBalance,
        'isVerified': isVerified,
        'isAvailable': isAvailable,
        'hasTrendingBadge': hasTrendingBadge,
        'shopAddress': shopAddress?.toJson(),
        'offersHomeVisit': offersHomeVisit,
        'joinedAt': joinedAt.toIso8601String(),
        'profileImageUrl': profileImageUrl,
        'experienceYears': experienceYears, // ── ADDED
      };

  // ── ADDED: needed for instant local updates after save/upload/toggle
  ArtistModel copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? bio,
    String? cnicNumber,
    String? cnicImageUrl,
    List<String>? portfolioImages,
    List<String>? specializations,
    double? rating,
    int? totalReviews,
    int? totalOrders,
    double? totalEarnings,
    double? walletBalance,
    bool? isVerified,
    bool? isAvailable,
    bool? hasTrendingBadge,
    AddressModel? shopAddress,
    bool? offersHomeVisit,
    DateTime? joinedAt,
    String? profileImageUrl,
    int? experienceYears,
  }) {
    return ArtistModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      bio: bio ?? this.bio,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      cnicImageUrl: cnicImageUrl ?? this.cnicImageUrl,
      portfolioImages: portfolioImages ?? this.portfolioImages,
      specializations: specializations ?? this.specializations,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalOrders: totalOrders ?? this.totalOrders,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      walletBalance: walletBalance ?? this.walletBalance,
      isVerified: isVerified ?? this.isVerified,
      isAvailable: isAvailable ?? this.isAvailable,
      hasTrendingBadge: hasTrendingBadge ?? this.hasTrendingBadge,
      shopAddress: shopAddress ?? this.shopAddress,
      offersHomeVisit: offersHomeVisit ?? this.offersHomeVisit,
      joinedAt: joinedAt ?? this.joinedAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      experienceYears: experienceYears ?? this.experienceYears,
    );
  }
}