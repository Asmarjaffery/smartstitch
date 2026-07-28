import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/artist/complaint/artist_complaint_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

class ArtistComplaintScreen extends StatelessWidget {
  const ArtistComplaintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => ArtistComplaintController());
    final controller = ArtistComplaintController.to;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Complaints', style: AppTextStyles.h4),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final complaints = controller.complaints;
        final openCount = complaints
            .where((c) =>
                c.status.toLowerCase() != 'resolved' &&
                c.status.toLowerCase() != 'closed')
            .length;

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: Theme.of(context).colorScheme.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryChip(
                      label: 'Open',
                      value: '$openCount',
                      color: Colors.orange,
                      icon: Icons.report_problem_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryChip(
                      label: 'Total',
                      value: '${complaints.length}',
                      color: Theme.of(context).colorScheme.primary,
                      icon: Icons.list_alt_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (complaints.isEmpty)
                const _EmptyState()
              else
                ...complaints.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ComplaintCard(complaint: c),
                    )),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Summary Chip ────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.small,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: AppTextStyles.h4, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: (Theme.of(context).textTheme.bodySmall?.color ??
                            AppColors.lightTextSecondary))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Complaint Card ──────────────────────────────────────────────────────────
class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint});

  final ArtistComplaintItem complaint;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        return Colors.green;
      case 'in_progress':
      case 'in progress':
      case 'reviewing':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return Colors.red;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final statusColor = _statusColor(c.status);
    final priorityColor = _priorityColor(c.priority);
    final mutedColor =
        Theme.of(context).textTheme.bodySmall?.color ?? AppColors.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: issueType / subject + status badge ───────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.issueType.isNotEmpty ? c.issueType : 'Complaint',
                      style: AppTextStyles.labelLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (c.subject.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        c.subject,
                        style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.full,
                ),
                child: Text(
                  c.status.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(color: statusColor),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Order / customer / time meta row ──────────────────────
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (c.orderId.isNotEmpty)
                Text(
                  'Order #${c.orderId}',
                  style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
                ),
              Text(
                '${c.userName} • ${_relativeTime(c.createdAt)}',
                style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.full,
                ),
                child: Text(
                  '${c.priority} priority',
                  style: AppTextStyles.labelSmall.copyWith(color: priorityColor),
                ),
              ),
            ],
          ),

          // ── Description ───────────────────────────────────────────
          if (c.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(c.description, style: AppTextStyles.bodyMedium),
          ],

          // ── Evidence thumbnails ───────────────────────────────────
          if (c.evidenceImages.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: c.evidenceImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: AppRadius.small,
                  child: Image.network(
                    c.evidenceImages[i],
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported_outlined, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ── Admin Reply — the key missing piece, now front and center ──
          const SizedBox(height: 12),
          _AdminReplyBlock(reply: c.adminReply, resolvedAt: c.resolvedAt),
        ],
      ),
    );
  }
}

// ─── Admin Reply block ────────────────────────────────────────────────────────
//
// Always rendered so the artist has a clear, consistent place to check for
// a response — either the actual reply, or an explicit "still waiting"
// state instead of the reply silently being absent.
class _AdminReplyBlock extends StatelessWidget {
  const _AdminReplyBlock({required this.reply, required this.resolvedAt});

  final AdminReply? reply;
  final DateTime? resolvedAt;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    if (reply == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: AppRadius.small,
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_top_rounded,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color ??
                    AppColors.lightTextSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Waiting for admin response',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color ??
                      AppColors.lightTextSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: AppRadius.small,
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.support_agent_rounded, size: 16, color: primary),
              const SizedBox(width: 6),
              Text(
                'Admin Reply',
                style: AppTextStyles.labelSmall.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (reply!.repliedAt != null) ...[
                const Spacer(),
                Text(
                  _relativeTime(reply!.repliedAt),
                  style: AppTextStyles.labelSmall.copyWith(color: primary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(reply!.message, style: AppTextStyles.bodyMedium),
          if (resolvedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Resolved ${_relativeTime(resolvedAt)}',
              style: AppTextStyles.labelSmall.copyWith(color: Colors.green),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 48,
              color: (Theme.of(context).textTheme.bodySmall?.color ??
                  AppColors.lightTextSecondary)),
          const SizedBox(height: 12),
          Text('No complaints', style: AppTextStyles.labelLarge),
          const SizedBox(height: 4),
          Text(
            'Complaints mentioning you will show up here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.lightTextSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _relativeTime(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);

  if (diff.inDays >= 365) {
    final years = (diff.inDays / 365).floor();
    return '$years ${years == 1 ? 'year' : 'years'} ago';
  }
  if (diff.inDays >= 30) {
    final months = (diff.inDays / 30).floor();
    return '$months ${months == 1 ? 'month' : 'months'} ago';
  }
  if (diff.inDays >= 1) {
    return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
  }
  if (diff.inHours >= 1) {
    return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
  }
  if (diff.inMinutes >= 1) {
    return '${diff.inMinutes} ${diff.inMinutes == 1 ? 'minute' : 'minutes'} ago';
  }
  return 'Just now';
}