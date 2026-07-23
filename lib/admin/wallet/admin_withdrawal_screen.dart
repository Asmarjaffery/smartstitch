import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/wallet_models.dart';
import 'package:smartstitch/services/artist_wallet_service.dart';
import 'package:smartstitch/services/wallet_service.dart';

// ─── Combined Withdrawal Model ────────────────────────────────
enum WithdrawalRole { rider, artist }

class CombinedWithdrawal {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final double amount;
  final String paymentMethod;
  final String accountTitle;
  final String accountNumber;
  final String status;
  final DateTime requestedAt;
  final String? notes;
  final String? adminNotes;
  final WithdrawalRole role;

  CombinedWithdrawal({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.amount,
    required this.paymentMethod,
    required this.accountTitle,
    required this.accountNumber,
    required this.status,
    required this.requestedAt,
    this.notes,
    this.adminNotes,
    required this.role,
  });
}

// ─── Filter Enums ─────────────────────────────────────────────
enum RoleFilter { all, riders, artists }

enum StatusFilter { all, pending, paid, rejected }

extension RoleFilterExt on RoleFilter {
  String get label {
    switch (this) {
      case RoleFilter.all:
        return 'All';
      case RoleFilter.riders:
        return 'Riders';
      case RoleFilter.artists:
        return 'Artists';
    }
  }
}

extension StatusFilterExt on StatusFilter {
  String get label {
    switch (this) {
      case StatusFilter.all:
        return 'All';
      case StatusFilter.pending:
        return 'Pending';
      case StatusFilter.paid:
        return 'Paid';
      case StatusFilter.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case StatusFilter.all:
        return AppColors.primary;
      case StatusFilter.pending:
        return AppColors.warning;
      case StatusFilter.paid:
        return AppColors.success;
      case StatusFilter.rejected:
        return AppColors.error;
    }
  }
}

// ============================================================
// MAIN SCREEN
// ============================================================

class AdminCombinedWithdrawalScreen extends StatefulWidget {
  const AdminCombinedWithdrawalScreen({super.key});

  @override
  State<AdminCombinedWithdrawalScreen> createState() =>
      _AdminCombinedWithdrawalScreenState();
}

class _AdminCombinedWithdrawalScreenState
    extends State<AdminCombinedWithdrawalScreen> {
  RoleFilter _roleFilter = RoleFilter.all;
  StatusFilter _statusFilter = StatusFilter.pending;
  final _notesCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _notesCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Fetch Both Collections ──────────────────────────────
  Stream<List<CombinedWithdrawal>> _combinedStream() {
    final riderStream = FirebaseFirestore.instance
        .collection('withdrawal_requests')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return CombinedWithdrawal(
                id: d.id,
                userId: data['riderId'] ?? '',
                userName: data['riderName'] ?? 'Rider',
                userEmail: data['riderEmail'] ?? '',
                amount: ((data['amount'] ?? 0) as num).toDouble(),
                paymentMethod: data['paymentMethod'] ?? '',
                accountTitle: data['accountTitle'] ?? '',
                accountNumber: data['accountNumber'] ?? '',
                status: data['status'] ?? 'pending',
                requestedAt: _parseDate(data['requestedAt']),
                notes: data['notes'],
                adminNotes: data['adminNotes'],
                role: WithdrawalRole.rider,
              );
            }).toList());

    final artistStream = FirebaseFirestore.instance
        .collection('artist_withdrawals')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return CombinedWithdrawal(
                id: d.id,
                userId: data['artistId'] ?? '',
                userName: data['artistName'] ?? 'Artist',
                userEmail: data['artistEmail'] ?? '',
                amount: ((data['amount'] ?? 0) as num).toDouble(),
                paymentMethod: data['paymentMethod'] ?? '',
                accountTitle: data['accountTitle'] ?? '',
                accountNumber: data['accountNumber'] ?? '',
                status: data['status'] ?? 'pending',
                requestedAt: _parseDate(data['requestedAt']),
                notes: data['notes'],
                adminNotes: data['adminNotes'],
                role: WithdrawalRole.artist,
              );
            }).toList());

    return riderStream.asyncMap((riders) async {
      final artists = await artistStream.first;
      final combined = [...riders, ...artists];
      combined.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return combined;
    });
  }

  DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  // ─── Filter Logic ────────────────────────────────────────
  List<CombinedWithdrawal> _applyFilters(List<CombinedWithdrawal> list) {
    return list.where((w) {
      if (_roleFilter == RoleFilter.riders && w.role != WithdrawalRole.rider) {
        return false;
      }
      if (_roleFilter == RoleFilter.artists &&
          w.role != WithdrawalRole.artist) {
        return false;
      }

      if (_statusFilter != StatusFilter.all &&
          w.status != _statusFilter.name) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!w.userName.toLowerCase().contains(q) &&
            !w.userEmail.toLowerCase().contains(q) &&
            !w.id.toLowerCase().contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ─── Stats ───────────────────────────────────────────────
  Map<String, double> _calcStats(List<CombinedWithdrawal> list) {
    double totalPending = 0;
    double totalPaid = 0;
    int pendingCount = 0;

    for (final w in list) {
      if (w.status == 'pending') {
        totalPending += w.amount;
        pendingCount++;
      }
      if (w.status == 'paid') totalPaid += w.amount;
    }

    return {
      'totalPending': totalPending,
      'totalPaid': totalPaid,
      'pendingCount': pendingCount.toDouble(),
    };
  }

  // ============================================================
  // ─── REJECT (simple status update, no Stripe involved) ─────
  // ============================================================
  Future<void> _reject(CombinedWithdrawal w, String? notes) async {
    try {
      if (w.role == WithdrawalRole.rider) {
        await WalletService.instance.updateWithdrawalStatus(
          withdrawalId: w.id,
          riderId: w.userId,
          amount: w.amount,
          newStatus: WithdrawalStatus.rejected,
          adminNotes: notes,
          riderEmail: w.userEmail,
          riderName: w.userName,
        );
      } else {
        await ArtistWalletService.instance.updateWithdrawalStatus(
          withdrawalId: w.id,
          artistId: w.userId,
          amount: w.amount,
          newStatus: WithdrawalStatus.rejected,
          adminNotes: notes,
          artistEmail: w.userEmail,
          artistName: w.userName,
        );
      }

      Get.snackbar(
        'Rejected',
        '${w.userName} — Rejected',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.cancel_rounded, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.error_rounded, color: Colors.white),
      );
    }
  }

  // ============================================================
  // ─── APPROVE (manual — no Stripe, no payout API call).
  // Admin pays the user outside the app (bank transfer, cash,
  // etc.) and simply marks the request as paid here.
  // ============================================================
  Future<void> _approveAndMarkPaid(CombinedWithdrawal w, String? notes) async {
    try {
      if (w.role == WithdrawalRole.rider) {
        await WalletService.instance.updateWithdrawalStatus(
          withdrawalId: w.id,
          riderId: w.userId,
          amount: w.amount,
          newStatus: WithdrawalStatus.paid,
          adminNotes: notes,
          riderEmail: w.userEmail,
          riderName: w.userName,
        );
      } else {
        await ArtistWalletService.instance.updateWithdrawalStatus(
          withdrawalId: w.id,
          artistId: w.userId,
          amount: w.amount,
          newStatus: WithdrawalStatus.paid,
          adminNotes: notes,
          artistEmail: w.userEmail,
          artistName: w.userName,
        );
      }

      Get.snackbar(
        'Success',
        '${w.userName} — Marked as Paid',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  // ─── Action Sheet ────────────────────────────────────────
  void _showActionSheet(CombinedWithdrawal w) {
    _notesCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActionSheet(
        withdrawal: w,
        notesCtrl: _notesCtrl,
        onApprove: () {
          Get.back(); // close sheet first
          final notes =
              _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
          _approveAndMarkPaid(w, notes);
        },
        onReject: () {
          Get.back();
          final notes =
              _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
          _reject(w, notes);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Withdrawal Requests'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.full,
            ),
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded,
                    color: theme.colorScheme.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Admin',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<CombinedWithdrawal>>(
        stream: _combinedStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                  color: theme.colorScheme.primary),
            );
          }

          final allData = snap.data ?? [];
          final stats = _calcStats(allData);
          final filtered = _applyFilters(allData);

          return Column(
            children: [
              _StatsBar(stats: stats),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email or ID...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              _FilterRow(
                selected: _roleFilter,
                onChanged: (v) => setState(() => _roleFilter = v),
              ),
              _StatusFilterRow(
                selected: _statusFilter,
                onChanged: (v) => setState(() => _statusFilter = v),
                allData: allData,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} request${filtered.length == 1 ? '' : 's'}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const Spacer(),
                    if (_roleFilter != RoleFilter.all ||
                        _statusFilter != StatusFilter.all ||
                        _searchQuery.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _roleFilter = RoleFilter.all;
                          _statusFilter = StatusFilter.all;
                          _searchQuery = '';
                          _searchCtrl.clear();
                        }),
                        icon:
                            const Icon(Icons.filter_alt_off_rounded, size: 16),
                        label: const Text('Clear Filters'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          textStyle: AppTextStyles.labelSmall,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(statusFilter: _statusFilter)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _WithdrawalCard(
                          withdrawal: filtered[i],
                          onManage: () => _showActionSheet(filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── STATS BAR ────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final Map<String, double> stats;
  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.large,
        boxShadow: AppShadows.primary,
      ),
      child: Row(
        children: [
          _StatItem(
            label: 'Pending Amount',
            value: 'Rs. ${_fmt(stats['totalPending'] ?? 0)}',
            icon: Icons.hourglass_top_rounded,
            color: Colors.white,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          _StatItem(
            label: 'Total Paid',
            value: 'Rs. ${_fmt(stats['totalPaid'] ?? 0)}',
            icon: Icons.check_circle_rounded,
            color: Colors.white,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          _StatItem(
            label: 'Pending Count',
            value: '${(stats['pendingCount'] ?? 0).toInt()}',
            icon: Icons.pending_actions_rounded,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color.withValues(alpha: 0.8), size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h5.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color.withValues(alpha: 0.75),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── ROLE FILTER ROW ──────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final RoleFilter selected;
  final ValueChanged<RoleFilter> onChanged;
  const _FilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unselectedText = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final unselectedBorder = theme.colorScheme.outline.withValues(alpha: 0.3);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: RoleFilter.values.map((f) {
          final isSelected = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              borderRadius: AppRadius.full,
              child: InkWell(
                onTap: () => onChanged(f),
                borderRadius: AppRadius.full,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    borderRadius: AppRadius.full,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : unselectedBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        f == RoleFilter.riders
                            ? Icons.delivery_dining_rounded
                            : f == RoleFilter.artists
                                ? Icons.palette_rounded
                                : Icons.people_rounded,
                        size: 14,
                        color: isSelected ? Colors.white : unselectedText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        f.label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isSelected ? Colors.white : unselectedText,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── STATUS FILTER ROW ────────────────────────────────────────

class _StatusFilterRow extends StatelessWidget {
  final StatusFilter selected;
  final ValueChanged<StatusFilter> onChanged;
  final List<CombinedWithdrawal> allData;
  const _StatusFilterRow({
    required this.selected,
    required this.onChanged,
    required this.allData,
  });

  int _count(StatusFilter f) {
    if (f == StatusFilter.all) return allData.length;
    return allData.where((w) => w.status == f.name).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unselectedText = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final unselectedBorder = theme.colorScheme.outline.withValues(alpha: 0.3);
    final unselectedBadgeBg = theme.colorScheme.onSurface.withValues(alpha: 0.25);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: StatusFilter.values.map((f) {
          final isSelected = f == selected;
          final count = _count(f);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              borderRadius: AppRadius.full,
              child: InkWell(
                onTap: () => onChanged(f),
                borderRadius: AppRadius.full,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? f.color.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: AppRadius.full,
                    border: Border.all(
                      color: isSelected ? f.color : unselectedBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        f.label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isSelected ? f.color : unselectedText,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? f.color : unselectedBadgeBg,
                          borderRadius: AppRadius.full,
                        ),
                        child: Text(
                          '$count',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── WITHDRAWAL CARD ──────────────────────────────────────────

class _WithdrawalCard extends StatelessWidget {
  final CombinedWithdrawal withdrawal;
  final VoidCallback onManage;
  const _WithdrawalCard({required this.withdrawal, required this.onManage});

  Color get _statusColor {
    switch (withdrawal.status) {
      case 'pending':
        return AppColors.warning;
      case 'paid':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String get _statusLabel {
    switch (withdrawal.status) {
      case 'pending':
        return 'Pending';
      case 'paid':
        return 'Paid';
      case 'rejected':
        return 'Rejected';
      default:
        return withdrawal.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRider = withdrawal.role == WithdrawalRole.rider;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.large,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: isRider
                          ? const LinearGradient(
                              colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : AppColors.primaryGradient,
                      borderRadius: AppRadius.medium,
                    ),
                    child: Icon(
                      isRider
                          ? Icons.delivery_dining_rounded
                          : Icons.palette_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              withdrawal.userName,
                              style: AppTextStyles.h5.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isRider
                                    ? AppColors.info.withValues(
                                        alpha: isDark ? 0.18 : 0.12)
                                    : theme.colorScheme.primary
                                        .withValues(alpha: isDark ? 0.18 : 0.1),
                                borderRadius: AppRadius.full,
                              ),
                              child: Text(
                                isRider ? 'Rider' : 'Artist',
                                style: AppTextStyles.caption.copyWith(
                                  color: isRider
                                      ? AppColors.info
                                      : theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          withdrawal.userEmail,
                          style: AppTextStyles.caption.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs. ${_fmt(withdrawal.amount)}',
                        style: AppTextStyles.h4.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(
                              alpha: isDark ? 0.18 : 0.12),
                          borderRadius: AppRadius.full,
                        ),
                        child: Text(
                          _statusLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.tag_rounded,
                    label: 'ID',
                    value: '#${withdrawal.id.substring(0, 8).toUpperCase()}',
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Method',
                    value: withdrawal.paymentMethod,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Account',
                    value: withdrawal.accountTitle,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.credit_card_rounded,
                    label: 'Number',
                    value: withdrawal.accountNumber,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Requested',
                    value: _fmtDate(withdrawal.requestedAt),
                  ),
                  if (withdrawal.notes != null &&
                      withdrawal.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.note_outlined,
                      label: 'Note',
                      value: withdrawal.notes!,
                    ),
                  ],
                  if (withdrawal.adminNotes != null &&
                      withdrawal.adminNotes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Admin Note',
                      value: withdrawal.adminNotes!,
                      valueColor: AppColors.warning,
                    ),
                  ],
                ],
              ),
            ),
            if (withdrawal.status == 'pending') ...[
              Divider(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onManage,
                    icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                    label: const Text('Manage Request'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: AppTextStyles.caption.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              color: valueColor ?? theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── ACTION SHEET ─────────────────────────────────────────────

class _ActionSheet extends StatelessWidget {
  final CombinedWithdrawal withdrawal;
  final TextEditingController notesCtrl;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ActionSheet({
    required this.withdrawal,
    required this.notesCtrl,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRider = withdrawal.role == WithdrawalRole.rider;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
            24, 0, 24, MediaQuery.of(context).padding.bottom + 24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 14, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: isRider
                        ? const LinearGradient(
                            colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
                          )
                        : AppColors.primaryGradient,
                    borderRadius: AppRadius.medium,
                  ),
                  child: Icon(
                    isRider
                        ? Icons.delivery_dining_rounded
                        : Icons.palette_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Request',
                        style: AppTextStyles.h5.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${withdrawal.userName} • Rs. ${_fmt(withdrawal.amount)}',
                        style: AppTextStyles.caption.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Admin notes (optional, sent to user via email)...',
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Approve & Mark Paid'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.cancel_outlined,
                    color: AppColors.error),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ─── EMPTY STATE ──────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final StatusFilter statusFilter;
  const _EmptyState({required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                statusFilter == StatusFilter.pending
                    ? Icons.hourglass_empty_rounded
                    : Icons.inbox_rounded,
                size: 48,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${statusFilter.label} Requests',
              style: AppTextStyles.h5.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No withdrawal requests found\nfor the selected filters.',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}