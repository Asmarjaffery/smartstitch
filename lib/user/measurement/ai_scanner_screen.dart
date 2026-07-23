import 'dart:math' as math;
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/ai_body_overlay.dart';
import 'package:smartstitch/user/measurement/ai_scanner_controller.dart';

class AiScannerScreen extends StatelessWidget {
  const AiScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AiScannerController>(
      init: AiScannerController(),
      builder: (_) => const _ScannerView(),
    );
  }
}

class _ScannerView extends GetView<AiScannerController> {
  const _ScannerView();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Obx(() => _buildBody(context)),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final phase = controller.phase.value;

    return Stack(
      children: [
        // ── Camera preview / AI grid fallback ────────────────────────────
        _CameraBackground(),

        // ── Vignette ─────────────────────────────────────────────────────
        _Vignette(),

        // ── AI skeleton overlay ──────────────────────────────────────────
        if (phase != ScannerPhase.initializing && phase != ScannerPhase.processing)
          _SkeletonOverlay(),

        // ── Processing overlay ───────────────────────────────────────────
        if (phase == ScannerPhase.processing) _ProcessingOverlay(),

        // ── Capture flash ────────────────────────────────────────────────
        if (phase == ScannerPhase.capturing) _CaptureFlash(),

        // ── Top bar ──────────────────────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _TopBar(phase: phase),
        ),

        // ── Quality panel (right side) ────────────────────────────────────
        if (phase != ScannerPhase.processing && phase != ScannerPhase.capturing)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            right: 16,
            child: _QualityPanel(),
          ),

        // ── Confidence meter (left side) ──────────────────────────────────
        if (phase == ScannerPhase.locking || phase == ScannerPhase.guiding)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 16,
            child: _ConfidenceMeter(),
          ),

        // ── Bottom guidance bar ───────────────────────────────────────────
        if (phase != ScannerPhase.processing && phase != ScannerPhase.complete)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomBar(phase: phase),
          ),

        // ── Auto-capture countdown ────────────────────────────────────────
        if (phase == ScannerPhase.locking && controller.isAutoCapturing.value)
          Center(child: _CountdownOverlay()),
      ],
    );
  }
}

// ─── Camera background (real camera on native, grid on web) ──────────────────
class _CameraBackground extends GetView<AiScannerController> {
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _GridBg();

    return Obx(() {
      if (controller.isCameraReady.value && controller.cameraController != null) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.cameraController!.value.previewSize!.height,
              height: controller.cameraController!.value.previewSize!.width,
              child: CameraPreview(controller.cameraController!),
            ),
          ),
        );
      }
      return _GridBg();
    });
  }
}

class _GridBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF06100F),
      child: CustomPaint(painter: _GridPainter()),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.04)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Vignette extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
        ),
      ),
    );
  }
}

// ─── Skeleton overlay ─────────────────────────────────────────────────────────
class _SkeletonOverlay extends GetView<AiScannerController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() => CustomPaint(
          painter: AiBodyOverlayPainter(
            confidence: controller.confidence.value,
            scanProgress: controller.scanProgress.value,
            skeletonPoints: controller.skeletonPoints,
            skeletonBones: controller.skeletonBones,
            activeColor: controller.activeColor,
            pulseValue: controller.pulseValue.value,
            isCapturing: controller.phase.value == ScannerPhase.capturing,
          ),
          size: Size.infinite,
        ));
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────
class _TopBar extends GetView<AiScannerController> {
  final ScannerPhase phase;
  const _TopBar({required this.phase});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, top + 8, 20, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0),
              ],
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Body Scanner',
                      style: AppTextStyles.h5.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    Obx(() => Text(
                          _phaseLabel(controller.phase.value),
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white60),
                        )),
                  ],
                ),
              ),
              _LiveBadge(),
            ],
          ),
        ),
      ),
    );
  }

  String _phaseLabel(ScannerPhase p) {
    switch (p) {
      case ScannerPhase.initializing: return 'Starting up...';
      case ScannerPhase.guiding:      return 'Position yourself';
      case ScannerPhase.locking:      return 'Locking pose...';
      case ScannerPhase.capturing:    return 'Capturing...';
      case ScannerPhase.processing:   return 'AI Processing';
      case ScannerPhase.complete:     return 'Complete!';
    }
  }
}

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blink,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.primary.withOpacity(_blink.value)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(_blink.value),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'AI LIVE',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quality panel ────────────────────────────────────────────────────────────
class _QualityPanel extends GetView<AiScannerController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QRow(label: 'LIGHT', value: controller.lightingScore.value,
                      icon: Icons.wb_sunny_rounded),
                  const SizedBox(height: 8),
                  _QRow(label: 'FOCUS', value: controller.blurScore.value,
                      icon: Icons.center_focus_strong_rounded),
                  const SizedBox(height: 8),
                  _QRow(label: 'ALIGN', value: controller.alignmentScore.value,
                      icon: Icons.swap_vert_rounded),
                  const SizedBox(height: 8),
                  _QRow(label: 'DIST', value: controller.distanceScore.value,
                      icon: Icons.straighten_rounded),
                ],
              ),
            ),
          ),
        ));
  }
}

class _QRow extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  const _QRow({required this.label, required this.value, required this.icon});

  Color get _color {
    if (value >= 0.8) return AppColors.success;
    if (value >= 0.6) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _color, size: 12),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: Colors.white54, fontSize: 10)),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          height: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Confidence meter ─────────────────────────────────────────────────────────
class _ConfidenceMeter extends GetView<AiScannerController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final conf = controller.confidence.value;
      final pct = (conf * 100).toInt();
      final color = conf >= 0.85
          ? AppColors.success
          : conf >= 0.65
              ? AppColors.warning
              : AppColors.error;

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text('AI',
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white54, fontSize: 10)),
                const SizedBox(height: 4),
                _CircularConf(confidence: conf),
                const SizedBox(height: 4),
                Text('$pct%',
                    style: AppTextStyles.labelSmall.copyWith(color: color)),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _CircularConf extends StatelessWidget {
  final double confidence;
  const _CircularConf({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final color = confidence >= 0.85
        ? AppColors.success
        : confidence >= 0.65
            ? AppColors.warning
            : AppColors.error;

    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(
        painter: _ArcPainter(
          progress: confidence,
          color: color,
          track: Colors.white.withOpacity(0.1),
        ),
        child: Center(
            child: Icon(Icons.person_outlined, color: color, size: 18)),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  const _ArcPainter(
      {required this.progress, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const strokeWidth = 3.0;
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, base);
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress.clamp(0.0, 1.0) * 2 * math.pi,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ─── Countdown overlay ────────────────────────────────────────────────────────
class _CountdownOverlay extends GetView<AiScannerController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() => AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(controller.autoCountdown.value),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success, width: 3),
              color: AppColors.success.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${controller.autoCountdown.value}',
                style: AppTextStyles.display.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          )
              .animate()
              .scale(begin: const Offset(1.3, 1.3), end: const Offset(1.0, 1.0))
              .fade(),
        ));
  }
}

// ─── Capture flash ────────────────────────────────────────────────────────────
class _CaptureFlash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.white)
        .animate()
        .fade(begin: 0.8, end: 0.0, duration: 400.ms);
  }
}

// ─── Processing overlay ───────────────────────────────────────────────────────
class _ProcessingOverlay extends GetView<AiScannerController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          color: const Color(0xF0060F0E),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AiOrb(),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          controller.processingStep.value,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.darkTextSecondary),
                        ),
                      ),
                      Text(
                        '${(controller.processingProgress.value * 100).toInt()}%',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: controller.processingProgress.value,
                      backgroundColor: AppColors.darkBorder,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'AI is computing your measurements',
                    style: AppTextStyles.h5
                        .copyWith(color: AppColors.darkTextPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while our neural network\nprocesses your body scan',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.darkTextSecondary),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}

class _AiOrb extends StatefulWidget {
  @override
  State<_AiOrb> createState() => _AiOrbState();
}

class _AiOrbState extends State<_AiOrb> with TickerProviderStateMixin {
  late final AnimationController _rot;
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _rot = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.85, end: 1.15).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _rot.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rot, _pulseAnim]),
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          Transform.scale(
            scale: _pulseAnim.value,
            child: SizedBox(
              width: 160,
              height: 160,
              child: CircularProgressIndicator(
                value: null,
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation(
                    AppColors.primary.withOpacity(0.3)),
              ),
            ),
          ),
          // Rotating dashed ring
          Transform.rotate(
            angle: _rot.value * 2 * math.pi,
            child: SizedBox(
              width: 130,
              height: 130,
              child: CustomPaint(
                painter:
                    _DashRing(color: AppColors.primary, dashCount: 12),
              ),
            ),
          ),
          // Counter-rotating ring
          Transform.rotate(
            angle: -_rot.value * 2 * math.pi * 0.7,
            child: SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter:
                    _DashRing(color: AppColors.accent, dashCount: 8),
              ),
            ),
          ),
          // Center orb
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF0A2827), Color(0xFF060F0E)],
              ),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5),
              ],
            ),
            child: const Icon(Icons.psychology_rounded,
                color: AppColors.primary, size: 32),
          ),
        ],
      ),
    );
  }
}

class _DashRing extends CustomPainter {
  final Color color;
  final int dashCount;
  const _DashRing({required this.color, required this.dashCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final totalAngle = 0.65 * 2 * math.pi;
    final dashAngle = totalAngle / dashCount;
    final gapAngle = (2 * math.pi - totalAngle) / dashCount;
    double currentAngle = -math.pi / 2;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        dashAngle * 0.7,
        false,
        Paint()
          ..color = color.withOpacity(0.3 + (i / dashCount) * 0.7)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      currentAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────
class _BottomBar extends GetView<AiScannerController> {
  final ScannerPhase phase;
  const _BottomBar({required this.phase});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.85),
                Colors.black.withOpacity(0.4),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _GuidanceMsg(
                      key: ValueKey(controller.guidanceMessage.value),
                      message: controller.guidanceMessage.value,
                    ),
                  )),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Issue indicator
                  Obx(() => _IssueChip(issue: controller.primaryIssue.value)),
                  // Capture button
                  _CaptureBtn(phase: phase),
                  // Flip (placeholder)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.flip_camera_ios_rounded,
                        color: Colors.white70, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuidanceMsg extends StatelessWidget {
  final String message;
  const _GuidanceMsg({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isPerfect = message.startsWith('Perfect') ||
        message.startsWith('Hold') ||
        message.startsWith('Complete');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isPerfect)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppColors.success),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
                duration: 600.ms),
        Flexible(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isPerfect ? AppColors.success : Colors.white,
              fontWeight:
                  isPerfect ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _IssueChip extends StatelessWidget {
  final PoseIssue? issue;
  const _IssueChip({required this.issue});

  @override
  Widget build(BuildContext context) {
    if (issue == null) return const SizedBox(width: 48);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.warning.withOpacity(0.15),
        border: Border.all(color: AppColors.warning.withOpacity(0.5)),
      ),
      child: const Icon(Icons.warning_amber_rounded,
          color: AppColors.warning, size: 20),
    );
  }
}

class _CaptureBtn extends GetView<AiScannerController> {
  final ScannerPhase phase;
  const _CaptureBtn({required this.phase});

  @override
  Widget build(BuildContext context) {
    final isReady =
        phase == ScannerPhase.guiding || phase == ScannerPhase.locking;
    final isAuto = controller.isAutoCapturing.value;

    return GestureDetector(
      onTap: isReady ? controller.captureManually : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isReady
                ? (isAuto ? AppColors.success : Colors.white)
                : Colors.white38,
            width: 3,
          ),
          color: Colors.transparent,
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isAuto
                    ? [AppColors.success, const Color(0xFF00B87D)]
                    : isReady
                        ? [AppColors.primary, AppColors.primaryLight]
                        : [Colors.white24, Colors.white12],
              ),
              boxShadow: isReady
                  ? [
                      BoxShadow(
                        color: (isAuto ? AppColors.success : AppColors.primary)
                            .withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
