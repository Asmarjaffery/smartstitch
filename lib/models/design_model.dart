
class DesignModel {
  final String id;
  final String artistId;
  final String title;
  final String description;
  final List<String> imageUrls;
  // final DressCategory category;
  final double estimatedPrice;
  final bool isTrending;
  final List<String> colorTags;
  final List<String> eventTags;
  final int viewCount;
  final DateTime createdAt;

  const DesignModel({
    required this.id,
    required this.artistId,
    required this.title,
    required this.description,
    required this.imageUrls,
    // required this.category,
    required this.estimatedPrice,
    this.isTrending = false,
    this.colorTags = const [],
    this.eventTags = const [],
    this.viewCount = 0,
    required this.createdAt,
  });

  factory DesignModel.fromJson(Map<String, dynamic> json) => DesignModel(
        id: json['id'] as String,
        artistId: json['artistId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        imageUrls: List<String>.from(json['imageUrls'] as List? ?? []),
        // category: DressCategory.values.byName(json['category'] as String),
        estimatedPrice: (json['estimatedPrice'] as num).toDouble(),
        isTrending: json['isTrending'] as bool? ?? false,
        colorTags: List<String>.from(json['colorTags'] as List? ?? []),
        eventTags: List<String>.from(json['eventTags'] as List? ?? []),
        viewCount: json['viewCount'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'artistId': artistId,
        'title': title,
        'description': description,
        'imageUrls': imageUrls,
        // 'category': category.name,
        'estimatedPrice': estimatedPrice,
        'isTrending': isTrending,
        'colorTags': colorTags,
        'eventTags': eventTags,
        'viewCount': viewCount,
        'createdAt': createdAt.toIso8601String(),
      };
}