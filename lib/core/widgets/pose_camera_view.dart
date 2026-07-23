import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/services/pose_estimation_service.dart';

class PoseCameraView extends StatefulWidget {
  final double knownHeightCm;
  final Future<void> Function(File imageFile) onCapture;

  const PoseCameraView({
    super.key,
    required this.knownHeightCm,
    required this.onCapture,
  });

  @override
  State<PoseCameraView> createState() => _PoseCameraViewState();
}

class _PoseCameraViewState extends State<PoseCameraView> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isProcessingFrame = false;
  DateTime _lastFrameTime = DateTime.now();
  String? _initError;
  final PoseEstimationService _poseService = PoseEstimationService();
  Map<PoseLandmarkType, PoseLandmark> _landmarks = {};
  double _poseConfidence = 0.0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() => _initError = 'No camera found on this device.');
        }
        return;
      }

final camera = _cameras.firstWhere(
  (c) => c.lensDirection == CameraLensDirection.back,
  orElse: () => _cameras.first,
);
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: kIsWeb
            ? null
            : (Platform.isAndroid
                ? ImageFormatGroup.nv21
                : ImageFormatGroup.bgra8888),
      );

      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_processCameraFrame);

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('❌ Camera init error: $e');
      if (mounted) {
        setState(() {
          _initError =
              'Could not start camera. Please check camera permission and try again.';
        });
      }
    }
  }

  Future<void> _processCameraFrame(CameraImage image) async {
  if (_isCapturing || _isProcessingFrame) return;

  if (DateTime.now().difference(_lastFrameTime).inMilliseconds < 120) {
    return;
  }

  _lastFrameTime = DateTime.now();
  _isProcessingFrame = true;

  try {
    final camera = _cameraController!.description;

    final inputImage = _convertCameraImage(image, camera);
    if (inputImage == null) return;

    final result = await _poseService.detectFromInputImage(inputImage);

    if (!mounted) return;

    setState(() {
      _landmarks = result.landmarks;
      _poseConfidence = result.overallConfidence;
    });
  } catch (e) {
    debugPrint("Pose Error: $e");
  } finally {
    _isProcessingFrame = false;
  }
} 
  InputImage? _convertCameraImage(CameraImage image, CameraDescription camera) {
    try {
      final rotation = InputImageRotationValue.fromRawValue(
            camera.sensorOrientation,
          ) ??
          InputImageRotation.rotation0deg;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;
      final Uint8List bytes = _concatenatePlanes(image.planes);

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Frame conversion error: $e');
      return null;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    if (planes.length == 1) return planes.first.bytes;
    final builder = BytesBuilder();
    for (final plane in planes) {
      builder.add(plane.bytes);
    }
    return builder.toBytes();
  }

  Future<void> _captureAndProcess() async {
    if (_isCapturing || _cameraController == null) return;
    if (!_isPoseReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Show your full body and wait until pose quality becomes green.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isCapturing = true);
    try {
      await _cameraController!.stopImageStream();
      final xFile = await _cameraController!.takePicture();
      final file = File(xFile.path);
      await widget.onCapture(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  double get _poseQuality {
    if (_landmarks.isEmpty) return 0;

    int visible = 0;

    final required = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    for (final type in required) {
      if ((_landmarks[type]?.likelihood ?? 0) > 0.6) {
        visible++;
      }
    }

    return (visible / required.length) * _poseConfidence;
  }

  bool get _isPoseReady {
    if (_landmarks.isEmpty) return false;

    final required = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    for (final type in required) {
      final landmark = _landmarks[type];
      if (landmark == null || landmark.likelihood < 0.6) {
        return false;
      }
    }

    return _poseQuality >= 0.90;
  }

Color get _confidenceColor {
  if (_poseQuality >= 0.90) return Colors.green;
  if (_poseQuality >= 0.75) return Colors.orange;
  return Colors.red;
}
 String get _confidenceText {
  if (_poseQuality >= 0.90) {
    return 'Perfect! Capture now';
  }

  if (_poseQuality >= 0.75) {
    return 'Almost ready';
  }

  return 'Show your full body';
}

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('AI Body Scan',
            style: AppTextStyles.h4.copyWith(color: Colors.white)),
      ),
      body: _initError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_rounded,
                        color: Colors.white70, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _initError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _initError = null;
                          _isInitialized = false;
                        });
                        _initCamera();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : !_isInitialized
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : Stack(
                  children: [
                    Positioned.fill(child: CameraPreview(_cameraController!)),
                    if (_landmarks.isNotEmpty)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _PoseOverlayPainter(
                            landmarks: _landmarks,
                            previewSize: Size(
                              _cameraController!.value.previewSize!.height,
                              _cameraController!.value.previewSize!.width,
                            ),
                            screenSize: MediaQuery.of(context).size,
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: CustomPaint(painter: _SilhouettePainter()),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_confidenceText,
                                    style: TextStyle(
                                        color: _confidenceColor, fontSize: 13)),
Text(
  '${(_poseQuality * 100).toInt()}%',
  style: TextStyle(
    color: _confidenceColor,
    fontWeight: FontWeight.bold,
  ),
)
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: _poseQuality,
                              backgroundColor: Colors.white24,
                              valueColor:
                                  AlwaysStoppedAnimation(_confidenceColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 120,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Stand 2-3 meters away • Keep your full body in frame • Arms slightly out to the sides',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _isPoseReady ? _captureAndProcess : null,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: !_isPoseReady
                                  ? Colors.grey
                                  : (_isCapturing
                                      ? Colors.grey
                                      : AppColors.primary),
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: _isCapturing
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 32),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _PoseOverlayPainter extends CustomPainter {
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final Size previewSize;
  final Size screenSize;

  _PoseOverlayPainter({
    required this.landmarks,
    required this.previewSize,
    required this.screenSize,
  });

  Offset _landmarkToOffset(PoseLandmarkType type) {
    final lm = landmarks[type]!;
    final scaleX = screenSize.width / previewSize.width;
    final scaleY = screenSize.height / previewSize.height;
    return Offset(lm.x * scaleX, lm.y * scaleY);
  }

  void _drawLine(
      Canvas canvas, Paint paint, PoseLandmarkType a, PoseLandmarkType b) {
    if (landmarks.containsKey(a) && landmarks.containsKey(b)) {
      canvas.drawLine(_landmarkToOffset(a), _landmarkToOffset(b), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final connections = [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    ];

    for (final conn in connections) {
      _drawLine(canvas, linePaint, conn[0], conn[1]);
    }
    for (final type in landmarks.keys) {
      if ((landmarks[type]?.likelihood ?? 0) > 0.5) {
        canvas.drawCircle(_landmarkToOffset(type), 4, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PoseOverlayPainter old) => true;
}

class _SilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final centerX = size.width / 2;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(centerX, size.height * 0.12), width: 50, height: 60),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(centerX, size.height * 0.38), width: 100, height: 120),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
