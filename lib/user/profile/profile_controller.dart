import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/models/address_model.dart';
import 'package:smartstitch/models/body_measurement_model.dart';
import 'package:smartstitch/services/firebase_service.dart';
import 'package:smartstitch/controllers/auth_controller.dart';

class ProfileController extends GetxController {
  static ProfileController get to => Get.find();

  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();

  final RxBool isLoading = false.obs;
  final RxBool isUploadingImage = false.obs;

  // ─── Update Name & Phone ──────────────────────────────────────────────────
  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    try {
      isLoading.value = true;
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

      // Update local user
      final updated = AuthController.to.currentUser.value!.copyWith(
        name: name,
        phone: phone,
      );
      AuthController.to.currentUser.value = updated;
      AppHelpers.showSuccess('Profile updated!');
    } catch (e) {
      AppHelpers.showError('Failed to update profile.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Upload Profile Image ─────────────────────────────────────────────────
  Future<void> uploadProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image == null) return;

      isUploadingImage.value = true;
      final uid = AuthController.to.currentUserId!;

      // Web ke liye bytes use karo
      final bytes = await image.readAsBytes();
      final fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dc58vppqz/image/upload'),
      );

      request.fields['upload_preset'] = 'smartstitch_profile';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
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

      final updated =
          AuthController.to.currentUser.value!.copyWith(profileImageUrl: url);
      AuthController.to.currentUser.value = updated;
      AppHelpers.showSuccess('Profile image updated!');
    } catch (e) {
      print('Upload error: $e');
      AppHelpers.showError('Failed to upload image.');
    } finally {
      isUploadingImage.value = false;
    }
  }

  // ─── Add Address ──────────────────────────────────────────────────────────
  Future<void> addAddress(AddressModel address) async {
    try {
      isLoading.value = true;
      final uid = AuthController.to.currentUserId!;
      final currentAddresses = List<AddressModel>.from(
          AuthController.to.currentUser.value!.addresses);

      if (address.isDefault) {
        for (int i = 0; i < currentAddresses.length; i++) {
          currentAddresses[i] = currentAddresses[i].copyWith(isDefault: false);
        }
      }

      currentAddresses.add(address);

      await _firebaseService.updateDocument(
        collection: 'users',
        docId: uid,
        data: {
          'addresses': currentAddresses.map((e) => e.toJson()).toList(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      final updated = AuthController.to.currentUser.value!
          .copyWith(addresses: currentAddresses);
      AuthController.to.currentUser.value = updated;
      AppHelpers.showSuccess('Address added!');
    } catch (e) {
      AppHelpers.showError('Failed to add address.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Delete Address ───────────────────────────────────────────────────────
  Future<void> deleteAddress(int index) async {
    try {
      isLoading.value = true;
      final uid = AuthController.to.currentUserId!;
      final currentAddresses = List<AddressModel>.from(
          AuthController.to.currentUser.value!.addresses);

      currentAddresses.removeAt(index);

      await _firebaseService.updateDocument(
        collection: 'users',
        docId: uid,
        data: {
          'addresses': currentAddresses.map((e) => e.toJson()).toList(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      final updated = AuthController.to.currentUser.value!
          .copyWith(addresses: currentAddresses);
      AuthController.to.currentUser.value = updated;
      AppHelpers.showSuccess('Address removed!');
    } catch (e) {
      AppHelpers.showError('Failed to delete address.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Save Measurements ────────────────────────────────────────────────────
  Future<void> saveMeasurements(BodyMeasurementModel measurements) async {
    try {
      isLoading.value = true;
      final uid = AuthController.to.currentUserId!;

      debugPrint('🔵 saveMeasurements called, uid: $uid');

      // toJson() ki copy banao aur measuredAt ko String karo
      final measurementJson = {
        ...measurements.toJson(),
        'measuredAt': measurements.measuredAt
            .toIso8601String(), // ← Timestamp nahi, String
      };

      debugPrint('🔵 measurementJson: $measurementJson');

      await _firebaseService.updateDocument(
        collection: 'users',
        docId: uid,
        data: {
          'savedMeasurements': measurementJson,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ Firestore update success!');

      final updated = AuthController.to.currentUser.value!
          .copyWith(savedMeasurements: measurements);
      AuthController.to.currentUser.value = updated;
      AppHelpers.showSuccess('Measurements saved!');
    } catch (e, stack) {
      debugPrint('❌ saveMeasurements ERROR: $e');
      debugPrint('❌ STACK: $stack');
      AppHelpers.showError('Failed to save measurements.');
    } finally {
      isLoading.value = false;
    }
  }

// ─── Toggle Dark Mode ─────────────────────────────────────────────────────
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

// ─── Change Language ──────────────────────────────────────────────────────
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
}
