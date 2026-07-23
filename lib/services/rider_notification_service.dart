import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/models/notification_model.dart';

class RiderNotificationService {
  static final RiderNotificationService instance =
      RiderNotificationService._();

  RiderNotificationService._();

  final _db = FirebaseFirestore.instance;
  static const String _collectionName = 'rider_notifications';

  // ─── Create Notification ────────────────────────────────────────────
  Future<String> createNotification({
    required String userId,          
    required String title,
    required String body,
    required NotificationType type,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Check for duplicate (within last 60 seconds)
      final isDuplicate = await _checkDuplicate(userId, title, body);
      if (isDuplicate) {
        debugPrint('🚫 Duplicate notification prevented: $title');
        return '';
      }

      final notificationId = _db.collection(_collectionName).doc().id;

      // ✅ NotificationModel use kar raha hai, RiderNotification nahi
      final notification = NotificationModel(
        id: notificationId,
        recipientId: userId,
        recipientRole: UserRole.rider,
        type: type,
        title: title,
        body: body,
        data: data,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _db
          .collection(_collectionName)
          .doc(notificationId)
          .set(notification.toJson());

      debugPrint('✅ Notification created: $notificationId');
      return notificationId;
    } catch (e) {
      debugPrint('❌ Error creating notification: $e');
      return '';
    }
  }

  // ─── Check for Duplicate ────────────────────────────────────────────
  Future<bool> _checkDuplicate(
      String userId, String title, String body) async {
    try {
      final sixtySecondsAgo = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(seconds: 60)));

      final snap = await _db
          .collection(_collectionName)
          .where('recipientId', isEqualTo: userId) // ✅ riderId → recipientId
          .where('title', isEqualTo: title)
          .where('body', isEqualTo: body)
          .where('createdAt', isGreaterThan: sixtySecondsAgo)
          .limit(1)
          .get();

      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking duplicate: $e');
      return false;
    }
  }

  // ─── Get Unread Count ───────────────────────────────────────────────
  Future<int> getUnreadCount(String userId) async {
    try {
      final snap = await _db
          .collection(_collectionName)
          .where('recipientId', isEqualTo: userId) // ✅
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snap.count ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      return 0;
    }
  }

  // ─── Listen to Notifications (Real-time) ─────────────────────────────
  Stream<List<NotificationModel>> listenToNotifications(String userId) {
    return _db
        .collection(_collectionName)
        .where('recipientId', isEqualTo: userId) // ✅
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => NotificationModel.fromJson(doc.data()))
            .toList());
  }

  // ─── Listen to Unread Count ─────────────────────────────────────────
  Stream<int> listenToUnreadCount(String userId) {
    return _db
        .collection(_collectionName)
        .where('recipientId', isEqualTo: userId) // ✅
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ─── Mark Single as Read ────────────────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db
          .collection(_collectionName)
          .doc(notificationId)
          .update({'isRead': true});

      debugPrint('✅ Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('❌ Error marking as read: $e');
    }
  }

  // ─── Mark All as Read ───────────────────────────────────────────────
  Future<void> markAllAsRead(String userId) async {
    try {
      final snap = await _db
          .collection(_collectionName)
          .where('recipientId', isEqualTo: userId) // ✅
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      debugPrint('✅ All notifications marked as read for $userId');
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
    }
  }

  // ─── Delete Notification ────────────────────────────────────────────
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db.collection(_collectionName).doc(notificationId).delete();
      debugPrint('✅ Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
    }
  }

  // ─── Delete All Notifications ───────────────────────────────────────
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final snap = await _db
          .collection(_collectionName)
          .where('recipientId', isEqualTo: userId) // ✅
          .get();

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ All notifications deleted for $userId');
    } catch (e) {
      debugPrint('❌ Error deleting all notifications: $e');
    }
  }

  // ─── Get Notifications by Type ──────────────────────────────────────
  Future<List<NotificationModel>> getNotificationsByType(
      String userId, NotificationType type) async {
    try {
      final snap = await _db
          .collection(_collectionName)
          .where('recipientId', isEqualTo: userId) // ✅
          .where('type', isEqualTo: type.name)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snap.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting notifications by type: $e');
      return [];
    }
  }
}