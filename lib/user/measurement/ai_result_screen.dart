import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/body_measurement_model.dart';
import 'package:smartstitch/user/measurement/ai_scanner_controller.dart';
import 'package:smartstitch/user/measurement/measurement_controller.dart';
import 'package:uuid/uuid.dart';

class AiResultScreen extends StatelessWidget {
  const AiResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = Get.arguments as AiScanResult?;
    if (result == null) {
      return const Scaffold(
        body: Center(child: Text('No scan result')),
      );
    }
    return _AiResultView(result: result);
  }
}

class _AiResultView extends StatefulWidget {
  final AiScanResult result;
  const _AiResultView({required this.result});

  @override
  State<_AiResultView> createState() => _AiResultViewState();
}

class _AiResultViewState extends State<_AiResultView> {
  bool _saving = false;

  Future<void> _saveMeasurement() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final r = widget.result;
      final uid = AuthController.to.currentUserId ?? 'unknown';
      final model = BodyMeasurementModel(
        id: const Uuid().v4(),
        userId: uid,
        height: r.height.value,
        chest: r.chest.value,
        waist: r.waist.value,
        shoulder: r.shoulder.value,
        hips: r.hip.value,
        sleevLength: r.sleeve.value,
        inseam: r.inseam.value,
        neck: r.neck.value,
        aiAccuracyScore: r.overallConfidence,
        isAiGenerated: true,
        measuredAt: r.capturedAt,
      );
      await MeasurementController.to.saveAiScanResult(model);
      Get.back();
      Get.back(); // back past scanner too
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: CustomScrollView(
          slivers: [
            // ── Hero app bar ─────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => Get.back(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _HeroHeader(result: r),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Scan quality + confidence ──────────────────────
                    _ScanSummaryRow(result: r),
                    const SizedBox(height: 24),

                    // ── Size recommendation ────────────────────────────
                    _SizeRecommendation(result: r),
                    const SizedBox(height: 24),

                    // ── Body map ───────────────────────────────────────
                    Text('Body Map', style: AppTextStyles.h4),
                    const SizedBox(height: 12),
                    _BodyMap(result: r),
                    const SizedBox(height: 24),

                    // ── All measurements grid ──────────────────────────
                    Text('All Measurements', style: AppTextStyles.h4),
                    const SizedBox(height: 4),
                    Text(
                      '${r.allMeasurements.length} measurements captured',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 16),
                    _MeasurementsGrid(result: r),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Bottom action bar ──────────────────────────────────────────────
        bottomNavigationBar: _BottomActionBar(
          onSave: _saveMeasurement,
          onRetake: () {
            Get.back();
            Get.back();
          },
          isSaving: _saving,
        ),
      ),
    );
  }
}

// ─── Hero header ──────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final AiScanResult result;
  const _HeroHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(painter: _HeroBgPainter()),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 56, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AI Scan Complete',
                      style: AppTextStyles.h4
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your body measurements are ready. Review and save to your profile.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                // Confidence bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: result.overallConfidence,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(result.overallConfidence * 100).toInt()}% confidence',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.3),
        30.0 + i * 18,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Scan summary row ─────────────────────────────────────────────────────────
class _ScanSummaryRow extends StatelessWidget {
  final AiScanResult result;
  const _ScanSummaryRow({required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryChip(
          icon: Icons.check_circle_rounded,
          label: result.scanQuality.toUpperCase(),
          color: AppColors.success,
        ),
        const SizedBox(width: 12),
        _SummaryChip(
          icon: Icons.straighten_rounded,
          label: '${result.allMeasurements.length} measurements',
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _SummaryChip(
          icon: Icons.access_time_rounded,
          label: _formatTime(result.capturedAt),
          color: AppColors.info,
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SummaryChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Size recommendation ──────────────────────────────────────────────────────
class _SizeRecommendation extends StatelessWidget {
  final AiScanResult result;
  const _SizeRecommendation({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.large,
        boxShadow: AppShadows.primary,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recommended Size',
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _SizeTag(label: 'Shirt', size: result.recommendedShirtSize),
                    const SizedBox(width: 12),
                    _SizeTag(label: 'Pant', size: result.recommendedPantSize),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.checkroom_rounded,
              color: Colors.white38, size: 40),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

class _SizeTag extends StatelessWidget {
  final String label;
  final String size;
  const _SizeTag({required this.label, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: Colors.white70, fontSize: 10)),
          Text(size,
              style: AppTextStyles.h4.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Body map ─────────────────────────────────────────────────────────────────
class _BodyMap extends StatelessWidget {
  final AiScanResult result;
  const _BodyMap({required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
        borderRadius: AppRadius.large,
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: CustomPaint(
        painter: _BodyMapPainter(result: result, isDark: isDark),
        size: Size.infinite,
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }
}

class _BodyMapPainter extends CustomPainter {
  final AiScanResult result;
  final bool isDark;
  const _BodyMapPainter({required this.result, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final bodyH = size.height * 0.75;
    final bodyW = size.width * 0.22;

    final bodyPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final headCY = cy - bodyH * 0.40;
    final headR = bodyW * 0.50;

    // Head
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, headCY), width: headR * 2, height: headR * 2.4),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, headCY), width: headR * 2, height: headR * 2.4),
      outlinePaint,
    );

    // Torso
    final shoulderY = cy - bodyH * 0.25;
    final waistY = cy + bodyH * 0.03;
    final hipY = cy + bodyH * 0.17;
    final kneeY = cy + bodyH * 0.35;
    final ankleY = cy + bodyH * 0.46;

    final torsoPath = Path()
      ..moveTo(cx - bodyW, shoulderY)
      ..quadraticBezierTo(cx - bodyW * 1.1, waistY - 10, cx - bodyW * 0.7, waistY)
      ..quadraticBezierTo(cx - bodyW * 0.8, hipY, cx - bodyW * 0.72, hipY)
      ..lineTo(cx - bodyW * 0.45, kneeY)
      ..lineTo(cx - bodyW * 0.45, ankleY)
      ..moveTo(cx + bodyW, shoulderY)
      ..quadraticBezierTo(cx + bodyW * 1.1, waistY - 10, cx + bodyW * 0.7, waistY)
      ..quadraticBezierTo(cx + bodyW * 0.8, hipY, cx + bodyW * 0.72, hipY)
      ..lineTo(cx + bodyW * 0.45, kneeY)
      ..lineTo(cx + bodyW * 0.45, ankleY)
      ..moveTo(cx - bodyW, shoulderY)
      ..lineTo(cx + bodyW, shoulderY);

    canvas.drawPath(torsoPath, outlinePaint);

    // Measurement annotations
    _drawAnnotation(canvas, size, 'Shoulder ${result.shoulder.formatted}',
        Offset(cx, shoulderY - 14), true);
    _drawAnnotation(canvas, size, 'Chest ${result.chest.formatted}',
        Offset(cx, shoulderY + 22), false);
    _drawAnnotation(canvas, size, 'Waist ${result.waist.formatted}',
        Offset(cx, waistY + 14), false);
    _drawAnnotation(canvas, size, 'Hip ${result.hip.formatted}',
        Offset(cx, hipY + 14), false);
  }

  void _drawAnnotation(
      Canvas canvas, Size size, String text, Offset center, bool isTop) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = center.dx - tp.width / 2;
    final dy = center.dy - tp.height / 2;
    tp.paint(canvas, Offset(dx.clamp(4, size.width - tp.width - 4), dy));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Measurements grid ────────────────────────────────────────────────────────
class _MeasurementsGrid extends StatelessWidget {
  final AiScanResult result;
  const _MeasurementsGrid({required this.result});

  @override
  Widget build(BuildContext context) {
    final entries = result.allMeasurements.entries.toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        return _MeasurementTile(label: entry.key, mv: entry.value)
            .animate(delay: (i * 40).ms)
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.1, end: 0);
      },
    );
  }
}

class _MeasurementTile extends StatelessWidget {
  final String label;
  final AiMeasurementValue mv;
  const _MeasurementTile({required this.label, required this.mv});

  Color get _qualityColor {
    switch (mv.quality) {
      case 'excellent': return AppColors.success;
      case 'good':      return AppColors.primary;
      default:          return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.medium,
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: _qualityColor),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            mv.formatted,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: mv.confidence,
              backgroundColor: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              valueColor: AlwaysStoppedAnimation(_qualityColor),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom action bar ────────────────────────────────────────────────────────
class _BottomActionBar extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onRetake;
  final bool isSaving;

  const _BottomActionBar({
    required this.onSave,
    required this.onRetake,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        boxShadow: isDark ? null : AppShadows.card(isDark),
      ),
      child: Row(
        children: [
          // Retake button
          OutlinedButton.icon(
            onPressed: onRetake,
            icon: const Icon(Icons.camera_alt_outlined,
                color: AppColors.primary, size: 18),
            label: Text('Retake',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          const SizedBox(width: 12),
          // Save button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                isSaving ? 'Saving...' : 'Save to Profile',
                style: AppTextStyles.labelLarge
                    .copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.medium),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
