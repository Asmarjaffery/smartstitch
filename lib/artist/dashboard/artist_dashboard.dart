import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/routes/routes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../core/theme/app.theme.dart';
import 'dashboard_controller.dart';

class ArtistDashboard extends StatefulWidget {
  const ArtistDashboard({super.key});

  @override
  State<ArtistDashboard> createState() => _ArtistDashboardState();
}

class _ArtistDashboardState extends State<ArtistDashboard> {
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }

  String _today() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day} ${now.year}';
  }

  String _timeNow() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatController = Get.find<ChatController>();
    final ctrl = Get.put(ArtistDashboardController());

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(gradient: AppColors.scaffoldGradient(isDark)),
        child: CustomScrollView(
          slivers: [
            // ── PREMIUM GRADIENT GREETING HEADER (admin-style) ─────
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _GreetingHeader(
                    greeting: _greeting(),
                    today: _today(),
                    time: _timeNow(),
                    userObs: auth.currentUser,
                    isAvailableObs: ctrl.isAvailable,
                    onToggle: ctrl.toggleAvailability,
                    ctrl: ctrl,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── STATS ROW ───────────────────────────────
                    Obx(() => _StatsGrid(
                          items: [
                            _StatItem(
                              title: 'Total Orders',
                              value: ctrl.totalOrders.value.toString(),
                              subtitle: 'All time',
                              icon: Icons.receipt_long_rounded,
                              color: AppColors.info,
                            ),
                            _StatItem(
                              title: 'Rating',
                              value: ctrl.rating.value.toStringAsFixed(1),
                              subtitle: 'Feedback',
                              icon: Icons.star_rounded,
                              color: AppColors.warning,
                            ),
                          ],
                          isDark: isDark,
                        )),

                    const SizedBox(height: 20),

                    // ── MESSAGES CARD ───────────────────────────
                    Obx(() {
                      final unread = chatController.totalUnread.value;
                      return GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.chatList),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: unread > 0 ? AppColors.tealGlow : null,
                            color: unread > 0 ? null : surface,
                            borderRadius: AppRadius.large,
                            border: Border.all(
                              color: unread > 0 ? Colors.transparent : border,
                            ),
                            boxShadow: unread > 0
                                ? AppShadows.glow(AppColors.primary, alpha: 0.25, blur: 18)
                                : AppShadows.card(isDark),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: unread > 0
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : (isDark ? AppColors.darkSurface2 : AppColors.primarySoft),
                                  borderRadius: AppRadius.medium,
                                ),
                                child: Icon(Icons.chat_bubble_rounded,
                                    color: unread > 0 ? Colors.white : AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Messages',
                                        style: AppTextStyles.labelLarge.copyWith(
                                            color: unread > 0 ? Colors.white : textPrimary)),
                                    Text(
                                        unread > 0
                                            ? '$unread unread messages'
                                            : 'Chat with customers',
                                        style: AppTextStyles.bodySmall.copyWith(
                                            color: unread > 0
                                                ? Colors.white.withValues(alpha: 0.85)
                                                : textSecondary)),
                                  ],
                                ),
                              ),
                              if (unread > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: const BoxDecoration(
                                      color: Colors.white, borderRadius: AppRadius.full),
                                  child: Text('$unread',
                                      style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.primary, fontWeight: FontWeight.bold)),
                                )
                              else
                                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: textSecondary),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // ── AVAILABILITY TOGGLE ─────────────────────
                    Obx(() => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: AppRadius.large,
                            border: Border.all(color: border),
                            boxShadow: AppShadows.card(isDark),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (ctrl.isAvailable.value ? AppColors.success : textSecondary)
                                      .withValues(alpha: 0.12),
                                  borderRadius: AppRadius.medium,
                                ),
                                child: Icon(Icons.circle,
                                    color: ctrl.isAvailable.value ? AppColors.success : textSecondary,
                                    size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Available for Orders',
                                        style: AppTextStyles.labelLarge.copyWith(color: textPrimary)),
                                    Text('Customers can book you',
                                        style: AppTextStyles.bodySmall.copyWith(color: textSecondary)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: ctrl.isAvailable.value,
                                onChanged: (_) => ctrl.toggleAvailability(),
                                activeThumbColor: AppColors.success,
                              ),
                            ],
                          ),
                        )),

                    const SizedBox(height: 24),

                    // ── PENDING ORDERS ──────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pending Orders',
                            style: AppTextStyles.h4.copyWith(color: textPrimary)),
                        TextButton(
                          onPressed: () => Get.toNamed(AppRoutes.artistOrders),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Obx(() {
                      if (ctrl.isLoading.value) {
                        return const Center(
                            child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      if (ctrl.pendingOrders.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.inbox_rounded, size: 36, color: textSecondary),
                                const SizedBox(height: 8),
                                Text('No pending orders',
                                    style: AppTextStyles.bodyMedium.copyWith(color: textSecondary)),
                              ],
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: ctrl.pendingOrders
                            .take(3)
                            .map((order) => _PendingOrderCard(order: order, isDark: isDark))
                            .toList(),
                      );
                    }),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GREETING HEADER — admin-style solid teal gradient card, with the
// artist's profile photo, date + live time row, and online-status toggle.
// ═══════════════════════════════════════════════════════════════════════
class _GreetingHeader extends StatelessWidget {
  final String greeting;
  final String today;
  final String time;
  final Rx userObs;
  final RxBool isAvailableObs;
  final VoidCallback onToggle;
  final ArtistDashboardController ctrl;

  const _GreetingHeader({
    required this.greeting,
    required this.today,
    required this.time,
    required this.userObs,
    required this.isAvailableObs,
    required this.onToggle,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.glow(AppColors.primary, alpha: 0.3, blur: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date + Time + Online status chips ──────────────────
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HeaderChip(icon: Icons.calendar_today_rounded, label: today),
              _HeaderChip(icon: Icons.access_time_rounded, label: time),
              Obx(() => _OnlineStatusChip(
                    isOnline: isAvailableObs.value,
                    onTap: onToggle,
                  )),
            ],
          ),
          const SizedBox(height: 18),

          // ── Avatar + Greeting ───────────────────────────────────
          Obx(() {
            final user = userObs.value;
            final imageUrl = user?.profileImageUrl ?? '';
            final name = user?.name ?? 'Artist';
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'A',
                            style: AppTextStyles.h4.copyWith(color: Colors.white, fontWeight: FontWeight.bold))
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$greeting, $name 👋',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Here's what's happening with your orders today.",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sectionSubtitle.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 18),

          // ── Earnings summary box (admin "Total Revenue" style) ──
          Obx(() => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: AppRadius.large,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Earnings',
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('Rs. ${ctrl.totalEarnings.value}',
                              style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          const Text('From delivered orders',
                              style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadius.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _OnlineStatusChip extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onTap;

  const _OnlineStatusChip({
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.full,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: AppRadius.full,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : Colors.white70,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? "You're Online" : 'Offline',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PENDING ORDER CARD
// ═══════════════════════════════════════════════════════════════════════
class _PendingOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isDark;
  const _PendingOrderCard({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final customerName = order['customerName'] as String? ?? 'Customer';
    final item = order['designTitle'] as String? ?? 'Order';
    // Artist ka 85% hissa dikhayein — wallet earnings jaisa hi calculation
    final price = order['artistEarning']?.toString() ??
        order['totalAmount']?.toString() ??
        '0';

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.artistOrders),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadius.large,
          border: Border.all(color: border),
          boxShadow: AppShadows.card(isDark),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.primarySoft,
              child: Text(
                customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                style: AppTextStyles.h4.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customerName, style: AppTextStyles.labelLarge.copyWith(color: textPrimary)),
                  Text(item, style: AppTextStyles.bodySmall.copyWith(color: textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Rs. $price',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: AppRadius.full,
                  ),
                  child: Text('Pending',
                      style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
                ),
              ],
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.chatList),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface2 : AppColors.primarySoft,
                  borderRadius: AppRadius.small,
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.primary, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STATS GRID — fully controlled, overflow-safe, responsive
// ═══════════════════════════════════════════════════════════════════════
class _StatItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  _StatItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> items;
  final bool isDark;

  const _StatsGrid({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Decide columns based on available width — never squeeze cards
        // below a width that would force text truncation.
        int columns;
        if (width < 340) {
          columns = 1;
        } else if (width < 560) {
          columns = 2;
        } else {
          columns = 3;
        }

        final spacing = 12.0;
        final cardWidth = columns == 1
            ? width
            : (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map((item) => SizedBox(
                    width: cardWidth,
                    child: _StatTile(item: item, isDark: isDark),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final _StatItem item;
  final bool isDark;

  const _StatTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: border),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(item.icon, size: 18, color: item.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(color: textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              item.value,
              maxLines: 1,
              style: AppTextStyles.h3.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }
}