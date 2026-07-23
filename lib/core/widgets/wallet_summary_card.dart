import 'package:flutter/material.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/glass_card.dart';

class WalletSummaryCard extends StatelessWidget {
  final double artistEarnings;
  final double riderEarnings;
  final double withdrawals;
  final double pendingWithdrawals;

  const WalletSummaryCard({
    Key? key,
    required this.artistEarnings,
    required this.riderEarnings,
    required this.withdrawals,
    required this.pendingWithdrawals,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalBalance = artistEarnings + riderEarnings - withdrawals;

    return GlassCard(
      glowColor: AppColors.primary,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Balance hero banner ───────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.tealGlow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -30,
                  child: Icon(Icons.blur_circular_rounded,
                      size: 140, color: Colors.white.withValues(alpha: 0.08)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Wallet & Payout Summary',
                            style: AppTextStyles.labelLarge.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                        const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Net Balance', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                    const SizedBox(height: 4),
                    AnimatedMetric(
                      value: totalBalance,
                      formatter: (v) => formatCurrency(v),
                      style: AppTextStyles.h1.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ─── Detail rows ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _walletRow(
                  context,
                  label: 'Total Artist Earnings',
                  value: artistEarnings,
                  icon: Icons.brush_rounded,
                  color: const Color(0xFF7C3AED),
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _walletRow(
                  context,
                  label: 'Total Rider Earnings',
                  value: riderEarnings,
                  icon: Icons.two_wheeler_rounded,
                  color: AppColors.info,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _walletRow(
                  context,
                  label: 'Completed Withdrawals',
                  value: withdrawals,
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _walletRow(
                  context,
                  label: 'Pending Payout Requests',
                  value: pendingWithdrawals,
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.warning,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletRow(
    BuildContext context, {
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
        borderRadius: AppRadius.medium,
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.small,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 10)],
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Text(label, style: AppTextStyles.labelMedium.copyWith(color: textSecondary)),
            ],
          ),
          Text(formatCurrency(value), style: AppTextStyles.labelLarge.copyWith(color: textPrimary)),
        ],
      ),
    );
  }
}