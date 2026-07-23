import 'package:cloud_firestore/cloud_firestore.dart';

class BodyMeasurementModel {
  final String id;
  final String userId;
  final double height; // cm
  final double chest; // cm
  final double waist; // cm
  final double shoulder; // cm
  final double hips; // cm
  final double sleevLength; // cm
  final double inseam; // cm
  final double neck; // cm
  final double aiAccuracyScore;
  final bool isAiGenerated;
  final DateTime measuredAt;

  const BodyMeasurementModel({
    required this.id,
    required this.userId,
    required this.height,
    required this.chest,
    required this.waist,
    required this.shoulder,
    required this.hips,
    required this.sleevLength,
    required this.inseam,
    required this.neck,
    required this.aiAccuracyScore,
    this.isAiGenerated = false,
    required this.measuredAt,
  });

  factory BodyMeasurementModel.fromJson(Map<String, dynamic> json) =>
      BodyMeasurementModel(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        height: (json['height'] as num?)?.toDouble() ?? 0.0,
        chest: (json['chest'] as num?)?.toDouble() ?? 0.0,
        waist: (json['waist'] as num?)?.toDouble() ?? 0.0,
        shoulder: (json['shoulder'] as num?)?.toDouble() ?? 0.0,
        hips: (json['hips'] as num?)?.toDouble() ?? 0.0,
        sleevLength: (json['sleevLength'] as num?)?.toDouble() ?? 0.0,
        inseam: (json['inseam'] as num?)?.toDouble() ?? 0.0,
        neck: (json['neck'] as num?)?.toDouble() ?? 0.0,
        aiAccuracyScore: (json['aiAccuracyScore'] as num?)?.toDouble() ?? 0.0,
        isAiGenerated: json['isAiGenerated'] as bool? ?? false,
        // ── YEH FIX HAI ──────────────────────────────────────────
        measuredAt: json['measuredAt'] == null
            ? DateTime.now()
            : json['measuredAt'] is Timestamp
                ? (json['measuredAt'] as Timestamp).toDate()
                : DateTime.parse(json['measuredAt'] as String),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'height': height,
        'chest': chest,
        'waist': waist,
        'shoulder': shoulder,
        'hips': hips,
        'sleevLength': sleevLength,
        'inseam': inseam,
        'neck': neck,
        'aiAccuracyScore': aiAccuracyScore,
        'isAiGenerated': isAiGenerated,
        'measuredAt':
            measuredAt.toIso8601String(), 
      };
}
