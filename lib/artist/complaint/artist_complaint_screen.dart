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
        final openCount =
            complaints.where((c) => c.status.toLowerCase() != 'resolved' && c.status.toLowerCase() != 'closed').length;

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.h4),
              Text(label,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: (Theme.of(context).textTheme.bodySmall?.color ?? AppColors.lightTextSecondary))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Complaint Card ──────────────────────────────────────────────────────────

class _ComplaintCard extends StatefulWidget {
  const _ComplaintCard({required this.complaint});

  final ArtistComplaintItem complaint;

  @override
  State<_ComplaintCard> createState() => _ComplaintCardState();
}

class _ComplaintCardState extends State<_ComplaintCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    final statusColor = _statusColor(c.status);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: AppRadius.medium,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(c.title, style: AppTextStyles.labelLarge),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: AppRadius.full,
                        ),
                        child: Text(
                          c.status.toUpperCase(),
                          style: AppTextStyles.labelSmall
                              .copyWith(color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${c.customerName} • ${_relativeTime(c.createdAt)}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: (Theme.of(context).textTheme.bodySmall?.color ?? AppColors.lightTextSecondary)),
                  ),
                  if (c.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(c.description, style: AppTextStyles.bodyMedium),
                  ],
                  if (c.timeline.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          _expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _expanded
                              ? 'Hide timeline'
                              : 'View timeline (${c.timeline.length})',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _Timeline(entries: c.timeline),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        return Colors.green;
      case 'in_progress':
      case 'in progress':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}

// ─── Timeline Stepper ────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  const _Timeline({required this.entries});

  final List<ComplaintTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(entries.length, (i) {
        final entry = entries[i];
        final isLast = i == entries.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, style: AppTextStyles.labelMedium),
                      if (entry.note.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          entry.note,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: (Theme.of(context).textTheme.bodySmall?.color ?? AppColors.lightTextSecondary)),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        _relativeTime(entry.time),
                        style: AppTextStyles.bodySmall.copyWith(
                            color: (Theme.of(context).textTheme.bodySmall?.color ?? AppColors.lightTextSecondary),
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
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
              size: 48, color: (Theme.of(context).textTheme.bodySmall?.color ?? AppColors.lightTextSecondary)),
          const SizedBox(height: 12),
          Text('No complaints', style: AppTextStyles.labelLarge),
          const SizedBox(height: 4),
          Text(
            'Complaints mentioning you will show up here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall
                .copyWith(color: (Theme.of(context).textTheme.bodySmall?.color ?? AppColors.lightTextSecondary)),
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
