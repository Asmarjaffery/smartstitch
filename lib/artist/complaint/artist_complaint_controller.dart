import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:smartstitch/controllers/auth_controller.dart';

// ─── Admin reply (nested inside a complaint doc) ─────────────────────────────
//
// `adminReply` in Firestore can come in either shape depending on how the
// admin panel writes it:
//   - a plain string, e.g. adminReply: "We'll look into this."
//   - a map, e.g. adminReply: { message: "...", repliedAt: Timestamp }
// This handles both so the UI never has to care which one it got.
class AdminReply {
  final String message;
  final DateTime? repliedAt;

  AdminReply({required this.message, required this.repliedAt});

  static AdminReply? parse(dynamic raw) {
    if (raw == null) return null;

    if (raw is String) {
      if (raw.trim().isEmpty) return null;
      return AdminReply(message: raw.trim(), repliedAt: null);
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final message =
          (map['message'] ?? map['text'] ?? map['reply'] ?? '').toString().trim();
      if (message.isEmpty) return null;
      return AdminReply(
        message: message,
        repliedAt: _parseTime(map['repliedAt'] ?? map['time'] ?? map['createdAt']),
      );
    }

    return null;
  }
}

// ─── Complaint item — mirrors the real `complaints` collection schema ───────
class ArtistComplaintItem {
  final String id;
  final String artistId;
  final String bookingId;
  final String orderId;
  final String issueType;
  final String subject;
  final String description;
  final String priority;
  final String status;
  final String userId;
  final String userName;
  final bool isAutoResponded;
  final List<String> evidenceImages;
  final List<String> evidenceVideos;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final AdminReply? adminReply;

  ArtistComplaintItem({
    required this.id,
    required this.artistId,
    required this.bookingId,
    required this.orderId,
    required this.issueType,
    required this.subject,
    required this.description,
    required this.priority,
    required this.status,
    required this.userId,
    required this.userName,
    required this.isAutoResponded,
    required this.evidenceImages,
    required this.evidenceVideos,
    required this.createdAt,
    required this.resolvedAt,
    required this.adminReply,
  });

  factory ArtistComplaintItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ArtistComplaintItem(
      id: doc.id,
      artistId: data['artistId'] ?? '',
      bookingId: data['bookingId'] ?? '',
      orderId: data['orderId'] ?? '',
      issueType: data['issueType'] ?? 'General',
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      priority: data['priority'] ?? 'Medium',
      status: (data['status'] ?? 'pending').toString(),
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      isAutoResponded: data['isAutoResponded'] == true,
      evidenceImages: List<String>.from(data['evidenceImages'] ?? const []),
      evidenceVideos: List<String>.from(data['evidenceVideos'] ?? const []),
      createdAt: _parseTime(data['createdAt']),
      resolvedAt: _parseTime(data['resolvedAt']),
      adminReply: AdminReply.parse(data['adminReply']),
    );
  }
}

DateTime? _parseTime(dynamic ts) {
  if (ts is Timestamp) return ts.toDate();
  if (ts is String) return DateTime.tryParse(ts);
  return null;
}

// ─── Controller ───────────────────────────────────────────────────────────────
class ArtistComplaintController extends GetxController {
  static ArtistComplaintController get to => Get.find();

  final _db = FirebaseFirestore.instance;

  final isLoading = true.obs;
  final complaints = <ArtistComplaintItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  Future<void> refresh() async {
    isLoading.value = true;
    try {
      final artistId = AuthController.to.currentUser.value?.id;
      if (artistId == null) {
        complaints.value = [];
        return;
      }
      final snap = await _db
          .collection('complaints')
          .where('artistId', isEqualTo: artistId)
          .orderBy('createdAt', descending: true)
          .get();

      complaints.value =
          snap.docs.map((d) => ArtistComplaintItem.fromDoc(d)).toList();
    } finally {
      isLoading.value = false;
    }
  }
}