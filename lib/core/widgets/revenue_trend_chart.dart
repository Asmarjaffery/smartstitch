import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/admin/analytics/analytics_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

class RevenueTrendChart extends StatefulWidget {
  final AnalyticsController controller;

  const RevenueTrendChart({Key? key, required this.controller}) : super(key: key);

  @override
  State<RevenueTrendChart> createState() => _RevenueTrendChartState();
}

class _RevenueTrendChartState extends State<RevenueTrendChart> {
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final data = widget.controller.revenueLineData;
      final labels = widget.controller.revenueLineLabels;

      if (data.isEmpty || data.every((v) => v == 0)) {
        return Center(
          child: Text(
            'No revenue data in this period',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
            ),
          ),
        );
      }

      final list = data.toList();

      return Column(
        children: [
          Expanded(
            child: MouseRegion(
              onHover: (event) {
                final box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                final width = box.size.width;
                final stepX = list.length > 1 ? width / (list.length - 1) : width;
                final idx = (event.localPosition.dx / stepX).round().clamp(0, list.length - 1);
                setState(() => _hoverIndex = idx);
              },
              onExit: (_) => setState(() => _hoverIndex = null),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _LineChartPainter(
                    data: list,
                    lineColor: AppColors.primary,
                    lineColor2: AppColors.accent,
                    fillColor: AppColors.primary,
                    gridColor: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    progress: t,
                    hoverIndex: _hoverIndex,
                    labels: labels.toList(),
                    isDark: isDark,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (labels.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _sampleLabels(labels.toList())
                  .map((l) => Text(
                        l,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
                        ),
                      ))
                  .toList(),
            ),
        ],
      );
    });
  }

  // Avoid overcrowding the x-axis — show at most 5 evenly spaced labels.
  List<String> _sampleLabels(List<String> labels) {
    if (labels.length <= 5) return labels;
    final step = (labels.length - 1) / 4;
    return List.generate(5, (i) => labels[(i * step).round()]);
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color lineColor2;
  final Color fillColor;
  final Color gridColor;
  final double progress;
  final int? hoverIndex;
  final List<String> labels;
  final bool isDark;

  _LineChartPainter({
    required this.data,
    required this.lineColor,
    required this.lineColor2,
    required this.fillColor,
    required this.gridColor,
    required this.progress,
    required this.hoverIndex,
    required this.labels,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);

    // Soft dashed grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final stepX = data.length > 1 ? size.width / (data.length - 1) : size.width;

    final points = List.generate(data.length, (i) {
      final x = stepX * i;
      final normalized = (data[i] - minVal) / range;
      final y = size.height - (normalized * size.height * 0.85) - (size.height * 0.05);
      return Offset(x, y);
    });

    final visibleCount = (points.length * progress).clamp(1, points.length).toInt();
    final visible = points.sublist(0, visibleCount);
    if (visible.isEmpty) return;

    // Fill under the line
    final fillPath = Path()..moveTo(visible.first.dx, size.height);
    for (final p in visible) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(visible.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fillColor.withValues(alpha: 0.28), fillColor.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Gradient line (teal -> accent)
    final linePath = Path()..moveTo(visible.first.dx, visible.first.dy);
    for (final p in visible.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..shader = LinearGradient(colors: [lineColor, lineColor2])
            .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Dots
    final dotPaint = Paint()..color = lineColor;
    for (final p in visible) {
      canvas.drawCircle(p, 3.5, Paint()..color = lineColor.withValues(alpha: 0.25));
      canvas.drawCircle(p, 3, dotPaint);
      canvas.drawCircle(p, 1.3, Paint()..color = isDark ? Colors.black : Colors.white);
    }

    // Hover tooltip
    if (hoverIndex != null && hoverIndex! < points.length && hoverIndex! < visible.length) {
      final p = points[hoverIndex!];
      canvas.drawLine(
        Offset(p.dx, 0),
        Offset(p.dx, size.height),
        Paint()
          ..color = gridColor
          ..strokeWidth = 1,
      );
      canvas.drawCircle(p, 5, Paint()..color = lineColor);
      canvas.drawCircle(p, 5, Paint()
        ..color = lineColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4);

      final value = data[hoverIndex!];
      final label = hoverIndex! < labels.length ? labels[hoverIndex!] : '';
      final tp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: value.toStringAsFixed(0),
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins'),
            ),
            if (label.isNotEmpty)
              TextSpan(
                text: '  $label',
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54, fontSize: 11, fontFamily: 'Poppins'),
              ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      double boxX = p.dx - tp.width / 2 - 8;
      if (boxX < 0) boxX = 0;
      if (boxX + tp.width + 16 > size.width) boxX = size.width - tp.width - 16;
      double boxY = p.dy - tp.height - 20;
      if (boxY < 0) boxY = p.dy + 12;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(boxX, boxY, tp.width + 16, tp.height + 10),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        rrect,
        Paint()..color = isDark ? const Color(0xE61E1E1E) : const Color(0xF2FFFFFF),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = gridColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      tp.paint(canvas, Offset(boxX + 8, boxY + 5));
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double distance = (end.dx - start.dx).abs();
    double drawn = 0;
    while (drawn < distance) {
      canvas.drawLine(
        Offset(start.dx + drawn, start.dy),
        Offset(start.dx + (drawn + dashWidth).clamp(0, distance), start.dy),
        paint,
      );
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.progress != progress || oldDelegate.hoverIndex != hoverIndex;
}