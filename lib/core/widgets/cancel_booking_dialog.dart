import 'package:flutter/material.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/enums.dart';

/// Result returned when the customer confirms cancellation.
class CancelBookingResult {
  final CancellationReason reason;
  final String description;
  const CancelBookingResult(this.reason, this.description);
}

/// Shows the Material 3 "Cancel Booking" confirmation dialog and resolves
/// with a [CancelBookingResult] once the customer confirms, or `null` if
/// they back out. Call this from the Cancel Booking button's onPressed —
/// it does not touch Firestore itself, keeping persistence in the
/// controller (see OrderController.cancelOrder).
Future<CancelBookingResult?> showCancelBookingDialog(
  BuildContext context, {
  required bool isPaid,
}) {
  return showDialog<CancelBookingResult>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _CancelBookingDialog(isPaid: isPaid),
  );
}

class _CancelBookingDialog extends StatefulWidget {
  final bool isPaid;
  const _CancelBookingDialog({required this.isPaid});

  @override
  State<_CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<_CancelBookingDialog> {
  CancellationReason? _selected;
  final TextEditingController _otherController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _otherController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_selected == null) {
      setState(() => _error = 'Please select a reason for cancellation.');
      return;
    }
    if (_selected == CancellationReason.other &&
        _otherController.text.trim().isEmpty) {
      setState(() => _error = 'Please tell us a bit more.');
      return;
    }

    final description = _selected == CancellationReason.other
        ? _otherController.text.trim()
        : _descController.text.trim();

    Navigator.of(context).pop(
      CancelBookingResult(_selected!, description),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: AppRadius.medium,
                    ),
                    child: const Icon(Icons.event_busy_rounded,
                        color: AppColors.error, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Cancel Booking', style: AppTextStyles.h4),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.isPaid
                    ? 'This booking is paid. Once cancelled, a refund request will be created automatically for our team to review.'
                    : 'Are you sure you want to cancel this booking?',
                style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 18),
              const Text('Reason for cancellation', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: CancellationReason.values.map((reason) {
                      final isSelected = _selected == reason;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: AppRadius.medium,
                          onTap: () => setState(() {
                            _selected = reason;
                            _error = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.medium,
                              color: isSelected
                                  ? AppColors.primarySoft
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : theme.colorScheme.outline,
                              ),
                            ),
                            child: RadioListTile<CancellationReason>(
                              value: reason,
                              groupValue: _selected,
                              onChanged: (val) => setState(() {
                                _selected = val;
                                _error = null;
                              }),
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(reason.label,
                                  style: AppTextStyles.labelMedium),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (_selected == CancellationReason.other) ...[
                const SizedBox(height: 4),
                TextField(
                  controller: _otherController,
                  maxLines: 3,
                  minLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Please describe your reason...',
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurface2
                        : AppColors.primarySoft,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.medium,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: AppTextStyles.bodySmall,
                ),
              ] else if (_selected != null) ...[
                const SizedBox(height: 4),
                TextField(
                  controller: _descController,
                  maxLines: 2,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Additional details (optional)',
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurface2
                        : AppColors.primarySoft,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.medium,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: AppTextStyles.bodySmall,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.outline),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.medium),
                      ),
                      child: Text('Keep Booking',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: theme.textTheme.bodyLarge?.color)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.medium),
                      ),
                      child: Text('Yes, Cancel',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
