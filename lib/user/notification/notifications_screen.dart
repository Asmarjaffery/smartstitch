import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/models/notification_model.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/user/notification/notification_user_controller.dart';


class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Orders', 'Offers', 'Wishlist', 'System'];


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<NotificationUserController>();
      debugPrint('🔔 Notifications Screen Opened - Total: ${controller.notifications.length}');
    });
  }


  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationUserController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.small,
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Icon(Icons.arrow_back_rounded, size: 20, color: theme.colorScheme.onSurface),
          ),
        ),
        title: Text('Notifications', style: AppTextStyles.h4.copyWith(color: theme.colorScheme.onSurface)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          GestureDetector(
            onTap: () => controller.markAllAsRead(),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppRadius.small,
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Icon(Icons.done_all_rounded, size: 20, color: theme.colorScheme.onSurface),
            ),
          ),
          GestureDetector(
            onTap: () => _showDeleteAllDialog(context, controller),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppRadius.small,
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Icon(Icons.delete_outline_rounded, size: 20, color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = _selectedFilter == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
                      borderRadius: AppRadius.full,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                      ),
                    ),
                    child: Text(
                      _filters[index],
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Obx(() {
              final filtered = _getFiltered(controller.notifications);

              if (filtered.isEmpty) {
                return _EmptyView(filterName: _filters[_selectedFilter]);
              }

              final grouped = _groupByDate(filtered);

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: grouped.length,
                itemBuilder: (context, index) {
                  final group = grouped[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        child: Text(
                          group['label'] as String,
                          style: AppTextStyles.h4.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: AppRadius.medium,
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: Column(
                          children: (group['items'] as List<NotificationModel>)
                              .asMap()
                              .entries
                              .map((entry) {
                            final i = entry.key;
                            final notif = entry.value;
                            final isLast = i == (group['items'] as List).length - 1;
                            return Column(
                              children: [
                                Dismissible(
                                  key: Key(notif.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error,
                                      borderRadius: isLast
                                          ? const BorderRadius.only(
                                              bottomLeft: Radius.circular(12),
                                              bottomRight: Radius.circular(12),
                                            )
                                          : BorderRadius.zero,
                                    ),
                                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                                  ),
                                  onDismissed: (_) => controller.deleteNotification(notif.id),
                                  child: _NotificationTile(
                                    notification: notif,
                                    controller: controller,
                                  ),
                                ),
                                if (!isLast)
                                  Divider(height: 1, color: theme.colorScheme.outline, indent: 72, endIndent: 16),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  List<NotificationModel> _getFiltered(List<NotificationModel> all) {
    switch (_selectedFilter) {
      case 1:
        return all.where((n) => n.type == NotificationType.orderUpdate).toList();
      case 2:
        return all.where((n) => n.type == NotificationType.promotional).toList();
      case 3:
        return all.where((n) => n.type == NotificationType.event).toList();
      case 4:
        return all.where((n) => n.type == NotificationType.general).toList();
      default:
        return all;
    }
  }

  List<Map<String, dynamic>> _groupByDate(List<NotificationModel> notifs) {
    final now = DateTime.now();
    final today = <NotificationModel>[];
    final yesterday = <NotificationModel>[];
    final earlier = <NotificationModel>[];

    for (final n in notifs) {
      final createdAt = n.createdAt ?? DateTime.now();
      final diff = now.difference(createdAt).inDays;

      if (diff == 0) {
        today.add(n);
      } else if (diff == 1) {
        yesterday.add(n);
      } else {
        earlier.add(n);
      }
    }

    final result = <Map<String, dynamic>>[];
    if (today.isNotEmpty) result.add({'label': 'Today', 'items': today});
    if (yesterday.isNotEmpty) result.add({'label': 'Yesterday', 'items': yesterday});
    if (earlier.isNotEmpty) result.add({'label': 'Earlier', 'items': earlier});

    return result;
  }

  void _showDeleteAllDialog(BuildContext context, NotificationUserController controller) {
    final theme = Theme.of(context);
    Get.dialog(
      AlertDialog(
        title: const Text('Clear All', style: AppTextStyles.h4),
        content: const Text(
          'Are you sure you want to delete all notifications?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel',
                style: AppTextStyles.labelMedium.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              for (final n in controller.notifications) {
                controller.deleteNotification(n.id);
              }
              Get.back();
            },
            child: Text('Delete All',
                style: AppTextStyles.labelMedium.copyWith(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Notification Tile ────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final NotificationUserController controller;

  const _NotificationTile({
    required this.notification,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: () {
        if (isUnread) {
          controller.markAsRead(notification.id);
        }
      },
      borderRadius: AppRadius.medium,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _iconBgColor(notification.type, theme),
                borderRadius: AppRadius.medium,
              ),
              child: Icon(
                _icon(notification.type),
                color: _iconColor(notification.type, theme),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(notification.createdAt),
                            style: AppTextStyles.caption.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          if (isUnread) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime).inDays;
    if (diff == 0) {
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:$minute $period';
    } else if (diff == 1) {
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return 'Yesterday, $hour12:$minute $period';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    }
  }

  IconData _icon(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return Icons.shopping_bag_outlined;
      case NotificationType.promotional:
        return Icons.card_giftcard_outlined;
      case NotificationType.event:
        return Icons.favorite_outline_rounded;
      case NotificationType.newMessage:
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconBgColor(NotificationType type, ThemeData theme) {
    switch (type) {
      case NotificationType.orderUpdate:
        return theme.colorScheme.primaryContainer;
      case NotificationType.promotional:
        return theme.colorScheme.primaryContainer.withValues(alpha: 0.5);
      case NotificationType.event:
        return theme.colorScheme.primaryContainer.withValues(alpha: 0.4);
      case NotificationType.newMessage:
        return theme.colorScheme.primaryContainer.withValues(alpha: 0.6);
      default:
        return theme.colorScheme.primaryContainer;
    }
  }

  Color _iconColor(NotificationType type, ThemeData theme) {
    switch (type) {
      case NotificationType.orderUpdate:
        return theme.colorScheme.primary;
      case NotificationType.promotional:
        return AppColors.success;
      case NotificationType.event:
        return AppColors.error;
      case NotificationType.newMessage:
        return AppColors.warning;
      default:
        return theme.colorScheme.primary;
    }
  }
}

// ─── Empty View ─────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String filterName;

  const _EmptyView({this.filterName = 'Notifications'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded, size: 40, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No $filterName notifications yet',
            style: AppTextStyles.h4.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            'Order updates and alerts will appear here',
            style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}