import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUserController extends GetxController {
  static AdminUserController get to => Get.find();

  final _db = FirebaseFirestore.instance;

  // ── Observables ─────────────────────────────────────────────
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedRole = 'all'.obs; // all | customer | artist | rider

  final allUsers = <QueryDocumentSnapshot>[].obs;
  final filteredUsers = <QueryDocumentSnapshot>[].obs;

  @override
  void onInit() {
    super.onInit();
    _listenToUsers();
    // Re-filter whenever query or role changes
    ever(searchQuery, (_) => _applyFilter());
    ever(selectedRole, (_) => _applyFilter());
  }

  // ── Stream ───────────────────────────────────────────────────

  void _listenToUsers() {
    _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      allUsers.value = snap.docs;
      _applyFilter();
    });
  }

  void _applyFilter() {
    var docs = [...allUsers];
    docs = docs.where((d) => (d.data() as Map)['role'] != 'admin').toList();

    if (selectedRole.value != 'all') {
      docs = docs
          .where((d) => (d.data() as Map)['role'] == selectedRole.value)
          .toList();
    }

    // Search filter
    final q = searchQuery.value.toLowerCase().trim();
    if (q.isNotEmpty) {
      docs = docs.where((d) {
        final data = d.data() as Map;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final phone = (data['phone'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q) || phone.contains(q);
      }).toList();
    }

    filteredUsers.value = docs;
  }

  // ── Actions ──────────────────────────────────────────────────

  /// Toggle block / unblock a user
  Future<void> toggleBlockUser(String userId, bool currentlyBlocked) async {
    try {
      await _db.collection('users').doc(userId).update({
        'isBlocked': !currentlyBlocked,
      });
      Get.snackbar(
        currentlyBlocked ? 'User Unblocked' : 'User Blocked',
        currentlyBlocked
            ? 'User has been unblocked successfully.'
            : 'User has been blocked.',
        backgroundColor: currentlyBlocked ? Colors.green : Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      _showError('Failed to update user: $e');
    }
  }

  /// Delete a user document (soft approach — keeps auth record)
  Future<void> deleteUser(String userId, String userName) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "$userName"?'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _db.collection('users').doc(userId).delete();
      Get.snackbar('Deleted', '$userName removed.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (e) {
      _showError('Delete failed: $e');
    }
  }

  /// Send email notification to a specific user
  Future<void> sendMailToUser({
    required String userId,
    required String subject,
    required String body,
  }) async {
    if (subject.trim().isEmpty || body.trim().isEmpty) {
      _showError('Subject and body cannot be empty.');
      return;
    }
    isLoading.value = true;
    try {
      // Store in `mail` collection — works with Firebase Extensions "Trigger Email"
      await _db.collection('mail').add({
        'to': userId, // Extension resolves userId → email
        'message': {
          'subject': subject,
          'text': body,
          'html': '<p>$body</p>',
        },
        'sentAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar('Mail Sent', 'Email queued successfully.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (e) {
      _showError('Mail failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _db.collection('users').doc(userId).update({'role': newRole});
    } catch (e) {
      _showError('Role update failed: $e');
    }
  }

  void setSearch(String q) => searchQuery.value = q;
  void setRole(String role) => selectedRole.value = role;

  void _showError(String msg) {
    Get.snackbar('Error', msg,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12);
  }
}
