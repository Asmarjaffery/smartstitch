import 'package:flutter/foundation.dart'; 
import 'package:get/get.dart';
import '../../models/notification_model.dart';
import '../../models/enums.dart';
import '../../services/notification_service.dart';
import '../../core/utils/helpers.dart';
import '../../controllers/auth_controller.dart';


class NotificationUserController extends GetxController {
  static NotificationUserController get to => Get.find();


  final NotificationService _service = NotificationService.instance;


  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt unreadCount = 0.obs;


  String get myId => AuthController.to.currentUserId ?? '';
  UserRole get myRole => AuthController.to.userRole.value;


  @override
  void onInit() {
    super.onInit();
    debugPrint('🔔 NotificationUserController initialized - User: $myId, Role: $myRole');
    _listenToNotifications();
    _listenToUnreadCount();
  }


  void _listenToNotifications() {
    debugPrint('🔍 Watching notifications for: $myId');
    _service.watchNotifications(myId).listen(
      (data) {
        debugPrint('✅ Notifications received: ${data.length}');
        notifications.value = data;
      },
      onError: (e) {
        debugPrint('❌ Notification error: $e');
        print('❌ $e');
      },
    );
  }


  void _listenToUnreadCount() {
    debugPrint('🔍 Watching unread count for: $myId');
    _service.watchUnreadCount(myId).listen(
      (count) {
        debugPrint('✅ Unread count: $count');
        unreadCount.value = count;
      },
      onError: (e) {
        debugPrint('❌ Unread count error: $e');
      },
    );
  }


  // ✅ Add manual refresh method
  @override
  Future<void> refresh() async {
    debugPrint('🔄 Manual refresh triggered');
    isLoading.value = true;
    try {
      // Force re-read from Firestore
      await _service.watchNotifications(myId).first;
    } catch (e) {
      debugPrint('❌ Refresh error: $e');
    }
    isLoading.value = false;
  }


  Future<void> markAsRead(String notificationId) async {
    try {
      debugPrint('✅ Marking as read: $notificationId');
      await _service.markAsRead(notificationId);
    } catch (e) {
      debugPrint('❌ Mark as read error: $e');
      AppHelpers.showError('Failed to mark as read');
    }
  }


  Future<void> markAllAsRead() async {
    try {
      debugPrint('✅ Marking all as read');
      await _service.markAllAsRead(myId);
      AppHelpers.showSuccess('All notifications marked as read');
    } catch (e) {
      debugPrint('❌ Mark all as read error: $e');
      AppHelpers.showError('Failed to mark all as read');
    }
  }


  Future<void> deleteNotification(String notificationId) async {
    try {
      debugPrint('✅ Deleting notification: $notificationId');
      await _service.deleteNotification(notificationId);
    } catch (e) {
      debugPrint('❌ Delete error: $e');
      AppHelpers.showError('Failed to delete notification');
    }
  }


  Future<void> sendOrderUpdate({
    required String recipientId,
    required UserRole recipientRole,
    required String orderId,
    required String status,
  }) async {
    await _service.sendNotification(
      recipientId: recipientId,
      recipientRole: recipientRole,
      type: NotificationType.orderUpdate,
      title: 'Order Update',
      body: 'Your order status has been updated to: $status',
      data: {'orderId': orderId, 'status': status},
    );
  }


  Future<void> sendPromoAlert({
    required String recipientId,
    required String promoTitle,
    required String promoBody,
  }) async {
    await _service.sendNotification(
      recipientId: recipientId,
      recipientRole: UserRole.customer,
      type: NotificationType.promotional,
      title: promoTitle,
      body: promoBody,
    );
  }


  Future<void> sendEventNotification({
    required String recipientId,
    required UserRole recipientRole,
    required String eventTitle,
    required String eventBody,
  }) async {
    await _service.sendNotification(
      recipientId: recipientId,
      recipientRole: recipientRole,
      type: NotificationType.event,
      title: eventTitle,
      body: eventBody,
    );
  }


  List<NotificationModel> get unreadNotifications =>
      notifications.where((n) => !n.isRead).toList();


  List<NotificationModel> get orderNotifications => notifications
      .where((n) => n.type == NotificationType.orderUpdate)
      .toList();


  List<NotificationModel> get promoNotifications => notifications
      .where((n) => n.type == NotificationType.promotional)
      .toList();


  String timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }


  Future<void> sendWishlistNotification({
    required String recipientId,
    required String itemName,
  }) async {
    await _service.sendNotification(
      recipientId: recipientId,
      recipientRole: UserRole.customer,
      type: NotificationType.event,
      title: 'Added to Wishlist!',
      body: '$itemName has been saved to your wishlist.',
      data: {'itemName': itemName},
    );
  }


  Future<void> sendWishlistRemovedNotification({
    required String recipientId,
    required String itemName,
  }) async {
    await _service.sendNotification(
      recipientId: recipientId,
      recipientRole: UserRole.customer,
      type: NotificationType.event,
      title: 'Removed from Wishlist',
      body: '$itemName has been removed from your wishlist.',
      data: {'itemName': itemName},
    );
  }
}