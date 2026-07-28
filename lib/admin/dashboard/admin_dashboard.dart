import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/admin/dashboard/admin_dashboard_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/dashboard_widgets.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AdminDashboardController());
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1100;
    final isMedium = width >= 700 && width < 1100;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Welcome Banner
                  _WelcomeBanner(ctrl: ctrl, isWide: isWide),
                  const SizedBox(height: 24),

                  // KPI Cards
                  _KpiGrid(
                      ctrl: ctrl,
                      crossAxisCount: isWide ? 4 : (isMedium ? 3 : 2)),
                  const SizedBox(height: 24),

                  // Charts row
                  if (isWide)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: RevenueLineChart(data: ctrl.revenueTrend),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child:
                                OrdersBarChart(data: ctrl.ordersTrend.toList()),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        RevenueLineChart(data: ctrl.revenueTrend),
                        const SizedBox(height: 16),
                        OrdersBarChart(data: ctrl.ordersTrend.toList()),
                      ],
                    ),
                  const SizedBox(height: 16),
                  WeeklyEarningsChart(data: ctrl.weeklyEarnings),
                  const SizedBox(height: 24),

                  // Recent Orders Table
                  RecentOrdersTable(orders: ctrl.recentOrders),
                  const SizedBox(height: 24),

                  // Quick Actions
                  QuickActions(
                    onApproveArtist: () {},
                    onApproveRider: () {},
                    onAddService: () {},
                    onSendNotification: () {},
                  ),
                  const SizedBox(height: 24),

                  // Bottom widgets grid
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              RecentReviewsList(reviews: ctrl.recentReviews),
                              const SizedBox(height: 16),
                              LatestComplaintsList(
                                  complaints: ctrl.latestComplaints),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              LatestPaymentsList(payments: ctrl.latestPayments),
                              const SizedBox(height: 16),
                              UpcomingAppointmentsList(
                                  appointments: ctrl.upcomingAppointments),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ActivityTimelineList(
                              activities: ctrl.activityTimeline),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        RecentReviewsList(reviews: ctrl.recentReviews),
                        const SizedBox(height: 16),
                        LatestComplaintsList(complaints: ctrl.latestComplaints),
                        const SizedBox(height: 16),
                        LatestPaymentsList(payments: ctrl.latestPayments),
                        const SizedBox(height: 16),
                        UpcomingAppointmentsList(
                            appointments: ctrl.upcomingAppointments),
                        const SizedBox(height: 16),
                        ActivityTimelineList(activities: ctrl.activityTimeline),
                      ],
                    ),
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  WELCOME BANNER (live date & time)
// ═══════════════════════════════════════════════════════════════
class _WelcomeBanner extends StatefulWidget {
  const _WelcomeBanner({required this.ctrl, required this.isWide});

  final AdminDashboardController ctrl;
  final bool isWide;

  @override
  State<_WelcomeBanner> createState() => _WelcomeBannerState();
}

class _WelcomeBannerState extends State<_WelcomeBanner> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  AdminDashboardController get ctrl => widget.ctrl;
  bool get isWide => widget.isWide;

  String _fmtCurrency(double v) {
    if (v >= 1000000) return 'Rs. ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'Rs. ${(v / 1000).toStringAsFixed(1)}k';
    return 'Rs. ${v.toStringAsFixed(0)}';
  }

  String _greeting() {
    final hour = _now.hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formattedDate() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${_now.day} ${months[_now.month - 1]} ${_now.year}';
  }

  String _formattedTime() {
    final hour24 = _now.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute:$second $period';
  }

  @override
  Widget build(BuildContext context) {
    final growth = ctrl.monthlyGrowth.value;
    final isPositive = growth >= 0;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.primary,
      ),
      child: Stack(
        children: [
          // Decorative glass circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -50,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _bannerText(context)),
                      _bannerHighlight(growth, isPositive),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bannerText(context),
                      const SizedBox(height: 20),
                      _bannerHighlight(growth, isPositive),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _bannerText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                _formattedDate(),
                style: AppTextStyles.caption.copyWith(color: Colors.white),
              ),
              const SizedBox(width: 10),
              Container(
                width: 1,
                height: 12,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.access_time_rounded,
                  size: 12, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                _formattedTime(),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '${_greeting()}, Admin 👋',
          style: AppTextStyles.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Here's what's happening with SmartStitch today.",
          style: AppTextStyles.bodySmall
              .copyWith(color: Colors.white.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  Widget _bannerHighlight(double growth, bool isPositive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Revenue',
            style: AppTextStyles.caption
                .copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            _fmtCurrency(ctrl.totalRevenue.value),
            style: AppTextStyles.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                '${growth.abs().toStringAsFixed(1)}% vs last month',
                style: AppTextStyles.caption.copyWith(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.ctrl, required this.crossAxisCount});

  final AdminDashboardController ctrl;
  final int crossAxisCount;

  String _fmtCurrency(double v) {
    if (v >= 1000000) return 'Rs. ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'Rs. ${(v / 1000).toStringAsFixed(1)}k';
    return 'Rs. ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final growth = ctrl.monthlyGrowth.value;
    final cards = [
      KpiCard(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Total Revenue',
        value: _fmtCurrency(ctrl.totalRevenue.value),
        color: AppColors.primary,
      ),
      KpiCard(
        icon: Icons.receipt_long_rounded,
        label: 'Total Orders',
        value: '${ctrl.totalOrders.value}',
        color: AppColors.info,
      ),
      KpiCard(
        icon: Icons.person_rounded,
        label: 'Total Customers',
        value: '${ctrl.totalCustomers.value}',
        color: AppColors.success,
      ),
      KpiCard(
        icon: Icons.content_cut_rounded,
        label: 'Total Artists',
        value: '${ctrl.totalArtists.value}',
        color: AppColors.primary,
      ),
      KpiCard(
        icon: Icons.delivery_dining_rounded,
        label: 'Total Riders',
        value: '${ctrl.totalRiders.value}',
        color: AppColors.info,
      ),
      KpiCard(
        icon: Icons.design_services_rounded,
        label: 'Active Services',
        value: '${ctrl.activeServices.value}',
        color: AppColors.success,
      ),
      KpiCard(
        icon: Icons.hourglass_top_rounded,
        label: 'Pending Orders',
        value: '${ctrl.pendingOrders.value}',
        color: AppColors.warning,
      ),
      KpiCard(
        icon: Icons.trending_up_rounded,
        label: 'Monthly Growth',
        value: '${growth.toStringAsFixed(1)}%',
        color: growth >= 0 ? AppColors.success : AppColors.error,
        trend: '${growth.toStringAsFixed(1)}%',
        isPositiveTrend: growth >= 0,
      ),
    ];

     return GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: cards.length,
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    mainAxisExtent: 130, // fixed height — no more aspect-ratio guessing
  ),
  itemBuilder: (context, index) => cards[index],
);  }
}
