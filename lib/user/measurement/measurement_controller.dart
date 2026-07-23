import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/core/utils/measurement_calculator.dart';
import 'package:smartstitch/models/body_measurement_model.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/services/firebase_service.dart';
import 'package:smartstitch/services/pose_estimation_service.dart';
import 'package:uuid/uuid.dart';


class _CalcParams {
  final Map<dynamic, dynamic> landmarks;
  final double knownHeightCm;
  final double imageHeightPx;
  const _CalcParams({
    required this.landmarks,
    required this.knownHeightCm,
    required this.imageHeightPx,
  });
}

class MeasurementController extends GetxController {
  static MeasurementController get to => Get.find();

  final FirebaseService _firebaseService = FirebaseService();
  final PoseEstimationService _poseService = PoseEstimationService();

  final RxList<BodyMeasurementModel> history = <BodyMeasurementModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isAiScanning = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  @override
  void onClose() {
    // NOTE: PoseEstimationService is an app-wide singleton shared with
    // PoseCameraView (and any other screen that uses AI scanning).
    // It must NOT be disposed here — doing so permanently breaks pose
    // detection for every subsequent scan in the app, since `_isDisposed`
    // on the shared instance never resets back to false.
    // _poseService.dispose(); // ❌ removed on purpose
    super.onClose();
  }

  // ─── Load History ──────────────────────────────────────────────────────────
  Future<void> loadHistory() async {
    try {
      isLoading.value = true;
      final uid = AuthController.to.currentUserId!;
      final snapshot = await _firebaseService.firestore
          .collection('measurements')
          .where('userId', isEqualTo: uid)
          .orderBy('measuredAt', descending: true)
          .get();
      history.value = snapshot.docs
          .map((doc) =>
              BodyMeasurementModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      AppHelpers.showError('Failed to load history.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── AI Scan ───────────────────────────────────────────────────────────────
  Future<BodyMeasurementModel?> startAiScan({
    required File imageFile,
    required double knownHeightCm,
  }) async {
    try {
      isAiScanning.value = true;

      final poseResult = await _poseService.detectFromFile(imageFile);

      if (!poseResult.isValid) {
        AppHelpers.showError(poseResult.failureReason!);
        return null;
      }

      final measurements = MeasurementCalculator.calculate(
        landmarks: poseResult.landmarks,
        knownHeightCm: knownHeightCm,
        imageHeightPx: 1920,
      );

      final uid = AuthController.to.currentUserId!;
      final aiMeasurement = BodyMeasurementModel(
        id: const Uuid().v4(),
        userId: uid,
        height: measurements.height.value,
        chest: measurements.chest.value,
        waist: measurements.waist.value,
        shoulder: measurements.shoulder.value,
        hips: measurements.hips.value,
        sleevLength: measurements.sleevLength.value,
        inseam: measurements.inseam.value,
        neck: measurements.neck.value,
        aiAccuracyScore: measurements.overallScore,
        isAiGenerated: true,
        measuredAt: DateTime.now(),
      );

      await _saveAiMeasurement(aiMeasurement);

      AppHelpers.showSuccess(
        'AI scan complete! Accuracy: ${(measurements.overallScore * 100).toInt()}%',
      );
      return aiMeasurement;
    } catch (e) {
      AppHelpers.showError('AI scan failed. Please retake photo.');
      return null;
    } finally {
      isAiScanning.value = false;
    }
  }

  Future<void> _saveAiMeasurement(BodyMeasurementModel m) async {
    final uid = AuthController.to.currentUserId!;
    final json = {...m.toJson(), 'measuredAt': m.measuredAt.toIso8601String()};

    await _firebaseService.firestore
        .collection('measurements')
        .doc(m.id)
        .set(json);

    await _firebaseService.updateDocument(
      collection: 'users',
      docId: uid,
      data: {'savedMeasurements': json, 'updatedAt': DateTime.now().toIso8601String()},
    );

    history.insert(0, m);
    AuthController.to.currentUser.value =
        AuthController.to.currentUser.value?.copyWith(savedMeasurements: m);
  }

  // ─── Save AI Scan Result (from premium scanner) ────────────────────────────
  Future<void> saveAiScanResult(BodyMeasurementModel model) async {
    try {
      isLoading.value = true;
      final uid = AuthController.to.currentUserId!;
      final m = BodyMeasurementModel(
        id: model.id,
        userId: uid,
        height: model.height,
        chest: model.chest,
        waist: model.waist,
        shoulder: model.shoulder,
        hips: model.hips,
        sleevLength: model.sleevLength,
        inseam: model.inseam,
        neck: model.neck,
        aiAccuracyScore: model.aiAccuracyScore,
        isAiGenerated: true,
        measuredAt: model.measuredAt,
      );
      final json = {...m.toJson(), 'measuredAt': m.measuredAt.toIso8601String()};
      await _firebaseService.firestore
          .collection('measurements')
          .doc(m.id)
          .set(json);
      await _firebaseService.updateDocument(
        collection: 'users',
        docId: uid,
        data: {'savedMeasurements': json, 'updatedAt': DateTime.now().toIso8601String()},
      );
      history.insert(0, m);
      AuthController.to.currentUser.value =
          AuthController.to.currentUser.value?.copyWith(savedMeasurements: m);
      AppHelpers.showSuccess(
          'Scan saved! Accuracy: ${(m.aiAccuracyScore * 100).toInt()}%');
    } catch (e) {
      AppHelpers.showError('Failed to save scan result.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Save Manual ───────────────────────────────────────────────────────────
  Future<void> saveManualMeasurement({
    required double height,
    required double chest,
    required double waist,
    required double shoulder,
    required double hips,
    required double sleevLength,
    required double inseam,
    required double neck,
  }) async {
    try {
      isLoading.value = true;
      final uid = AuthController.to.currentUserId!;
      final measurement = BodyMeasurementModel(
        id: const Uuid().v4(),
        userId: uid,
        height: height,
        chest: chest,
        waist: waist,
        shoulder: shoulder,
        hips: hips,
        sleevLength: sleevLength,
        inseam: inseam,
        neck: neck,
        aiAccuracyScore: 0.0,
        isAiGenerated: false,
        measuredAt: DateTime.now(),
      );
      final json = {
        ...measurement.toJson(),
        'measuredAt': measurement.measuredAt.toIso8601String(),
      };
      await _firebaseService.firestore
          .collection('measurements')
          .doc(measurement.id)
          .set(json);
      await _firebaseService.updateDocument(
        collection: 'users',
        docId: uid,
        data: {'savedMeasurements': json, 'updatedAt': DateTime.now().toIso8601String()},
      );
      history.insert(0, measurement);
      AuthController.to.currentUser.value = AuthController.to.currentUser.value
          ?.copyWith(savedMeasurements: measurement);
      AppHelpers.showSuccess('Measurements saved!');
    } catch (e) {
      AppHelpers.showError('Failed to save measurements.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Delete ────────────────────────────────────────────────────────────────
  Future<void> deleteMeasurement(String id) async {
    try {
      await _firebaseService.firestore
          .collection('measurements')
          .doc(id)
          .delete();
      history.removeWhere((m) => m.id == id);
      AppHelpers.showSuccess('Deleted!');
    } catch (e) {
      AppHelpers.showError('Failed to delete.');
    }
  }

  // ─── Update ────────────────────────────────────────────────────────────────
  Future<void> updateMeasurement(BodyMeasurementModel updated) async {
    try {
      isLoading.value = true;
      final uid = AuthController.to.currentUserId!;
      final json = {
        ...updated.toJson(),
        'measuredAt': updated.measuredAt.toIso8601String(),
      };
      await _firebaseService.firestore
          .collection('measurements')
          .doc(updated.id)
          .update(json);
      await _firebaseService.updateDocument(
        collection: 'users',
        docId: uid,
        data: {'savedMeasurements': json, 'updatedAt': DateTime.now().toIso8601String()},
      );
      final index = history.indexWhere((m) => m.id == updated.id);
      if (index != -1) history[index] = updated;
      AuthController.to.currentUser.value = AuthController.to.currentUser.value
          ?.copyWith(savedMeasurements: updated);
      AppHelpers.showSuccess('Measurement updated!');
    } catch (e, stack) {
      debugPrint('❌ $e\n$stack');
      AppHelpers.showError('Failed to update measurement.');
    } finally {
      isLoading.value = false;
    }
  }
}