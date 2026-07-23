import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/admin/payment/admin_payment_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/dashboard_widgets.dart';
import 'package:smartstitch/core/widgets/wallet_widgets.dart' hide SectionHeader;

class AdminPaymentScreen extends StatelessWidget {
  const AdminPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminPaymentController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Payment Dashboard'),
        centerTitle: true,
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ───────── STATS GRID ─────────
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                children: [
                  _StatCard(
                    title: 'Total Revenue',
                    value: controller.totalRevenue.value,
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.primary,
                  ),
                  _StatCard(
                    title: 'Commission',
                    value: controller.totalCommission.value,
                    icon: Icons.percent_rounded,
                    color: AppColors.success,
                  ),
                  _StatCard(
                    title: 'Paid Out',
                    value: controller.totalPaidOut.value,
                    icon: Icons.send_rounded,
                    color: AppColors.warning,
                  ),
                  _StatCard(
                    title: 'Net Revenue',
                    value: controller.netRevenue.value,
                    icon: Icons.trending_up_rounded,
                    color: AppColors.info,
                  ),
                ],
              ),

              const SectionHeader(title: 'Top Earners'),
              const SizedBox(height: 12),
              const _TopEarnersCard(),

              const SectionHeader(title: 'Pending Withdrawals'),
              const SizedBox(height: 12),
              _WithdrawalList(controller: controller),
            ],
          ),
        );
      }),
    );
  }
}

// ─── STAT CARD ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Rs ${_fmt(value)}',
              style: AppTextStyles.h4.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ─── TOP EARNERS ──────────────────────────────────────────────────────────────

class _TopEarnersCard extends StatelessWidget {
  const _TopEarnersCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // TODO: connect to real Firestore ranking when ready.
    const earners = [
      _Earner(name: 'Artist A', role: 'Artist', amount: 12000, rank: 0),
      _Earner(name: 'Rider B', role: 'Rider', amount: 9000, rank: 1),
      _Earner(name: 'Artist C', role: 'Artist', amount: 7000, rank: 2),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(earners.length, (i) {
          final e = earners[i];
          return Column(
            children: [
              _EarnerTile(earner: e),
              if (i != earners.length - 1)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: theme.dividerColor,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _Earner {
  final String name;
  final String role;
  final double amount;
  final int rank;

  const _Earner({
    required this.name,
    required this.role,
    required this.amount,
    required this.rank,
  });
}

class _EarnerTile extends StatelessWidget {
  final _Earner earner;
  const _EarnerTile({required this.earner});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArtist = earner.role == 'Artist';
    final roleColor = isArtist ? AppColors.primary : AppColors.info;
    final medalColors = _medalColors(earner.rank);

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: roleColor.withValues(alpha: 0.12),
              child: Icon(
                isArtist ? Icons.palette_rounded : Icons.electric_moped_rounded,
                size: 18,
                color: roleColor,
              ),
            ),
            if (earner.rank < 3)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: medalColors),
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.cardColor, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          earner.name,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          earner.role,
          style: AppTextStyles.bodySmall.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        trailing: Text(
          'Rs ${earner.amount.toStringAsFixed(0)}',
          style: AppTextStyles.labelLarge.copyWith(
            color: roleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  List<Color> _medalColors(int rank) {
    switch (rank) {
      case 0:
        return const [Color(0xFFFFD700), Color(0xFFE8A317)];
      case 1:
        return const [Color(0xFFD4D4D4), Color(0xFF9E9E9E)];
      case 2:
        return const [Color(0xFFD08B4C), Color(0xFFA0522D)];
      default:
        return const [Colors.transparent, Colors.transparent];
    }
  }
}

// ─── PENDING WITHDRAWALS ──────────────────────────────────────────────────────

class _WithdrawalList extends StatelessWidget {
  final AdminPaymentController controller;

  const _WithdrawalList({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.pendingWithdrawals.isEmpty) {
      return const WalletEmptyState(
        icon: Icons.hourglass_empty_rounded,
        title: 'No Pending Withdrawals',
        subtitle: 'All withdrawal requests have been processed.',
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: controller.pendingWithdrawals.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: AppRadius.medium,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: isDark ? 0.18 : 0.1),
                      borderRadius: AppRadius.small,
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 18,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (data['userName'] ?? '').toString(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rs ${data['amount']}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => controller.approveWithdrawal(doc.id, data),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: AppTextStyles.labelMedium,
                    ),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}