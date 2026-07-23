import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/models/artist_model.dart';
import 'package:smartstitch/services/firebase_service.dart';
import 'package:smartstitch/services/chat_service.dart';

class ArtistProfileController extends GetxController {
  // ─── Singleton ────────────────────────────────────────────
  static ArtistProfileController get to => Get.find();

  // ─── Services ─────────────────────────────────────────────
  final _firebaseService = FirebaseService();
  final _picker = ImagePicker();

  // ─── Loading / Status States ──────────────────────────────
  final isLoading = false.obs; // first load (skeleton)
  final isRefreshing = false.obs; // pull-to-refresh
  final isUploadingImage = false.obs;
  final isSaving = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  // ─── Source of Truth: Reactive Artist Data ────────────────
  final artist = Rx<ArtistModel?>(null);

  // ─── Order / Service Stats (computed, not hardcoded) ──────
  final totalCompletedOrders = 0.obs;
  final totalServices = 0.obs;
  final activeServices = 0.obs;
  final draftServices = 0.obs;
  final isLoadingStats = false.obs;

  // Statuses that count as "completed" — covers different naming used
  // across the app (orders vs bookings collections).
  static const List<String> _completedStatuses = [
    'completed',
    'delivered',
    'Completed',
    'Delivered',
  ];

  // ─── Specializations (edit sheet state — safe to keep here since it's
  //      just a list of strings, not a disposable controller) ─────────
  final RxList<String> specializations = <String>[].obs;

  // ─── Field limits (used for validation + UI counters) ─────
  static const int businessNameMaxLength = 60;
  static const int bioMaxLength = 300;
  // ─── On Init ────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    fetchArtistProfile();
  }

  // ───────────────────────────────────────────────────────────
  //  DERIVED / COMPUTED GETTERS
  // ───────────────────────────────────────────────────────────

  double get profileCompletion {
    final a = artist.value;
    if (a == null) return 0.0;
    final checks = <bool>[
      a.profileImageUrl.isNotEmpty,
      a.businessName.trim().isNotEmpty,
      a.bio.trim().isNotEmpty,
      a.cnicNumber.trim().isNotEmpty,
      a.specializations.isNotEmpty,
      true,
    ];
    final done = checks.where((c) => c).length;
    return done / checks.length;
  }

  int get profileCompletionPercent => (profileCompletion * 100).round();

  bool get isVerified => artist.value?.isVerified ?? false;

  bool get hasCnicUploaded => artist.value?.cnicImageUrl.isNotEmpty ?? false;

  // ───────────────────────────────────────────────────────────
  //  FETCH PROFILE + STATS
  // ───────────────────────────────────────────────────────────

  Future<void> fetchArtistProfile({bool silent = false}) async {
    try {
      if (!silent) isLoading.value = true;
      hasError.value = false;

      final uid = AuthController.to.currentUserId;
      if (uid == null) throw Exception('Not authenticated');

      final doc =
          await FirebaseFirestore.instance.collection('artists').doc(uid).get();

      if (doc.exists) {
        artist.value = ArtistModel.fromJson({...doc.data()!, 'id': doc.id});
      } else {
        hasError.value = true;
        errorMessage.value = 'Profile not found';
      }

      await fetchStats();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load profile';
      AppHelpers.showError('Failed to load profile: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshProfile() async {
    isRefreshing.value = true;
    await fetchArtistProfile(silent: true);
  }

  /// Fetches completed-order count + service counts.
  ///
  /// IMPORTANT: this checks BOTH `orders` and `bookings` collections
  /// (filtered by `artistId`) since different parts of the app were
  /// built against different collection names. Debug prints are left
  /// in on purpose — check the console output once, see which
  /// collection actually returns docs for your artist account, and
  /// then you can delete the unused branch.
  Future<void> fetchStats() async {
    final uid = AuthController.to.currentUserId;
    if (uid == null) {
      debugPrint('[Stats] No uid found — user not authenticated yet.');
      return;
    }
    try {
      isLoadingStats.value = true;
      int completedCount = 0;

      // ── Try "orders" collection ──────────────────────────────
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('artistId', isEqualTo: uid)
          .get();
      debugPrint(
          '[Stats] orders collection: ${ordersSnap.docs.length} docs for artistId=$uid');
      completedCount += ordersSnap.docs
          .where((d) => _completedStatuses.contains(d.data()['status']))
          .length;

      // ── Also try "bookings" collection (used elsewhere in app) ─
      final bookingsSnap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('artistId', isEqualTo: uid)
          .get();
      debugPrint(
          '[Stats] bookings collection: ${bookingsSnap.docs.length} docs for artistId=$uid');
      completedCount += bookingsSnap.docs
          .where((d) => _completedStatuses.contains(d.data()['status']))
          .length;

      totalCompletedOrders.value = completedCount;

      if (ordersSnap.docs.isEmpty && bookingsSnap.docs.isEmpty) {
        debugPrint(
            '[Stats] Nothing found in either collection for artistId=$uid. '
            'Check Firestore: field might not be called "artistId", or the '
            'uid stored on the order/booking doc might differ from '
            'AuthController.to.currentUserId.');
      }

      // ── Services ──────────────────────────────────────────────
      final servicesSnap = await FirebaseFirestore.instance
          .collection('services')
          .where('artistId', isEqualTo: uid)
          .get();
      totalServices.value = servicesSnap.docs.length;
      activeServices.value = servicesSnap.docs
          .where((d) => (d.data()['status'] ?? '') == 'active')
          .length;
      draftServices.value = servicesSnap.docs
          .where((d) => (d.data()['status'] ?? '') == 'draft')
          .length;
    } catch (e) {
      debugPrint('[Stats] fetch error: $e');
      // Non-fatal — stats simply show as 0, profile itself still loads.
    } finally {
      isLoadingStats.value = false;
    }
  }

  // ───────────────────────────────────────────────────────────
  //  SPECIALIZATIONS (RxList — safe to manipulate directly, but these
  //  helpers are kept for convenience / reuse)
  // ───────────────────────────────────────────────────────────

  void addSpecialization(String rawValue,
      {required TextEditingController inputController}) {
    final value = rawValue.trim();
    if (value.isEmpty) return;
    final formatted = value[0].toUpperCase() + value.substring(1);
    if (specializations.contains(formatted)) {
      AppHelpers.showError('Already added');
      return;
    }
    specializations.add(formatted);
    inputController.clear();
  }

  void removeSpecialization(String value) {
    specializations.remove(value);
  }

  // ───────────────────────────────────────────────────────────
  //  UPLOAD PROFILE IMAGE (Cloudinary)
  // ───────────────────────────────────────────────────────────

  Future<void> uploadProfileImage() async {
    final a = artist.value;
    if (a == null) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image == null) return;

      isUploadingImage.value = true;
      final uid = AuthController.to.currentUserId!;

      final bytes = await image.readAsBytes();
      final fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dc58vppqz/image/upload'),
      );
      request.fields['upload_preset'] = 'smartstitch_profile';
      request.files
          .add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);
      final url = jsonData['secure_url'] as String?;

      if (url == null) {
        throw Exception(jsonData['error']?['message'] ?? 'Upload failed');
      }

      await _firebaseService.updateDocument(
        collection: 'artists',
        docId: uid,
        data: {
          'profileImageUrl': url,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      // DIRECT FIX: users collection ko bhi guaranteed update karo,
      // AuthController.currentUser isi se refresh hota hai. Chat service
      // ka sync call kabhi silently fail ho sakta hai, isliye yeh
      // independent write bhi rakh rahe hain.
      try {
        await _firebaseService.updateDocument(
          collection: 'users',
          docId: uid,
          data: {
            'profileImageUrl': url,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      } catch (e) {
        debugPrint('users collection profileImageUrl update failed: $e');
      }

      await ChatService.instance.syncArtistDataToUsersCollection(
        userId: uid,
        profileImageUrl: url,
        name: a.businessName,
      );

      artist.value = a.copyWith(profileImageUrl: url);

      final currentUser = AuthController.to.currentUser.value;
      if (currentUser != null) {
        AuthController.to.currentUser.value =
            currentUser.copyWith(profileImageUrl: url);
      }

      AppHelpers.showSuccess('Profile image updated!');
    } catch (e) {
      debugPrint('Upload error: $e');
      AppHelpers.showError('Failed to upload image. Please try again.');
    } finally {
      isUploadingImage.value = false;
    }
  }
  // ───────────────────────────────────────────────────────────
  //  UPLOAD CNIC IMAGE (Cloudinary)
  // ───────────────────────────────────────────────────────────

  Future<void> uploadCnicImage() async {
    final a = artist.value;
    if (a == null) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return;

      isUploadingImage.value = true;
      final uid = AuthController.to.currentUserId!;

      final bytes = await image.readAsBytes();
      final fileName =
          'cnic_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dc58vppqz/image/upload'),
      );
      request.fields['upload_preset'] = 'smartstitch_profile';
      request.files
          .add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);
      final url = jsonData['secure_url'] as String?;

      if (url == null) {
        throw Exception(jsonData['error']?['message'] ?? 'Upload failed');
      }

      // Uploading a new CNIC image resets verification — an admin must
      // re-approve.
      await _firebaseService.updateDocument(
        collection: 'artists',
        docId: uid,
        data: {
          'cnicImageUrl': url,
          'isVerified': false,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      artist.value = a.copyWith(cnicImageUrl: url, isVerified: false);

      AppHelpers.showSuccess('CNIC image uploaded! Pending verification.');
    } catch (e) {
      debugPrint('CNIC upload error: $e');
      AppHelpers.showError('Failed to upload CNIC image.');
    } finally {
      isUploadingImage.value = false;
    }
  }

  // ───────────────────────────────────────────────────────────
  //  SAVE PROFILE CHANGES
  //  (now takes the edited values in directly instead of reading
  //  from controller-owned TextEditingControllers)
  // ───────────────────────────────────────────────────────────

  Future<void> saveProfile({
    required String businessName,
    required String bio,
    required String cnic,
    required String experience,
    required List<String> specializations,
  }) async {
    if (!_validateForm(
      businessName: businessName,
      bio: bio,
      cnic: cnic,
      experience: experience,
    )) {
      return;
    }

    final a = artist.value;
    if (a == null) return;

    try {
      isSaving.value = true;
      final uid = AuthController.to.currentUserId!;

      final experienceYears = int.tryParse(experience.trim());

      final updatedData = {
        'businessName': businessName.trim(),
        'bio': bio.trim(),
        'cnicNumber': cnic.trim(),
        'specializations': specializations,
        'experienceYears': experienceYears ?? a.experienceYears,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _firebaseService.updateDocument(
        collection: 'artists',
        docId: uid,
        data: updatedData,
      );

      artist.value = a.copyWith(
        businessName: businessName.trim(),
        bio: bio.trim(),
        cnicNumber: cnic.trim(),
        specializations: List<String>.from(specializations),
        experienceYears: experienceYears ?? a.experienceYears,
      );

      Get.back();
      AppHelpers.showSuccess('Profile updated successfully!');
    } catch (e) {
      AppHelpers.showError('Failed to save profile: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ───────────────────────────────────────────────────────────
  //  AVAILABILITY / HOME VISIT TOGGLES (both persisted)
  // ───────────────────────────────────────────────────────────

  Future<void> toggleAvailability() async {
    final a = artist.value;
    if (a == null) return;
    final newValue = !a.isAvailable;

    artist.value = a.copyWith(isAvailable: newValue);
    try {
      final uid = AuthController.to.currentUserId!;
      await _firebaseService.updateDocument(
        collection: 'artists',
        docId: uid,
        data: {
          'isAvailable': newValue,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      AppHelpers.showSuccess(
        newValue ? 'You are now available for orders' : 'You are now offline',
      );
    } catch (e) {
      artist.value = a.copyWith(isAvailable: !newValue);
      AppHelpers.showError('Failed to update availability: $e');
    }
  }

  Future<void> toggleHomeVisit(bool value) async {
    final a = artist.value;
    if (a == null) return;

    artist.value = a.copyWith(offersHomeVisit: value);
    try {
      final uid = AuthController.to.currentUserId!;
      await _firebaseService.updateDocument(
        collection: 'artists',
        docId: uid,
        data: {
          'offersHomeVisit': value,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      artist.value = a.copyWith(offersHomeVisit: !value);
      AppHelpers.showError('Failed to update home visit setting: $e');
    }
  }

  // ───────────────────────────────────────────────────────────
  //  ACCOUNT SETTINGS — EMAIL CHANGE
  // ───────────────────────────────────────────────────────────

  bool validateEmail(String email) {
    return RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
  }

  /// Sends a verification link to the new email. Firebase requires the
  /// user to click that link before the email is actually swapped.
  Future<void> changeEmail(String newEmail) async {
    try {
      isSaving.value = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await user.verifyBeforeUpdateEmail(newEmail);

      Get.back();
      AppHelpers.showSuccess(
        'Verification link sent to $newEmail. Please check your inbox to confirm the change.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        AppHelpers.showError('Please log out and log in again, then retry.');
      } else {
        AppHelpers.showError(e.message ?? 'Failed to change email');
      }
    } catch (e) {
      AppHelpers.showError('Failed to change email: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ───────────────────────────────────────────────────────────
  //  ACCOUNT SETTINGS — PASSWORD CHANGE
  // ───────────────────────────────────────────────────────────

  bool validatePassword(String password) {
    return password.length >= 6;
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      isSaving.value = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Not authenticated');
      }

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);

      Get.back();
      AppHelpers.showSuccess('Password changed successfully!');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        AppHelpers.showError('Current password is incorrect');
      } else {
        AppHelpers.showError(e.message ?? 'Failed to change password');
      }
    } catch (e) {
      AppHelpers.showError('Failed to change password: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ───────────────────────────────────────────────────────────
  //  VALIDATION
  // ───────────────────────────────────────────────────────────

  bool _validateForm({
    required String businessName,
    required String bio,
    required String cnic,
    required String experience,
  }) {
    businessName = businessName.trim();
    bio = bio.trim();
    cnic = cnic.trim();
    experience = experience.trim();

    if (businessName.isEmpty) {
      AppHelpers.showError('Please enter business name');
      return false;
    }
    if (businessName.length > businessNameMaxLength) {
      AppHelpers.showError(
          'Business name must be under $businessNameMaxLength characters');
      return false;
    }
    if (bio.isEmpty) {
      AppHelpers.showError('Please enter bio');
      return false;
    }
    if (bio.length > bioMaxLength) {
      AppHelpers.showError('Bio must be under $bioMaxLength characters');
      return false;
    }
    if (cnic.isEmpty) {
      AppHelpers.showError('Please enter CNIC number');
      return false;
    }
    if (!RegExp(r'^\d{5}-\d{7}-\d{1}$').hasMatch(cnic)) {
      AppHelpers.showError('CNIC must be in format 12345-1234567-1');
      return false;
    }
    if (experience.isNotEmpty && int.tryParse(experience) == null) {
      AppHelpers.showError('Experience must be a number');
      return false;
    }
    return true;
  }

  // ───────────────────────────────────────────────────────────
  //  DISPOSE
  //  (nothing to dispose here anymore — all TextEditingControllers
  //  are now owned locally by the widgets that use them)
  // ───────────────────────────────────────────────────────────

  @override
  void onClose() {
    super.onClose();
  }
}