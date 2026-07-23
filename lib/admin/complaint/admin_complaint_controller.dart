import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminComplaintController extends GetxController {
  static AdminComplaintController get to => Get.find();

  final _db = FirebaseFirestore.instance;

  static const Map<String, String> autoResponses = {
    'payment':
        'Thank you for reaching out. Your payment issue has been forwarded to our finance team and will be resolved within 24–48 hours.',
    'delivery':
        'We apologise for the inconvenience. Your delivery concern has been escalated to our logistics team for immediate action.',
    'quality':
        'We take service quality seriously. Your complaint has been shared with the artist and our quality assurance team.',
    'general':
        'Thank you for contacting SmartStitch support. Your complaint has been received and our team will respond within 24 hours.',
  };

  // Mirrors the templates offered in the Smart Reply panel of the UI.
  static const Map<String, String> smartTemplates = {
    'Payment Issue':
        'Thank you for bringing this payment issue to our attention. Our finance team has been notified and is reviewing your transaction. You can expect an update within 24–48 hours.',
    'Delivery Delay':
        'We sincerely apologise for the delay in your delivery. Our logistics team has been alerted and is prioritising your order to get it to you as quickly as possible.',
    'Refund Request':
        'We have received your refund request and it is currently being processed by our billing team. Refunds are typically credited back within 5–7 business days.',
    'Quality Issue':
        'We are sorry to hear the quality did not meet your expectations. Your feedback has been shared with the artist and our quality assurance team for review.',
    'Artist Behaviour':
        'Thank you for letting us know. We take conduct concerns seriously and have escalated this to our artist relations team for immediate investigation.',
    'Technical Issue':
        'Thanks for reporting this technical issue. Our engineering team has been notified and is actively investigating the root cause.',
    'General Inquiry':
        'Thank you for contacting SmartStitch support. We have received your message and a member of our team will respond shortly.',
  };

  final isLoading = false.obs;
  final allComplaints = <QueryDocumentSnapshot>[].obs;
  final pendingComplaints = <QueryDocumentSnapshot>[].obs;
  final resolvedComplaints = <QueryDocumentSnapshot>[].obs;
  final totalComplaints = 0.obs;
  final currentFilter = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToComplaints();
  }

  void setFilter(String value) => currentFilter.value = value;

  Map<String, dynamic> _dataOf(QueryDocumentSnapshot doc) =>
      doc.data() as Map<String, dynamic>;

  void _listenToComplaints() {
    _db
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      allComplaints.value = snap.docs;
      totalComplaints.value = snap.docs.length;

      pendingComplaints.value = snap.docs.where((doc) {
        final status = (_dataOf(doc)['status'] ?? 'pending').toString();
        return status != 'resolved';
      }).toList();

      resolvedComplaints.value = snap.docs.where((doc) {
        final status = (_dataOf(doc)['status'] ?? 'pending').toString();
        return status == 'resolved';
      }).toList();
    });
  }

  List<QueryDocumentSnapshot> get filteredComplaints {
    return allComplaints.where((doc) {
      final status = (_dataOf(doc)['status'] ?? 'pending').toString().trim();
      switch (currentFilter.value) {
        case 'pending':    return status == 'pending';
        case 'in_process': return status == 'in_process' || status == 'in_progress';
        case 'resolved':   return status == 'resolved';
        case 'closed':     return status == 'closed';
        default:           return true;
      }
    }).toList();
  }

  // ─── Resolve ──────────────────────────────────────────────────────────────

  Future<void> resolveComplaint({
    required String complaintId,
    required String replyMessage,
  }) async {
    if (replyMessage.trim().isEmpty) {
      _showError('Reply message cannot be empty.');
      return;
    }
    isLoading.value = true;
    try {
      await _db.collection('complaints').doc(complaintId).update({
        'status': 'resolved',
        'adminReply': replyMessage.trim(),
        'lastReplyAt': FieldValue.serverTimestamp(),
        'resolvedAt': FieldValue.serverTimestamp(),   // ✅ timeline
        'reviewedAt': FieldValue.serverTimestamp(),   // ✅ timeline
        'assignedAt': FieldValue.serverTimestamp(),   // ✅ timeline (agar pehle set nahi tha)
      });

      _showSuccess('Resolved ✓', 'Complaint marked as resolved.');
    } catch (e) {
      _showError('Resolution failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Send Reply (does not necessarily change status) ─────────────────────

  Future<void> sendReply({
    required String complaintId,
    required String replyMessage,
    required String currentStatus,
    bool customerVisible = true,
  }) async {
    if (replyMessage.trim().isEmpty) {
      _showError('Reply message cannot be empty.');
      return;
    }
    isLoading.value = true;
    try {
      final update = <String, dynamic>{
        'lastReplyAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.serverTimestamp(),
        'customerVisible': customerVisible,
      };
      if (customerVisible) update['adminReply'] = replyMessage.trim();
      if (currentStatus == 'pending') {
        update['status'] = 'in_process';
        update['assignedAt'] = FieldValue.serverTimestamp();
      }
      await _db.collection('complaints').doc(complaintId).update(update);
      _showSuccess('Reply sent', 'Your response has been sent to the customer.');
    } catch (e) {
      _showError('Failed to send reply: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Internal Notes (admin-only, never shown to customer) ────────────────

  Future<void> addInternalNote(String complaintId, String note) async {
    if (note.trim().isEmpty) return;
    try {
      await _db.collection('complaints').doc(complaintId).update({
        'internalNotes': FieldValue.arrayUnion([
          {'note': note.trim(), 'addedAt': Timestamp.now()},
        ]),
      });
      _showSuccess('Note saved', 'Internal note added to this complaint.');
    } catch (e) {
      _showError('Failed to save note: $e');
    }
  }

  // ─── Priority / Assignment / Estimated Resolution ─────────────────────────

  Future<void> updatePriority(String complaintId, String priority) async {
    try {
      await _db.collection('complaints').doc(complaintId).update({'priority': priority});
    } catch (e) {
      _showError('Failed to update priority: $e');
    }
  }

  Future<void> setEstimatedResolution(String complaintId, String eta) async {
    try {
      await _db.collection('complaints').doc(complaintId).update({'estimatedResolution': eta});
    } catch (e) {
      _showError('Failed to update ETA: $e');
    }
  }

  // ─── Mark In Progress ───────────────────────────────────────────────────

  Future<void> markInProgress(String complaintId) async {
    try {
      await _db.collection('complaints').doc(complaintId).update({
        'status': 'in_process',
        'assignedAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      _showSuccess('Updated ✓', 'Complaint marked as in progress.');
    } catch (e) {
      _showError('Update failed: $e');
    }
  }

  // ─── Auto Response ────────────────────────────────────────────────────────

  Future<void> sendAutoResponse(String id, String category) async {
    final response = autoResponses[category] ?? autoResponses['general']!;
    await _db.collection('complaints').doc(id).update({
      'adminReply': response,
      'status': 'in_process',
      'isAutoResponded': true,
      'autoResponseAt': FieldValue.serverTimestamp(),  // ✅ timeline
      'assignedAt': FieldValue.serverTimestamp(),       // ✅ timeline
    });
  }

  // ─── Reopen ───────────────────────────────────────────────────────────────

  Future<void> reopenComplaint(String complaintId) async {
    try {
      await _db.collection('complaints').doc(complaintId).update({
        'status': 'pending',
        'reopenedAt': FieldValue.serverTimestamp(),
        // Reset timeline fields so they show Unknown again (fresh start)
        'resolvedAt': null,
        'closedAt': null,
      });
      _showSuccess('Reopened', 'Complaint has been reopened.');
    } catch (e) {
      _showError('Reopen failed: $e');
    }
  }

  // ─── Close ────────────────────────────────────────────────────────────────

  Future<void> closeComplaint(String complaintId) async {
    try {
      await _db.collection('complaints').doc(complaintId).update({
        'status': 'closed',
        'closedAt': FieldValue.serverTimestamp(),  // ✅ timeline
      });
      _showSuccess('Closed', 'Complaint has been closed.');
    } catch (e) {
      _showError('Close failed: $e');
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────
  // Confirmation now lives in the UI layer (see ActionButtons / confirmComplaintAction),
  // so this simply performs the deletion.

  Future<void> deleteComplaint(String complaintId) async {
    try {
      await _db.collection('complaints').doc(complaintId).delete();
      _showSuccess('Deleted', 'Complaint has been removed.');
    } catch (e) {
      _showError('Delete failed: $e');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String getAutoResponsePreview(String category) =>
      autoResponses[category] ?? autoResponses['general']!;

  /// Deterministic, locally-generated "AI suggested reply". Swap the body of
  /// this method for a real LLM API call when one is wired up — the return
  /// contract (a single String) stays the same either way.
  String generateAiReply({required String category, required String description}) {
    final opener = smartTemplates[_categoryToTemplateLabel(category)] ?? autoResponses['general']!;
    final snippet = description.trim().isEmpty
        ? ''
        : ' Regarding your note — "${_truncate(description.trim(), 70)}" — we want to assure you this is being handled with priority.';
    return '$opener$snippet We appreciate your patience and will keep you updated every step of the way.';
  }

  String _categoryToTemplateLabel(String category) {
    switch (category.toLowerCase()) {
      case 'payment': return 'Payment Issue';
      case 'delivery': return 'Delivery Delay';
      case 'refund': return 'Refund Request';
      case 'quality': return 'Quality Issue';
      case 'artist_behaviour':
      case 'artist behaviour': return 'Artist Behaviour';
      case 'technical': return 'Technical Issue';
      default: return 'General Inquiry';
    }
  }

  String _truncate(String s, int n) => s.length <= n ? s : '${s.substring(0, n)}…';

  void _showSuccess(String title, String msg) {
    Get.snackbar(
      title, msg,
      backgroundColor: Colors.green.shade600, colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16), borderRadius: 14,
      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
      duration: const Duration(seconds: 3),
      isDismissible: true,
    );
  }

  void _showError(String msg) {
    Get.snackbar('Error', msg,
        backgroundColor: Colors.red.shade600, colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16), borderRadius: 14,
        icon: const Icon(Icons.error_rounded, color: Colors.white),
        duration: const Duration(seconds: 3));
  }
}