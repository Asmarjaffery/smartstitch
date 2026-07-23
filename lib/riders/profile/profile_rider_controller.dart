import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/models/rider_model.dart';
import 'package:smartstitch/services/firebase_service.dart';

class RiderProfileController extends GetxController {
  static RiderProfileController get to => Get.find();

  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();

  // ─── Observables ───────────────────────────────────────────────────────
  final Rx<RiderModel?> rider = Rx<RiderModel?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isUploadingImage = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isOnline = false.obs;

  // ─── Text Controllers ──────────────────────────────────────────────────
  late TextEditingController vehicleTypeController;
  late TextEditingController vehicleNumberController;
  late TextEditingController cnicController;

  @override
  void onInit() {
    super.onInit();
    vehicleTypeController = TextEditingController();
    vehicleNumberController = TextEditingController();
    cnicController = TextEditingController();
    _loadRiderData();
  }

  // ─── Public reload (delivery complete ke baad call karo) ──────────────
  Future<void> reloadRiderData() async {
    try {
      final uid = AuthController.to.currentUserId;
      if (uid == null) return;

      final doc = await _firebaseService.getDocument(
        collection: 'riders',
        docId: uid,
      );

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        rider.value = RiderModel.fromJson(data);
        isOnline.value = rider.value?.isOnline ?? false;

        // ✅ Reload deliveries count
        await _loadDeliveriesCount(uid);
      }
    } catch (e) {
      debugPrint('Reload error: $e');
    }
  }

  // ─── Load Rider Data (initial load) ───────────────────────────────────
  Future<void> _loadRiderData() async {
    try {
      isLoading.value = true;
      final uid = AuthController.to.currentUserId;
      if (uid == null) return;

      final doc = await _firebaseService.getDocument(
        collection: 'riders',
        docId: uid,
      );

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        rider.value = RiderModel.fromJson(data);
        _populateControllers();
        isOnline.value = rider.value?.isOnline ?? false;

        // ✅ Load deliveries count
        await _loadDeliveriesCount(uid);

        debugPrint('✅ Rider loaded: ${rider.value?.vehicleType}');
      }
    } catch (e) {
      AppHelpers.showError('Failed to load profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Populate text controllers ─────────────────────────────────────────
  void _populateControllers() {
    if (rider.value != null) {
      vehicleTypeController.text = rider.value!.vehicleType;
      vehicleNumberController.text = rider.value!.vehicleNumber;
      cnicController.text = rider.value!.cnicNumber;
    }
  }

  // ─── Update Personal Info ──────────────────────────────────────────────
  Future<void> updatePersonalInfo({
    required String name,
    required String phone,
  }) async {
    try {
      isSaving.value = true;
      final uid = AuthController.to.currentUserId!;

      await _firebaseService.updateDocument(
        collection: 'users',
        docId: uid,
        data: {
          'name': name,
          'phone': phone,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      final updated = AuthController.to.currentUser.value!.copyWith(
        name: name,
        phone: phone,
      );
      AuthController.to.currentUser.value = updated;
      AppHelpers.showSuccess('Profile updated!');
    } catch (e) {
      AppHelpers.showError('Failed to update profile.');
    } finally {
      isSaving.value = false;
    }
  }

  // ─── Save Vehicle Info ─────────────────────────────────────────────────
  Future<void> saveProfile() async {
    if (vehicleTypeController.text.isEmpty) {
      AppHelpers.showError('Please enter vehicle type');
      return;
    }
    if (vehicleNumberController.text.isEmpty) {
      AppHelpers.showError('Please enter vehicle number');
      return;
    }

    try {
      isSaving.value = true;
      final uid = AuthController.to.currentUserId!;

      await _firebaseService.updateDocument(
        collection: 'riders',
        docId: uid,
        data: {
          'vehicleType': vehicleTypeController.text.trim(),
          'vehicleNumber': vehicleNumberController.text.trim(),
          'cnicNumber': cnicController.text.trim(),
        },
      );

      if (rider.value != null) {
        rider.value = rider.value!.copyWith(
          vehicleType: vehicleTypeController.text.trim(),
          vehicleNumber: vehicleNumberController.text.trim(),
          cnicNumber: cnicController.text.trim(),
        );
      }

      AppHelpers.showSuccess('Vehicle info updated!');
      Get.back();
    } catch (e) {
      AppHelpers.showError('Failed to save vehicle info: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ─── Upload Profile Image ──────────────────────────────────────────────
  Future<void> uploadProfileImage() async {
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

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dc58vppqz/image/upload'),
      );
      request.fields['upload_preset'] = 'smartstitch_profile';
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);
      final url = jsonData['secure_url'];

      if (url == null) {
        throw Exception('Upload failed: ${jsonData['error']?['message']}');
      }

      await _firebaseService.updateDocument(
        collection: 'users',
        docId: uid,
        data: {
          'profileImageUrl': url,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      await _firebaseService.updateDocument(
        collection: 'riders',
        docId: uid,
        data: {'profileImageUrl': url},
      );

      final updated =
          AuthController.to.currentUser.value!.copyWith(profileImageUrl: url);
      AuthController.to.currentUser.value = updated;
      AppHelpers.showSuccess('Profile image updated!');
    } catch (e) {
      debugPrint('Upload error: $e');
      AppHelpers.showError('Failed to upload image.');
    } finally {
      isUploadingImage.value = false;
    }
  }

  // ─── Toggle Online Status ──────────────────────────────────────────────
  Future<void> toggleOnlineStatus() async {
    try {
      final newStatus = !isOnline.value;
      isOnline.value = newStatus;

      await _firebaseService.updateDocument(
        collection: 'riders',
        docId: AuthController.to.currentUserId!,
        data: {
          'isOnline': newStatus,
          'lastSeen': DateTime.now().toIso8601String(),
        },
      );

      if (rider.value != null) {
        rider.value = rider.value!.copyWith(isOnline: newStatus);
      }

      AppHelpers.showSuccess(
          newStatus ? 'You are now online' : 'You are now offline');
    } catch (e) {
      isOnline.value = !isOnline.value;
      AppHelpers.showError('Failed to update status');
    }
  }

  // ─── Toggle Dark Mode ──────────────────────────────────────────────────
  Future<void> toggleDarkMode(bool value) async {
    try {
      Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);

      final uid = AuthController.to.currentUserId!;
      await _firebaseService.updateDocument(
        collection: 'users',
        docId: uid,
        data: {
          'isDarkMode': value,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      final updated =
          AuthController.to.currentUser.value!.copyWith(isDarkMode: value);
      AuthController.to.currentUser.value = updated;
    } catch (e) {
      AppHelpers.showError('Failed to update theme.');
    }
  }

  // ─── Change Language ───────────────────────────────────────────────────
  Future<void> changeLanguage(String langCode) async {
    try {
      final uid = AuthController.to.currentUserId!;

      await _firebaseService.updateDocument(
        collection: 'users',
        docId: uid,
        data: {
          'preferredLanguage': langCode,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      final updated = AuthController.to.currentUser.value!
          .copyWith(preferredLanguage: langCode);
      AuthController.to.currentUser.value = updated;
      AppHelpers.showSuccess('Language updated!');
    } catch (e) {
      AppHelpers.showError('Failed to update language.');
    }
  }

  // ─── Load Deliveries Count ────────────────────────────────────────────
  Future<void> _loadDeliveriesCount(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('riderId', isEqualTo: uid)
          .where('status', isEqualTo: 'delivered')
          .get();

      final count = snap.docs.length;
      debugPrint('📦 Profile deliveries count: $count');

      if (rider.value != null) {
        rider.value = rider.value!.copyWith(totalDeliveries: count);
      }
    } catch (e) {
      debugPrint('❌ Deliveries count error: $e');
    }
  }

  @override
  void onClose() {
    vehicleTypeController.dispose();
    vehicleNumberController.dispose();
    cnicController.dispose();
    super.onClose();
  }
}