import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app.theme.dart';
import 'admin_notification_controller.dart';

class AdminNotificationScreen extends StatelessWidget {
  const AdminNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AdminNotificationController());

    return Scaffold(
      backgroundColor: AppColors.lightBackground,

      // ── APP BAR ─────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppRadius.small,
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
        ),
        title: Obx(() => Text(
              'Notifications (${ctrl.unreadCount.value})',
              style: AppTextStyles.h4,
            )),
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: AppRadius.small,
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: const Icon(Icons.more_horiz_rounded),
            ),
            onSelected: (value) {
              switch (value) {
                case 'read':
                  ctrl.markAllAsRead();
                  break;

                case 'clearRead':
                  ctrl.clearReadNotifications();
                  break;

                case 'clearAll':
                  ctrl.clearAllNotifications();
                  break;

                case 'send':
                  _showSendNotificationSheet(context);
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'read',
                child: Text('Mark all as read'),
              ),
              PopupMenuItem(
                value: 'clearRead',
                child: Text('Clear read'),
              ),
              PopupMenuItem(
                value: 'clearAll',
                child: Text('Clear all'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'send',
                child: Text('Send notification'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ── BODY ────────────────────────────────
      body: Column(
        children: [
          const SizedBox(height: 10),

          // FILTER BAR
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _chip(ctrl, "all"),
                  _chip(ctrl, "unread"),
                  _chip(ctrl, "read"),
                ],
              )),

          const SizedBox(height: 10),

          // LIST
          Expanded(
            child: Obx(() {
              final list = ctrl.filteredNotifications;

              if (list.isEmpty) {
                return const Center(
                  child: Text("No notifications found"),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final doc = list[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final isRead = data['isRead'] ?? false;

                  return Dismissible(
                    key: Key(doc.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) {
                      ctrl.deleteNotification(doc.id);
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        ctrl.markAsRead(doc.id);

                        // OPTIONAL: open related order/booking
                        if (data['bookingId'] != null) {
                          // Get.to(() => OrderDetailScreen(id: data['bookingId']));
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(
                                Icons.notifications,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['title'] ?? '',
                                    style: TextStyle(
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['body'] ?? '',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (!isRead)
                              const Icon(Icons.circle,
                                  size: 10, color: Colors.green),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 4,
        onPressed: () => _showSendNotificationSheet(context),
        icon: const Icon(Icons.campaign_rounded),
        label: const Text('Send Alert'),
      ),
    );
  }

  Widget _chip(AdminNotificationController ctrl, String label) {
    final active = ctrl.filter.value == label;

    return GestureDetector(
      onTap: () => ctrl.setFilter(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: active ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
void _showSendNotificationSheet(BuildContext context) {
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();

  String targetRole = 'customer';

  Get.bottomSheet(
    StatefulBuilder(
      builder: (_, setState) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Send Notification',
                style: AppTextStyles.h4,
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                initialValue: targetRole,
                decoration: const InputDecoration(
                  labelText: 'Send To',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'customer',
                    child: Text('Customers'),
                  ),
                  DropdownMenuItem(
                    value: 'artist',
                    child: Text('Artists'),
                  ),
                  DropdownMenuItem(
                    value: 'rider',
                    child: Text('Riders'),
                  ),
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('Everyone'),
                  ),
                ],
                onChanged: (v) {
                  setState(() {
                    targetRole = v!;
                  });
                },
              ),

              const SizedBox(height: 12),

              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: bodyCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message',
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await AdminNotificationController.to
                        .sendNotificationToRole(
                      role: targetRole,
                      title: titleCtrl.text.trim(),
                      body: bodyCtrl.text.trim(),
                    );

                    Get.back();
                  },
                  child: const Text('Send Notification'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
