import 'package:smartstitch/models/clothing_type.dart';
import 'package:smartstitch/models/measurement_field.dart';

class FieldValidationResult {
  final bool isValid;
  final String? errorMessage;

  const FieldValidationResult.valid()
      : isValid = true,
        errorMessage = null;

  const FieldValidationResult.invalid(String message)
      : isValid = false,
        errorMessage = message;
}

/// Centralized validation so every measurement input (manual entry sheet,
/// edit sheet, custom checklist) enforces the same rules:
///  - required fields cannot be empty
///  - value must be numeric
///  - value must be greater than zero
///  - value must fall inside a realistic range for that field
class MeasurementValidator {
  MeasurementValidator._();

  static FieldValidationResult validateField({
    required MeasurementField field,
    required String? rawValue,
    required bool required,
  }) {
    final spec = MeasurementFieldRegistry.specOf(field);
    final text = rawValue?.trim() ?? '';

    if (text.isEmpty) {
      return required
          ? FieldValidationResult.invalid('${spec.label} is required')
          : const FieldValidationResult.valid();
    }

    final value = double.tryParse(text);
    if (value == null) {
      return FieldValidationResult.invalid('${spec.label} must be a number');
    }
    if (value <= 0) {
      return FieldValidationResult.invalid(
          '${spec.label} must be greater than zero');
    }
    if (value < spec.min || value > spec.max) {
      return FieldValidationResult.invalid(
        '${spec.label} must be between ${spec.min.toStringAsFixed(0)}-${spec.max.toStringAsFixed(0)} cm',
      );
    }
    return const FieldValidationResult.valid();
  }

  /// Validates a whole form for [clothingType]. For [ClothingType.custom],
  /// pass the user-selected [customFields] — they're all treated as
  /// required since the customer explicitly chose to track them.
  ///
  /// Returns a map of field -> error message for every field that failed.
  /// An empty map means the form is valid and safe to save.
  static Map<MeasurementField, String> validateForm({
    required ClothingType clothingType,
    required Map<MeasurementField, String?> rawValues,
    Set<MeasurementField> customFields = const {},
  }) {
    final config = ClothingMeasurementRegistry.of(clothingType);
    final fieldsToCheck = clothingType == ClothingType.custom
        ? customFields
        : config.displayFields.toSet();
    final requiredFields =
        clothingType == ClothingType.custom ? customFields : config.required;

    final errors = <MeasurementField, String>{};
    for (final field in fieldsToCheck) {
      final result = validateField(
        field: field,
        rawValue: rawValues[field],
        required: requiredFields.contains(field),
      );
      if (!result.isValid) errors[field] = result.errorMessage!;
    }
    return errors;
  }
}