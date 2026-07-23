import 'dart:io';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseEstimationResult {
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final double overallConfidence;
  final String? failureReason;

  const PoseEstimationResult({
    required this.landmarks,
    required this.overallConfidence,
    this.failureReason,
  });

  bool get isValid => failureReason == null;
}

class PoseEstimationService {
  // ── Singleton ─────────────────────────────────────────────────────────────
  static final PoseEstimationService _instance =
      PoseEstimationService._internal();
  factory PoseEstimationService() => _instance;
  PoseEstimationService._internal();

  // ── ML Kit detector (accurate mode = better landmarks, a bit slower) ──────
  late final PoseDetector _detector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.single),
  );

  bool _isDisposed = false;

  // ── Required landmarks used to compute measurements ────────────────────────
  static const List<PoseLandmarkType> _requiredLandmarks = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
    PoseLandmarkType.nose,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
  ];

  // ── Main method: detect pose from a captured File image ────────────────────
  Future<PoseEstimationResult> detectFromFile(File imageFile) async {
    if (_isDisposed) {
      return const PoseEstimationResult(
        landmarks: {},
        overallConfidence: 0,
        failureReason: 'Service disposed',
      );
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final poses = await _detector.processImage(inputImage);

      if (poses.isEmpty) {
        return const PoseEstimationResult(
          landmarks: {},
          overallConfidence: 0,
          failureReason: 'No person detected in image',
        );
      }

      final pose = poses.first;
      final landmarks = pose.landmarks;

      // ── Confidence check — average over required landmarks ────────────────
      final confidenceValues = _requiredLandmarks
          .map((type) => landmarks[type]?.likelihood ?? 0.0)
          .toList();

      final avgConfidence =
          confidenceValues.reduce((a, b) => a + b) / confidenceValues.length;

      // ── Missing landmarks check ────────────────────────────────────────────
      final missingLandmarks = _requiredLandmarks
          .where((type) =>
              (landmarks[type]?.likelihood ?? 0) < 0.5) // 50% threshold
          .map((type) => type.name)
          .toList();

      if (missingLandmarks.isNotEmpty) {
        return PoseEstimationResult(
          landmarks: landmarks,
          overallConfidence: avgConfidence,
          failureReason:
              'Body parts not clearly visible: ${missingLandmarks.join(', ')}',
        );
      }

      return PoseEstimationResult(
        landmarks: landmarks,
        overallConfidence: avgConfidence,
      );
    } catch (e) {
      return PoseEstimationResult(
        landmarks: {},
        overallConfidence: 0,
        failureReason: 'Detection error: $e',
      );
    }
  }

  // ── For live stream (camera preview guide overlay) ─────────────────────────
  Future<PoseEstimationResult> detectFromInputImage(
      InputImage inputImage) async {
    if (_isDisposed) {
      return const PoseEstimationResult(
        landmarks: {},
        overallConfidence: 0,
        failureReason: 'Service disposed',
      );
    }

    try {
      final poses = await _detector.processImage(inputImage);
      if (poses.isEmpty) {
        return const PoseEstimationResult(
          landmarks: {},
          overallConfidence: 0,
          failureReason: 'No person detected',
        );
      }

      final landmarks = poses.first.landmarks;
      final confidenceValues = _requiredLandmarks
          .map((type) => landmarks[type]?.likelihood ?? 0.0)
          .toList();
      final avgConfidence =
          confidenceValues.reduce((a, b) => a + b) / confidenceValues.length;

      return PoseEstimationResult(
        landmarks: landmarks,
        overallConfidence: avgConfidence,
      );
    } catch (_) {
      return const PoseEstimationResult(
        landmarks: {},
        overallConfidence: 0,
        failureReason: 'Stream error',
      );
    }
  }

  // ── Memory cleanup — call ONCE, only at true app shutdown, if at all. ──────
  // Do NOT call this from a screen or GetxController's dispose()/onClose().
  void dispose() {
    if (!_isDisposed) {
      _detector.close();
      _isDisposed = true;
    }
  }
}