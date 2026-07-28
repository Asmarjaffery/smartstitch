import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/widgets/wallet_widgets.dart';
import 'package:smartstitch/riders/wallet/wallet_controller.dart';
import 'package:smartstitch/riders/wallet/withdraw_screen.dart';
import 'package:smartstitch/riders/wallet/withdrawal_history_screen.dart';
import '../../models/wallet_models.dart';

class RiderWalletScreen extends StatelessWidget {
  const RiderWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<WalletController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── APP BAR ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: WalletColors.teal900,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Obx(
                () => _WalletHeroCard(
                  wallet: ctrl.wallet.value,
                  riderName: ctrl.riderName,
                  riderId: ctrl.riderId,
                ),
              ),
            ),
            title: const Text(
              'My Wallet',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.white),
                tooltip: 'Withdrawal History',
                onPressed: () => Get.to(
                  () => const WithdrawalHistoryScreen(),
                  transition: Transition.rightToLeft,
                ),
              ),
            ],
          ),

          // ─── STATS GRID ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Obx(() => _StatsGrid(wallet: ctrl.wallet.value)),
          ),

          // ─── QUICK ACTIONS ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _QuickActions(ctrl: ctrl),
            ),
          ),

          // ─── RECENT TRANSACTIONS ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: SectionHeader(
                title: 'Recent Transactions',
                action: 'View All',
                onAction: () => Get.to(
                  () => const WithdrawalHistoryScreen(),
                  transition: Transition.rightToLeft,
                ),
              ),
            ),
          ),

          Obx(() {
            if (ctrl.transactions.isEmpty) {
              return const SliverToBoxAdapter(
                child: WalletEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No Transactions Yet',
                  subtitle:
                      'Complete deliveries to start earning and see your transaction history here.',
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _TransactionTile(tx: ctrl.transactions[i]),
                childCount: ctrl.transactions.length > 10
                    ? 10
                    : ctrl.transactions.length,
              ),
            );
          }),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),

      // ─── WITHDRAW BUTTON ──────────────────────────────────────────
      bottomNavigationBar: _WithdrawBottomBar(ctrl: ctrl),
    );
  }
}

// ─── WALLET HERO CARD ─────────────────────────────────────────────────────────

class _WalletHeroCard extends StatelessWidget {
  final RiderWallet? wallet;
  final String riderName;
  final String riderId;

  const _WalletHeroCard({
    this.wallet,
    required this.riderName,
    required this.riderId,
  });

  @override
  Widget build(BuildContext context) {
    final shortId =
        riderId.length >= 8 ? riderId.substring(0, 8).toUpperCase() : '--------';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF044548),
            Color(0xFF065F63),
            Color(0xFF0E8F95),
            Color(0xFF35BFC4),
          ],
          stops: [0.0, 0.3, 0.65, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          const Positioned(
            top: -50,
            right: -50,
            child: _Circle(size: 200, opacity: 0.05),
          ),
          const Positioned(
            top: 40,
            right: 60,
            child: _Circle(size: 100, opacity: 0.06),
          ),
          const Positioned(
            bottom: -30,
            left: -40,
            child: _Circle(size: 160, opacity: 0.07),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rider info row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            riderName.isNotEmpty
                                ? riderName[0].toUpperCase()
                                : 'R',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            riderName.isNotEmpty ? riderName : 'Rider',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'ID: $shortId',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Verified badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_rounded,
                                size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Balance
                  Text(
                    'Available Balance',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  wallet == null
                      ? const ShimmerBox(width: 200, height: 44, radius: 10)
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rs. ',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _fmt(wallet!.availableBalance),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 42,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.5,
                              ),
                            ),
                          ],
                        ),

                  const SizedBox(height: 20),

                  // Pending + Last Updated row
                  Row(
                    children: [
                      Expanded(
                        child: _HeroInfoPill(
                          icon: Icons.access_time_rounded,
                          label: 'Pending',
                          value: wallet == null
                              ? '...'
                              : 'Rs. ${_fmt(wallet!.pendingWithdrawal)}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeroInfoPill(
                          icon: Icons.update_rounded,
                          label: 'Updated',
                          value: wallet == null
                              ? '...'
                              : _timeAgo(wallet!.updatedAt),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final double opacity;
  const _Circle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}

class _HeroInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroInfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── STATS GRID ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final RiderWallet? wallet;
  const _StatsGrid({this.wallet});

  @override
  Widget build(BuildContext context) {
    final w = wallet;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: WalletStatCard(
                  label: "Today's Earnings",
                  amount: w?.todayEarnings ?? 0,
                  icon: Icons.wb_sunny_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  iconBg: const Color(0xFFFFF4D6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WalletStatCard(
                  label: 'This Week',
                  amount: w?.weekEarnings ?? 0,
                  icon: Icons.date_range_rounded,
                  iconColor: const Color(0xFF0EA5E9),
                  iconBg: const Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: WalletStatCard(
                  label: 'This Month',
                  amount: w?.monthEarnings ?? 0,
                  icon: Icons.calendar_month_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  iconBg: const Color(0xFFEDE9FE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WalletStatCard(
                  label: 'Lifetime',
                  amount: w?.lifetimeEarnings ?? 0,
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFF22C55E),
                  iconBg: const Color(0xFFDCFCE7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── QUICK ACTIONS ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final WalletController ctrl;
  const _QuickActions({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Withdraw',
            color: WalletColors.teal700,
            bg: WalletColors.teal100,
            onTap: () => Get.to(
              () => const WithdrawScreen(),
              transition: Transition.upToDown,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.history_rounded,
            label: 'History',
            color: WalletColors.purple,
            bg: WalletColors.purpleBg,
            onTap: () => Get.to(
              () => const WithdrawalHistoryScreen(),
              transition: Transition.rightToLeft,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.refresh_rounded,
            label: 'Refresh',
            color: WalletColors.blue,
            bg: WalletColors.blueBg,
            onTap: () {
              ctrl.setRiderInfo(id: ctrl.riderId, name: ctrl.riderName, email: ctrl.riderEmail);
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.15) : bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TRANSACTION TILE ─────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final WalletTransaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (tx.type) {
      case TransactionType.earning:
        icon = Icons.arrow_downward_rounded;
        iconColor = WalletColors.green;
        iconBg = WalletColors.greenBg;
        break;
      case TransactionType.withdrawal:
        icon = Icons.arrow_upward_rounded;
        iconColor = WalletColors.teal700;
        iconBg = WalletColors.teal100;
        break;
      case TransactionType.bonus:
        icon = Icons.card_giftcard_rounded;
        iconColor = WalletColors.purple;
        iconBg = WalletColors.purpleBg;
        break;
      case TransactionType.refund:
        icon = Icons.replay_rounded;
        iconColor = WalletColors.amber;
        iconBg = WalletColors.amberBg;
        break;
      case TransactionType.compensation:
        // Rider payout for a failed-delivery exception claim — treated as
        // a credit, distinct color so it reads apart from regular earnings.
        icon = Icons.support_agent_rounded;
        iconColor = WalletColors.blue;
        iconBg = WalletColors.blueBg;
        break;
    }

    final isCredit = tx.type == TransactionType.earning ||
        tx.type == TransactionType.bonus ||
        tx.type == TransactionType.refund ||
        tx.type == TransactionType.compensation;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withValues(alpha: 0.15) : iconBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (tx.orderId != null) ...[
                      Text(
                        '#${tx.orderId!.substring(0, 6).toUpperCase()}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                    Text(
                      _fmtDate(tx.createdAt),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'} Rs. ${_fmt(tx.amount)}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isCredit
                      ? WalletColors.green
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 5),
              StatusBadge.fromTransactionStatus(tx.status),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} • $h:$m $ampm';
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ─── WITHDRAW BOTTOM BAR ──────────────────────────────────────────────────────

class _WithdrawBottomBar extends StatelessWidget {
  final WalletController ctrl;
  const _WithdrawBottomBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Obx(() => PremiumButton(
            label: 'Withdraw Earnings',
            icon: Icons.account_balance_wallet_rounded,
            isLoading: ctrl.isSubmittingWithdrawal.value,
            onTap: () => Get.to(
              () => const WithdrawScreen(),
              transition: Transition.upToDown,
            ),
          )),
    );
  }
}