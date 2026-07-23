import 'package:flutter/material.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

// ─── Main AI Overlay Painter ─────────────────────────────────────────────────
class AiBodyOverlayPainter extends CustomPainter {
  final double confidence;
  final double scanProgress;
  final List<SkeletonPoint> skeletonPoints;
  final List<SkeletonBone> skeletonBones;
  final Color activeColor;
  final double pulseValue;
  final bool isCapturing;

  const AiBodyOverlayPainter({
    required this.confidence,
    required this.scanProgress,
    required this.skeletonPoints,
    required this.skeletonBones,
    required this.activeColor,
    required this.pulseValue,
    this.isCapturing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBodyOutline(canvas, size);
    if (!isCapturing) _drawScanLine(canvas, size);
    _drawBones(canvas, size);
    _drawJoints(canvas, size);
    _drawCornerBrackets(canvas, size);
    if (confidence > 0.7) _drawMeasurementLines(canvas, size);
  }

  void _drawBodyOutline(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final bodyH = size.height * 0.78;
    final bodyW = size.width * 0.38;

    final paint = Paint()
      ..color = activeColor.withOpacity(0.12 + pulseValue * 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    final headR = bodyW * 0.18;
    final headCY = cy - bodyH * 0.42;
    path.addOval(Rect.fromCenter(
      center: Offset(cx, headCY),
      width: headR * 2.2,
      height: headR * 2.5,
    ));

    path.moveTo(cx - headR * 0.45, headCY + headR * 1.1);
    path.lineTo(cx - bodyW * 0.16, headCY + headR * 1.7);
    path.moveTo(cx + headR * 0.45, headCY + headR * 1.1);
    path.lineTo(cx + bodyW * 0.16, headCY + headR * 1.7);

    final shoulderY = cy - bodyH * 0.28;
    final waistY = cy + bodyH * 0.02;
    final hipY = cy + bodyH * 0.14;
    final kneeY = cy + bodyH * 0.32;
    final ankleY = cy + bodyH * 0.44;

    path.moveTo(cx - bodyW * 0.50, shoulderY);
    path.quadraticBezierTo(
        cx - bodyW * 0.52, waistY - bodyH * 0.05, cx - bodyW * 0.33, waistY);
    path.quadraticBezierTo(cx - bodyW * 0.37, hipY, cx - bodyW * 0.34, hipY);
    path.lineTo(cx - bodyW * 0.20, kneeY);
    path.lineTo(cx - bodyW * 0.20, ankleY);

    path.moveTo(cx + bodyW * 0.50, shoulderY);
    path.quadraticBezierTo(
        cx + bodyW * 0.52, waistY - bodyH * 0.05, cx + bodyW * 0.33, waistY);
    path.quadraticBezierTo(cx + bodyW * 0.37, hipY, cx + bodyW * 0.34, hipY);
    path.lineTo(cx + bodyW * 0.20, kneeY);
    path.lineTo(cx + bodyW * 0.20, ankleY);

    path.moveTo(cx - bodyW * 0.50, shoulderY);
    path.lineTo(cx + bodyW * 0.50, shoulderY);

    final leftElbowX = cx - bodyW * 0.66;
    final leftElbowY = cy - bodyH * 0.08;
    final leftWristX = cx - bodyW * 0.60;
    final leftWristY = cy + bodyH * 0.12;
    path.moveTo(cx - bodyW * 0.50, shoulderY);
    path.quadraticBezierTo(leftElbowX, leftElbowY, leftWristX, leftWristY);

    final rightElbowX = cx + bodyW * 0.66;
    final rightElbowY = cy - bodyH * 0.08;
    final rightWristX = cx + bodyW * 0.60;
    final rightWristY = cy + bodyH * 0.12;
    path.moveTo(cx + bodyW * 0.50, shoulderY);
    path.quadraticBezierTo(rightElbowX, rightElbowY, rightWristX, rightWristY);

    canvas.drawPath(path, paint);
  }

  void _drawScanLine(Canvas canvas, Size size) {
    final y = size.height * scanProgress;
    const lineH = 3.0;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          activeColor.withOpacity(0),
          activeColor.withOpacity(0.8),
          activeColor,
          activeColor.withOpacity(0.8),
          activeColor.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, y - lineH, size.width, lineH * 2))
      ..strokeWidth = lineH
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [activeColor.withOpacity(0.15), activeColor.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, y, size.width, 40));

    canvas.drawRect(Rect.fromLTWH(0, y, size.width, 40), glowPaint);
  }

  void _drawBones(Canvas canvas, Size size) {
    for (final bone in skeletonBones) {
      final a = Offset(bone.from.x * size.width, bone.from.y * size.height);
      final b = Offset(bone.to.x * size.width, bone.to.y * size.height);

      final opacity = (bone.confidence * 0.8).clamp(0.2, 0.8);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = activeColor.withOpacity(opacity)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawJoints(Canvas canvas, Size size) {
    for (final point in skeletonPoints) {
      final offset = Offset(point.x * size.width, point.y * size.height);
      final opacity = (point.confidence * 0.9).clamp(0.2, 1.0);
      final radius = point.isKeyJoint ? 6.0 : 4.0;
      final glowRadius = radius + 4 + pulseValue * 3;

      canvas.drawCircle(
          offset, glowRadius,
          Paint()..color = activeColor.withOpacity(opacity * 0.3));

      canvas.drawCircle(
          offset, radius + 2,
          Paint()
            ..color = activeColor.withOpacity(opacity * 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);

      canvas.drawCircle(
          offset, radius,
          Paint()..color = activeColor.withOpacity(opacity));

      canvas.drawCircle(
          offset, radius * 0.35,
          Paint()..color = Colors.white.withOpacity(opacity * 0.9));
    }
  }

  void _drawCornerBrackets(Canvas canvas, Size size) {
    final padding = size.width * 0.06;
    final bLen = size.width * 0.08;
    const bWidth = 2.5;
    final color = isCapturing ? AppColors.success : activeColor;
    final opacity = 0.7 + pulseValue * 0.3;

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = bWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Top-left
    canvas.drawLine(Offset(padding, padding + bLen), Offset(padding, padding), paint);
    canvas.drawLine(Offset(padding, padding), Offset(padding + bLen, padding), paint);
    // Top-right
    canvas.drawLine(Offset(size.width - padding, padding + bLen),
        Offset(size.width - padding, padding), paint);
    canvas.drawLine(Offset(size.width - padding, padding),
        Offset(size.width - padding - bLen, padding), paint);
    // Bottom-left
    canvas.drawLine(Offset(padding, size.height - padding - bLen),
        Offset(padding, size.height - padding), paint);
    canvas.drawLine(Offset(padding, size.height - padding),
        Offset(padding + bLen, size.height - padding), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width - padding, size.height - padding - bLen),
        Offset(size.width - padding, size.height - padding), paint);
    canvas.drawLine(Offset(size.width - padding, size.height - padding),
        Offset(size.width - padding - bLen, size.height - padding), paint);
  }

  void _drawMeasurementLines(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final bodyW = size.width * 0.38;
    final shoulderY = cy - size.height * 0.78 * 0.28;

    final linePaint = Paint()
      ..color = AppColors.accent.withOpacity(0.5 + pulseValue * 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Shoulder width measurement arrow
    _drawArrow(
      canvas,
      start: Offset(cx - bodyW * 0.48, shoulderY - 20),
      end: Offset(cx + bodyW * 0.48, shoulderY - 20),
      paint: linePaint,
    );
  }

  void _drawArrow(Canvas canvas,
      {required Offset start, required Offset end, required Paint paint}) {
    canvas.drawLine(start, end, paint);
    const s = 5.0;
    canvas.drawLine(start, Offset(start.dx + s, start.dy - s), paint);
    canvas.drawLine(start, Offset(start.dx + s, start.dy + s), paint);
    canvas.drawLine(end, Offset(end.dx - s, end.dy - s), paint);
    canvas.drawLine(end, Offset(end.dx - s, end.dy + s), paint);
  }

  @override
  bool shouldRepaint(AiBodyOverlayPainter old) =>
      old.scanProgress != scanProgress ||
      old.pulseValue != pulseValue ||
      old.confidence != confidence ||
      old.isCapturing != isCapturing ||
      old.skeletonPoints != skeletonPoints;
}

// ─── Data classes ─────────────────────────────────────────────────────────────
class SkeletonPoint {
  final double x;
  final double y;
  final double confidence;
  final bool isKeyJoint;

  const SkeletonPoint({
    required this.x,
    required this.y,
    required this.confidence,
    this.isKeyJoint = false,
  });
}

class SkeletonBone {
  final SkeletonPoint from;
  final SkeletonPoint to;
  final double confidence;

  const SkeletonBone({
    required this.from,
    required this.to,
    required this.confidence,
  });
}

// ─── Default skeleton builder ─────────────────────────────────────────────────
List<SkeletonPoint> buildDefaultSkeleton({
  double confidence = 0.85,
  double wobbleX = 0.0,
  double wobbleY = 0.0,
}) {
  final w = wobbleX;
  final wy = wobbleY;
  return [
    SkeletonPoint(x: 0.50 + w, y: 0.12 + wy, confidence: confidence, isKeyJoint: true),
    SkeletonPoint(x: 0.46 + w, y: 0.10 + wy, confidence: confidence * 0.9),
    SkeletonPoint(x: 0.54 + w, y: 0.10 + wy, confidence: confidence * 0.9),
    SkeletonPoint(x: 0.43 + w, y: 0.12 + wy, confidence: confidence * 0.85),
    SkeletonPoint(x: 0.57 + w, y: 0.12 + wy, confidence: confidence * 0.85),
    SkeletonPoint(x: 0.33 + w, y: 0.22 + wy, confidence: confidence, isKeyJoint: true),
    SkeletonPoint(x: 0.67 + w, y: 0.22 + wy, confidence: confidence, isKeyJoint: true),
    SkeletonPoint(x: 0.26 + w, y: 0.36 + wy, confidence: confidence * 0.9),
    SkeletonPoint(x: 0.74 + w, y: 0.36 + wy, confidence: confidence * 0.9),
    SkeletonPoint(x: 0.28 + w, y: 0.50 + wy, confidence: confidence * 0.85),
    SkeletonPoint(x: 0.72 + w, y: 0.50 + wy, confidence: confidence * 0.85),
    SkeletonPoint(x: 0.40 + w, y: 0.52 + wy, confidence: confidence, isKeyJoint: true),
    SkeletonPoint(x: 0.60 + w, y: 0.52 + wy, confidence: confidence, isKeyJoint: true),
    SkeletonPoint(x: 0.40 + w, y: 0.70 + wy, confidence: confidence * 0.9),
    SkeletonPoint(x: 0.60 + w, y: 0.70 + wy, confidence: confidence * 0.9),
    SkeletonPoint(x: 0.40 + w, y: 0.87 + wy, confidence: confidence * 0.85, isKeyJoint: true),
    SkeletonPoint(x: 0.60 + w, y: 0.87 + wy, confidence: confidence * 0.85, isKeyJoint: true),
  ];
}

List<SkeletonBone> buildDefaultBones(List<SkeletonPoint> pts,
    {double confidence = 0.85}) {
  if (pts.length < 17) return [];
  return [
    SkeletonBone(from: pts[0], to: pts[1], confidence: confidence),
    SkeletonBone(from: pts[0], to: pts[2], confidence: confidence),
    SkeletonBone(from: pts[1], to: pts[3], confidence: confidence),
    SkeletonBone(from: pts[2], to: pts[4], confidence: confidence),
    SkeletonBone(from: pts[5], to: pts[6], confidence: confidence),
    SkeletonBone(from: pts[5], to: pts[7], confidence: confidence),
    SkeletonBone(from: pts[7], to: pts[9], confidence: confidence),
    SkeletonBone(from: pts[6], to: pts[8], confidence: confidence),
    SkeletonBone(from: pts[8], to: pts[10], confidence: confidence),
    SkeletonBone(from: pts[5], to: pts[11], confidence: confidence),
    SkeletonBone(from: pts[6], to: pts[12], confidence: confidence),
    SkeletonBone(from: pts[11], to: pts[12], confidence: confidence),
    SkeletonBone(from: pts[11], to: pts[13], confidence: confidence),
    SkeletonBone(from: pts[13], to: pts[15], confidence: confidence),
    SkeletonBone(from: pts[12], to: pts[14], confidence: confidence),
    SkeletonBone(from: pts[14], to: pts[16], confidence: confidence),
  ];
}
