import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
class MeasurementWithConfidence {
  final double value;       // cm mein
  final double confidence;  // 0.0 – 1.0

  const MeasurementWithConfidence({
    required this.value,
    required this.confidence,
  });
}

/// Saare measurements + overall score
class CalculatedMeasurements {
  final MeasurementWithConfidence height;
  final MeasurementWithConfidence shoulder;
  final MeasurementWithConfidence chest;     // estimated
  final MeasurementWithConfidence waist;     // estimated
  final MeasurementWithConfidence hips;      // estimated
  final MeasurementWithConfidence inseam;
  final MeasurementWithConfidence sleevLength;
  final MeasurementWithConfidence neck;      // estimated
  final double overallScore;

  const CalculatedMeasurements({
    required this.height,
    required this.shoulder,
    required this.chest,
    required this.waist,
    required this.hips,
    required this.inseam,
    required this.sleevLength,
    required this.neck,
    required this.overallScore,
  });
}

class MeasurementCalculator {
  // ── Entry point ───────────────────────────────────────────────────────────
  static CalculatedMeasurements calculate({
    required Map<PoseLandmarkType, PoseLandmark> landmarks,
    required double knownHeightCm, // calibration: user ka actual height
    required double imageHeightPx, // image ki pixel height
  }) {
    // ── Scale factor: pixels → cm ─────────────────────────────────────────
    //    Pehle pixel mein height nikalte hain nose-to-ankle se,
    //    phir usse known height se divide karte hain
    final noseY = landmarks[PoseLandmarkType.nose]!.y;
    final leftAnkleY = landmarks[PoseLandmarkType.leftAnkle]!.y;
    final rightAnkleY = landmarks[PoseLandmarkType.rightAnkle]!.y;
    final ankleY = (leftAnkleY + rightAnkleY) / 2;

    final heightPx = (ankleY - noseY).abs();
    // pixels per cm
    final scale = heightPx / (knownHeightCm * 0.94);
    // 0.94 because nose to ankle ≈ 94% of full height

    // ── Helper lambdas ────────────────────────────────────────────────────
    double dist(PoseLandmarkType a, PoseLandmarkType b) {
      final la = landmarks[a]!;
      final lb = landmarks[b]!;
      return sqrt(pow(la.x - lb.x, 2) + pow(la.y - lb.y, 2));
    }

    double conf(PoseLandmarkType a, PoseLandmarkType b) {
      return ((landmarks[a]?.likelihood ?? 0) +
              (landmarks[b]?.likelihood ?? 0)) /
          2;
    }

    // ── Height ────────────────────────────────────────────────────────────
    final heightVal = knownHeightCm; // user-provided, always confident
    final heightConfidence =
        ((landmarks[PoseLandmarkType.nose]?.likelihood ?? 0) +
                (landmarks[PoseLandmarkType.leftAnkle]?.likelihood ?? 0)) /
            2;

    // ── Shoulder width ────────────────────────────────────────────────────
    final shoulderPx =
        dist(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    final shoulderCm = shoulderPx / scale;
    final shoulderConf =
        conf(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);

    // ── Inseam (hip to ankle) ─────────────────────────────────────────────
    final hipY =
        (landmarks[PoseLandmarkType.leftHip]!.y +
                landmarks[PoseLandmarkType.rightHip]!.y) /
            2;
    final inseamPx = (ankleY - hipY).abs();
    final inseamCm = inseamPx / scale;
    final inseamConf = (landmarks[PoseLandmarkType.leftHip]!.likelihood +
            landmarks[PoseLandmarkType.leftAnkle]!.likelihood) /
        2;

    // ── Sleeve length (shoulder to wrist) ─────────────────────────────────
    final lShoulderToElbow =
        dist(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    final lElbowToWrist =
        dist(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    final sleevePx = lShoulderToElbow + lElbowToWrist;
    final sleeveCm = sleevePx / scale;
    final sleeveConf = (landmarks[PoseLandmarkType.leftShoulder]!.likelihood +
            landmarks[PoseLandmarkType.leftElbow]!.likelihood +
            landmarks[PoseLandmarkType.leftWrist]!.likelihood) /
        3;
    final chestCm = shoulderCm * 2.28;
    final chestConf = shoulderConf * 0.85; 

    // Waist ≈ shoulder width × 1.75
    final waistCm = shoulderCm * 1.75;
    final waistConf = shoulderConf * 0.80;

    // Hips ≈ hip landmark width × 2.1
    final hipPx =
        dist(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    final hipsCm = (hipPx / scale) * 2.1;
    final hipsConf =
        conf(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip) * 0.82;

    // Neck ≈ shoulder width × 0.43
    final neckCm = shoulderCm * 0.43;
    final neckConf = shoulderConf * 0.75;

    // ── Overall score ─────────────────────────────────────────────────────
    final scores = [
      heightConfidence,
      shoulderConf,
      inseamConf,
      sleeveConf,
      chestConf,
      waistConf,
      hipsConf,
      neckConf,
    ];
    final overall = scores.reduce((a, b) => a + b) / scores.length;

    return CalculatedMeasurements(
      height: MeasurementWithConfidence(
          value: heightVal, confidence: heightConfidence),
      // NOTE: clamp ranges used to be fixed cm values (e.g. chest.clamp(60,160))
      // which assumed an adult body. For a child (e.g. knownHeightCm ~100),
      // a correctly-calculated ~50cm chest would get force-clamped up to the
      // 60cm adult floor, producing "adult-looking" numbers even when the
      // underlying detection/scale was fine. Clamping as a fraction of the
      // person's own entered height fixes this for any body size.
      shoulder: MeasurementWithConfidence(
          value: shoulderCm.clamp(knownHeightCm * 0.18, knownHeightCm * 0.32),
          confidence: shoulderConf),
      chest: MeasurementWithConfidence(
          value: chestCm.clamp(knownHeightCm * 0.45, knownHeightCm * 0.65),
          confidence: chestConf),
      waist: MeasurementWithConfidence(
          value: waistCm.clamp(knownHeightCm * 0.40, knownHeightCm * 0.60),
          confidence: waistConf),
      hips: MeasurementWithConfidence(
          value: hipsCm.clamp(knownHeightCm * 0.45, knownHeightCm * 0.65),
          confidence: hipsConf),
      inseam: MeasurementWithConfidence(
          value: inseamCm.clamp(knownHeightCm * 0.35, knownHeightCm * 0.55),
          confidence: inseamConf),
      sleevLength: MeasurementWithConfidence(
          value: sleeveCm.clamp(knownHeightCm * 0.25, knownHeightCm * 0.45),
          confidence: sleeveConf),
      neck: MeasurementWithConfidence(
          value: neckCm.clamp(knownHeightCm * 0.15, knownHeightCm * 0.30),
          confidence: neckConf),
      overallScore: overall.clamp(0.0, 1.0),
    );
  }
}