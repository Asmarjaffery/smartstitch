import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:smartstitch/controllers/auth_controller.dart';

class ComplaintTimelineEntry {
  final String title;
  final String note;
  final DateTime? time;

  ComplaintTimelineEntry({
    required this.title,
    required this.note,
    required this.time,
  });

  factory ComplaintTimelineEntry.fromMap(Map<String, dynamic> data) {
    return ComplaintTimelineEntry(
      title: data['title'] ?? '',
      note: data['note'] ?? '',
      time: _parseTime(data['time']),
    );
  }

  static DateTime? _parseTime(dynamic ts) {
    if (ts is Timestamp) return ts.toDate();
    if (ts is String) return DateTime.tryParse(ts);
    return null;
  }
}

class ArtistComplaintItem {
  final String bookingId;
  final String title;
  final String description;
  final String customerName;
  final String status;
  final DateTime? createdAt;
  final List<ComplaintTimelineEntry> timeline;

  ArtistComplaintItem({
    required this.bookingId,
    required this.title,
    required this.description,
    required this.customerName,
    required this.status,
    required this.createdAt,
    required this.timeline,
  });
}

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

      // 1. Get every booking for this artist. Complaints reference no
      //    artistId of their own — they inherit it from the parent booking.
      final bookingSnap = await _db
          .collection('bookings')
          .where('artistId', isEqualTo: artistId)
          .get();

      if (bookingSnap.docs.isEmpty) {
        complaints.value = [];
        return;
      }

      // 2. Collect customer names in one batch (avoid N+1 reads per booking).
      final customerIds = bookingSnap.docs
          .map((d) => d.data()['customerId'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final customerNames = <String, String>{};
      for (var i = 0; i < customerIds.length; i += 10) {
        final chunk = customerIds.sublist(
            i, i + 10 > customerIds.length ? customerIds.length : i + 10);
        final usersSnap = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final u in usersSnap.docs) {
          customerNames[u.id] =
              u.data()['fullName'] ?? u.data()['name'] ?? 'Unknown';
        }
      }

      // 3. For each booking, check its complaints subcollection.
      final results = <ArtistComplaintItem>[];
      for (final bookingDoc in bookingSnap.docs) {
        final complaintsSnap = await bookingDoc.reference
            .collection('complaints')
            .orderBy('time')
            .get();

        if (complaintsSnap.docs.isEmpty) continue;

        final entries = complaintsSnap.docs
            .map((d) => ComplaintTimelineEntry.fromMap(d.data()))
            .toList();

        final bookingData = bookingDoc.data();
        final customerId = bookingData['customerId'] as String?;

        results.add(ArtistComplaintItem(
          bookingId: bookingDoc.id,
          title: bookingData['serviceTitle'] != null
              ? 'Complaint — ${bookingData['serviceTitle']}'
              : entries.first.title,
          description: entries.first.note,
          customerName: customerNames[customerId] ?? 'Unknown',
          // No status field exists in the source data yet. We infer it from
          // the most recent timeline entry's title as a best-effort guess;
          // add a real `status` field to the last entry doc for accuracy.
          status: _inferStatus(entries.last.title),
          createdAt: entries.first.time,
          timeline: entries,
        ));
      }

      results.sort((a, b) {
        final ta = a.createdAt ?? DateTime(2000);
        final tb = b.createdAt ?? DateTime(2000);
        return tb.compareTo(ta);
      });

      complaints.value = results;
    } finally {
      isLoading.value = false;
    }
  }

  String _inferStatus(String lastEntryTitle) {
    final t = lastEntryTitle.toLowerCase();
    if (t.contains('resolved') || t.contains('closed')) return 'resolved';
    if (t.contains('progress') || t.contains('review')) return 'in_progress';
    return 'open';
  }
}
