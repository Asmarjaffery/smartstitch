import 'package:flutter/material.dart';

/// Supported clothing types for the Body Measurement module.
///
/// To support a new clothing type in the future:
/// 1. Add a value here.
/// 2. Register its required/optional measurement fields in
///    [ClothingMeasurementRegistry] (see measurement_field.dart).
/// That's it — every screen (selector, manual entry, AI scan display,
/// history, edit, validation) reads from that single registry.
enum ClothingType { shirt, trouser, shalwarKameez, fullDress, custom }

extension ClothingTypeX on ClothingType {
  /// Firestore-safe key. Also used to map legacy documents (which have no
  /// `clothingType` field at all) to [ClothingType.custom] so their data
  /// keeps displaying exactly as it did before this feature existed.
  String get key {
    switch (this) {
      case ClothingType.shirt:
        return 'shirt';
      case ClothingType.trouser:
        return 'trouser';
      case ClothingType.shalwarKameez:
        return 'shalwarKameez';
      case ClothingType.fullDress:
        return 'fullDress';
      case ClothingType.custom:
        return 'custom';
    }
  }

  String get label {
    switch (this) {
      case ClothingType.shirt:
        return 'Shirt';
      case ClothingType.trouser:
        return 'Trouser';
      case ClothingType.shalwarKameez:
        return 'Shalwar Kameez';
      case ClothingType.fullDress:
        return 'Full Dress';
      case ClothingType.custom:
        return 'Custom';
    }
  }

  String get emoji {
    switch (this) {
      case ClothingType.shirt:
        return '👔';
      case ClothingType.trouser:
        return '👖';
      case ClothingType.shalwarKameez:
        return '🥻';
      case ClothingType.fullDress:
        return '👗';
      case ClothingType.custom:
        return '✂️';
    }
  }

  IconData get icon {
    switch (this) {
      case ClothingType.shirt:
        return Icons.checkroom_rounded;
      case ClothingType.trouser:
        return Icons.dry_cleaning_rounded;
      case ClothingType.shalwarKameez:
        return Icons.style_rounded; // valid icon
      case ClothingType.fullDress:
        return Icons.woman_rounded;
      case ClothingType.custom:
        return Icons.tune_rounded;
    }
  }

  static ClothingType fromKey(String? key) {
    return ClothingType.values.firstWhere(
      (e) => e.key == key,
      orElse: () => ClothingType.custom,
    );
  }
}
