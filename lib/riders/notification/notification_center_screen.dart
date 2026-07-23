import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/models/notification_model.dart';
import 'package:smartstitch/riders/notification/notification_center_controller.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationCenterController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _buildAppBar(context, controller, isDark),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.notifications.isEmpty) {
          return _EmptyState(isDark: isDark);
        }

        return _NotificationList(controller: controller, isDark: isDark);
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    NotificationCenterController controller,
    bool isDark,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                // Back button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Get.back(),
                    child: Ink(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Notifications',
                  style: AppTextStyles.h5.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                // Unread badge
                Obx(() {
                  final count = controller.unreadCount.value;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$count unread',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: Colors.white),
                    ),
                  );
                }),
                // Mark all read
                Obx(() {
                  if (controller.unreadCount.value == 0) {
                    return const SizedBox.shrink();
                  }
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: controller.markAllAsRead,
                      child: Ink(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.done_all_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification List
// ---------------------------------------------------------------------------

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.controller,
    required this.isDark,
  });

  final NotificationCenterController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter tabs
        _FilterTabs(controller: controller, isDark: isDark),

        // List
        Expanded(
          child: Obx(() {
            final list = controller.notifications;
            if (list.isEmpty) return _EmptyState(isDark: isDark);

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = list[index];
                return _NotificationCard(
                  notification: n,
                  isDark: isDark,
                  onTap: () => controller.markAsRead(n.id),
                  onDelete: () => controller.deleteNotification(n.id),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Tabs
// ---------------------------------------------------------------------------

class _FilterTabs extends StatefulWidget {
  const _FilterTabs({required this.controller, required this.isDark});

  final NotificationCenterController controller;
  final bool isDark;

  @override
  State<_FilterTabs> createState() => _FilterTabsState();
}

class _FilterTabsState extends State<_FilterTabs> {
  int _selected = 0;

  final _tabs = const [
    ('All', null),
    ('Orders', NotificationType.order),
    ('Wallet', NotificationType.wallet),
    ('Withdrawal', NotificationType.withdrawal),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final isActive = _selected == i;
            return GestureDetector(
              onTap: () {
                setState(() => _selected = i);
                // Filter logic — swap observable list
                final type = _tabs[i].$2;
                if (type == null) {
                  widget.controller.clearFilter();
                } else {
                  widget.controller.filterByType(type);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : widget.isDark
                          ? AppColors.darkSurface2
                          : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _tabs[i].$1,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isActive
                        ? Colors.white
                        : widget.isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.primaryDark,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification Card
// ---------------------------------------------------------------------------

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationModel notification;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? isDark
                  ? AppColors.primaryDark.withValues(alpha: 0.3)
                  : AppColors.primarySoft
              : isDark
                  ? AppColors.darkSurface
                  : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withValues(alpha: 0.4)
                : isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBg(notification.type, isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _icon(notification.type),
                color: _iconColor(notification.type),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _timeAgo(notification.createdAt),
                        style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.lightTextHint,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.lightTextHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.local_shipping_rounded;
      case NotificationType.wallet:
        return Icons.account_balance_wallet_rounded;
      case NotificationType.withdrawal:
        return Icons.payment_rounded;
      case NotificationType.account:
        return Icons.person_rounded;
      case NotificationType.system:
        return Icons.settings_rounded;
      case NotificationType.promotion:
        return Icons.local_offer_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _iconColor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return AppColors.primary;
      case NotificationType.wallet:
        return AppColors.success;
      case NotificationType.withdrawal:
        return AppColors.warning;
      case NotificationType.account:
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  Color _iconBg(NotificationType type, bool isDark) {
    switch (type) {
      case NotificationType.order:
        return isDark ? AppColors.primaryDark : AppColors.primarySoft;
      case NotificationType.wallet:
        return isDark ? AppColors.successSoftDark : AppColors.successSoft;
      case NotificationType.withdrawal:
        return isDark ? AppColors.warningSoftDark : AppColors.warningSoft;
      case NotificationType.account:
        return isDark ? AppColors.infoSoftDark : AppColors.infoSoft;
      default:
        return isDark ? AppColors.darkSurface2 : AppColors.primarySoft;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: AppTextStyles.h5.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Order updates and alerts\nwill appear here',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}