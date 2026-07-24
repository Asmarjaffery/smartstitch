import 'package:flutter/material.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/utils/measurement_validator.dart';
import 'package:smartstitch/models/measurement_field.dart';

/// A single measurement input with live validation (empty / numeric /
/// greater-than-zero / realistic-range). Replaces the old `_Field` widget
/// that both the manual-entry sheet and the edit sheet used to duplicate.
class MeasurementFieldInput extends StatefulWidget {
  final TextEditingController controller;
  final MeasurementField field;
  final bool required;

  const MeasurementFieldInput({
    super.key,
    required this.controller,
    required this.field,
    this.required = true,
  });

  @override
  State<MeasurementFieldInput> createState() => _MeasurementFieldInputState();
}

class _MeasurementFieldInputState extends State<MeasurementFieldInput> {
  String? _error;

  void _validate() {
    final result = MeasurementValidator.validateField(
      field: widget.field,
      rawValue: widget.controller.text,
      required: widget.required,
    );
    setState(() => _error = result.isValid ? null : result.errorMessage);
  }

  @override
  Widget build(BuildContext context) {
    final spec = MeasurementFieldRegistry.specOf(widget.field);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: widget.controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => _validate(),
        decoration: InputDecoration(
          labelText: widget.required ? '${spec.label} *' : spec.label,
          suffixText: 'cm',
          helperText: spec.rangeLabel,
          errorText: _error,
          border: const OutlineInputBorder(borderRadius: AppRadius.medium),
        ),
      ),
    );
  }
}