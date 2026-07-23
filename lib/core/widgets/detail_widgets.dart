import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartstitch/core/widgets/shared_widgets.dart';

import '../../../core/theme/app.theme.dart';

// ─── SECTION WRAPPER ──────────────────────────────────────────────────────

class ComplaintSectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;
  const ComplaintSectionCard({
    super.key,
    required this.isDark,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 8), child: c)),
      child: ComplaintGlassCard(
        isDark: isDark,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: ComplaintUI.accent(isDark)),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(title, style: AppTextStyles.sectionTitle.copyWith(color: ComplaintUI.textPrimary(isDark)))),
              if (trailing != null) trailing!,
            ]),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class ComplaintKeyValueRow extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const ComplaintKeyValueRow({super.key, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: ComplaintUI.textSecondary(isDark)))),
          Expanded(
              child: Text(value,
                  style: AppTextStyles.bodySmall.copyWith(color: ComplaintUI.textPrimary(isDark), fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

// ─── CUSTOMER INFORMATION ─────────────────────────────────────────────────
// ✅ FIXED: Email / Phone / Total Orders / Total Complaints were always
// showing "—" because those fields live on the `users` (and separately
// `orders`/`complaints`) collections, not on the complaint document itself.
// This now fetches the real customer doc (by userId/customerId found on the
// complaint) and computes live order/complaint counts.

class ComplaintCustomerInfoCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  const ComplaintCustomerInfoCard({super.key, required this.data, required this.isDark});

  @override
  State<ComplaintCustomerInfoCard> createState() => _ComplaintCustomerInfoCardState();
}

class _ComplaintCustomerInfoCardState extends State<ComplaintCustomerInfoCard> {
  late Future<_CustomerDetails> _future;
  String? _loadedForUserId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant ComplaintCustomerInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final userId = _resolveUserId();
    if (userId != _loadedForUserId) {
      _future = _load();
    }
  }

  String? _resolveUserId() {
    final id = widget.data['userId'] ??
        widget.data['customerId'] ??
        widget.data['uid'];
    return id?.toString();
  }

  Future<_CustomerDetails> _load() async {
    final userId = _resolveUserId();
    _loadedForUserId = userId;

    if (userId == null || userId.isEmpty) {
      return _CustomerDetails.fromComplaintOnly(widget.data);
    }

    final db = FirebaseFirestore.instance;
    String? email;
    String? phone;
    int? totalOrders;
    int? totalComplaints;

    try {
      final userDoc = await db.collection('users').doc(userId).get();
      final u = userDoc.data();
      email = u?['email']?.toString();
      phone = (u?['phone'] ?? u?['phoneNumber'] ?? u?['contactNumber'])?.toString();
      if (u?['totalOrders'] != null) totalOrders = (u!['totalOrders'] as num).toInt();
      if (u?['totalComplaints'] != null) totalComplaints = (u!['totalComplaints'] as num).toInt();
    } catch (_) {
      // fall through — will fall back to complaint-level fields / dashes
    }

    // If not stored directly on the user doc, count them live.
    if (totalOrders == null) {
      try {
        final ordersSnap = await db
            .collection('orders')
            .where('customerId', isEqualTo: userId)
            .count()
            .get();
        totalOrders = ordersSnap.count;
      } catch (_) {
        totalOrders = null;
      }
    }

    if (totalComplaints == null) {
      try {
        final complaintsSnap = await db
            .collection('complaints')
            .where('userId', isEqualTo: userId)
            .count()
            .get();
        totalComplaints = complaintsSnap.count;
      } catch (_) {
        totalComplaints = null;
      }
    }

    return _CustomerDetails(
      email: email ?? widget.data['email']?.toString(),
      phone: phone ?? widget.data['phone']?.toString(),
      totalOrders: totalOrders,
      totalComplaints: totalComplaints,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final data = widget.data;
    final name = (data['userName'] ?? 'User').toString();
    final tier = (data['customerType'] ?? data['role'] ?? 'Regular').toString();

    return ComplaintSectionCard(
      isDark: isDark,
      title: 'Customer Information',
      icon: Icons.person_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ComplaintAvatar(name: name, radius: 24, isDark: isDark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.labelLarge.copyWith(color: ComplaintUI.textPrimary(isDark))),
                  const SizedBox(height: 6),
                  ComplaintTierBadge(tier: tier),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Divider(color: ComplaintUI.border(isDark)),
          const SizedBox(height: 10),
          FutureBuilder<_CustomerDetails>(
            future: _future,
            builder: (context, snap) {
              final details = snap.data;
              final loading = snap.connectionState == ConnectionState.waiting;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ComplaintKeyValueRow(
                    label: 'Email',
                    value: loading ? 'Loading...' : (details?.email ?? '—'),
                    isDark: isDark,
                  ),
                  ComplaintKeyValueRow(
                    label: 'Phone',
                    value: loading ? 'Loading...' : (details?.phone ?? '—'),
                    isDark: isDark,
                  ),
                  ComplaintKeyValueRow(
                    label: 'Total Orders',
                    value: loading ? 'Loading...' : (details?.totalOrders?.toString() ?? '—'),
                    isDark: isDark,
                  ),
                  ComplaintKeyValueRow(
                    label: 'Total Complaints',
                    value: loading ? 'Loading...' : (details?.totalComplaints?.toString() ?? '—'),
                    isDark: isDark,
                  ),
                ],
              );
            },
          ),
          ComplaintKeyValueRow(
            label: 'Member Since',
            value: ComplaintUI.formatTimestamp(data['memberSince'] ?? data['createdAt']),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _CustomerDetails {
  final String? email;
  final String? phone;
  final int? totalOrders;
  final int? totalComplaints;
  const _CustomerDetails({this.email, this.phone, this.totalOrders, this.totalComplaints});

  factory _CustomerDetails.fromComplaintOnly(Map<String, dynamic> data) => _CustomerDetails(
        email: data['email']?.toString(),
        phone: data['phone']?.toString(),
        totalOrders: data['totalOrders'] != null ? (data['totalOrders'] as num).toInt() : null,
        totalComplaints: data['totalComplaints'] != null ? (data['totalComplaints'] as num).toInt() : null,
      );
}

// ─── COMPLAINT INFORMATION ────────────────────────────────────────────────

class ComplaintInfoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  final String id;
  const ComplaintInfoCard({super.key, required this.data, required this.isDark, required this.id});

  @override
  Widget build(BuildContext context) {
    final priority = (data['priority'] ?? 'Normal').toString();
    final status = (data['status'] ?? 'pending').toString();
    return ComplaintSectionCard(
      isDark: isDark,
      title: 'Complaint Information',
      icon: Icons.description_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ComplaintKeyValueRow(label: 'Complaint ID', value: id, isDark: isDark),
          ComplaintKeyValueRow(label: 'Order ID', value: (data['orderId'] ?? '—').toString(), isDark: isDark),
          ComplaintKeyValueRow(label: 'Booking ID', value: (data['bookingId'] ?? '—').toString(), isDark: isDark),
          ComplaintKeyValueRow(label: 'Artist ID', value: (data['artistId'] ?? '—').toString(), isDark: isDark),
          ComplaintKeyValueRow(label: 'Category', value: (data['category'] ?? data['issueType'] ?? 'general').toString(), isDark: isDark),
          ComplaintKeyValueRow(label: 'Subject', value: (data['subject'] ?? '—').toString(), isDark: isDark),
          const SizedBox(height: 4),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ComplaintMiniBadge(label: priority, color: ComplaintUI.priority(priority), icon: Icons.flag_rounded),
            ComplaintStatusBadge(status: status, isDark: isDark),
          ]),
          const SizedBox(height: 10),
          Divider(color: ComplaintUI.border(isDark)),
          const SizedBox(height: 6),
          ComplaintKeyValueRow(label: 'Submitted', value: ComplaintUI.formatTimestamp(data['createdAt']), isDark: isDark),
        ],
      ),
    );
  }
}

// ─── CONVERSATION THREAD ──────────────────────────────────────────────────

class ComplaintChatMessage {
  final String name;
  final String message;
  final dynamic timestamp;
  final bool isAdmin;
  final bool read;
  const ComplaintChatMessage({
    required this.name,
    required this.message,
    required this.timestamp,
    required this.isAdmin,
    this.read = true,
  });
}

class ComplaintConversationThread extends StatelessWidget {
  final bool isDark;
  final List<ComplaintChatMessage> messages;
  const ComplaintConversationThread({super.key, required this.isDark, required this.messages});

  @override
  Widget build(BuildContext context) {
    return ComplaintSectionCard(
      isDark: isDark,
      title: 'Conversation',
      icon: Icons.forum_outlined,
      child: Column(
        children: [
          for (int i = 0; i < messages.length; i++) ...[
            _Bubble(isDark: isDark, msg: messages[i]),
            if (i != messages.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool isDark;
  final ComplaintChatMessage msg;
  const _Bubble({required this.isDark, required this.msg});

  @override
  Widget build(BuildContext context) {
    final accent = ComplaintUI.accent(isDark);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset((msg.isAdmin ? 1 : -1) * (1 - v) * 16, 0), child: child),
      ),
      child: Row(
        mainAxisAlignment: msg.isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isAdmin) ...[ComplaintAvatar(name: msg.name, radius: 16, isDark: isDark), const SizedBox(width: 8)],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: msg.isAdmin ? (isDark ? accent.withValues(alpha: .22) : AppColors.primarySoft) : ComplaintUI.surface2(isDark),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isAdmin ? 16 : 4),
                  bottomRight: Radius.circular(msg.isAdmin ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg.name, style: AppTextStyles.labelSmall.copyWith(color: ComplaintUI.textSecondary(isDark))),
                  const SizedBox(height: 6),
                  Text(msg.message, style: AppTextStyles.bodyMedium.copyWith(color: ComplaintUI.textPrimary(isDark))),
                  const SizedBox(height: 8),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(ComplaintUI.formatTimestamp(msg.timestamp), style: AppTextStyles.caption.copyWith(color: ComplaintUI.textHint(isDark))),
                    if (msg.isAdmin) ...[
                      const SizedBox(width: 6),
                      Icon(msg.read ? Icons.done_all_rounded : Icons.done_rounded,
                          size: 14, color: msg.read ? accent : ComplaintUI.textHint(isDark)),
                    ],
                  ]),
                ],
              ),
            ),
          ),
          if (msg.isAdmin) ...[const SizedBox(width: 8), ComplaintAvatar(name: msg.name, radius: 16, isDark: isDark)],
        ],
      ),
    );
  }
}

// ─── ATTACHMENTS ──────────────────────────────────────────────────────────

class ComplaintAttachmentsGallery extends StatelessWidget {
  final bool isDark;
  final List<String> images;
  final List<String> videos;
  const ComplaintAttachmentsGallery({super.key, required this.isDark, this.images = const [], this.videos = const []});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty && videos.isEmpty) return const SizedBox.shrink();
    return ComplaintSectionCard(
      isDark: isDark,
      title: 'Attachments',
      icon: Icons.attach_file_rounded,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final url in images) _Thumb(isDark: isDark, url: url, isVideo: false),
          for (final url in videos) _Thumb(isDark: isDark, url: url, isVideo: true),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final bool isDark;
  final String url;
  final bool isVideo;
  const _Thumb({required this.isDark, required this.url, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    return ComplaintHoverLift(
      child: GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: AppRadius.large,
              child: isVideo
                  ? Container(color: Colors.black87, width: 480, height: 300,
                      child: const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 64)))
                  : Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded)),
            ),
          ),
        ),
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            borderRadius: AppRadius.medium,
            border: Border.all(color: ComplaintUI.border(isDark)),
            color: ComplaintUI.surface2(isDark),
            image: isVideo
                ? null
                : DecorationImage(image: NetworkImage(url), fit: BoxFit.cover, onError: (_, __) {}),
          ),
          child: isVideo
              ? Center(child: Icon(Icons.play_circle_fill_rounded, color: ComplaintUI.accent(isDark), size: 32))
              : null,
        ),
      ),
    );
  }
}

// ─── TIMELINE ─────────────────────────────────────────────────────────────

class ComplaintStatusTimeline extends StatelessWidget {
  final bool isDark;
  final Map<String, dynamic> data;
  const ComplaintStatusTimeline({super.key, required this.isDark, required this.data});

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'pending').toString();
    final items = <_TimelineItem>[
      _TimelineItem('Complaint Submitted', data['createdAt'], Icons.flag_rounded),
      _TimelineItem('Auto Acknowledgement Sent', data['autoResponseAt'], Icons.mark_email_read_rounded),
      _TimelineItem('Assigned to Admin', data['assignedAt'], Icons.assignment_ind_rounded),
      _TimelineItem('Under Review', data['reviewedAt'], Icons.visibility_rounded),
      _TimelineItem('Waiting for Customer', data['waitingAt'], Icons.hourglass_bottom_rounded),
      _TimelineItem('Resolved', data['resolvedAt'], Icons.check_circle_rounded),
      _TimelineItem('Closed', data['closedAt'], Icons.lock_rounded),
    ];

    // Determine the "current" step: last completed one, unless closed/resolved.
    int currentIndex = -1;
    for (int i = 0; i < items.length; i++) {
      if (items[i].timestamp is Timestamp) currentIndex = i;
    }
    if (status == 'resolved' || status == 'closed') currentIndex = -1; // no glow once finished

    return ComplaintSectionCard(
      isDark: isDark,
      title: 'Status Timeline',
      icon: Icons.timeline_rounded,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            _TimelineRow(
              isDark: isDark,
              item: items[i],
              isLast: i == items.length - 1,
              isCurrent: i == currentIndex,
            ),
        ],
      ),
    );
  }
}

class _TimelineItem {
  final String label;
  final dynamic timestamp;
  final IconData icon;
  const _TimelineItem(this.label, this.timestamp, this.icon);
  bool get done => timestamp is Timestamp;
}

class _TimelineRow extends StatelessWidget {
  final bool isDark;
  final _TimelineItem item;
  final bool isLast;
  final bool isCurrent;
  const _TimelineRow({required this.isDark, required this.item, required this.isLast, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final color = item.done ? AppColors.success : ComplaintUI.textHint(isDark);
    final glowColor = isCurrent ? ComplaintUI.accent(isDark) : color;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: glowColor.withValues(alpha: .16),
                  shape: BoxShape.circle,
                  boxShadow: isCurrent
                      ? [BoxShadow(color: glowColor.withValues(alpha: .55), blurRadius: 12, spreadRadius: 2)]
                      : null,
                ),
                child: Icon(item.icon, size: 16, color: glowColor),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: ComplaintUI.border(isDark))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrent ? ComplaintUI.accent(isDark).withValues(alpha: .08) : Colors.transparent,
                  borderRadius: AppRadius.medium,
                  border: isCurrent ? Border.all(color: ComplaintUI.accent(isDark).withValues(alpha: .4)) : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label,
                              style: AppTextStyles.labelLarge.copyWith(
                                  color: item.done ? ComplaintUI.textPrimary(isDark) : ComplaintUI.textHint(isDark))),
                          const SizedBox(height: 2),
                          Text(ComplaintUI.formatTimestamp(item.timestamp),
                              style: AppTextStyles.caption.copyWith(color: ComplaintUI.textSecondary(isDark))),
                        ],
                      ),
                    ),
                    if (item.done) const Icon(Icons.check_rounded, size: 16, color: AppColors.success),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── STATUS MESSAGE BANNER ────────────────────────────────────────────────

class ComplaintStatusMessageBanner extends StatelessWidget {
  final String status;
  final bool isDark;
  const ComplaintStatusMessageBanner({super.key, required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final Color soft;
    late final IconData icon;
    late final String message;

    switch (status) {
      case 'in_process':
      case 'in_progress':
        color = AppColors.info;
        soft = isDark ? AppColors.infoSoftDark : AppColors.infoSoft;
        icon = Icons.support_agent_rounded;
        message = 'Your complaint has been assigned to our support team and is currently under investigation.';
        break;
      case 'resolved':
        color = AppColors.success;
        soft = isDark ? AppColors.successSoftDark : AppColors.successSoft;
        icon = Icons.check_circle_rounded;
        message =
            'Your complaint has been successfully resolved. Thank you for your patience. If the issue persists, you can reopen this complaint.';
        break;
      case 'closed':
        return const SizedBox.shrink();
      default:
        color = AppColors.warning;
        soft = isDark ? AppColors.warningSoftDark : AppColors.warningSoft;
        icon = Icons.hourglass_top_rounded;
        message =
            "We've received your complaint successfully. Our support team is reviewing your request. Expected response time: within 24 hours.";
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: AppRadius.large,
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: color))),
        ],
      ),
    );
  }
}