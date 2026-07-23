import 'package:flutter/material.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/complaint_model.dart';
import 'package:smartstitch/models/enums.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final ComplaintModel complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          "Complaint Details",
          style: AppTextStyles.h4.copyWith(color: theme.colorScheme.onSurface),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HEADER CARD ────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppRadius.medium,
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "#${complaint.id.substring(0, 6).toUpperCase()}",
                    style: AppTextStyles.h4
                        .copyWith(color: theme.colorScheme.onSurface),
                  ),
                  Row(
                    children: [
                      _statusChip(complaint.status.name, theme),
                      const SizedBox(width: 8),
                      Text(
                        complaint.submittedAt.toString().split(" ")[0],
                        style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── STATUS TIMELINE ────────────────────────
            _sectionCard(
              context: context,
              title: "Status Timeline",
              child: _timeline(context),
            ),

            const SizedBox(height: 16),

            // ── COMPLAINT DETAILS ──────────────────────
            _sectionCard(
              context: context,
              title: "Complaint Details",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow(context, "Order ID",
                      complaint.orderId?.toString() ?? "—"),
                  _detailRow(context, "Artist",
                      complaint.subject.isNotEmpty ? complaint.subject : "—"),
                  _detailRow(
                      context, "Issue Type", complaint.issueType ?? "—"),
                  _detailRow(
                      context, "Priority", complaint.priority ?? "—"),
                  const SizedBox(height: 8),
                  Text("Description",
                      style: AppTextStyles.labelMedium.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(complaint.description,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface)),

                  if (complaint.evidenceImages.isNotEmpty ||
                      complaint.evidenceVideos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text("Attachments",
                        style: AppTextStyles.labelMedium.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(height: 8),
                    _attachmentThumbnailGrid(context, [
                      ...complaint.evidenceImages,
                      ...complaint.evidenceVideos,
                    ]),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── ADMIN RESPONSE ────────────────────────
            _sectionCard(
              context: context,
              title: "Admin Response",
              child: Text(
                complaint.adminResponse ?? "No response yet",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: complaint.adminResponse != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── CHAT WITH SUPPORT ─────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text("Chat With Support"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.medium),
                  elevation: 0,
                  textStyle: AppTextStyles.button,
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _attachmentThumbnailGrid(
      BuildContext context, List<String> urls) {
    const int maxVisible = 3;
    final int total = urls.length;
    final List<String> visible = urls.take(maxVisible).toList();
    final int extra = total - maxVisible;
    final theme = Theme.of(context);

    return Row(
      children: visible.asMap().entries.map((entry) {
        final int index = entry.key;
        final String url = entry.value;
        final bool isLast = index == maxVisible - 1 && extra > 0;
        final bool isVideo = complaint.evidenceVideos.contains(url);

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: AppRadius.small,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      child: Icon(Icons.broken_image_outlined,
                          color: theme.colorScheme.outline),
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                  ),
                  if (isVideo && !isLast)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.videocam,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  if (isLast)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Center(
                        child: Text(
                          "+$extra",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _timeline(BuildContext context) {
    final theme = Theme.of(context);
    final steps = _buildSteps();

    return Column(
      children: steps.asMap().entries.map((entry) {
        final step = entry.value;
        final isDone = step["done"] as bool;
        final date = step["date"] as String;
        final isLast = entry.key == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? theme.colorScheme.primary : Colors.transparent,
                    border: isDone
                        ? null
                        : Border.all(
                            color: theme.colorScheme.onSurfaceVariant, width: 2),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 36,
                    color: isDone
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step["title"] as String,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isDone
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(date,
                      style: AppTextStyles.caption.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  if (!isLast) const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _buildSteps() {
    final status = complaint.status;
    final submitted = complaint.submittedAt.toString().split(" ")[0];
    final resolved = complaint.resolvedAt?.toString().split(" ")[0] ?? "—";

    return [
      {"title": "Complaint Submitted", "done": true, "date": submitted},
      {"title": "Complaint Received", "done": true, "date": submitted},
      {
        "title": "Under Investigation",
        "done": status == ComplaintStatus.inProgress ||
            status == ComplaintStatus.resolved,
        "date": status == ComplaintStatus.inProgress ||
                status == ComplaintStatus.resolved
            ? submitted
            : "—",
      },
      {
        "title": "Resolved",
        "done": status == ComplaintStatus.resolved,
        "date": status == ComplaintStatus.resolved ? resolved : "—",
      },
    ];
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.labelMedium.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: theme.colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.h5
                  .copyWith(color: theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _statusChip(String status, ThemeData theme) {
    Color color;
    String label;
    switch (status) {
      case "pending":
        color = AppColors.warning;
        label = "Pending";
        break;
      case "inProgress":
        color = AppColors.info;
        label = "In Progress";
        break;
      case "resolved":
        color = AppColors.success;
        label = "Resolved";
        break;
      default:
        color = AppColors.info;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
      ),
      child: Text(label,
          style: AppTextStyles.labelSmall.copyWith(color: color)),
    );
  }
}