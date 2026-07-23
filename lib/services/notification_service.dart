import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../models/enums.dart';

// ─── Custom sound channel (shared between foreground + background) ────────────
const String _kChannelId = 'smartstitch_sound_channel';
const String _kChannelName = 'SmartStitch Notifications';
const String _kSoundFile = 'notification_sound';

const AndroidNotificationChannel _soundChannel = AndroidNotificationChannel(
  _kChannelId,
  _kChannelName,
  description: 'SmartStitch app notifications with custom sound',
  importance: Importance.high,
  playSound: true,
  sound: RawResourceAndroidNotificationSound(_kSoundFile),
  enableVibration: true,
);

/// Full notification details used everywhere — foreground, background, data-only.
NotificationDetails _buildDetails() => const NotificationDetails(
      android: AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        channelDescription: 'SmartStitch app notifications with custom sound',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_kSoundFile),
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        sound: 'notification_sound.wav',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

// ─── Background Handler (must be top-level) ───────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final notification = message.notification;
  if (notification == null) return; // data-only — no visible notification needed

  final plugin = FlutterLocalNotificationsPlugin();

  // Minimal init for the isolated background context
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  await plugin.show(
    message.hashCode,
    notification.title,
    notification.body,
    _buildDetails(),
  );
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ─── INIT ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notifications init
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // ── Create Android notification channel with custom sound ──────────────
    // Must be done before any notification is shown.
    // On Android 8+, channel sound is locked after first creation —
    // reinstall the app to reset if changing the sound.
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_soundChannel);

    // Foreground FCM presentation (iOS) — let our local notification handle it
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: false, // we show via flutter_local_notifications (has our sound)
      badge: true,
      sound: false,
    );

    // Listen foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  // ─── SAVE TOKEN ────────────────────────────────────────────────────────────

  Future<void> saveTokenToFirestore(String userId) async {
    final token = await _fcm.getToken();
    if (token == null) return;

    await _firestore.collection('users').doc(userId).update({
      'fcmToken': token,
      'tokenUpdatedAt': Timestamp.now(),
    });

    // Refresh token listener
    _fcm.onTokenRefresh.listen((newToken) async {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': newToken,
        'tokenUpdatedAt': Timestamp.now(),
      });
    });
  }

  // ─── SEND NOTIFICATION (save to Firestore) ─────────────────────────────────

  Future<void> sendNotification({
    required String recipientId,
    required UserRole recipientRole,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Create the docRef first so we have the ID up front
    final docRef = _firestore.collection('notifications').doc();

    final notification = NotificationModel(
      id: docRef.id,
      recipientId: recipientId,
      recipientRole: recipientRole,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await docRef.set(notification.toJson());
  }

  // ─── WATCH NOTIFICATIONS ───────────────────────────────────────────────────
  //
  // Note: `orderBy('createdAt')` was intentionally removed here. Combining
  // `where('recipientId', ...)` with `orderBy('createdAt', ...)` requires a
  // Firestore composite index. If that index hasn't been created in the
  // Firebase Console, the query fails silently and the list stays empty
  // (while the unread count still shows correctly, since that query has no
  // orderBy). Sorting is now done client-side in Dart instead — no index
  // needed, and it works immediately.
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => NotificationModel.fromJson({'id': d.id, ...d.data()}))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ─── MARK AS READ ──────────────────────────────────────────────────────────

  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final unread = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ─── DELETE ────────────────────────────────────────────────────────────────

  Future<void> deleteNotification(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // ─── DELETE ALL (for a user) ────────────────────────────────────────────────
  Future<void> deleteAllNotifications(String userId) async {
    final snap = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ─── GET BY TYPE (one-time fetch) ───────────────────────────────────────────
  //
  // Same reasoning as above — `orderBy` removed and replaced with client-side
  // sorting, since this query already has 2 `where` clauses and adding
  // `orderBy` would make the index requirement even stricter.
  Future<List<NotificationModel>> getNotificationsByType(
      String userId, NotificationType type) async {
    final snap = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .get();

    final list = snap.docs
        .map((d) => NotificationModel.fromJson({'id': d.id, ...d.data()}))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(20).toList();
  }

  // ─── FOREGROUND HANDLER ────────────────────────────────────────────────────

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Uses _soundChannel — custom sound plays on both Android and iOS
    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      _buildDetails(),
    );
  }

  // ─── UNREAD COUNT ──────────────────────────────────────────────────────────

  Stream<int> watchUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}