import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationController extends GetxController {
  static AdminNotificationController get to => Get.find();

  final _db = FirebaseFirestore.instance;

  // ── OBSERVABLES ─────────────────────────────
  final allNotifications = <QueryDocumentSnapshot>[].obs;
  final filter = 'all'.obs;

  final unreadCount = 0.obs;
  final isLoading = false.obs;
  int get readCount => allNotifications.length - unreadCount.value;

  int get totalCount => allNotifications.length;

  @override
  void onInit() {
    super.onInit();
    _listenNotifications();
  }

  // ── REALTIME STREAM ─────────────────────────
  void _listenNotifications() {
    isLoading.value = true;
    _db
        .collection('notifications')
        // FIX: documents are written with a `createdAt` field
        // (FieldValue.serverTimestamp() in sendNotificationToRole), but this
        // was ordering by `sentAt`, a field that doesn't exist on any doc.
        // Firestore's orderBy() silently excludes documents missing the
        // ordered field, so this always returned an empty result set —
        // that's why the screen showed "Notifications (0)" even with data
        // in the collection.
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        // ignore: avoid_print
        print('✅ [admin-notifications] fetched: ${snap.docs.length} docs');
        allNotifications.value = snap.docs;
        unreadCount.value =
            snap.docs.where((d) => (d.data() as Map)['isRead'] == false).length;
        isLoading.value = false;
      },
      onError: (e) {
        // ignore: avoid_print
        print('❌ [admin-notifications] ERROR: $e');
        isLoading.value = false;
      },
    );
  }

  // ── FILTER ──────────────────────────────────
  List<QueryDocumentSnapshot> get filteredNotifications {
    switch (filter.value) {
      case 'unread':
        return allNotifications.where((d) => (d.data() as Map)['isRead'] == false).toList();
      case 'read':
        return allNotifications.where((d) => (d.data() as Map)['isRead'] == true).toList();
      default:
        return allNotifications;
    }
  }

  void setFilter(String value) => filter.value = value;

  // ── MARK AS READ ────────────────────────────
  Future<void> markAsRead(String id) async {
    await _db.collection('notifications').doc(id).update({
      'isRead': true,
    });
  }

  // ── DELETE SINGLE ───────────────────────────
  Future<void> deleteNotification(String id) async {
    await _db.collection('notifications').doc(id).delete();
  }

  // ── CLEAR READ ──────────────────────────────
  Future<void> clearReadNotifications() async {
    final readItems =
        allNotifications.where((d) => (d.data() as Map)['isRead'] == true).toList();

    for (var doc in readItems) {
      await _db.collection('notifications').doc(doc.id).delete();
    }
  }

  // ── CLEAR ALL ───────────────────────────────
  Future<void> clearAllNotifications() async {
    for (var doc in allNotifications) {
      await _db.collection('notifications').doc(doc.id).delete();
    }
  }

  Future<void> markAllAsRead() async {
    for (final doc in allNotifications) {
      if (((doc.data() as Map)['isRead'] ?? false) == false) {
        await _db.collection('notifications').doc(doc.id).update({
          'isRead': true,
        });
      }
    }
  }

  Future<void> sendNotificationToRole({
    required String role,
    required String title,
    required String body,
  }) async {
    final users = await FirebaseFirestore.instance.collection('users').get();

    for (final user in users.docs) {
      final userRole = user['role'];

      if (role != 'all' && role != userRole) {
        continue;
      }

      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': user.id,
        'recipientRole': userRole,
        'title': title,
        'body': body,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}