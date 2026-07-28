import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/models/notification_model.dart';
import 'package:smartstitch/services/notification_service.dart';

class NotificationCenterController extends GetxController {
  static NotificationCenterController get to => Get.find();
  final _service = NotificationService.instance;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  final notifications = <NotificationModel>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;
  final _allNotifications = <NotificationModel>[];

  StreamSubscription<List<NotificationModel>>? _notificationsSub;
  StreamSubscription<int>? _unreadCountSub;

  String get _riderId => AuthController.to.currentUserId ?? '';

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    if (_riderId.isNotEmpty) _startListeners();
  }

  @override
  void onClose() {
    _notificationsSub?.cancel();
    _unreadCountSub?.cancel();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> markAsRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);
    } catch (e) {
      AppHelpers.showError('Failed to mark as read');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead(_riderId);
      AppHelpers.showSuccess('All notifications marked as read');
    } catch (e) {
      AppHelpers.showError('Failed to mark all as read');
    }
  }

  /// Filters the visible list by a tab's "logical" type — but matches
  /// against a *group* of related enum values, since real notifications
  /// are saved with granular types (e.g. `orderUpdate`, `paymentReceived`)
  /// while the filter tabs use broader categories (`order`, `wallet`, ...).
  void filterByType(NotificationType type) {
    final matchTypes = _relatedTypes(type);
    notifications.value =
        _allNotifications.where((n) => matchTypes.contains(n.type)).toList();
  }

  void clearFilter() {
    notifications.value = List.from(_allNotifications);
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _service.deleteNotification(notificationId);
    } catch (e) {
      AppHelpers.showError('Failed to delete notification');
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      await _service.deleteAllNotifications(_riderId);
      AppHelpers.showSuccess('All notifications deleted');
    } catch (e) {
      AppHelpers.showError('Failed to delete notifications');
    }
  }

  Future<List<NotificationModel>> getByType(NotificationType type) async {
    try {
      return await _service.getNotificationsByType(_riderId, type);
    } catch (e) {
      debugPrint('❌ getByType failed: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Computed filters
  // ---------------------------------------------------------------------------

  List<NotificationModel> get unread =>
      notifications.where((n) => !n.isRead).toList();

  List<NotificationModel> get orderNotifications =>
      _byGroup(NotificationType.order);

  List<NotificationModel> get walletNotifications =>
      _byGroup(NotificationType.wallet);

  List<NotificationModel> get withdrawalNotifications =>
      _byGroup(NotificationType.withdrawal);

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  void _startListeners() {
    _notificationsSub?.cancel();
    _notificationsSub = _service.watchNotifications(_riderId).listen(
      (list) {
        _allNotifications
          ..clear()
          ..addAll(list);
        notifications.value = list;
        debugPrint('📬 Notifications updated: ${list.length}');
      },
      onError: (e) => debugPrint('❌ Notifications stream error: $e'),
    );

    _unreadCountSub?.cancel();
    _unreadCountSub = _service.watchUnreadCount(_riderId).listen(
      (count) {
        unreadCount.value = count;
        debugPrint('🔔 Unread count: $count');
      },
      onError: (e) => debugPrint('❌ Unread count stream error: $e'),
    );
  }

  List<NotificationModel> _byGroup(NotificationType type) {
    final matchTypes = _relatedTypes(type);
    return notifications.where((n) => matchTypes.contains(n.type)).toList();
  }

  /// Groups legacy + actual enum values together so filter tabs
  /// match whichever value a notification was actually saved with.
  ///
  /// e.g. tapping the "Orders" tab (NotificationType.order) should also
  /// show notifications saved as `orderUpdate`, `newDelivery`, etc.
  Set<NotificationType> _relatedTypes(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return {
          NotificationType.order,
          NotificationType.orderUpdate,
          NotificationType.newDelivery,
          NotificationType.reviewReceived,
        };
      case NotificationType.wallet:
        return {
          NotificationType.wallet,
          NotificationType.paymentReceived,
        };
      case NotificationType.withdrawal:
        return {
          NotificationType.withdrawal,
          NotificationType.withdrawUpdate,
        };
      default:
        return {type};
    }
  }
}