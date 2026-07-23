import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ─── Notification Type Enum ───────────────────────────────
enum NotificationType {
  newOrder,
  orderAuthorization,
  paymentReceived,
  withdrawApproved,
  withdrawRejected,
  newMessage,
  promotional,
  orderCancelled,
  reviewRating,
  orderUpdate,
  event,
}

extension NotificationTypeExtension on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.newOrder:
        return 'New Order';
      case NotificationType.orderAuthorization:
        return 'Order Authorization';
      case NotificationType.paymentReceived:
        return 'Payment Received';
      case NotificationType.withdrawApproved:
        return 'Withdraw Approved';
      case NotificationType.withdrawRejected:
        return 'Withdraw Rejected';
      case NotificationType.newMessage:
        return 'New Message';
      case NotificationType.promotional:
        return 'Promotional';
      case NotificationType.orderCancelled:
        return 'Order Cancelled';
      case NotificationType.reviewRating:
        return 'Review & Rating';
      case NotificationType.orderUpdate:
        // TODO: Handle this case.
        throw UnimplementedError();
      case NotificationType.event:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.newOrder:
        return Icons.shopping_bag_outlined;
      case NotificationType.orderAuthorization:
        return Icons.verified_outlined;
      case NotificationType.paymentReceived:
        return Icons.payment_outlined;
      case NotificationType.withdrawApproved:
        return Icons.check_circle_outline;
      case NotificationType.withdrawRejected:
        return Icons.cancel_outlined;
      case NotificationType.newMessage:
        return Icons.message_outlined;
      case NotificationType.promotional:
        return Icons.campaign_outlined;
      case NotificationType.orderCancelled:
        return Icons.block_outlined;
      case NotificationType.reviewRating:
        return Icons.star_outline;
      case NotificationType.orderUpdate:
        // TODO: Handle this case.
        throw UnimplementedError();
      case NotificationType.event:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.newOrder:
        return const Color(0xFF6C3FC5);
      case NotificationType.orderAuthorization:
        return const Color(0xFF3B82F6);
      case NotificationType.paymentReceived:
        return const Color(0xFF4CAF82);
      case NotificationType.withdrawApproved:
        return const Color(0xFF4CAF82);
      case NotificationType.withdrawRejected:
        return const Color(0xFFEF4444);
      case NotificationType.newMessage:
        return const Color(0xFF6C3FC5);
      case NotificationType.promotional:
        return const Color(0xFFF59E0B);
      case NotificationType.orderCancelled:
        return const Color(0xFFEF4444);
      case NotificationType.reviewRating:
        return const Color(0xFFF59E0B);
      case NotificationType.orderUpdate:
        // TODO: Handle this case.
        throw UnimplementedError();
      case NotificationType.event:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}

// ─── Notification Model ───────────────────────────────────
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  bool isRead;
  final String? referenceId; // orderId, messageId etc.

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.referenceId,
  });
}

// ─── Notification Controller ──────────────────────────────
class NotificationController extends GetxController {
  // ─── Firebase Messaging ───────────────────────────────────
  final _fcm = FirebaseMessaging.instance;

  // ─── Socket ───────────────────────────────────────────────
  IO.Socket? _socket;

  // ─── Loading States ───────────────────────────────────────
  final isLoading = false.obs;
  final isSocketConnected = false.obs;

  // ─── Notifications List ───────────────────────────────────
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  // ─── Unread Count ─────────────────────────────────────────
  final unreadCount = 0.obs;

  // ─── FCM Token ────────────────────────────────────────────
  final fcmToken = ''.obs;

  // ─── Server URL ───────────────────────────────────────────
  // TODO: Replace with your actual server URL
  static const String _socketServerUrl = 'https://your-server.com';

  // ─── On Init ──────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    initFCM();
    fetchNotifications();
  }

  // ───────────────────────────────────────────────────────────
  //  FCM SETUP
  // ───────────────────────────────────────────────────────────

  Future<void> initFCM() async {
    // Request permission
    await _requestPermission();

    // Get FCM token
    await _getFCMToken();

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // App opened from background notification
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTapped);

    // App opened from terminated state
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationNavigation(initialMessage.data);
    }
  }

  // ─── Request FCM Permission ───────────────────────────────
  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM permission denied');
    }
  }

  // ─── Get FCM Token ────────────────────────────────────────
  Future<void> _getFCMToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        fcmToken.value = token;
        debugPrint('FCM Token: $token');

        // TODO: Send token to your backend
        // await ApiService.updateFCMToken(token);
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        fcmToken.value = newToken;
        // TODO: Update token on backend
        // ApiService.updateFCMToken(newToken);
      });
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  // ─── Foreground Message Handler ───────────────────────────
  void _onForegroundMessage(RemoteMessage message) {
    final notification = _parseRemoteMessage(message);
    if (notification != null) {
      notifications.insert(0, notification);
      unreadCount.value++;
      _showLocalNotificationBanner(notification);
    }
  }

  // ─── Notification Tapped Handler ──────────────────────────
  void _onNotificationTapped(RemoteMessage message) {
    _handleNotificationNavigation(message.data);
  }

  // ─── Parse Remote Message ─────────────────────────────────
  NotificationModel? _parseRemoteMessage(RemoteMessage message) {
    if (message.notification == null) return null;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().toString(),
      title: message.notification!.title ?? '',
      body: message.notification!.body ?? '',
      type: _getTypeFromData(message.data),
      createdAt: DateTime.now(),
      referenceId: message.data['referenceId'],
    );
  }

  // ─── Get Type from Data ───────────────────────────────────
  NotificationType _getTypeFromData(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    switch (type) {
      case 'new_order':
        return NotificationType.newOrder;
      case 'order_authorization':
        return NotificationType.orderAuthorization;
      case 'payment_received':
        return NotificationType.paymentReceived;
      case 'withdraw_approved':
        return NotificationType.withdrawApproved;
      case 'withdraw_rejected':
        return NotificationType.withdrawRejected;
      case 'new_message':
        return NotificationType.newMessage;
      case 'promotional':
        return NotificationType.promotional;
      case 'order_cancelled':
        return NotificationType.orderCancelled;
      case 'review_rating':
        return NotificationType.reviewRating;
      default:
        return NotificationType.promotional;
    }
  }

  // ─── Show Banner (Foreground) ─────────────────────────────
  void _showLocalNotificationBanner(NotificationModel notification) {
    Get.snackbar(
      notification.title,
      notification.body,
      backgroundColor: notification.type.color,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      icon: Icon(notification.type.icon, color: Colors.white),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          // TODO: Navigate based on type
        },
        child: const Text('View', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // ─── Handle Navigation on Tap ─────────────────────────────
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final referenceId = data['referenceId'];

    switch (type) {
      case 'new_order':
      case 'order_authorization':
      case 'order_cancelled':
        // TODO: Get.toNamed(AppRoutes.orderDetail, arguments: referenceId);
        break;
      case 'payment_received':
      case 'withdraw_approved':
      case 'withdraw_rejected':
        // TODO: Get.toNamed(AppRoutes.earnings);
        break;
      case 'new_message':
        // TODO: Get.toNamed(AppRoutes.chat, arguments: referenceId);
        break;
      case 'review_rating':
        // TODO: Get.toNamed(AppRoutes.reviews);
        break;
      default:
        // TODO: Get.toNamed(AppRoutes.notifications);
        break;
    }
  }

  // ───────────────────────────────────────────────────────────
  //  SOCKET.IO SETUP
  // ───────────────────────────────────────────────────────────

  void connectSocket(String userId) {
    try {
      _socket = IO.io(
        _socketServerUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setQuery({'userId': userId})
            .build(),
      );

      _socket!.connect();

      // ─── Socket Events ──────────────────────────────────
      _socket!.onConnect((_) {
        isSocketConnected.value = true;
        debugPrint('Socket connected');
      });

      _socket!.onDisconnect((_) {
        isSocketConnected.value = false;
        debugPrint('Socket disconnected');
      });

      _socket!.onConnectError((error) {
        isSocketConnected.value = false;
        debugPrint('Socket connection error: $error');
      });

      // ─── Listen to Real-time Notifications ──────────────
      _socket!.on('new_order',
          (data) => _onSocketNotification(data, NotificationType.newOrder));
      _socket!.on(
          'order_authorization',
          (data) =>
              _onSocketNotification(data, NotificationType.orderAuthorization));
      _socket!.on(
          'payment_received',
          (data) =>
              _onSocketNotification(data, NotificationType.paymentReceived));
      _socket!.on(
          'withdraw_approved',
          (data) =>
              _onSocketNotification(data, NotificationType.withdrawApproved));
      _socket!.on(
          'withdraw_rejected',
          (data) =>
              _onSocketNotification(data, NotificationType.withdrawRejected));
      _socket!.on('new_message',
          (data) => _onSocketNotification(data, NotificationType.newMessage));
      _socket!.on(
          'order_cancelled',
          (data) =>
              _onSocketNotification(data, NotificationType.orderCancelled));
      _socket!.on('review_rating',
          (data) => _onSocketNotification(data, NotificationType.reviewRating));
    } catch (e) {
      debugPrint('Socket init error: $e');
    }
  }

  // ─── Socket Notification Handler ──────────────────────────
  void _onSocketNotification(dynamic data, NotificationType type) {
    final notification = NotificationModel(
      id: data['id'] ?? DateTime.now().toString(),
      title: data['title'] ?? type.label,
      body: data['body'] ?? '',
      type: type,
      createdAt: DateTime.now(),
      referenceId: data['referenceId'],
    );

    notifications.insert(0, notification);
    unreadCount.value++;
    _showLocalNotificationBanner(notification);
  }

  // ─── Disconnect Socket ────────────────────────────────────
  void disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    isSocketConnected.value = false;
  }

  // ───────────────────────────────────────────────────────────
  //  NOTIFICATIONS MANAGEMENT
  // ───────────────────────────────────────────────────────────

  // ─── Fetch Notifications from API ─────────────────────────
  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;

      // TODO: Call your API here
      // final response = await ApiService.getNotifications();
      await Future.delayed(const Duration(seconds: 1));

      // TODO: Replace with real notification model list
      notifications.value = [];
      _updateUnreadCount();
    } catch (e) {
      _showError('Failed to load notifications: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Mark Single Notification as Read ────────────────────
  Future<void> markAsRead(String notificationId) async {
    try {
      // TODO: Call your API here
      // await ApiService.markNotificationRead(notificationId);

      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !notifications[index].isRead) {
        notifications[index].isRead = true;
        notifications.refresh();
        _updateUnreadCount();
      }
    } catch (e) {
      debugPrint('Mark read error: $e');
    }
  }

  // ─── Mark All as Read ─────────────────────────────────────
  Future<void> markAllAsRead() async {
    try {
      // TODO: Call your API here
      // await ApiService.markAllNotificationsRead();

      for (final n in notifications) {
        n.isRead = true;
      }
      notifications.refresh();
      unreadCount.value = 0;

      Get.snackbar(
        'Done',
        'All notifications marked as read',
        backgroundColor: const Color(0xFF4CAF82),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      _showError('Failed to mark all read: ${e.toString()}');
    }
  }

  // ─── Delete Notification ──────────────────────────────────
  Future<void> deleteNotification(String notificationId) async {
    try {
      // TODO: Call your API here
      // await ApiService.deleteNotification(notificationId);

      notifications.removeWhere((n) => n.id == notificationId);
      _updateUnreadCount();
    } catch (e) {
      _showError('Failed to delete notification: ${e.toString()}');
    }
  }

  // ─── Clear All Notifications ──────────────────────────────
  Future<void> clearAllNotifications() async {
    try {
      // TODO: Call your API here
      // await ApiService.clearAllNotifications();

      notifications.clear();
      unreadCount.value = 0;
    } catch (e) {
      _showError('Failed to clear notifications: ${e.toString()}');
    }
  }

  // ─── Update Unread Count ──────────────────────────────────
  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  // ─── Show Error ───────────────────────────────────────────
  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: const Color(0xFFEF4444),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  // ─── Dispose ──────────────────────────────────────────────
  @override
  void onClose() {
    disconnectSocket();
    super.onClose();
  }
}
