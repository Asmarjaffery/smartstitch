import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double basePrice;
  final bool isActive;
  final DateTime createdAt;
  final String categoryId;
  final String artistId;
  final String status; // ← ADDED: published / draft (artist services ke liye)

  const ServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.basePrice,
    this.isActive = true,
    required this.createdAt,
    this.categoryId = '',
    this.artistId = '',
    this.status = 'published', // ← ADDED
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['id'] as String? ?? '',
        // ✅ FIX: artist-published docs mein 'serviceName' hoti hai,
        // admin template docs mein 'name' — dono check karein
        title: json['serviceName'] as String? ??
            json['name'] as String? ??
            json['title'] as String? ??
            '',
        // ✅ FIX: artist docs mein 'shortDescription' hoti hai
        description: json['shortDescription'] as String? ??
            json['description'] as String? ??
            '',
        // ✅ FIX: artist docs mein 'coverImageUrl' hoti hai
        imageUrl: json['coverImageUrl'] as String? ??
            json['imageUrl'] as String? ??
            '',
        // ✅ FIX: artist docs mein 'startingPrice' hoti hai,
        // admin template docs mein 'price'
        basePrice: (json['startingPrice'] as num?)?.toDouble() ??
            (json['price'] as num?)?.toDouble() ??
            (json['basePrice'] as num?)?.toDouble() ??
            0.0,
        isActive: json['isActive'] as bool? ?? true,
        categoryId: json['categoryId'] as String? ?? '',
        artistId: json['artistId'] as String? ?? '',
        status: json['status'] as String? ?? 'published', // ← ADDED
        createdAt: json['createdAt'] == null
            ? DateTime.now()
            : json['createdAt'] is String
                ? DateTime.parse(json['createdAt'] as String)
                : (json['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'basePrice': basePrice,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'categoryId': categoryId,
        'artistId': artistId,
        'status': status,
      };
}