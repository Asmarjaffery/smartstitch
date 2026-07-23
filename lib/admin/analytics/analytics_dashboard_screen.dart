import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/admin/analytics/analytics_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/booking_stats_card.dart';
import 'package:smartstitch/core/widgets/filter_chips.dart';
import 'package:smartstitch/core/widgets/glass_card.dart';
import 'package:smartstitch/core/widgets/growth_chart.dart';
import 'package:smartstitch/core/widgets/premium_app_bar.dart';
import 'package:smartstitch/core/widgets/revenue_card.dart';
import 'package:smartstitch/core/widgets/revenue_trend_chart.dart';
import 'package:smartstitch/core/widgets/service_pie_chart.dart';
import 'package:smartstitch/core/widgets/stats_card.dart';
import 'package:smartstitch/core/widgets/top_performers_card.dart';
import 'package:smartstitch/core/widgets/wallet_summary_card.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  late AnalyticsController controller;

  @override
  void initState() {
    super.initState();
    controller = AnalyticsController.to;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1100;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.scaffoldGradient(isDark)),
        child: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── PREMIUM HEADER ─────────────────────────────────────
                    // NOTE: wire `onRefresh` to your controller's existing refresh
                    // method (e.g. controller.fetchAnalytics()) — left null here
                    // since the exact method name isn't in the provided source.
                    PremiumDashboardHeader(
                      onRefresh: null,
                      notificationCount: 0,
                    ),

                    SizedBox(height: isMobile ? 20 : 24),

                    // ─── FILTER SECTION ─────────────────────────────────────
                    _sectionLabel('Filter by Period', isDark),
                    const SizedBox(height: 12),
                    FilterChips(controller: controller),

                    SizedBox(height: isMobile ? 20 : 24),

                    // ─── SUMMARY CARDS GRID ─────────────────────────────────
                    _buildSummaryGrid(context, isDark, isMobile, isTablet),

                    SizedBox(height: isMobile ? 20 : 24),

                    // ─── REVENUE TREND CHART ────────────────────────────────
                    GlassCard(
                      glowColor: AppColors.primary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Revenue Trend',
                                      style: AppTextStyles.sectionTitle.copyWith(
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Gross Sales over time',
                                      style: AppTextStyles.sectionSubtitle.copyWith(
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              ),
                              Text('Gross Sales',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 280,
                            child: RevenueTrendChart(controller: controller),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isMobile ? 20 : 24),

                    // ─── SERVICE & BOOKING ANALYTICS ────────────────────────
                    if (!isMobile)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GlassCard(
                              glowColor: const Color(0xFF7C3AED),
                              child: SizedBox(
                                height: 330,
                                child: ServicePieChart(
                                  slices: controller.servicePopularity,
                                  title: 'Service Breakdown',
                                  controller: controller,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: BookingStatsCard(
                              totalBookings: controller.completedOrders.value +
                                  controller.activeOrders.value +
                                  controller.cancelledOrders.value,
                              completedBookings: controller.completedOrders.value,
                              activeBookings: controller.activeOrders.value,
                              cancelledBookings: controller.cancelledOrders.value,
                              successRate: controller.deliverySuccessRate.value,
                              cancellationRate: controller.cancellationRate.value,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          GlassCard(
                            glowColor: const Color(0xFF7C3AED),
                            child: SizedBox(
                              height: 320,
                              child: ServicePieChart(
                                slices: controller.servicePopularity,
                                title: 'Service Breakdown',
                                controller: controller,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          BookingStatsCard(
                            totalBookings: controller.completedOrders.value +
                                controller.activeOrders.value +
                                controller.cancelledOrders.value,
                            completedBookings: controller.completedOrders.value,
                            activeBookings: controller.activeOrders.value,
                            cancelledBookings: controller.cancelledOrders.value,
                            successRate: controller.deliverySuccessRate.value,
                            cancellationRate: controller.cancellationRate.value,
                          ),
                        ],
                      ),

                    SizedBox(height: isMobile ? 20 : 24),

                    // ─── GROWTH ANALYTICS ───────────────────────────────────
                    _sectionLabel('Growth Analytics · Last 6 Months', isDark),
                    const SizedBox(height: 12),
                    GrowthChart(
                      title: 'Customer Growth',
                      subtitle: 'New customers acquired',
                      values: controller.customerGrowthData,
                      labels: _last6MonthLabels(),
                      barColor: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    GrowthChart(
                      title: 'Artist Growth',
                      subtitle: 'Artists onboarded',
                      values: controller.artistGrowthData,
                      labels: _last6MonthLabels(),
                      barColor: AppColors.accent,
                    ),
                    const SizedBox(height: 16),
                    GrowthChart(
                      title: 'Rider Growth',
                      subtitle: 'Riders onboarded',
                      values: controller.riderGrowthData,
                      labels: _last6MonthLabels(),
                      barColor: AppColors.warning,
                    ),

                    SizedBox(height: isMobile ? 20 : 24),

                    // ─── TOP PERFORMERS ─────────────────────────────────────
                    _sectionLabel('Top Performers Panel', isDark),
                    const SizedBox(height: 12),
                    if (!isMobile)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TopPerformersCard(
                              title: 'Top Artists',
                              entries: controller.topArtists,
                              icon: Icons.star_border_rounded,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TopPerformersCard(
                              title: 'Top Riders',
                              entries: controller.topRiders,
                              icon: Icons.motorcycle_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TopPerformersCard(
                              title: 'Top Customers',
                              entries: controller.topCustomers,
                              icon: Icons.person_outline_rounded,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          TopPerformersCard(
                            title: 'Top Artists',
                            entries: controller.topArtists,
                            icon: Icons.star_border_rounded,
                          ),
                          const SizedBox(height: 16),
                          TopPerformersCard(
                            title: 'Top Riders',
                            entries: controller.topRiders,
                            icon: Icons.motorcycle_outlined,
                          ),
                          const SizedBox(height: 16),
                          TopPerformersCard(
                            title: 'Top Customers',
                            entries: controller.topCustomers,
                            icon: Icons.person_outline_rounded,
                          ),
                        ],
                      ),

                    SizedBox(height: isMobile ? 20 : 24),

                    // ─── WALLET ANALYTICS ───────────────────────────────────
                    // NOTE: AnalyticsController has no dedicated "pendingWithdrawals"
                    // field yet — passing 0.0 until that's tracked. Add a
                    // `pendingWithdrawals` Rx<double> to the controller (filtered
                    // from `withdrawal_requests` where status == 'pending') to
                    // wire this up properly.
                    WalletSummaryCard(
                      artistEarnings: controller.totalArtistEarnings.value,
                      riderEarnings: controller.totalRiderEarnings.value,
                      withdrawals: controller.totalWithdrawals.value,
                      pendingWithdrawals: 0.0,
                    ),

                    SizedBox(height: isMobile ? 20 : 24),

                    // ─── FINANCIAL SUMMARY ──────────────────────────────────
                    _sectionLabel('Financial Summary', isDark),
                    const SizedBox(height: 12),
                    _buildFinancialSummary(context, isDark, isMobile),

                    SizedBox(height: isMobile ? 20 : 24),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: AppTextStyles.sectionTitle.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, bool isDark, bool isMobile, bool isTablet) {
    final cards = [
      RevenueCard(
        title: 'Gross Sales',
        value: controller.grossSales.value,
        icon: Icons.trending_up_rounded,
        accentColor: AppColors.primary,
      ),
      RevenueCard(
        title: 'Net Sales',
        value: controller.netSales.value,
        icon: Icons.shopping_bag_rounded,
        accentColor: AppColors.accent,
      ),
      StatsCard(
        title: 'Total Orders',
        value:
            '${controller.completedOrders.value + controller.cancelledOrders.value + controller.activeOrders.value}',
        subtitle: '${controller.completedOrders.value} completed',
        icon: Icons.shopping_cart_rounded,
        color: AppColors.info,
      ),
      StatsCard(
        title: 'Platform Revenue',
        value: formatCurrency(controller.totalPlatformRevenue.value),
        subtitle: 'Commission + Fees',
        icon: Icons.account_balance_rounded,
        color: AppColors.warning,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return GridView.count(
      crossAxisCount: isTablet ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isTablet ? 1.6 : 1.15,
      children: cards,
    );
  }

  Widget _buildFinancialSummary(BuildContext context, bool isDark, bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;

    final rows = [
      _FinancialStat(
        label: 'Admin Commission',
        value: controller.adminCommission.value,
        icon: Icons.percent_rounded,
        color: AppColors.primary,
      ),
      _FinancialStat(
        label: 'Artist Earnings',
        value: controller.totalArtistEarnings.value,
        icon: Icons.brush_rounded,
        color: const Color(0xFF7C3AED),
      ),
      _FinancialStat(
        label: 'Rider Earnings',
        value: controller.totalRiderEarnings.value,
        icon: Icons.two_wheeler_rounded,
        color: AppColors.info,
      ),
      _FinancialStat(
        label: 'Total Refunds',
        value: controller.totalRefunds.value,
        icon: Icons.replay_rounded,
        color: AppColors.error,
        isNegative: true,
      ),
      _FinancialStat(
        label: 'Profit',
        value: controller.platformProfit.value,
        icon: Icons.savings_rounded,
        color: AppColors.success,
        isPositive: true,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _financialCard(rows[i], isDark),
            if (i != rows.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: rows
          .map((row) => SizedBox(width: (screenWidth - 56) / 2, child: _financialCard(row, isDark)))
          .toList(),
    );
  }

  Widget _financialCard(_FinancialStat stat, bool isDark) {
    Color valueColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    if (stat.isNegative) valueColor = AppColors.error;
    if (stat.isPositive) valueColor = AppColors.success;

    return GlassCard(
      glowColor: stat.color,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: stat.color, width: 3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: stat.color.withValues(alpha: 0.14),
                    borderRadius: AppRadius.small,
                  ),
                  child: Icon(stat.icon, size: 16, color: stat.color),
                ),
                const SizedBox(width: 12),
                Text(
                  stat.label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            Text(
              formatCurrency(stat.value),
              style: AppTextStyles.h5.copyWith(color: valueColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _last6MonthLabels() {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final now = DateTime.now();
    return List.generate(6, (i) {
      final monthIndex = (now.month - 1 - (5 - i)) % 12;
      final normalizedIndex = monthIndex < 0 ? monthIndex + 12 : monthIndex;
      return monthNames[normalizedIndex];
    });
  }
}

class _FinancialStat {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final bool isNegative;
  final bool isPositive;

  _FinancialStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isNegative = false,
    this.isPositive = false,
  });
}