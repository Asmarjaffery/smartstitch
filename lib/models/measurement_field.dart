import 'package:smartstitch/models/clothing_type.dart';

/// Every individual body measurement the app knows how to collect.
enum MeasurementField {
  height,
  chest,
  shoulder,
  sleeveLength,
  neck,
  wrist,
  shirtLength,
  waist,
  hips,
  inseam,
  outseam,
  thigh,
  knee,
  bottomWidth,
  trouserLength,
}

/// Static metadata for a single field: label, Firestore key and the
/// realistic validation range, in centimeters.
class MeasurementFieldSpec {
  final MeasurementField field;
  final String label;

  /// Key used in `measurements` map / flat Firestore fields.
  /// NOTE: kept as `sleevLength` (not `sleeveLength`) for [MeasurementField.sleeveLength]
  /// to match the existing model/AI-calculator field name and avoid a
  /// breaking Firestore migration.
  final String jsonKey;
  final double min;
  final double max;

  const MeasurementFieldSpec({
    required this.field,
    required this.label,
    required this.jsonKey,
    required this.min,
    required this.max,
  });

  String get rangeLabel =>
      '${min.toStringAsFixed(0)}–${max.toStringAsFixed(0)} cm';
}

/// Central registry — every screen and the validator read field metadata
/// from here instead of hardcoding labels/ranges in multiple places.
class MeasurementFieldRegistry {
  MeasurementFieldRegistry._();

  static const Map<MeasurementField, MeasurementFieldSpec> specs = {
    MeasurementField.height: MeasurementFieldSpec(
      field: MeasurementField.height,
      label: 'Height',
      jsonKey: 'height',
      min: 50,
      max: 250,
    ),
    MeasurementField.chest: MeasurementFieldSpec(
      field: MeasurementField.chest,
      label: 'Chest',
      jsonKey: 'chest',
      min: 20,
      max: 200,
    ),
    MeasurementField.shoulder: MeasurementFieldSpec(
      field: MeasurementField.shoulder,
      label: 'Shoulder',
      jsonKey: 'shoulder',
      min: 20,
      max: 80,
    ),
    MeasurementField.sleeveLength: MeasurementFieldSpec(
      field: MeasurementField.sleeveLength,
      label: 'Sleeve Length',
      jsonKey: 'sleevLength',
      min: 20,
      max: 100,
    ),
    MeasurementField.neck: MeasurementFieldSpec(
      field: MeasurementField.neck,
      label: 'Neck',
      jsonKey: 'neck',
      min: 20,
      max: 70,
    ),
    MeasurementField.wrist: MeasurementFieldSpec(
      field: MeasurementField.wrist,
      label: 'Wrist',
      jsonKey: 'wrist',
      min: 10,
      max: 30,
    ),
    MeasurementField.shirtLength: MeasurementFieldSpec(
      field: MeasurementField.shirtLength,
      label: 'Shirt Length',
      jsonKey: 'shirtLength',
      min: 20,
      max: 150,
    ),
    MeasurementField.waist: MeasurementFieldSpec(
      field: MeasurementField.waist,
      label: 'Waist',
      jsonKey: 'waist',
      min: 20,
      max: 200,
    ),
    MeasurementField.hips: MeasurementFieldSpec(
      field: MeasurementField.hips,
      label: 'Hips',
      jsonKey: 'hips',
      min: 20,
      max: 220,
    ),
    MeasurementField.inseam: MeasurementFieldSpec(
      field: MeasurementField.inseam,
      label: 'Inseam',
      jsonKey: 'inseam',
      min: 20,
      max: 150,
    ),
    MeasurementField.outseam: MeasurementFieldSpec(
      field: MeasurementField.outseam,
      label: 'Outseam',
      jsonKey: 'outseam',
      min: 20,
      max: 170,
    ),
    MeasurementField.thigh: MeasurementFieldSpec(
      field: MeasurementField.thigh,
      label: 'Thigh',
      jsonKey: 'thigh',
      min: 20,
      max: 100,
    ),
    MeasurementField.knee: MeasurementFieldSpec(
      field: MeasurementField.knee,
      label: 'Knee',
      jsonKey: 'knee',
      min: 15,
      max: 80,
    ),
    MeasurementField.bottomWidth: MeasurementFieldSpec(
      field: MeasurementField.bottomWidth,
      label: 'Bottom Width',
      jsonKey: 'bottomWidth',
      min: 10,
      max: 60,
    ),
    MeasurementField.trouserLength: MeasurementFieldSpec(
      field: MeasurementField.trouserLength,
      label: 'Trouser Length',
      jsonKey: 'trouserLength',
      min: 50,
      max: 150,
    ),
  };

  static MeasurementFieldSpec specOf(MeasurementField field) => specs[field]!;

  static MeasurementField? fromJsonKey(String key) {
    for (final spec in specs.values) {
      if (spec.jsonKey == key) return spec.field;
    }
    return null;
  }
}

/// Which fields are required / optional for a clothing type.
class ClothingMeasurementConfig {
  final Set<MeasurementField> required;
  final Set<MeasurementField> optional;

  const ClothingMeasurementConfig({
    this.required = const {},
    this.optional = const {},
  });

  /// All fields that should be shown for this clothing type, required
  /// fields first, in the stable declaration order of [MeasurementField].
  List<MeasurementField> get displayFields => MeasurementField.values
      .where((f) => required.contains(f) || optional.contains(f))
      .toList();

  bool isRequired(MeasurementField field) => required.contains(field);
}

/// Maps each [ClothingType] to the measurement fields it needs.
/// This is *the* place that encodes the business rule "a shirt customer
/// should never be asked for trouser measurements" — everything else
/// (manual entry, AI scan display, edit screen, validation) just reads
/// from it.
class ClothingMeasurementRegistry {
  ClothingMeasurementRegistry._();

  static const Map<ClothingType, ClothingMeasurementConfig> _config = {
    ClothingType.shirt: ClothingMeasurementConfig(
      required: {
        MeasurementField.chest,
        MeasurementField.shoulder,
        MeasurementField.sleeveLength,
        MeasurementField.neck,
        MeasurementField.wrist,
        MeasurementField.shirtLength,
      },
      optional: {MeasurementField.height},
    ),
    ClothingType.trouser: ClothingMeasurementConfig(
      required: {
        MeasurementField.waist,
        MeasurementField.hips,
        MeasurementField.inseam,
        MeasurementField.outseam,
        MeasurementField.thigh,
        MeasurementField.knee,
        MeasurementField.bottomWidth,
      },
    ),
    ClothingType.fullDress: ClothingMeasurementConfig(
      required: {
        MeasurementField.height,
        MeasurementField.chest,
        MeasurementField.waist,
        MeasurementField.shoulder,
        MeasurementField.sleeveLength,
        MeasurementField.hips,
        MeasurementField.neck,
        MeasurementField.inseam,
      },
    ),
    ClothingType.shalwarKameez: ClothingMeasurementConfig(
      required: {
        MeasurementField.height,
        MeasurementField.chest,
        MeasurementField.waist,
        MeasurementField.shoulder,
        MeasurementField.sleeveLength,
        MeasurementField.neck,
        MeasurementField.shirtLength,
        MeasurementField.hips,
        MeasurementField.trouserLength,
        MeasurementField.inseam,
        MeasurementField.bottomWidth,
      },
    ),
    // Custom starts empty on purpose — the customer builds the field set
    // themselves from the full checklist (see [allFields]).
    ClothingType.custom: ClothingMeasurementConfig(),
  };

  static ClothingMeasurementConfig of(ClothingType type) => _config[type]!;

  /// Full checklist offered on the "Custom" flow.
  static List<MeasurementField> get allFields => MeasurementField.values;
}