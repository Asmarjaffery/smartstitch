class WishlistModel {
  final String id;
  final String userId;
  final List<String> favoriteDesignIds;
  final List<String> favoriteArtistIds;
  final DateTime updatedAt;

  const WishlistModel({
    required this.id,
    required this.userId,
    this.favoriteDesignIds = const [],
    this.favoriteArtistIds = const [],
    required this.updatedAt,
  });

  factory WishlistModel.fromJson(Map<String, dynamic> json) => WishlistModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        favoriteDesignIds:
            List<String>.from(json['favoriteDesignIds'] as List? ?? []),
        favoriteArtistIds:
            List<String>.from(json['favoriteArtistIds'] as List? ?? []),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'favoriteDesignIds': favoriteDesignIds,
        'favoriteArtistIds': favoriteArtistIds,
        'updatedAt': updatedAt.toIso8601String(),
      };
}