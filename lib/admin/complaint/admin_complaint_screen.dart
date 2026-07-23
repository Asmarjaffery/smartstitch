import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/widgets/detail_widgets.dart';
import 'package:smartstitch/core/widgets/shared_widgets.dart';
import 'package:smartstitch/core/widgets/smart_reply_panel.dart';

import '../../core/theme/app.theme.dart';
import 'admin_complaint_controller.dart';


// ─── SCREEN ────────────────────────────────────────────────────────────────

class AdminComplaintScreen extends StatefulWidget {
  const AdminComplaintScreen({super.key});

  @override
  State<AdminComplaintScreen> createState() => _AdminComplaintScreenState();
}

class _AdminComplaintScreenState extends State<AdminComplaintScreen> {
  final ctrl = AdminComplaintController.to;
  final TextEditingController searchCtrl = TextEditingController();
  final RxString selectedId = ''.obs;

  @override
  void initState() {
    super.initState();
    searchCtrl.addListener(_handleSearch);
    ever(ctrl.allComplaints, (_) {
      if (selectedId.value.isEmpty && ctrl.allComplaints.isNotEmpty) {
        selectedId.value = ctrl.allComplaints.first.id;
      } else if (selectedId.value.isNotEmpty &&
          !ctrl.allComplaints.any((e) => e.id == selectedId.value) &&
          ctrl.allComplaints.isNotEmpty) {
        selectedId.value = ctrl.allComplaints.first.id;
      }
    });
  }

  void _handleSearch() => setState(() {});

  @override
  void dispose() {
    searchCtrl.removeListener(_handleSearch);
    searchCtrl.dispose();
    super.dispose();
  }

  QueryDocumentSnapshot? get _selectedComplaint {
    for (final d in ctrl.allComplaints) {
      if (d.id == selectedId.value) return d;
    }
    return ctrl.allComplaints.isNotEmpty ? ctrl.allComplaints.first : null;
  }

  List<QueryDocumentSnapshot> get _searchFiltered {
    final q = searchCtrl.text.trim().toLowerCase();
    return ctrl.allComplaints.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final id = doc.id.toLowerCase();
      final name = (data['userName'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? data['issueType'] ?? '').toString().toLowerCase();
      final status = (data['status'] ?? '').toString().toLowerCase();
      return q.isEmpty || id.contains(q) || name.contains(q) || category.contains(q) || status.contains(q);
    }).toList();
  }

  List<QueryDocumentSnapshot> _applyTimeFilter(List<QueryDocumentSnapshot> items) {
    final filter = ctrl.currentFilter.value;
    final now = DateTime.now();

    if (['all', 'pending', 'in_process', 'resolved', 'closed'].contains(filter)) {
      return items.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = (data['status'] ?? 'pending').toString().trim();
        switch (filter) {
          case 'pending': return status == 'pending';
          case 'in_process': return status == 'in_process' || status == 'in_progress';
          case 'resolved': return status == 'resolved';
          case 'closed': return status == 'closed';
          default: return true;
        }
      }).toList();
    }

    return items.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['createdAt'];
      if (ts is! Timestamp) return true;
      final createdAt = ts.toDate();
      switch (filter) {
        case 'today':
          return createdAt.year == now.year && createdAt.month == now.month && createdAt.day == now.day;
        case 'week':
          return createdAt.isAfter(now.subtract(const Duration(days: 7)));
        case 'month':
          return createdAt.isAfter(DateTime(now.year, now.month - 1, now.day));
        default: return true;
      }
    }).toList();
  }

  void _showDetailSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: ComplaintUI.surface(isDark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: ComplaintUI.border(isDark), borderRadius: AppRadius.full)),
              const SizedBox(height: 8),
              Expanded(
                child: Obx(() => ComplaintRightPanel(
                      isDark: isDark,
                      complaint: _selectedComplaint,
                      isLoading: ctrl.isLoading.value,
                      compact: true,
                      scrollController: scrollCtrl,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.scaffoldGradient(isDark)),
        child: SafeArea(
          child: Obx(() {
            final isLoading = ctrl.isLoading.value;
            final items = _applyTimeFilter(_searchFiltered);

            if (ctrl.totalComplaints.value == 0 && !isLoading) {
              return ComplaintEmptyState(isDark: isDark);
            }

            return LayoutBuilder(builder: (context, c) {
              if (c.maxWidth >= 1100) {
                return Row(children: [
                  SizedBox(
                    width: 440,
                    child: ComplaintLeftPanel(
                      isDark: isDark, ctrl: ctrl, searchCtrl: searchCtrl,
                      list: items, selectedId: selectedId, isLoading: isLoading,
                      onSelect: (id) => selectedId.value = id,
                    ),
                  ),
                  Expanded(
                    child: ComplaintRightPanel(isDark: isDark, complaint: _selectedComplaint, isLoading: isLoading),
                  ),
                ]);
              }

              if (c.maxWidth >= 700) {
                return Column(children: [
                  SizedBox(
                    height: 440,
                    child: ComplaintLeftPanel(
                      isDark: isDark, ctrl: ctrl, searchCtrl: searchCtrl,
                      list: items, selectedId: selectedId, isLoading: isLoading,
                      onSelect: (id) => selectedId.value = id,
                    ),
                  ),
                  Expanded(
                    child: ComplaintRightPanel(isDark: isDark, complaint: _selectedComplaint, isLoading: isLoading),
                  ),
                ]);
              }

              return ComplaintLeftPanel(
                isDark: isDark, ctrl: ctrl, searchCtrl: searchCtrl,
                list: items, selectedId: selectedId, isLoading: isLoading,
                fullBleed: true,
                onSelect: (id) {
                  selectedId.value = id;
                  _showDetailSheet(context, isDark);
                },
              );
            });
          }),
        ),
      ),
    );
  }
}

// ─── LEFT PANEL (Complaint Inbox) ─────────────────────────────────────────

class ComplaintLeftPanel extends StatelessWidget {
  final bool isDark;
  final AdminComplaintController ctrl;
  final TextEditingController searchCtrl;
  final List<QueryDocumentSnapshot> list;
  final RxString selectedId;
  final bool isLoading;
  final bool fullBleed;
  final ValueChanged<String> onSelect;

  const ComplaintLeftPanel({
    super.key,
    required this.isDark,
    required this.ctrl,
    required this.searchCtrl,
    required this.list,
    required this.selectedId,
    required this.isLoading,
    required this.onSelect,
    this.fullBleed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: fullBleed
          ? BoxDecoration(color: ComplaintUI.surface(isDark))
          : BoxDecoration(color: ComplaintUI.surface(isDark), border: Border(right: BorderSide(color: ComplaintUI.border(isDark)))),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(fullBleed ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(gradient: ComplaintUI.avatarGradient(isDark), borderRadius: AppRadius.medium, boxShadow: AppShadows.primary),
                      child: const Icon(Icons.support_agent_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Complaints', style: AppTextStyles.h4.copyWith(color: ComplaintUI.textPrimary(isDark))),
                          const SizedBox(height: 4),
                          Text('Support inbox and resolution queue', style: AppTextStyles.bodySmall.copyWith(color: ComplaintUI.textSecondary(isDark))),
                        ],
                      ),
                    ),
                    Obx(() => ComplaintCountPill(count: ctrl.totalComplaints.value, isDark: isDark)),
                  ],
                ),
                const SizedBox(height: 16),
                _SearchBar(controller: searchCtrl, isDark: isDark),
                const SizedBox(height: 14),
                _FilterChips(ctrl: ctrl, isDark: isDark),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? ComplaintShimmerListPlaceholder(isDark: isDark)
                : list.isEmpty
                    ? Center(child: Text('No complaints found', style: AppTextStyles.bodyMedium.copyWith(color: ComplaintUI.textSecondary(isDark))))
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, fullBleed ? 16 : 20),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final doc = list[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return Obx(() {
                            final isSelected = selectedId.value == doc.id;
                            return ComplaintListCard(
                              isDark: isDark, id: doc.id, data: data,
                              selected: isSelected, onTap: () => onSelect(doc.id),
                            );
                          });
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  const _SearchBar({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTextStyles.bodyMedium.copyWith(color: ComplaintUI.textPrimary(isDark)),
      decoration: InputDecoration(
        hintText: 'Search by name, ID, category, or status',
        prefixIcon: Icon(Icons.search_rounded, color: ComplaintUI.textHint(isDark)),
        filled: true,
        fillColor: ComplaintUI.surface2(isDark),
        border: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide(color: ComplaintUI.accent(isDark), width: 1.5)),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final AdminComplaintController ctrl;
  final bool isDark;
  const _FilterChips({required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final filters = ['all', 'pending', 'in_process', 'resolved', 'closed', 'today', 'week', 'month'];
    return Obx(() {
      final currentFilter = ctrl.currentFilter.value;
      return SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = filters[i];
            final selected = currentFilter == f;
            return ChoiceChip(
              label: Text(f.replaceAll('_', ' ').toUpperCase()),
              labelStyle: AppTextStyles.labelSmall.copyWith(color: selected ? Colors.white : ComplaintUI.textSecondary(isDark)),
              selected: selected,
              onSelected: (_) => ctrl.setFilter(f),
              backgroundColor: ComplaintUI.surface2(isDark),
              selectedColor: ComplaintUI.accent(isDark),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.full),
              side: BorderSide(color: selected ? Colors.transparent : ComplaintUI.border(isDark)),
            );
          },
        ),
      );
    });
  }
}

class ComplaintListCard extends StatelessWidget {
  final bool isDark;
  final String id;
  final Map<String, dynamic> data;
  final bool selected;
  final VoidCallback onTap;

  const ComplaintListCard({
    super.key, required this.isDark, required this.id, required this.data,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final userName = (data['userName'] ?? 'User').toString();
    final tier = (data['customerType'] ?? data['role'] ?? 'Regular').toString();
    final category = (data['category'] ?? data['issueType'] ?? 'general').toString();
    final status = (data['status'] ?? 'pending').toString();
    final subject = (data['subject'] ?? '').toString();
    final message = (data['description'] ?? data['message'] ?? 'No message').toString();
    final created = ComplaintUI.formatTimestamp(data['createdAt']);
    final updated = ComplaintUI.formatTimestamp(data['lastReplyAt'] ?? data['reviewedAt']);
    final unread = (data['isRead'] ?? false) == false;
    final priority = (data['priority'] ?? 'Normal').toString();
    final accent = ComplaintUI.accent(isDark);

    return ComplaintHoverLift(
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.large,
        child: InkWell(
          borderRadius: AppRadius.large,
          onTap: onTap,
          splashColor: accent.withValues(alpha: .12),
          highlightColor: accent.withValues(alpha: .06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: selected ? (isDark ? AppColors.primaryDark.withValues(alpha: .35) : AppColors.primarySoft) : ComplaintUI.surface(isDark),
              borderRadius: AppRadius.large,
              border: Border.all(color: selected ? accent : ComplaintUI.border(isDark), width: selected ? 1.6 : 1),
              boxShadow: AppShadows.card(isDark),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Stack(clipBehavior: Clip.none, children: [
                        ComplaintAvatar(name: userName, radius: 22, isDark: isDark),
                        if (unread)
                          Positioned(
                            right: -1, top: -1,
                            child: Container(
                              width: 11, height: 11,
                              decoration: BoxDecoration(color: accent, shape: BoxShape.circle, border: Border.all(color: ComplaintUI.surface(isDark), width: 2)),
                            ),
                          ),
                      ]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Flexible(child: Text(userName, overflow: TextOverflow.ellipsis, style: AppTextStyles.labelLarge.copyWith(color: ComplaintUI.textPrimary(isDark)))),
                            ]),
                            const SizedBox(height: 4),
                            ComplaintTierBadge(tier: tier),
                          ],
                        ),
                      ),
                      ComplaintStatusBadge(status: status, isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (subject.isNotEmpty) ...[
                    Text(subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.labelLarge.copyWith(color: ComplaintUI.textPrimary(isDark))),
                    const SizedBox(height: 6),
                  ],
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    ComplaintMiniBadge(label: category, color: accent),
                    ComplaintMiniBadge(label: priority, color: ComplaintUI.priority(priority), icon: Icons.flag_rounded),
                  ]),
                  const SizedBox(height: 10),
                  Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySmall.copyWith(color: ComplaintUI.textSecondary(isDark))),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Text('ID: $id', overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: ComplaintUI.textHint(isDark)))),
                    Text(created, style: AppTextStyles.caption.copyWith(color: ComplaintUI.textHint(isDark))),
                  ]),
                  const SizedBox(height: 2),
                  Text('Updated: $updated', style: AppTextStyles.caption.copyWith(color: ComplaintUI.textHint(isDark))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── RIGHT PANEL (Complaint Details) ──────────────────────────────────────

class ComplaintRightPanel extends StatelessWidget {
  final bool isDark;
  final QueryDocumentSnapshot? complaint;
  final bool isLoading;
  final bool compact;
  final ScrollController? scrollController;

  const ComplaintRightPanel({
    super.key, required this.isDark, required this.complaint, required this.isLoading,
    this.compact = false, this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return ComplaintShimmerDetailPlaceholder(isDark: isDark);

    if (complaint == null) {
      return Center(child: Text('Select a complaint to view details', style: AppTextStyles.bodyMedium.copyWith(color: ComplaintUI.textSecondary(isDark))));
    }

    final data = complaint!.data() as Map<String, dynamic>;
    final id = complaint!.id;
    final status = (data['status'] ?? 'pending').toString();
    final adminReply = (data['adminReply'] ?? '').toString();

    final messages = <ComplaintChatMessage>[
      ComplaintChatMessage(
        name: (data['userName'] ?? 'User').toString(),
        message: (data['description'] ?? data['message'] ?? 'No message').toString(),
        timestamp: data['createdAt'], isAdmin: false,
      ),
      if (adminReply.isNotEmpty)
        ComplaintChatMessage(name: 'Admin', message: adminReply, timestamp: data['lastReplyAt'] ?? data['resolvedAt'], isAdmin: true, read: true),
    ];

    final images = ((data['evidenceImages'] as List?) ?? []).map((e) => e.toString()).toList();
    final videos = ((data['evidenceVideos'] as List?) ?? []).map((e) => e.toString()).toList();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: SingleChildScrollView(
        key: ValueKey(id),
        controller: scrollController,
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailHeader(isDark: isDark, id: id, data: data),
            const SizedBox(height: 16),
            ComplaintStatusMessageBanner(status: status, isDark: isDark),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              final stacked = c.maxWidth < 760;
              final customer = ComplaintCustomerInfoCard(data: data, isDark: isDark);
              final info = ComplaintInfoCard(data: data, isDark: isDark, id: id);
              if (stacked) {
                return Column(children: [customer, const SizedBox(height: 16), info]);
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: customer), const SizedBox(width: 16), Expanded(child: info),
              ]);
            }),
            const SizedBox(height: 16),
            ComplaintConversationThread(isDark: isDark, messages: messages),
            if (images.isNotEmpty || videos.isNotEmpty) ...[
              const SizedBox(height: 16),
              ComplaintAttachmentsGallery(isDark: isDark, images: images, videos: videos),
            ],
            const SizedBox(height: 16),
            ComplaintStatusTimeline(isDark: isDark, data: data),
            const SizedBox(height: 16),
            ComplaintSmartReplyPanel(
              isDark: isDark, complaintId: id,
              category: (data['category'] ?? data['issueType'] ?? 'general').toString(),
              description: (data['description'] ?? data['message'] ?? '').toString(),
              currentStatus: status,
            ),
            const SizedBox(height: 16),
            ComplaintActionButtons(isDark: isDark, complaintId: id, status: status),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final bool isDark;
  final String id;
  final Map<String, dynamic> data;
  const _DetailHeader({required this.isDark, required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = (data['userName'] ?? 'User').toString();
    final priority = (data['priority'] ?? 'Normal').toString();
    final status = (data['status'] ?? 'pending').toString();
    final issueType = (data['issueType'] ?? data['category'] ?? 'general').toString();
    final isAutoResponded = (data['isAutoResponded'] ?? false) == true;

    return ComplaintGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ComplaintAvatar(name: name, radius: 26, isDark: isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.h4.copyWith(color: ComplaintUI.textPrimary(isDark))),
                const SizedBox(height: 4),
                Text('Complaint ID: $id', style: AppTextStyles.bodySmall.copyWith(color: ComplaintUI.textSecondary(isDark))),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ComplaintMiniBadge(label: issueType, color: ComplaintUI.accent(isDark)),
                  ComplaintMiniBadge(label: priority, color: ComplaintUI.priority(priority), icon: Icons.flag_rounded),
                  ComplaintStatusBadge(status: status, isDark: isDark, glow: status == 'in_process' || status == 'in_progress'),
                  if (isAutoResponded) ComplaintMiniBadge(label: 'Auto-replied', color: AppColors.info),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}