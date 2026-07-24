import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/admin/refunds/refund_requests_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/booking_status_badge.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/models/refund_model.dart';

class RefundRequestsScreen extends StatelessWidget {
  const RefundRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(RefundRequestsController());
    final ctrl = RefundRequestsController.to;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Refund Requests', style: AppTextStyles.h4),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Obx(() {
        if (ctrl.isLoading.value && ctrl.refundRequests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.refundRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined,
                    size: 56, color: theme.textTheme.bodySmall?.color),
                const SizedBox(height: 16),
                const Text('No refund requests', style: AppTextStyles.h4),
                const SizedBox(height: 6),
                Text(
                  'Refund requests will appear here as customers cancel paid bookings.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.refundRequests.length,
          itemBuilder: (context, index) {
            return _RefundCard(request: ctrl.refundRequests[index]);
          },
        );
      }),
    );
  }
}

class _RefundCard extends StatelessWidget {
  final RefundRequestModel request;
  const _RefundCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ctrl = RefundRequestsController.to;

    return Obx(() {
      final isProcessing = ctrl.processingIds.contains(request.orderId);
      final isPending = request.refundStatus == RefundStatus.requested;

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.large,
          border: Border.all(color: theme.colorScheme.outline),
          boxShadow: AppShadows.soft(AppColors.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Order #${_shortId(request.orderId)}',
                    style: AppTextStyles.h4,
                  ),
                ),
                _refundStatusBadge(),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(
                icon: Icons.person_outline_rounded,
                label: 'Customer',
                value: request.customerName.isNotEmpty
                    ? request.customerName
                    : '-'),
            const SizedBox(height: 10),
            _InfoRow(
                icon: Icons.content_cut_rounded,
                label: 'Tailor',
                value:
                    request.tailorName.isNotEmpty ? request.tailorName : '-'),
            const SizedBox(height: 10),
            _InfoRow(
                icon: Icons.payments_outlined,
                label: 'Paid Amount',
                value: 'Rs ${request.paidAmount.toInt()}'),
            const SizedBox(height: 10),
            _InfoRow(
                icon: Icons.report_gmailerrorred_rounded,
                label: 'Reason',
                value: request.cancellationReason.label),
            if (request.cancellationDescription.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(
                  icon: Icons.notes_rounded,
                  label: 'Description',
                  value: request.cancellationDescription),
            ],
            const SizedBox(height: 10),
            _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Requested',
                value: request.requestedAt != null
                    ? _formatDate(request.requestedAt!)
                    : '-'),
            const SizedBox(height: 10),
            _InfoRow(
                icon: Icons.assignment_turned_in_outlined,
                label: 'Booking Status',
                value: request.bookingStatus),
            if (request.refundStatus == RefundStatus.rejected &&
                request.rejectionReason != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(isDark ? 0.15 : 0.08),
                  borderRadius: AppRadius.small,
                ),
                child: Text(
                  'Rejection reason: ${request.rejectionReason}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _showRejectDialog(context, request),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.medium),
                      ),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.error, size: 18),
                      label: Text('Reject',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.error)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          isProcessing ? null : () => ctrl.approveRefund(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.medium),
                      ),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18),
                      label: Text(
                        isProcessing ? 'Processing...' : 'Approve Refund',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _refundStatusBadge() {
    late final BookingDisplayStatus status;
    switch (request.refundStatus) {
      case RefundStatus.approved:
        status = BookingDisplayStatus.refunded;
        break;
      case RefundStatus.rejected:
        status = BookingDisplayStatus.refundRejected;
        break;
      case RefundStatus.requested:
        status = BookingDisplayStatus.refundRequested;
        break;
    }
    return BookingStatusBadge(status: status);
  }

  void _showRejectDialog(BuildContext context, RefundRequestModel request) {
    final controller = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reject Refund', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Text(
                'Let the customer know why this refund request was rejected.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: theme.textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                minLines: 2,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Reason for rejection...',
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark
                      ? AppColors.darkSurface2
                      : AppColors.primarySoft,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.medium,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.outline),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.medium),
                      ),
                      child: Text('Cancel',
                          style: AppTextStyles.labelLarge.copyWith(
                              color: theme.textTheme.bodyLarge?.color)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final reason = controller.text.trim();
                        Navigator.of(dialogContext).pop();
                        RefundRequestsController.to.rejectRefund(
                          request,
                          rejectionReason: reason,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.medium),
                      ),
                      child: Text('Reject',
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

  String _shortId(String id) =>
      id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${_formatTime(dt)}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 96,
          child: Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: theme.textTheme.bodySmall?.color)),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.labelMedium),
        ),
      ],
    );
  }
}
