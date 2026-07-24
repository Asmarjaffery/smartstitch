import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/models/clothing_type.dart';
import 'package:smartstitch/models/measurement_field.dart';

class BodyMeasurementModel {
  final String id;
  final String userId;

  /// Which garment these measurements are for. Documents saved before this
  /// feature existed have no `clothingType` in Firestore, so they default
  /// to [ClothingType.custom] — which keeps showing every original field,
  /// exactly like before.
  final ClothingType clothingType;

  // ── Original fields — names/types unchanged so any existing code that
  //    reads `measurement.chest`, `measurement.sleevLength`, etc. keeps
  //    compiling and working exactly as before. ──────────────────────────
  final double height; // cm
  final double chest; // cm
  final double waist; // cm
  final double shoulder; // cm
  final double hips; // cm
  final double sleevLength; // cm
  final double inseam; // cm
  final double neck; // cm

  // ── New fields, required for Shirt / Trouser / Shalwar Kameez ─────────
  final double? wrist;
  final double? shirtLength;
  final double? outseam;
  final double? thigh;
  final double? knee;
  final double? bottomWidth;
  final double? trouserLength;

  /// Only meaningful when [clothingType] is [ClothingType.custom] — the
  /// exact fields the customer chose to track for this record.
  final List<MeasurementField>? customFields;

  final double aiAccuracyScore;
  final bool isAiGenerated;
  final DateTime measuredAt;

  const BodyMeasurementModel({
    required this.id,
    required this.userId,
    this.clothingType = ClothingType.custom,
    required this.height,
    required this.chest,
    required this.waist,
    required this.shoulder,
    required this.hips,
    required this.sleevLength,
    required this.inseam,
    required this.neck,
    this.wrist,
    this.shirtLength,
    this.outseam,
    this.thigh,
    this.knee,
    this.bottomWidth,
    this.trouserLength,
    this.customFields,
    required this.aiAccuracyScore,
    this.isAiGenerated = false,
    required this.measuredAt,
  });

  /// The fields that actually apply to this record. This is what makes
  /// history/edit/AI-scan screens clothing-type aware instead of always
  /// showing all fifteen measurements.
  List<MeasurementField> get activeFields {
    if (clothingType == ClothingType.custom) {
      return customFields ?? MeasurementField.values;
    }
    return ClothingMeasurementRegistry.of(clothingType).displayFields;
  }

  /// Generic accessor so UI code can loop over [activeFields] instead of
  /// writing a repeated switch/if-chain per screen.
  double? valueOf(MeasurementField field) {
    switch (field) {
      case MeasurementField.height:
        return height;
      case MeasurementField.chest:
        return chest;
      case MeasurementField.waist:
        return waist;
      case MeasurementField.shoulder:
        return shoulder;
      case MeasurementField.hips:
        return hips;
      case MeasurementField.sleeveLength:
        return sleevLength;
      case MeasurementField.inseam:
        return inseam;
      case MeasurementField.neck:
        return neck;
      case MeasurementField.wrist:
        return wrist;
      case MeasurementField.shirtLength:
        return shirtLength;
      case MeasurementField.outseam:
        return outseam;
      case MeasurementField.thigh:
        return thigh;
      case MeasurementField.knee:
        return knee;
      case MeasurementField.bottomWidth:
        return bottomWidth;
      case MeasurementField.trouserLength:
        return trouserLength;
    }
  }

  BodyMeasurementModel copyWith({
    String? id,
    String? userId,
    ClothingType? clothingType,
    double? height,
    double? chest,
    double? waist,
    double? shoulder,
    double? hips,
    double? sleevLength,
    double? inseam,
    double? neck,
    double? wrist,
    double? shirtLength,
    double? outseam,
    double? thigh,
    double? knee,
    double? bottomWidth,
    double? trouserLength,
    List<MeasurementField>? customFields,
    double? aiAccuracyScore,
    bool? isAiGenerated,
    DateTime? measuredAt,
  }) {
    return BodyMeasurementModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clothingType: clothingType ?? this.clothingType,
      height: height ?? this.height,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      shoulder: shoulder ?? this.shoulder,
      hips: hips ?? this.hips,
      sleevLength: sleevLength ?? this.sleevLength,
      inseam: inseam ?? this.inseam,
      neck: neck ?? this.neck,
      wrist: wrist ?? this.wrist,
      shirtLength: shirtLength ?? this.shirtLength,
      outseam: outseam ?? this.outseam,
      thigh: thigh ?? this.thigh,
      knee: knee ?? this.knee,
      bottomWidth: bottomWidth ?? this.bottomWidth,
      trouserLength: trouserLength ?? this.trouserLength,
      customFields: customFields ?? this.customFields,
      aiAccuracyScore: aiAccuracyScore ?? this.aiAccuracyScore,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      measuredAt: measuredAt ?? this.measuredAt,
    );
  }

  factory BodyMeasurementModel.fromJson(Map<String, dynamic> json) {
    // New documents nest values under "measurements": { ... }. Old
    // documents (pre clothing-type) have everything flat at the top
    // level — both are read transparently.
    final nested = json['measurements'] is Map
        ? Map<String, dynamic>.from(json['measurements'] as Map)
        : null;

    num? read(String key) {
      if (nested != null && nested[key] != null) return nested[key] as num;
      return json[key] as num?;
    }

    List<MeasurementField>? readCustomFields() {
      final raw = json['customFields'];
      if (raw is! List) return null;
      return raw
          .whereType<String>()
          .map(MeasurementFieldRegistry.fromJsonKey)
          .whereType<MeasurementField>()
          .toList();
    }

    return BodyMeasurementModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      clothingType: ClothingTypeX.fromKey(json['clothingType'] as String?),
      height: read('height')?.toDouble() ?? 0.0,
      chest: read('chest')?.toDouble() ?? 0.0,
      waist: read('waist')?.toDouble() ?? 0.0,
      shoulder: read('shoulder')?.toDouble() ?? 0.0,
      hips: read('hips')?.toDouble() ?? 0.0,
      sleevLength: read('sleevLength')?.toDouble() ?? 0.0,
      inseam: read('inseam')?.toDouble() ?? 0.0,
      neck: read('neck')?.toDouble() ?? 0.0,
      wrist: read('wrist')?.toDouble(),
      shirtLength: read('shirtLength')?.toDouble(),
      outseam: read('outseam')?.toDouble(),
      thigh: read('thigh')?.toDouble(),
      knee: read('knee')?.toDouble(),
      bottomWidth: read('bottomWidth')?.toDouble(),
      trouserLength: read('trouserLength')?.toDouble(),
      customFields: readCustomFields(),
      aiAccuracyScore: (json['aiAccuracyScore'] as num?)?.toDouble() ?? 0.0,
      isAiGenerated: json['isAiGenerated'] as bool? ?? false,
      // ── YEH FIX HAI ──────────────────────────────────────────
      measuredAt: json['measuredAt'] == null
          ? DateTime.now()
          : json['measuredAt'] is Timestamp
              ? (json['measuredAt'] as Timestamp).toDate()
              : DateTime.parse(json['measuredAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    // New nested format — only the measurements relevant to this
    // clothing type, per the updated Firestore shape.
    final measurements = <String, dynamic>{};
    for (final field in activeFields) {
      final value = valueOf(field);
      if (value != null) {
        measurements[MeasurementFieldRegistry.specOf(field).jsonKey] = value;
      }
    }

    return {
      'id': id,
      'userId': userId,
      'clothingType': clothingType.key,
      'measurements': measurements,
      if (clothingType == ClothingType.custom && customFields != null)
        'customFields': customFields!
            .map((f) => MeasurementFieldRegistry.specOf(f).jsonKey)
            .toList(),
      // ── Flat top-level fields kept for backward compatibility with any
      //    existing reads (order system, older app builds, etc). ────────
      'height': height,
      'chest': chest,
      'waist': waist,
      'shoulder': shoulder,
      'hips': hips,
      'sleevLength': sleevLength,
      'inseam': inseam,
      'neck': neck,
      if (wrist != null) 'wrist': wrist,
      if (shirtLength != null) 'shirtLength': shirtLength,
      if (outseam != null) 'outseam': outseam,
      if (thigh != null) 'thigh': thigh,
      if (knee != null) 'knee': knee,
      if (bottomWidth != null) 'bottomWidth': bottomWidth,
      if (trouserLength != null) 'trouserLength': trouserLength,
      'aiAccuracyScore': aiAccuracyScore,
      'isAiGenerated': isAiGenerated,
      'measuredAt': measuredAt.toIso8601String(),
    };
  }
}