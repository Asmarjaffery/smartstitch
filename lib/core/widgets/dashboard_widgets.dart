import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/dashboard_models.dart';


// ═══════════════════════════════════════════════════════════════
//  KPI CARD
// ═══════════════════════════════════════════════════════════════
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.trend,
    this.isPositiveTrend = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? trend;
  final bool isPositiveTrend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: AppShadows.soft(color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositiveTrend
                            ? AppColors.success
                            : AppColors.error)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveTrend
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 12,
                        color: isPositiveTrend
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend!,
                        style: AppTextStyles.caption.copyWith(
                          color: isPositiveTrend
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.lightTextPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.lightTextSecondary),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SECTION HEADER
// ═══════════════════════════════════════════════════════════════
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: AppTextStyles.h5
                  .copyWith(color: AppColors.lightTextPrimary),
            ),
          ],
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GLASS CONTAINER (reusable card shell)
// ═══════════════════════════════════════════════════════════════
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: AppShadows.soft(AppColors.primary),
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  REVENUE LINE CHART
// ═══════════════════════════════════════════════════════════════
class RevenueLineChart extends StatelessWidget {
  const RevenueLineChart({super.key, required this.data});

  final List<double> data;

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i]),
    );
    final maxY = data.isEmpty
        ? 100.0
        : (data.reduce((a, b) => a > b ? a : b) * 1.3).clamp(10.0, double.infinity);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Revenue Trend'),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: data.isEmpty
                ? const Center(child: Text('No data yet'))
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.lightBorder,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(
                              value >= 1000
                                  ? '${(value / 1000).toStringAsFixed(0)}k'
                                  : value.toStringAsFixed(0),
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.lightTextHint),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun'
                              ];
                              final idx = value.toInt();
                              if (idx < 0 || idx >= days.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  days[idx],
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.lightTextHint),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C4DFF), Color(0xFF8A63FF)],
                          ),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.25),
                                AppColors.primary.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.lightTextPrimary,
                          getTooltipItems: (spots) => spots
                              .map((s) => LineTooltipItem(
                                    'Rs. ${s.y.toStringAsFixed(0)}',
                                    AppTextStyles.labelSmall
                                        .copyWith(color: Colors.white),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ORDERS BAR CHART
// ═══════════════════════════════════════════════════════════════
class OrdersBarChart extends StatelessWidget {
  const OrdersBarChart({super.key, required this.data});

  final List<int> data;

  @override
  Widget build(BuildContext context) {
    final maxY = data.isEmpty
        ? 10.0
        : (data.reduce((a, b) => a > b ? a : b) * 1.4).clamp(5.0, double.infinity);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Orders Trend'),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: data.isEmpty
                ? const Center(child: Text('No data yet'))
                : BarChart(
                    BarChartData(
                      maxY: maxY,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.lightBorder,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) => Text(
                              value.toStringAsFixed(0),
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.lightTextHint),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun'
                              ];
                              final idx = value.toInt();
                              if (idx < 0 || idx >= days.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  days[idx],
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.lightTextHint),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(data.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: data[i].toDouble(),
                              width: 18,
                              borderRadius: BorderRadius.circular(6),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C4DFF), Color(0xFF8A63FF)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  WEEKLY EARNINGS CHART (area-style mini chart)
// ═══════════════════════════════════════════════════════════════
class WeeklyEarningsChart extends StatelessWidget {
  const WeeklyEarningsChart({super.key, required this.data});

  final List<double> data;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final maxVal =
        data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);
    final today = DateTime.now().weekday - 1;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Weekly Earnings'),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final ratio = data[i] / maxVal;
                final isToday = i == today;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 500 + (i * 60)),
                          curve: Curves.easeOutCubic,
                          height: (90 * ratio).clamp(4.0, 90.0),
                          decoration: BoxDecoration(
                            gradient: isToday
                                ? AppColors.primaryGradient
                                : LinearGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.4),
                                      AppColors.primary.withValues(alpha: 0.15),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _days[i],
                          style: AppTextStyles.caption.copyWith(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.lightTextSecondary,
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  RECENT ORDERS TABLE
// ═══════════════════════════════════════════════════════════════
class RecentOrdersTable extends StatelessWidget {
  const RecentOrdersTable({super.key, required this.orders});

  final List<RecentOrderModel> orders;

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Recent Orders'),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No recent orders')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.lightTextSecondary),
                dataTextStyle: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.lightTextPrimary),
                columnSpacing: 28,
                columns: const [
                  DataColumn(label: Text('Order ID')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Artist')),
                  DataColumn(label: Text('Rider')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Date')),
                ],
                rows: orders.map((o) {
                  return DataRow(cells: [
                    DataCell(Text(
                        '#${o.orderId.length > 6 ? o.orderId.substring(0, 6) : o.orderId}')),
                    DataCell(Text(o.customerName)),
                    DataCell(Text(o.artistName)),
                    DataCell(Text(o.riderName ?? '—')),
                    DataCell(Text('Rs. ${o.amount.toStringAsFixed(0)}')),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(o.status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        o.status,
                        style: AppTextStyles.caption
                            .copyWith(color: _statusColor(o.status)),
                      ),
                    )),
                    DataCell(
                        Text('${o.date.day}/${o.date.month}/${o.date.year}')),
                  ]);
                }).toList(),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  QUICK ACTIONS
// ═══════════════════════════════════════════════════════════════
class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onApproveArtist,
    required this.onApproveRider,
    required this.onAddService,
    required this.onSendNotification,
  });

  final VoidCallback onApproveArtist;
  final VoidCallback onApproveRider;
  final VoidCallback onAddService;
  final VoidCallback onSendNotification;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.verified_user_rounded, 'Approve Artist', onApproveArtist),
      (Icons.delivery_dining_rounded, 'Approve Rider', onApproveRider),
      (Icons.add_box_rounded, 'Add Service', onAddService),
      (Icons.notifications_active_rounded, 'Send Notification',
          onSendNotification),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions.map((a) {
              return InkWell(
                onTap: a.$3,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppShadows.primary,
                  ),
                  child: Column(
                    children: [
                      Icon(a.$1, color: Colors.white, size: 24),
                      const SizedBox(height: 8),
                      Text(
                        a.$2,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  RECENT REVIEWS LIST
// ═══════════════════════════════════════════════════════════════
class RecentReviewsList extends StatelessWidget {
  const RecentReviewsList({super.key, required this.reviews});

  final List<ReviewModel> reviews;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Recent Reviews'),
          const SizedBox(height: 12),
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No reviews yet'),
            )
          else
            ...reviews.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          r.customerName.isNotEmpty
                              ? r.customerName[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(r.customerName,
                                    style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.lightTextPrimary)),
                                const SizedBox(width: 6),
                                Icon(Icons.star_rounded,
                                    size: 14, color: AppColors.warning),
                                Text(r.rating.toStringAsFixed(1),
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.lightTextSecondary)),
                              ],
                            ),
                            Text(
                              r.comment,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.lightTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  LATEST COMPLAINTS LIST
// ═══════════════════════════════════════════════════════════════
class LatestComplaintsList extends StatelessWidget {
  const LatestComplaintsList({super.key, required this.complaints});

  final List<ComplaintModel> complaints;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Latest Complaints'),
          const SizedBox(height: 12),
          if (complaints.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No complaints yet'),
            )
          else
            ...complaints.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.report_problem_rounded,
                          size: 18, color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.lightTextPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(c.status,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.warning)),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  LATEST PAYMENTS LIST
// ═══════════════════════════════════════════════════════════════
class LatestPaymentsList extends StatelessWidget {
  const LatestPaymentsList({super.key, required this.payments});

  final List<PaymentModel> payments;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Latest Payments'),
          const SizedBox(height: 12),
          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No payments yet'),
            )
          else
            ...payments.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.payments_rounded,
                            size: 16, color: AppColors.success),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.userName,
                                style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.lightTextPrimary)),
                            Text(p.method,
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.lightTextSecondary)),
                          ],
                        ),
                      ),
                      Text('Rs. ${p.amount.toStringAsFixed(0)}',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.lightTextPrimary)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  UPCOMING APPOINTMENTS LIST
// ═══════════════════════════════════════════════════════════════
class UpcomingAppointmentsList extends StatelessWidget {
  const UpcomingAppointmentsList({super.key, required this.appointments});

  final List<AppointmentModel> appointments;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Upcoming Appointments'),
          const SizedBox(height: 12),
          if (appointments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No upcoming appointments'),
            )
          else
            ...appointments.map((a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.event_rounded,
                            size: 16, color: AppColors.info),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.customerName,
                                style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.lightTextPrimary)),
                            Text(a.serviceName,
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.lightTextSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        '${a.scheduledAt.day}/${a.scheduledAt.month} ${a.scheduledAt.hour}:${a.scheduledAt.minute.toString().padLeft(2, '0')}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ACTIVITY TIMELINE
// ═══════════════════════════════════════════════════════════════
class ActivityTimelineList extends StatelessWidget {
  const ActivityTimelineList({super.key, required this.activities});

  final List<ActivityModel> activities;

  IconData _iconFor(String type) {
    switch (type) {
      case 'order':
        return Icons.receipt_long_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'user':
        return Icons.person_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: "Today's Activity Timeline"),
          const SizedBox(height: 12),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No activity yet'),
            )
          else
            ...List.generate(activities.length, (i) {
              final a = activities[i];
              final isLast = i == activities.length - 1;
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_iconFor(a.type),
                              size: 12, color: Colors.white),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: AppColors.lightBorder,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title,
                                style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.lightTextPrimary)),
                            if (a.subtitle.isNotEmpty)
                              Text(a.subtitle,
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.lightTextSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              '${a.time.hour}:${a.time.minute.toString().padLeft(2, '0')}',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.lightTextHint),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}