import 'package:flutter/material.dart';
import 'package:smartstitch/admin/analytics/analytics_controller.dart';
import '../../models/analytics_metrics.dart';

class ServicePieChart extends StatelessWidget {
  final List<ServiceSlice> slices;
  final String title;

  const ServicePieChart({
    Key? key,
    required this.slices,
    required this.title, required AnalyticsController controller,
  }) : super(key: key);

  static const List<Color> sliceColors = [
    Colors.purple,
    Colors.teal,
    Colors.orange,
    Colors.blue,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalVal = slices.fold<double>(0.0, (sum, item) => sum + item.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 24),
          if (slices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Text(
                  'No service sales in this period',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ),
            )
          else ...[
            Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    slices: slices,
                    totalValue: totalVal,
                    colors: sliceColors,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: List.generate(slices.length, (i) {
                final slice = slices[i];
                final col = sliceColors[slice.colorIndex % sliceColors.length];
                final percentage = totalVal == 0 ? 0.0 : (slice.value / totalVal) * 100;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${slice.label} (${percentage.toStringAsFixed(0)}%)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<ServiceSlice> slices;
  final double totalValue;
  final List<Color> colors;

  _PieChartPainter({
    required this.slices,
    required this.totalValue,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalValue == 0) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    double startAngle = -3.14159 / 2; // Start from top (12 o'clock)

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final col = colors[slice.colorIndex % colors.length];
      final sweepAngle = (slice.value / totalValue) * 2 * 3.14159;

      paint.color = col;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      startAngle += sweepAngle;
    }

    // Draw an inner white/grey circle to turn it into a beautiful donut chart!
    final center = Offset(size.width / 2, size.height / 2);
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // We can check if it is dark mode by drawing a circle of the canvas' background color or just white.
    // Instead of using context, we can just make a subtle semi-transparent mask or a clean white cutout
    canvas.drawCircle(center, size.width * 0.3, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
