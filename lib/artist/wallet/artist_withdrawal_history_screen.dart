import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/artist/wallet/artist_wallet_controller.dart';
import 'package:smartstitch/core/widgets/wallet_widgets.dart';
import '../../models/artist_wallet_models.dart';

class ArtistWithdrawalHistoryScreen extends StatefulWidget {
  const ArtistWithdrawalHistoryScreen({super.key});

  @override
  State<ArtistWithdrawalHistoryScreen> createState() => _ArtistWithdrawalHistoryScreenState();
}

class _ArtistWithdrawalHistoryScreenState extends State<ArtistWithdrawalHistoryScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ArtistWalletController>();
    final theme = Theme.of(context);

    final filters = [
      ('all', 'All'),
      ('pending', 'Pending'),
      ('approved', 'Approved'),
      ('paid', 'Paid'),
      ('rejected', 'Rejected'),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Withdrawal History',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search by ID or amount...',
                hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                        child: Icon(Icons.close_rounded, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                      )
                    : null,
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.15))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.15))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: WalletColors.teal700, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              ),
            ),
          ),

          // ── Filter Chips ─────────────────────────────────────────
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: filters.map((f) => _FilterChip(
                label: f.$2,
                selected: _filter == f.$1,
                onTap: () => setState(() => _filter = f.$1),
              )).toList(),
            ),
          ),

          // ── List ──────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              var list = ctrl.withdrawalHistory.where((r) {
                final matchFilter = _filter == 'all' || r.status.name == _filter;
                final matchSearch = _searchQuery.isEmpty ||
                    r.id.toLowerCase().contains(_searchQuery) ||
                    r.amount.toString().contains(_searchQuery) ||
                    r.paymentMethod.label.toLowerCase().contains(_searchQuery);
                return matchFilter && matchSearch;
              }).toList();

if (list.isEmpty) {
                return WalletEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No Results',
                  subtitle: _searchQuery.isNotEmpty
                      ? 'No withdrawals match your search.'
                      : 'No withdrawals in this category yet.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _WithdrawalCard(request: list[i]),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── FILTER CHIP ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? WalletColors.teal700 : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? WalletColors.teal700 : theme.colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: selected
              ? [BoxShadow(color: WalletColors.teal700.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ─── WITHDRAWAL CARD ──────────────────────────────────────────────────────────

class _WithdrawalCard extends StatelessWidget {
  final ArtistWithdrawalRequest request;
  const _WithdrawalCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortId = request.id.substring(0, 8).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: WalletColors.teal100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: WalletColors.teal700, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#$shortId',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                    Text(_fmtDate(request.requestedAt),
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.45))),
                  ],
                ),
              ),
              StatusBadge.fromWithdrawalStatus(request.status),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          const SizedBox(height: 14),

          // Details grid
          Row(
            children: [
              Expanded(child: _DetailItem(label: 'Amount', value: 'Rs. ${_fmt(request.amount)}', valueColor: WalletColors.teal700)),
              Expanded(child: _DetailItem(label: 'Method', value: request.paymentMethod.label)),
            ],
          ),
          const SizedBox(height: 10),

          // Admin notes
          if (request.adminNotes != null && request.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: request.status == WithdrawalStatus.rejected
                    ? WalletColors.redBg
                    : WalletColors.teal100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14,
                      color: request.status == WithdrawalStatus.rejected ? WalletColors.red : WalletColors.teal700),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      request.adminNotes!,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: request.status == WithdrawalStatus.rejected ? WalletColors.red : WalletColors.teal700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _fmtDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.45))),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? theme.colorScheme.onSurface), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}