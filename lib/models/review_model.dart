class ReviewModel {
  final String id;
  final String orderId;
  final String customerId;
  final String artistId;
  final String? artistName;
  final String? riderId;
  final String? riderName;
  final String type; 
  final int rating;
  final String? comment;
  final bool isVerifiedOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> imageUrls;
  final Map<String, int> subRatings;
  final String? adminReply;
  final DateTime? adminRepliedAt;
  final String? customerName;

  const ReviewModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.artistId,
    this.artistName,
    this.riderId,
    this.riderName,
    this.type = 'artist_service',
    required this.rating,
    this.comment,
    this.isVerifiedOrder = true,
    required this.createdAt,
    this.updatedAt,
    this.imageUrls = const [],
    this.subRatings = const {},
    this.adminReply,
    this.adminRepliedAt,
    this.customerName,
  });

  bool get isRiderReview => type == 'rider_delivery';

  static DateTime _parseDate(dynamic value) {
    if (value is String) return DateTime.parse(value);
    return (value as dynamic).toDate();
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as String,
        orderId: json['orderId'] as String? ?? '',
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String?,
        artistId: json['artistId'] as String? ?? '',
        artistName: json['artistName'] as String?,
        riderId: json['riderId'] as String?,
        riderName: json['riderName'] as String?,
        type: json['type'] as String? ?? 'artist_service',
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        isVerifiedOrder: json['isVerifiedOrder'] as bool? ?? true,
        createdAt: _parseDate(json['createdAt']),
        updatedAt: json['updatedAt'] != null ? _parseDate(json['updatedAt']) : null,
        imageUrls: List<String>.from(json['imageUrls'] ?? []),
        subRatings: Map<String, int>.from(
          (json['subRatings'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, (v as num).toInt())),
        ),
        adminReply: json['adminReply'] as String?,
        adminRepliedAt: json['adminRepliedAt'] != null
            ? _parseDate(json['adminRepliedAt'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'customerId': customerId,
        'artistId': artistId,
        'artistName': artistName,
        'riderId': riderId,
        'riderName': riderName,
        'type': type,
        'rating': rating,
        'comment': comment,
        'isVerifiedOrder': isVerifiedOrder,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'imageUrls': imageUrls,
        'subRatings': subRatings,
        'adminReply': adminReply,
        'adminRepliedAt': adminRepliedAt?.toIso8601String(),
      };

  ReviewModel copyWith({
    String? adminReply,
    DateTime? adminRepliedAt,
  }) =>
      ReviewModel(
        id: id,
        orderId: orderId,
        customerId: customerId,
        artistId: artistId,
        artistName: artistName,
        riderId: riderId,
        riderName: riderName,
        type: type,
        rating: rating,
        comment: comment,
        isVerifiedOrder: isVerifiedOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
        imageUrls: imageUrls,
        subRatings: subRatings,
        customerName: customerName,
        adminReply: adminReply ?? this.adminReply,
        adminRepliedAt: adminRepliedAt ?? this.adminRepliedAt,
      );
}