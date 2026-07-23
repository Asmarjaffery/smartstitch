import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/utils/measurement_calculator.dart';
import 'package:smartstitch/core/widgets/ai_body_overlay.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/services/pose_estimation_service.dart';

// ─── Scan phases ─────────────────────────────────────────────────────────────
enum ScannerPhase {
  initializing,
  guiding,
  locking,
  capturing,
  processing,
  complete,
}

// ─── Pose issue ───────────────────────────────────────────────────────────────
enum PoseIssue {
  notStanding,
  crossedArms,
  crossedLegs,
  bentKnees,
  headTilt,
  bodyRotation,
  missingFeet,
  missingShoulders,
  tooFar,
  tooClose,
  badLighting,
  blurry,
  lowCameraQuality,
}

extension PoseIssueMessage on PoseIssue {
  String get message {
    switch (this) {
      case PoseIssue.notStanding:      return 'Stand straight facing the camera';
      case PoseIssue.crossedArms:      return 'Keep your arms relaxed at your sides';
      case PoseIssue.crossedLegs:      return 'Keep feet shoulder-width apart';
      case PoseIssue.bentKnees:        return 'Straighten your knees';
      case PoseIssue.headTilt:         return 'Keep your head straight';
      case PoseIssue.bodyRotation:     return 'Face directly towards the camera';
      case PoseIssue.missingFeet:      return 'Step back so your full body is visible';
      case PoseIssue.missingShoulders: return 'Make sure your shoulders are visible';
      case PoseIssue.tooFar:           return 'Move closer to the camera';
      case PoseIssue.tooClose:         return 'Step back a little';
      case PoseIssue.badLighting:      return 'Find a brighter, evenly lit area';
      case PoseIssue.blurry:           return 'Hold still — camera is refocusing';
      case PoseIssue.lowCameraQuality: return 'Use a higher resolution camera';
    }
  }
}

// ─── AI Scan result (17 measurements) ────────────────────────────────────────
class AiMeasurementValue {
  final double value;
  final double confidence;
  final String quality;

  const AiMeasurementValue({
    required this.value,
    required this.confidence,
    required this.quality,
  });

  String get formatted => '${value.toStringAsFixed(1)} cm';
}

class AiScanResult {
  final String id;
  final DateTime capturedAt;
  final double overallConfidence;
  final String scanQuality;

  final AiMeasurementValue height;
  final AiMeasurementValue shoulder;
  final AiMeasurementValue chest;
  final AiMeasurementValue waist;
  final AiMeasurementValue hip;
  final AiMeasurementValue neck;
  final AiMeasurementValue sleeve;
  final AiMeasurementValue armLength;
  final AiMeasurementValue bicep;
  final AiMeasurementValue forearm;
  final AiMeasurementValue thigh;
  final AiMeasurementValue knee;
  final AiMeasurementValue calf;
  final AiMeasurementValue inseam;
  final AiMeasurementValue outseam;
  final AiMeasurementValue backLength;
  final AiMeasurementValue frontLength;

  const AiScanResult({
    required this.id,
    required this.capturedAt,
    required this.overallConfidence,
    required this.scanQuality,
    required this.height,
    required this.shoulder,
    required this.chest,
    required this.waist,
    required this.hip,
    required this.neck,
    required this.sleeve,
    required this.armLength,
    required this.bicep,
    required this.forearm,
    required this.thigh,
    required this.knee,
    required this.calf,
    required this.inseam,
    required this.outseam,
    required this.backLength,
    required this.frontLength,
  });

  Map<String, AiMeasurementValue> get allMeasurements => {
        'Height': height,
        'Shoulder': shoulder,
        'Chest': chest,
        'Waist': waist,
        'Hip': hip,
        'Neck': neck,
        'Sleeve': sleeve,
        'Arm Length': armLength,
        'Bicep': bicep,
        'Forearm': forearm,
        'Thigh': thigh,
        'Knee': knee,
        'Calf': calf,
        'Inseam': inseam,
        'Outseam': outseam,
        'Back Length': backLength,
        'Front Length': frontLength,
      };

  String get recommendedShirtSize {
    final c = chest.value;
    if (c < 86) return 'XS';
    if (c < 92) return 'S';
    if (c < 98) return 'M';
    if (c < 106) return 'L';
    if (c < 114) return 'XL';
    return 'XXL';
  }

  String get recommendedPantSize {
    final w = waist.value;
    if (w < 68) return '28';
    if (w < 74) return '30';
    if (w < 80) return '32';
    if (w < 86) return '34';
    if (w < 92) return '36';
    return '38+';
  }
}

// ─── Scanner Controller ───────────────────────────────────────────────────────
class AiScannerController extends GetxController {
  static AiScannerController get to => Get.find();

  // ── Public observables ────────────────────────────────────────────────────
  final phase          = ScannerPhase.initializing.obs;
  final confidence     = 0.0.obs;
  final lightingScore  = 0.8.obs;
  final blurScore      = 0.9.obs;
  final alignmentScore = 0.0.obs;
  final distanceScore  = 0.0.obs;

  final guidanceMessage  = 'Initializing AI Scanner...'.obs;
  final primaryIssue     = Rxn<PoseIssue>();

  final scanProgress    = 0.0.obs;
  final pulseValue      = 0.0.obs;
  final autoCountdown   = 3.obs;
  final isAutoCapturing = false.obs;

  final skeletonPoints = <SkeletonPoint>[].obs;
  final skeletonBones  = <SkeletonBone>[].obs;

  final processingProgress = 0.0.obs;
  final processingStep     = ''.obs;

  final isCameraReady = false.obs;
  final cameraError   = Rxn<String>();
  final scanError     = Rxn<String>();

  AiScanResult? result;

  // Completes when the visual processing animation finishes its minimum
  // run (~4.2s). _captureAndProcess awaits this too, so navigation never
  // fires before either (a) the real async work finishes AND (b) the
  // animation has played out — whichever takes longer.
  Future<void> _processingAnimationDone = Future.value();

  // ── Camera / ML Kit ───────────────────────────────────────────────────────
  CameraController? _cameraCtrl;
  CameraController? get cameraController => _cameraCtrl;

  final _poseService = PoseEstimationService();
  bool _isProcessingFrame = false;
  DateTime _lastFrameTime = DateTime.now();
  Size _previewDisplaySize = const Size(1, 1);

  // Known height from route arguments
  double _knownHeightCm = 170.0;

  // ── Animation timers (used in simulation / always) ────────────────────────
  Timer? _scanLineTimer;
  Timer? _autoCapturTimer;
  Timer? _processingTimer;
  Timer? _skeletonSimTimer; // only on web
  Timer? _pulseTimer;

  final _rng = math.Random();
  double _wobblePhase = 0.0;

  // Camera always attempted; ML Kit only on native
  bool get _useRealCamera => true;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _knownHeightCm = (Get.arguments as double?) ?? 170.0;
    _startAnimations();
    _initCamera(); // tries real camera on all platforms; falls back to simulation
  }

  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }

  // ─── Camera initialisation (native only) ─────────────────────────────────
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        cameraError.value = 'No camera found on this device.';
        _initSimulation(); // fallback
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraCtrl = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: kIsWeb
            ? null
            : (Platform.isAndroid
                ? ImageFormatGroup.nv21
                : ImageFormatGroup.bgra8888),
      );

      await _cameraCtrl!.initialize();

      // Store display-oriented preview dimensions
      final prev = _cameraCtrl!.value.previewSize!;
      // On most phones camera is landscape internally; portrait display = swap
      _previewDisplaySize = Size(prev.height, prev.width);

      if (!kIsWeb) {
        await _cameraCtrl!.startImageStream(_processCameraFrame);
      } else {
        // Web: real camera preview + simulated skeleton via timer
        _skeletonSimTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
          if (!isClosed) _runWebSimulationTick();
        });
      }

      isCameraReady.value = true;
      phase.value = ScannerPhase.guiding;
      guidanceMessage.value = 'Stand straight, arms at your sides';
    } catch (e) {
      debugPrint('❌ Camera init: $e');
      cameraError.value = 'Camera unavailable — using simulation mode.';
      _initSimulation();
    }
  }

  // ─── Live frame processing ────────────────────────────────────────────────
  Future<void> _processCameraFrame(CameraImage image) async {
    if (_isProcessingFrame) return;
    if (phase.value == ScannerPhase.processing ||
        phase.value == ScannerPhase.complete ||
        phase.value == ScannerPhase.capturing) return;

    // Throttle to ~8 fps to stay smooth
    if (DateTime.now().difference(_lastFrameTime).inMilliseconds < 120) return;
    _lastFrameTime = DateTime.now();
    _isProcessingFrame = true;

    try {
      // ML Kit not available on web — run simulation skeleton over real preview
      if (kIsWeb) {
        _runWebSimulationTick();
        return;
      }

      final inputImage = _toInputImage(image, _cameraCtrl!.description);
      if (inputImage == null) return;

      final poseResult = await _poseService.detectFromInputImage(inputImage);

      if (!isClosed) {
        if (poseResult.landmarks.isNotEmpty) {
          _updateFromRealLandmarks(poseResult.landmarks, poseResult.overallConfidence);
        }
        lightingScore.value = 0.78 + _rng.nextDouble() * 0.18;
        blurScore.value     = 0.82 + _rng.nextDouble() * 0.15;
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  // Web: real camera preview but simulated skeleton overlay
  void _runWebSimulationTick() {
    _wobblePhase += 0.04;
    final wx = math.sin(_wobblePhase) * 0.005;
    final wy = math.cos(_wobblePhase * 0.7) * 0.003;

    double targetConf = phase.value == ScannerPhase.guiding
        ? 0.65 + _rng.nextDouble() * 0.08
        : 0.82 + _rng.nextDouble() * 0.06;

    confidence.value += (targetConf - confidence.value) * 0.08;

    final pts = buildDefaultSkeleton(
        confidence: confidence.value, wobbleX: wx, wobbleY: wy);
    skeletonPoints.value = pts;
    skeletonBones.value  = buildDefaultBones(pts, confidence: confidence.value);

    lightingScore.value  = 0.80 + _rng.nextDouble() * 0.15;
    blurScore.value      = 0.84 + _rng.nextDouble() * 0.12;
    alignmentScore.value = 0.75 + _rng.nextDouble() * 0.15;
    distanceScore.value  = 0.82 + _rng.nextDouble() * 0.12;

    if (phase.value == ScannerPhase.guiding && confidence.value > 0.80) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!isClosed && phase.value == ScannerPhase.guiding) {
          phase.value = ScannerPhase.locking;
          guidanceMessage.value = 'Perfect! Hold still...';
          _startAutoCapture();
        }
      });
    }
  }

  void _updateFromRealLandmarks(
    Map<PoseLandmarkType, PoseLandmark> lm,
    double conf,
  ) {
    confidence.value += (conf - confidence.value) * 0.15;

    // Convert ML Kit pixel coords → normalized SkeletonPoints
    final pts = _landmarksToSkeleton(lm);
    skeletonPoints.value = pts;
    skeletonBones.value  = buildDefaultBones(pts, confidence: conf);

    alignmentScore.value = _computeAlignmentScore(lm);
    distanceScore.value  = _computeDistanceScore(lm);

    // Determine guidance
    final issue = _detectPrimaryIssue(lm, conf);
    primaryIssue.value = issue;
    guidanceMessage.value = issue?.message ?? (conf > 0.80
        ? 'Perfect! Hold still...'
        : 'Stand straight, arms at your sides');

    // Auto-advance phase
    if (phase.value == ScannerPhase.guiding && conf > 0.80) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!isClosed && phase.value == ScannerPhase.guiding && confidence.value > 0.78) {
          phase.value = ScannerPhase.locking;
          guidanceMessage.value = 'Perfect! Hold still...';
          _startAutoCapture();
        }
      });
    }
  }

  // ─── Landmark → SkeletonPoint conversion ──────────────────────────────────
  List<SkeletonPoint> _landmarksToSkeleton(
      Map<PoseLandmarkType, PoseLandmark> lm) {
    SkeletonPoint pt(PoseLandmarkType type, {bool key = false}) {
      final l = lm[type];
      if (l == null) return SkeletonPoint(x: 0, y: 0, confidence: 0);
      return SkeletonPoint(
        x: (l.x / _previewDisplaySize.width).clamp(0.0, 1.0),
        y: (l.y / _previewDisplaySize.height).clamp(0.0, 1.0),
        confidence: l.likelihood,
        isKeyJoint: key,
      );
    }

    return [
      pt(PoseLandmarkType.nose, key: true),
      pt(PoseLandmarkType.leftEye),
      pt(PoseLandmarkType.rightEye),
      pt(PoseLandmarkType.leftEar),
      pt(PoseLandmarkType.rightEar),
      pt(PoseLandmarkType.leftShoulder, key: true),
      pt(PoseLandmarkType.rightShoulder, key: true),
      pt(PoseLandmarkType.leftElbow),
      pt(PoseLandmarkType.rightElbow),
      pt(PoseLandmarkType.leftWrist),
      pt(PoseLandmarkType.rightWrist),
      pt(PoseLandmarkType.leftHip, key: true),
      pt(PoseLandmarkType.rightHip, key: true),
      pt(PoseLandmarkType.leftKnee),
      pt(PoseLandmarkType.rightKnee),
      pt(PoseLandmarkType.leftAnkle, key: true),
      pt(PoseLandmarkType.rightAnkle, key: true),
    ];
  }

  // ─── Pose quality helpers ─────────────────────────────────────────────────
  double _computeAlignmentScore(Map<PoseLandmarkType, PoseLandmark> lm) {
    final ls = lm[PoseLandmarkType.leftShoulder];
    final rs = lm[PoseLandmarkType.rightShoulder];
    if (ls == null || rs == null) return 0.5;
    final dy = (ls.y - rs.y).abs() / _previewDisplaySize.height;
    return (1.0 - dy * 10).clamp(0.0, 1.0);
  }

  double _computeDistanceScore(Map<PoseLandmarkType, PoseLandmark> lm) {
    final ls = lm[PoseLandmarkType.leftShoulder];
    final rs = lm[PoseLandmarkType.rightShoulder];
    if (ls == null || rs == null) return 0.5;
    final ratio = (rs.x - ls.x).abs() / _previewDisplaySize.width;
    if (ratio < 0.10) return (ratio / 0.10).clamp(0.0, 1.0);
    if (ratio > 0.55) return (1.0 - (ratio - 0.55) / 0.45).clamp(0.0, 1.0);
    return 1.0;
  }

  PoseIssue? _detectPrimaryIssue(
      Map<PoseLandmarkType, PoseLandmark> lm, double conf) {
    bool vis(PoseLandmarkType t) => (lm[t]?.likelihood ?? 0) > 0.5;

    if (!vis(PoseLandmarkType.leftShoulder) ||
        !vis(PoseLandmarkType.rightShoulder)) return PoseIssue.missingShoulders;
    if (!vis(PoseLandmarkType.leftAnkle) ||
        !vis(PoseLandmarkType.rightAnkle)) return PoseIssue.missingFeet;

    final dist = _computeDistanceScore(lm);
    if (dist < 0.4) return PoseIssue.tooFar;
    if (dist < 0.6 && dist > 0.95) return PoseIssue.tooClose;

    if (_computeAlignmentScore(lm) < 0.6) return PoseIssue.bodyRotation;
    return null;
  }

  // ─── InputImage conversion (camera stream → ML Kit) ──────────────────────
  InputImage? _toInputImage(CameraImage img, CameraDescription cam) {
    try {
      final rotation = InputImageRotationValue.fromRawValue(cam.sensorOrientation)
          ?? InputImageRotation.rotation0deg;
      final format = InputImageFormatValue.fromRawValue(img.format.raw);
      if (format == null) return null;

      final bytes = img.planes.length == 1
          ? img.planes.first.bytes
          : _concatPlanes(img.planes);

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(img.width.toDouble(), img.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: img.planes.first.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Uint8List _concatPlanes(List<Plane> planes) {
    final builder = BytesBuilder();
    for (final p in planes) builder.add(p.bytes);
    return builder.toBytes();
  }

  // ─── Web simulation (fallback) ────────────────────────────────────────────
  Future<void> _initSimulation() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (isClosed) return;
    phase.value = ScannerPhase.guiding;
    guidanceMessage.value = 'Stand straight, arms at your sides';
    _startSkeletonSimulation();
  }

  void _startSkeletonSimulation() {
    _skeletonSimTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (phase.value == ScannerPhase.processing ||
          phase.value == ScannerPhase.complete) return;

      _wobblePhase += 0.04;
      final wx = math.sin(_wobblePhase) * 0.005;
      final wy = math.cos(_wobblePhase * 0.7) * 0.003;

      double targetConf;
      switch (phase.value) {
        case ScannerPhase.initializing: targetConf = 0.0;
        case ScannerPhase.guiding:      targetConf = 0.65 + _rng.nextDouble() * 0.08;
        case ScannerPhase.locking:      targetConf = 0.82 + _rng.nextDouble() * 0.06;
        case ScannerPhase.capturing:    targetConf = 0.92 + _rng.nextDouble() * 0.06;
        default:                        targetConf = 0.95;
      }

      confidence.value += (targetConf - confidence.value) * 0.08;

      final pts = buildDefaultSkeleton(
          confidence: confidence.value, wobbleX: wx, wobbleY: wy);
      skeletonPoints.value = pts;
      skeletonBones.value  = buildDefaultBones(pts, confidence: confidence.value);

      if (phase.value == ScannerPhase.guiding) {
        lightingScore.value  = 0.78 + _rng.nextDouble() * 0.15;
        blurScore.value      = 0.82 + _rng.nextDouble() * 0.15;
        alignmentScore.value = 0.70 + _rng.nextDouble() * 0.15;
        distanceScore.value  = 0.80 + _rng.nextDouble() * 0.10;

        if (confidence.value > 0.80) {
          Future.delayed(const Duration(seconds: 2), () {
            if (!isClosed && phase.value == ScannerPhase.guiding) {
              phase.value = ScannerPhase.locking;
              guidanceMessage.value = 'Perfect! Hold still...';
              _startAutoCapture();
            }
          });
        }
      } else if (phase.value == ScannerPhase.locking) {
        lightingScore.value  = 0.88 + _rng.nextDouble() * 0.10;
        blurScore.value      = 0.90 + _rng.nextDouble() * 0.08;
        alignmentScore.value = 0.85 + _rng.nextDouble() * 0.12;
        distanceScore.value  = 0.88 + _rng.nextDouble() * 0.10;
      }
    });
  }

  // ─── Animations ───────────────────────────────────────────────────────────
  void _startAnimations() {
    _scanLineTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (phase.value == ScannerPhase.processing) return;
      scanProgress.value = (scanProgress.value + 0.004) % 1.0;
    });

    double pulsePhase = 0.0;
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      pulsePhase += 0.05;
      pulseValue.value = (math.sin(pulsePhase) + 1) / 2;
    });
  }

  // ─── Auto capture ─────────────────────────────────────────────────────────
  void _startAutoCapture() {
    _cancelAutoCapture();
    autoCountdown.value   = 3;
    isAutoCapturing.value = true;

    _autoCapturTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (autoCountdown.value > 1) {
        autoCountdown.value--;
      } else {
        t.cancel();
        _triggerCapture();
      }
    });
  }

  void _cancelAutoCapture() {
    _autoCapturTimer?.cancel();
    isAutoCapturing.value = false;
    autoCountdown.value   = 3;
  }

  void _triggerCapture() {
    phase.value           = ScannerPhase.capturing;
    isAutoCapturing.value = false;
    Future.delayed(const Duration(milliseconds: 400), _captureAndProcess);
  }

  // ─── Capture & process ────────────────────────────────────────────────────
  // IMPORTANT: this used to be fire-and-forget while a fixed 4.2s animation
  // timer independently called _completeProcessing(), which filled in a
  // *fake* simulated result via "result ??= _buildSimulatedResult()" any
  // time real capture + pose detection took longer than 4.2s (very common
  // on real devices, especially the first ML Kit inference). It also
  // silently swapped in fake data whenever poseResult.isValid was false,
  // with no error shown to the user. Both are fixed below: we now properly
  // await the real work, only use simulation on non-native platforms, and
  // surface a real error + let the user retry on native failures instead
  // of faking a result.
  Future<void> _captureAndProcess() async {
    phase.value = ScannerPhase.processing;
    scanError.value = null;
    _startProcessingAnimation();

    bool success = false;

    if (_useRealCamera && _cameraCtrl != null && isCameraReady.value && !kIsWeb) {
      try {
        await _cameraCtrl!.stopImageStream();
        final xFile = await _cameraCtrl!.takePicture();
        final imageFile = File(xFile.path);

        final poseResult = await _poseService
            .detectFromFile(imageFile)
            .timeout(const Duration(seconds: 20));

        if (poseResult.isValid) {
          final m = MeasurementCalculator.calculate(
            landmarks: poseResult.landmarks,
            knownHeightCm: _knownHeightCm,
            imageHeightPx: _previewDisplaySize.height,
          );
          result = _buildRealResult(m, poseResult.overallConfidence);
          success = true;
        } else {
          scanError.value = poseResult.failureReason ??
              'Could not detect your pose clearly. Please retake the photo.';
        }
      } on TimeoutException {
        scanError.value = 'Scan took too long. Please try again.';
      } catch (e) {
        debugPrint('❌ Capture error: $e');
        scanError.value = 'Capture failed. Please try again.';
      }
    } else if (kIsWeb) {
      // ML Kit pose detection has no web implementation — simulation is the
      // *expected* path here, not a silent fallback.
      result = _buildSimulatedResult();
      success = true;
    } else {
      // Native platform but the real pipeline wasn't usable (camera not
      // ready yet, controller null, etc.) — this must NOT silently fake a
      // result. Surface it as a real error instead.
      scanError.value = cameraError.value ??
          'Camera is not ready yet. Please wait a moment and try again.';
    }

    // Let the visual processing animation finish its minimum run so the
    // UI doesn't feel like it snapped instantly, then act on the real
    // outcome (this is what used to race against the fixed timer).
    await _processingAnimationDone;
    _processingTimer?.cancel();

    if (isClosed) return;

    if (success) {
      _completeProcessing();
    } else {
      _failProcessing();
    }
  }

  void _startProcessingAnimation() {
    final steps = [
      'Analyzing body contours...',
      'Detecting pose landmarks...',
      'Calibrating pixel scale...',
      'Computing shoulder width...',
      'Measuring torso dimensions...',
      'Calculating arm measurements...',
      'Processing leg measurements...',
      'Applying AI refinements...',
      'Validating measurements...',
      'Generating your profile...',
    ];

    int stepIdx = 0;
    processingProgress.value = 0.0;
    processingStep.value     = steps[0];

    final completer = Completer<void>();
    _processingAnimationDone = completer.future;

    _processingTimer = Timer.periodic(const Duration(milliseconds: 420), (t) {
      processingProgress.value += 0.10;
      stepIdx = (stepIdx + 1).clamp(0, steps.length - 1);
      processingStep.value = steps[stepIdx];

      if (processingProgress.value >= 1.0) {
        t.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });
  }

  void _completeProcessing() {
    phase.value = ScannerPhase.complete;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (isClosed) return;
      Get.toNamed(AppRoutes.aiMeasurementResult, arguments: result);
    });
  }

  void _failProcessing() {
    result = null;
    Get.snackbar(
      'Scan failed',
      scanError.value ?? 'Could not complete the scan. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
    );
    phase.value = ScannerPhase.guiding;
    guidanceMessage.value = 'Stand straight, arms at your sides';
  }

  // ─── Build real result from ML Kit measurements ───────────────────────────
  AiScanResult _buildRealResult(CalculatedMeasurements m, double poseConf) {
    AiMeasurementValue fromMwc(MeasurementWithConfidence mwc) {
      final q = mwc.confidence >= 0.85
          ? 'excellent'
          : mwc.confidence >= 0.70
              ? 'good'
              : 'fair';
      return AiMeasurementValue(
          value: double.parse(mwc.value.toStringAsFixed(1)),
          confidence: mwc.confidence,
          quality: q);
    }

    AiMeasurementValue est(double val, double conf) {
      final q = conf >= 0.85
          ? 'excellent'
          : conf >= 0.70
              ? 'good'
              : 'fair';
      return AiMeasurementValue(
          value: double.parse(val.toStringAsFixed(1)),
          confidence: conf,
          quality: q);
    }

    final scanQuality = poseConf >= 0.85
        ? 'excellent'
        : poseConf >= 0.70
            ? 'good'
            : 'fair';

    return AiScanResult(
      id:                'ai_${DateTime.now().millisecondsSinceEpoch}',
      capturedAt:        DateTime.now(),
      overallConfidence: poseConf,
      scanQuality:       scanQuality,
      height:      fromMwc(m.height),
      shoulder:    fromMwc(m.shoulder),
      chest:       fromMwc(m.chest),
      waist:       fromMwc(m.waist),
      hip:         fromMwc(m.hips),
      neck:        fromMwc(m.neck),
      sleeve:      fromMwc(m.sleevLength),
      armLength:   est(m.sleevLength.value * 0.98,  m.sleevLength.confidence * 0.90),
      bicep:       est(m.shoulder.value   * 0.72,   poseConf * 0.85),
      forearm:     est(m.shoulder.value   * 0.60,   poseConf * 0.82),
      thigh:       est(m.hips.value       * 0.60,   poseConf * 0.84),
      knee:        est(m.hips.value       * 0.38,   poseConf * 0.82),
      calf:        est(m.hips.value       * 0.36,   poseConf * 0.82),
      inseam:      fromMwc(m.inseam),
      outseam:     est(m.inseam.value     * 1.30,   m.inseam.confidence * 0.90),
      backLength:  est(m.height.value     * 0.257,  poseConf * 0.87),
      frontLength: est(m.height.value     * 0.252,  poseConf * 0.86),
    );
  }

  // ─── Simulation fallback result ───────────────────────────────────────────
  AiScanResult _buildSimulatedResult() {
    AiMeasurementValue mv(double base, double variance, {double c = 0.88}) {
      final val  = base + (_rng.nextDouble() - 0.5) * 2 * variance;
      final conf = (c + _rng.nextDouble() * 0.05).clamp(0.0, 1.0);
      final q    = conf >= 0.90 ? 'excellent' : conf >= 0.80 ? 'good' : 'fair';
      return AiMeasurementValue(
          value: double.parse(val.toStringAsFixed(1)),
          confidence: conf,
          quality: q);
    }

    return AiScanResult(
      id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
      capturedAt:        DateTime.now(),
      overallConfidence: 0.89 + _rng.nextDouble() * 0.07,
      scanQuality:       'excellent',
      height:      mv(175.5, 0.8, c: 0.94),
      shoulder:    mv(44.0,  0.5, c: 0.92),
      chest:       mv(96.5,  1.2, c: 0.91),
      waist:       mv(82.0,  1.0, c: 0.90),
      hip:         mv(96.0,  1.2, c: 0.89),
      neck:        mv(38.5,  0.5, c: 0.88),
      sleeve:      mv(63.0,  0.8, c: 0.87),
      armLength:   mv(62.5,  0.8, c: 0.87),
      bicep:       mv(32.0,  0.6, c: 0.86),
      forearm:     mv(27.5,  0.5, c: 0.85),
      thigh:       mv(58.0,  1.0, c: 0.86),
      knee:        mv(37.5,  0.5, c: 0.84),
      calf:        mv(36.0,  0.5, c: 0.84),
      inseam:      mv(78.5,  0.8, c: 0.88),
      outseam:     mv(102.0, 1.0, c: 0.87),
      backLength:  mv(45.0,  0.5, c: 0.89),
      frontLength: mv(44.0,  0.5, c: 0.88),
    );
  }

  // ─── Manual capture ───────────────────────────────────────────────────────
  void captureManually() {
    if (phase.value == ScannerPhase.guiding ||
        phase.value == ScannerPhase.locking) {
      _triggerCapture();
    }
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────────
  void _cleanup() {
    _scanLineTimer?.cancel();
    _autoCapturTimer?.cancel();
    _processingTimer?.cancel();
    _skeletonSimTimer?.cancel();
    _pulseTimer?.cancel();
    if (!kIsWeb) _cameraCtrl?.stopImageStream().catchError((_) {});
    _cameraCtrl?.dispose();
    _cameraCtrl = null;
  }

  // ─── Getters ──────────────────────────────────────────────────────────────
  Color get activeColor {
    switch (phase.value) {
      case ScannerPhase.initializing: return AppColors.darkTextHint;
      case ScannerPhase.guiding:      return AppColors.warning;
      case ScannerPhase.locking:      return AppColors.accent;
      case ScannerPhase.capturing:
      case ScannerPhase.complete:     return AppColors.success;
      case ScannerPhase.processing:   return AppColors.primary;
    }
  }

  double get overallQuality =>
      (confidence.value + lightingScore.value + blurScore.value +
          alignmentScore.value + distanceScore.value) / 5.0;
}