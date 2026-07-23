
class AiPriceEstimateModel {
  final String id;
  final String userId;
  final String fabricType;
  // final DressCategory category;
  final int complexityLevel; // 1 (simple) to 5 (complex)
  final int estimatedDays;
  final double minPrice;
  final double maxPrice;
  final double suggestedPrice;
  final DateTime generatedAt;

  const AiPriceEstimateModel({
    required this.id,
    required this.userId,
    required this.fabricType,
    // required this.category,
    required this.complexityLevel,
    required this.estimatedDays,
    required this.minPrice,
    required this.maxPrice,
    required this.suggestedPrice,
    required this.generatedAt,
  });

  factory AiPriceEstimateModel.fromJson(Map<String, dynamic> json) =>
      AiPriceEstimateModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        fabricType: json['fabricType'] as String,
        // category: DressCategory.values.byName(json['category'] as String),
        complexityLevel: json['complexityLevel'] as int,
        estimatedDays: json['estimatedDays'] as int,
        minPrice: (json['minPrice'] as num).toDouble(),
        maxPrice: (json['maxPrice'] as num).toDouble(),
        suggestedPrice: (json['suggestedPrice'] as num).toDouble(),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'fabricType': fabricType,
        // 'category': category.name,
        'complexityLevel': complexityLevel,
        'estimatedDays': estimatedDays,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'suggestedPrice': suggestedPrice,
        'generatedAt': generatedAt.toIso8601String(),
      };
}