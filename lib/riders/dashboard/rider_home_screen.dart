import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/riders/dashboard/rider_controller.dart';
import 'package:smartstitch/riders/wallet/wallet_controller.dart';
import '../../controllers/chat_controller.dart';

class RiderHomeScreen extends StatelessWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RiderController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardHeader(controller),
              const SizedBox(height: 22),
              _HeroDeliveryCard(controller),
              const SizedBox(height: 24),
              const _SectionTitle(title: "Overview"),
              const SizedBox(height: 12),
              _StatsGrid(controller),
              const SizedBox(height: 26),
              const _SectionTitle(title: "Recent Deliveries", actionLabel: "View All"),
              const SizedBox(height: 12),
              _RecentDeliveries(controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final RiderController controller;
  const _DashboardHeader(this.controller);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(Icons.delivery_dining_rounded, color: colorScheme.primary, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome Back",
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 2),
                  Text(
                    controller.riderName.isEmpty ? "Rider" : controller.riderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              )),
        ),
      ],
    );
  }
}

class _HeroDeliveryCard extends StatelessWidget {
  final RiderController controller;
  const _HeroDeliveryCard(this.controller);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
        boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Deliveries",
                    style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Obx(() => Text("${controller.totalDeliveries.value} Active Orders",
                    style: const TextStyle(color: Colors.white70, fontSize: 14))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("View Deliveries", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Icon(Icons.local_shipping_rounded, size: 64, color: Colors.white.withValues(alpha: 0.9)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  const _SectionTitle({required this.title, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        if (actionLabel != null)
          Text(actionLabel!, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary)),
      ],
    );
  }
}

// ─── Stats Grid — live data from WalletController ────────────────────────────

class _StatsGrid extends StatelessWidget {
  final RiderController controller;
  const _StatsGrid(this.controller);

  @override
  Widget build(BuildContext context) {
    final walletCtrl = Get.isRegistered<WalletController>() ? Get.find<WalletController>() : null;

    return Obx(() {
      final walletBalance   = walletCtrl?.wallet.value?.availableBalance  ?? 0.0;
      final lifetimeEarnings = walletCtrl?.wallet.value?.lifetimeEarnings ?? 0.0;
      final todayEarnings   = walletCtrl?.wallet.value?.todayEarnings     ?? 0.0;
      final pendingWithdraw = walletCtrl?.wallet.value?.pendingWithdrawal ?? 0.0;

      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    title: "Total Earnings",
                    value: "Rs ${_fmt(lifetimeEarnings)}",
                    icon: Icons.account_balance_wallet_rounded,
                    badge: todayEarnings > 0 ? "Today +${_fmt(todayEarnings)}" : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    title: "Wallet Balance",
                    value: "Rs ${_fmt(walletBalance)}",
                    icon: Icons.wallet_rounded,
                    badge: pendingWithdraw > 0 ? "Pending ${_fmt(pendingWithdraw)}" : null,
                    badgeColor: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    title: "Orders",
                    value: controller.totalDeliveries.value.toString(),
                    icon: Icons.local_shipping_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    title: "Rating",
                    value: controller.rating.toStringAsFixed(1),
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  String _fmt(double v) =>
      v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String? badge;
  final Color? badgeColor;
  final Color? iconColor;

  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    this.badge,
    this.badgeColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ic = iconColor ?? colorScheme.primary;
    final bc = badgeColor ?? colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: ic.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: ic, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
            if (badge != null) ...[
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: bc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(badge!,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: bc, fontFamily: 'Poppins')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Recent Deliveries ────────────────────────────────────────────────────────

class _RecentDeliveries extends StatelessWidget {
  final RiderController controller;
  const _RecentDeliveries(this.controller);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      if (controller.activeDeliveries.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded, size: 40, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 10),
                  Text("No active deliveries",
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
            ),
          ),
        );
      }

      return Column(
        children: controller.activeDeliveries.take(3).map((d) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AddressRow(icon: Icons.radio_button_checked_rounded, iconColor: colorScheme.primary, address: d.pickupAddress.fullAddress),
                  Padding(padding: const EdgeInsets.only(left: 9), child: Container(height: 16, width: 1.5, color: colorScheme.outline)),
                  _AddressRow(icon: Icons.location_on_rounded, iconColor: colorScheme.error, address: d.dropAddress.fullAddress),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String address;
  const _AddressRow({required this.icon, required this.iconColor, required this.address});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(child: Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}