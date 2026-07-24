import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/core/utils/measurement_calculator.dart';
import 'package:smartstitch/core/utils/measurement_validator.dart';
import 'package:smartstitch/models/body_measurement_model.dart';
import 'package:smartstitch/models/clothing_type.dart';
import 'package:smartstitch/models/measurement_field.dart';
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

  /// Step 1 of the measurement flow — "What would you like to stitch?".
  /// Every subsequent action (AI scan, manual entry) is scoped to this
  /// selection so the customer is never asked for irrelevant fields.
  final Rx<ClothingType?> selectedClothingType = Rx<ClothingType?>(null);

  /// Only used while [selectedClothingType] is [ClothingType.custom] — the
  /// fields the customer picked from the checklist.
  final RxSet<MeasurementField> customSelectedFields = <MeasurementField>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  @override
  void onClose() {
    super.onClose();
  }

  // ─── Clothing type selection ────────────────────────────────────────────
  void selectClothingType(ClothingType type) {
    selectedClothingType.value = type;
    if (type != ClothingType.custom) {
      customSelectedFields.clear();
    }
  }

  void setCustomFields(Set<MeasurementField> fields) {
    customSelectedFields
      ..clear()
      ..addAll(fields);
  }

  void resetClothingTypeSelection() {
    selectedClothingType.value = null;
    customSelectedFields.clear();
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
      final clothingType = selectedClothingType.value ?? ClothingType.custom;
      final aiMeasurement = BodyMeasurementModel(
        id: const Uuid().v4(),
        userId: uid,
        clothingType: clothingType,
        height: measurements.height.value,
        chest: measurements.chest.value,
        waist: measurements.waist.value,
        shoulder: measurements.shoulder.value,
        hips: measurements.hips.value,
        sleevLength: measurements.sleevLength.value,
        inseam: measurements.inseam.value,
        neck: measurements.neck.value,
        customFields: clothingType == ClothingType.custom
            ? customSelectedFields.toList()
            : null,
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
    final json = m.toJson();

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
      final clothingType =
          model.clothingType != ClothingType.custom || selectedClothingType.value == null
              ? model.clothingType
              : selectedClothingType.value!;
      final m = BodyMeasurementModel(
        id: model.id,
        userId: uid,
        clothingType: clothingType,
        height: model.height,
        chest: model.chest,
        waist: model.waist,
        shoulder: model.shoulder,
        hips: model.hips,
        sleevLength: model.sleevLength,
        inseam: model.inseam,
        neck: model.neck,
        wrist: model.wrist,
        shirtLength: model.shirtLength,
        outseam: model.outseam,
        thigh: model.thigh,
        knee: model.knee,
        bottomWidth: model.bottomWidth,
        trouserLength: model.trouserLength,
        customFields: clothingType == ClothingType.custom
            ? (model.customFields ?? customSelectedFields.toList())
            : null,
        aiAccuracyScore: model.aiAccuracyScore,
        isAiGenerated: true,
        measuredAt: model.measuredAt,
      );
      final json = m.toJson();
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
  /// Clothing-type aware manual save. [rawValues] holds the raw text typed
  /// into each field's input — validation (required/numeric/>0/range) runs
  /// here so invalid data is never written to Firestore, no matter which
  /// screen called this.
  Future<void> saveManualMeasurement({
    required ClothingType clothingType,
    required Map<MeasurementField, String> rawValues,
    Set<MeasurementField> customFields = const {},
  }) async {
    final errors = MeasurementValidator.validateForm(
      clothingType: clothingType,
      rawValues: rawValues,
      customFields: customFields,
    );
    if (errors.isNotEmpty) {
      AppHelpers.showError(errors.values.first);
      return;
    }

    double? parse(MeasurementField f) =>
        double.tryParse(rawValues[f]?.trim() ?? '');

    try {
      isLoading.value = true;
      final uid = AuthController.to.currentUserId!;
      final measurement = BodyMeasurementModel(
        id: const Uuid().v4(),
        userId: uid,
        clothingType: clothingType,
        height: parse(MeasurementField.height) ?? 0,
        chest: parse(MeasurementField.chest) ?? 0,
        waist: parse(MeasurementField.waist) ?? 0,
        shoulder: parse(MeasurementField.shoulder) ?? 0,
        hips: parse(MeasurementField.hips) ?? 0,
        sleevLength: parse(MeasurementField.sleeveLength) ?? 0,
        inseam: parse(MeasurementField.inseam) ?? 0,
        neck: parse(MeasurementField.neck) ?? 0,
        wrist: parse(MeasurementField.wrist),
        shirtLength: parse(MeasurementField.shirtLength),
        outseam: parse(MeasurementField.outseam),
        thigh: parse(MeasurementField.thigh),
        knee: parse(MeasurementField.knee),
        bottomWidth: parse(MeasurementField.bottomWidth),
        trouserLength: parse(MeasurementField.trouserLength),
        customFields:
            clothingType == ClothingType.custom ? customFields.toList() : null,
        aiAccuracyScore: 0.0,
        isAiGenerated: false,
        measuredAt: DateTime.now(),
      );
      final json = measurement.toJson();
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
  /// Generic update — works for any clothing type since [updated] already
  /// carries its own `clothingType` / `activeFields`.
  Future<void> updateMeasurement(BodyMeasurementModel updated) async {
    try {
      isLoading.value = true;
      final uid = AuthController.to.currentUserId!;
      final json = updated.toJson();
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