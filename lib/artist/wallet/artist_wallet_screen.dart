// ============================================================
// SmartStitch — Artist Wallet Dashboard
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/artist/wallet/artist_wallet_controller.dart';
import 'package:smartstitch/artist/wallet/artist_withdraw_screen.dart';
import 'package:smartstitch/artist/wallet/artist_withdrawal_history_screen.dart';
import 'package:smartstitch/core/widgets/wallet_widgets.dart';
import '../../models/artist_wallet_models.dart';

class ArtistWalletScreen extends StatelessWidget {
  const ArtistWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ArtistWalletController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Artist Wallet',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Withdrawal History',
            onPressed: () => Get.to(() => const ArtistWithdrawalHistoryScreen()),
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.wallet.value == null && ctrl.isLoadingWallet.value) {
          return const WalletSkeletonLoader();
        }

        final wallet = ctrl.wallet.value ?? ArtistWallet.empty(ctrl.artistId);

        return RefreshIndicator(
          color: WalletColors.teal700,
          onRefresh: () async {
            // Streams auto-update; this just gives the user a tactile
            // "refreshed" moment without needing a manual fetch.
            await Future.delayed(const Duration(milliseconds: 400));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroBalanceCard(
                  balance: wallet.availableBalance,
                  pending: wallet.pendingWithdrawal,
                ),
                const SizedBox(height: 22),
                PremiumButton(
                  label: 'Withdraw Earnings',
                  icon: Icons.account_balance_wallet_rounded,
                  onTap: () => Get.to(() => const ArtistWithdrawScreen()),
                ),
                const SizedBox(height: 28),
                const SectionHeader(title: 'Earnings Overview'),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    WalletStatCard(
                      label: "Today's Earnings",
                      amount: wallet.todayEarnings,
                      icon: Icons.today_rounded,
                      iconColor: WalletColors.teal700,
                      iconBg: WalletColors.teal100,
                    ),
                    WalletStatCard(
                      label: 'Weekly Earnings',
                      amount: wallet.weekEarnings,
                      icon: Icons.calendar_view_week_rounded,
                      iconColor: WalletColors.blue,
                      iconBg: WalletColors.blueBg,
                    ),
                    WalletStatCard(
                      label: 'Monthly Earnings',
                      amount: wallet.monthEarnings,
                      icon: Icons.calendar_month_rounded,
                      iconColor: WalletColors.purple,
                      iconBg: WalletColors.purpleBg,
                    ),
                    WalletStatCard(
                      label: 'Lifetime Earnings',
                      amount: wallet.lifetimeEarnings,
                      icon: Icons.workspace_premium_rounded,
                      iconColor: WalletColors.amber,
                      iconBg: WalletColors.amberBg,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SectionHeader(
                  title: 'Recent Transactions',
                  action: 'View History',
                  onAction: () =>
                      Get.to(() => const ArtistWithdrawalHistoryScreen()),
                ),
                const SizedBox(height: 14),
                Obx(() {
                  final txns = ctrl.transactions;
                  if (ctrl.isLoadingTransactions.value && txns.isEmpty) {
                    return Column(
                      children: List.generate(
                        3,
                        (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: ShimmerBox(width: double.infinity, height: 70),
                        ),
                      ),
                    );
                  }
 if (txns.isEmpty) {
                    return const WalletEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Transactions Yet',
                      subtitle:
                          'Your earnings and withdrawals will show up here once you start completing orders.',
                    );
                  }
                  return Column(
                    children: txns
                        .take(8)
                        .map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _TransactionCard(
                                tx: t,
                                formatDate: ctrl.formatDateTime,
                              ),
                            ))
                        .toList(),
                  );
                }),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── HERO BALANCE CARD ────────────────────────────────────────

class _HeroBalanceCard extends StatelessWidget {
  final double balance;
  final double pending;
  const _HeroBalanceCard({required this.balance, required this.pending});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [WalletColors.teal900, WalletColors.teal700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: WalletColors.teal700.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Available Balance',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.palette_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _fmt(balance),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded,
                    color: Colors.white, size: 15),
                const SizedBox(width: 8),
                Text(
                  'Pending Withdrawals',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const Spacer(),
                Text(
                  _fmt(pending),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      'Rs. ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

// ─── TRANSACTION CARD ─────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final ArtistWalletTransaction tx;
  final String Function(DateTime) formatDate;
  const _TransactionCard({required this.tx, required this.formatDate});

  IconData get _icon {
    switch (tx.type) {
      case TransactionType.earning:
        return Icons.trending_up_rounded;
      case TransactionType.withdrawal:
        return Icons.north_east_rounded;
      case TransactionType.bonus:
        return Icons.card_giftcard_rounded;
      case TransactionType.refund:
        return Icons.replay_rounded;
    }
  }

  Color get _color {
    switch (tx.type) {
      case TransactionType.earning:
        return WalletColors.green;
      case TransactionType.withdrawal:
        return WalletColors.red;
      case TransactionType.bonus:
        return WalletColors.purple;
      case TransactionType.refund:
        return WalletColors.blue;
    }
  }

  bool get _isCredit =>
      tx.type == TransactionType.earning ||
      tx.type == TransactionType.bonus ||
      tx.type == TransactionType.refund;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark
                  ? _color.withValues(alpha: 0.18)
                  : _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  formatDate(tx.createdAt),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_isCredit ? '+' : '-'} Rs. ${tx.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _isCredit ? WalletColors.green : WalletColors.red,
                ),
              ),
              const SizedBox(height: 4),
              StatusBadge.fromTransactionStatus(tx.status),
            ],
          ),
        ],
      ),
    );
  }
}