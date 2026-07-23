import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:smartstitch/models/complaint_model.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:image_picker/image_picker.dart';

class ComplaintController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<ComplaintModel> _complaints = <ComplaintModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<ComplaintStatus> filterStatus = Rxn<ComplaintStatus>();

  // ─── BOOKINGS ──────────────────────────────────────────
  final RxList<Map<String, dynamic>> eligibleBookings =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingBookings = false.obs;

  // Statuses jinme ONLINE (safepay/card/wallet) payment wali booking pe,
  // order complete hone se pehle bhi, complaint ban sakti hai
  static const List<String> _eligibleOnlineStatuses = [
    'pending',
    'confirmed',
    'completed',
    'delivered',
  ];

  // Order complete/deliver ho chuka ho to — payment method chahe jo bhi ho —
  // complaint hamesha khulni chahiye
  static const List<String> _alwaysEligibleStatuses = [
    'completed',
    'delivered',
  ];

  StreamSubscription<QuerySnapshot>? _streamSub;
  TextEditingController? _subjectController;
  TextEditingController? _descriptionController;
  TextEditingController? _orderIdController;
  final formKey = GlobalKey<FormState>();

  TextEditingController get subjectController {
    _subjectController ??= TextEditingController();
    return _subjectController!;
  }

  TextEditingController get descriptionController {
    _descriptionController ??= TextEditingController();
    return _descriptionController!;
  }

  TextEditingController get orderIdController {
    _orderIdController ??= TextEditingController();
    return _orderIdController!;
  }

  // ─── GETTERS ───────────────────────────────────────────
  RxList<ComplaintModel> get complaints => _complaints;

  int get pendingCount =>
      _complaints.where((c) => c.status == ComplaintStatus.pending).length;

  int get inProgressCount =>
      _complaints.where((c) => c.status == ComplaintStatus.inProgress).length;

  int get resolvedCount =>
      _complaints.where((c) => c.status == ComplaintStatus.resolved).length;

  // ─── LOAD COMPLAINTS ───────────────────────────────────
  // FIX: `.snapshots()` real-time listener web/DDC debug mode mein
  // unreliable nikla (kabhi timeout, kabhi silently 0 docs) — isliye
  // ab simple one-time `.get()` fetch use kar rahe hain. Real-time
  // updates yahan zaroori bhi nahi (complaint list, chat nahi hai).
  Future<void> loadComplaints(String userId) async {
    print("========== LOAD COMPLAINTS ==========");
    print("Parameter User ID: $userId");
    print("Firebase UID: ${FirebaseAuth.instance.currentUser?.uid}");

    // Agar koi purana listener kahin se laga reh gaya ho, cancel karo
    await _streamSub?.cancel();
    _streamSub = null;

    errorMessage.value = null;
    isLoading.value = true;

    try {
      print("Fetching complaints (one-time get)...");

      final snap = await _db
          .collection('complaints')
          .where('userId', isEqualTo: userId)
          .get();

      print("✅ Fetched. Documents: ${snap.docs.length}");

      final list =
          snap.docs.map((e) => ComplaintModel.fromFirestore(e)).toList();
      // orderBy Firestore se hataya (index dependency avoid karne ke
      // liye) — sort ab yahan client-side ho raha hai.
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      _complaints.assignAll(list);
      errorMessage.value = null;
    } catch (e, stack) {
      print("🔥 Firestore Error:");
      print(e);
      print(stack);
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // ─── LOAD ELIGIBLE BOOKINGS ────────────────────────────
  // NOTE: pehle jo booking pe already complaint ban chuki thi wo dropdown se
  // hata di jati thi (`continue`) — is wajah se user ko pata hi nahi chalta
  // tha ke ye booking complain ho chuki hai. Ab wo booking list mein rehti
  // hai lekin `hasComplaint: true` flag ke sath, taake UI "Already
  // Complained" dikha sake aur dobara select hone pe rok sake.
  Future<void> loadEligibleBookings(String userId) async {
    isLoadingBookings.value = true;
    try {
      final complaintsSnap = await _db
          .collection('complaints')
          .where('userId', isEqualTo: userId)
          .get();

      final Set<String> alreadyComplainedBookingIds = complaintsSnap.docs
          .map((d) => (d.data()['bookingId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      final snap = await _db
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .where('status', whereIn: [
        'pending',
        'confirmed',
        'completed',
        'delivered',
      ]).get();

      final List<Map<String, dynamic>> bookings = [];

      for (final doc in snap.docs) {
        final data = doc.data();
        final String bookingId = data['id'] ?? doc.id;

        // ── PAYMENT CHECK ────────────────────────────
        final paymentMethod =
            (data['paymentMethod'] ?? '').toString().toLowerCase();
        final String status = (data['status'] ?? '').toString().toLowerCase();

        final bool isOnlinePayment = paymentMethod != 'cash';

        final bool isEligible = _alwaysEligibleStatuses.contains(status) ||
            (isOnlinePayment && _eligibleOnlineStatuses.contains(status));

        if (!isEligible) continue;

        // ── ARTIST NAME FETCH ────────────────────────
        final artistId = data['artistId'] ?? '';
        String artistName = 'Unknown Artist';

        if (artistId.isNotEmpty) {
          try {
            final artistDoc =
                await _db.collection('users').doc(artistId).get();
            if (artistDoc.exists) {
              artistName = artistDoc.data()?['name'] ?? 'Unknown Artist';
            }
          } catch (_) {}
        }

        bookings.add({
          'id': bookingId,
          'shortId': bookingId.split('-')[0].toUpperCase(),
          'artistId': artistId,
          'artistName': artistName,
          'serviceTitle': data['serviceTitle'] ?? '—',
          'status': status,
          'paymentMethod': isOnlinePayment ? 'card' : 'cash',
          'hasComplaint': alreadyComplainedBookingIds.contains(bookingId),
        });
      }

      eligibleBookings.value = bookings;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoadingBookings.value = false;
    }
  }

  // ─── SUBMIT ────────────────────────────────────────────
  Future<bool> submitComplaint({
    required String userId,
    required String userName,
    required String issueType,
    required String priority,
    required String bookingId,
    required String artistId,
    List<XFile>? images,
    List<XFile>? videos,
  }) async {
    if (!(formKey.currentState?.validate() ?? false)) return false;

    isSubmitting.value = true;
    errorMessage.value = null;

    try {
      // Race-condition guard: submit se theek pehle bhi check kar lo
      // ke isi booking pe kahin already complaint na ban chuki ho
      final existing = await _db
          .collection('complaints')
          .where('userId', isEqualTo: userId)
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        errorMessage.value =
            'You have already submitted a complaint for this booking.';
        return false;
      }

      final List<String> imageUrls = [];
      final List<String> videoUrls = [];

      if (images != null && images.isNotEmpty) {
        for (final image in images) {
          final url =
              await _uploadToCloudinary(image, 'complaints/$userId/images');
          if (url != null) imageUrls.add(url);
        }
      }

      if (videos != null && videos.isNotEmpty) {
        for (final video in videos) {
          final url =
              await _uploadToCloudinary(video, 'complaints/$userId/videos');
          if (url != null) videoUrls.add(url);
        }
      }

      final docRef = await _db.collection('complaints').add({
        'userId': userId,
        'userName': userName,
        'subject': subjectController.text.trim(),
        'description': descriptionController.text.trim(),
        'issueType': issueType,
        'priority': priority,
        'orderId': orderIdController.text.trim(),
        'bookingId': bookingId,
        'artistId': artistId,
        'status': 'pending',
        'adminReply': null,
        'isAutoResponded': false,
        'evidenceImages': imageUrls,
        'evidenceVideos': videoUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
      });

      await docRef.collection('timeline').add({
        'title': 'Complaint Submitted',
        'note': 'User created complaint',
        'time': FieldValue.serverTimestamp(),
      });

      // Ab yeh booking dropdown mein "Already Complained" ban jaye,
      // list se hatani nahi hai — taake user ko pata rahe
      final idx = eligibleBookings.indexWhere((b) => b['id'] == bookingId);
      if (idx != -1) {
        eligibleBookings[idx] = {
          ...eligibleBookings[idx],
          'hasComplaint': true,
        };
      }

      _clearForm();
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── UPDATE ────────────────────────────────────────────
  Future<bool> updateComplaint({
    required String complaintId,
    required String issueType,
    required String priority,
    List<XFile>? images,
    List<XFile>? videos,
  }) async {
    if (!(formKey.currentState?.validate() ?? false)) return false;

    isSubmitting.value = true;
    errorMessage.value = null;

    try {
      await _db.collection('complaints').doc(complaintId).update({
        'subject': subjectController.text.trim(),
        'description': descriptionController.text.trim(),
        'issueType': issueType,
        'priority': priority,
        'orderId': orderIdController.text.trim(),
        // bookingId & artistId immutable
      });

      _clearForm();
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── DELETE ────────────────────────────────────────────
  Future<bool> deleteComplaint(String id) async {
    try {
      await _db.collection('complaints').doc(id).delete();
      return true;
    } catch (e) {
      errorMessage.value = "Failed to delete complaint";
      return false;
    }
  }

  // ─── FILTER ────────────────────────────────────────────
  void setFilter(ComplaintStatus? status) {
    filterStatus.value = status;
  }

  // ─── CLOUDINARY UPLOAD ─────────────────────────────────
  Future<String?> _uploadToCloudinary(XFile file, String folder) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      final isVideo = file.name.toLowerCase().endsWith('.mp4') ||
          file.name.toLowerCase().endsWith('.mov') ||
          file.name.toLowerCase().endsWith('.avi');

      final uploadUrl = isVideo
          ? 'https://api.cloudinary.com/v1_1/dc58vppqz/video/upload'
          : 'https://api.cloudinary.com/v1_1/dc58vppqz/image/upload';

      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['upload_preset'] = 'smartstitch_profile';
      request.fields['folder'] = folder;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      final streamedResponse = await request.send();
      final responseData = await streamedResponse.stream.bytesToString();
      final jsonData = jsonDecode(responseData);
      final url = jsonData['secure_url'];

      if (url == null) {
        throw Exception('Upload failed: ${jsonData['error']?['message']}');
      }
      return url;
    } catch (e) {
      return null;
    }
  }

  // ─── CLEAR FORM ────────────────────────────────────────
  void _clearForm() {
    _subjectController?.clear();
    _descriptionController?.clear();
    _orderIdController?.clear();
  }

  // ─── DISPOSE ───────────────────────────────────────────
  @override
  void onClose() {
    _streamSub?.cancel();
    _subjectController?.dispose();
    _descriptionController?.dispose();
    _orderIdController?.dispose();
    super.onClose();
  }
}