import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/utils/bucket_helper.dart';
import 'package:smartstitch/core/utils/parser_helper.dart';
import 'package:smartstitch/core/utils/settings_helper.dart';
import 'package:smartstitch/models/admin_analytics_model.dart';
import 'package:smartstitch/models/analytics_metrics.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/models/top_performer_entry.dart';
import 'package:smartstitch/services/analytics_service.dart';
import 'package:smartstitch/services/financial_service.dart';
import 'package:smartstitch/services/growth_service.dart';
import '../../models/top_performer_entry.dart';



class AnalyticsController extends GetxController {
  static AnalyticsController get to => Get.find();

  final _db = FirebaseFirestore.instance;

  final isLoading = true.obs;
  // Default changed from last7Days -> last30Days. Real bookings can be weeks
  // old (e.g. seeded/test data), so defaulting to a 7-day window made the
  // dashboard look "broken" (all zeros) even though data was fetching fine.
  // 30 days gives a much better chance of showing something meaningful on
  // first load; the user can still switch to "This Week" manually.
  final selectedFilter = AnalyticsFilter.last30Days.obs;
  final customStart = Rxn<DateTime>();
  final customEnd = Rxn<DateTime>();

  // ─── LOAD / ERROR TRACKING ─────────────────────────────────────────────
  // Tracks whether each source collection has successfully returned at
  // least once, so isLoading only clears once everything has responded
  // (success OR error) instead of depending solely on the users listener.
  final _settingsLoaded = false.obs;
  final _usersLoaded = false.obs;
  final _ordersLoaded = false.obs;
  final _bookingsLoaded = false.obs;
  final _refundsLoaded = false.obs;
  final _withdrawalsLoaded = false.obs;

  // Surfaces the last error per source, in case the UI wants to show it.
  final lastError = Rxn<String>();

  // ─── REVENUE SUMMARIES ─────────────────────────────────────────────────
  final dailyRevenue = 0.0.obs;
  final weeklyRevenue = 0.0.obs;
  final monthlyRevenue = 0.0.obs;
  final yearlyRevenue = 0.0.obs;

  // ─── CHART SERIES ─────────────────────────────────────────────────────
  final revenueLineData = <double>[].obs;
  final revenueLineLabels = <String>[].obs;
  final ordersTrendData = <int>[].obs;
  final customerGrowthData = <double>[].obs;
  final artistGrowthData = <double>[].obs;
  final riderGrowthData = <double>[].obs;
  final servicePopularity = <ServiceSlice>[].obs;

  // ─── PERFORMANCE CARDS ─────────────────────────────────────────────────
  final topArtists = <TopPerformerEntry>[].obs;
  final topRiders = <TopPerformerEntry>[].obs;
  final mostOrderedServices = <TopPerformerEntry>[].obs;
  final highestRevenueCategory = ''.obs;
  final cancellationRate = 0.0.obs;
  final deliverySuccessRate = 0.0.obs;
  final avgOrderValue = 0.0.obs;

  // ─── FINANCIAL ANALYTICS ──────────────────────────────────────────────
  final grossSales = 0.0.obs;
  final netSales = 0.0.obs;
  final totalPlatformRevenue = 0.0.obs;
  final adminCommission = 0.0.obs;
  final totalArtistEarnings = 0.0.obs;
  final totalRiderEarnings = 0.0.obs;
  final platformProfit = 0.0.obs;
  final platformLoss = 0.0.obs;
  final totalRefunds = 0.0.obs;
  final totalWithdrawals = 0.0.obs;

  // ─── FINANCIAL CHART DATA ─────────────────────────────────────────────
  final profitVsLossData = <Map<String, double>>[].obs;
  final adminCommissionTrendData = <double>[].obs;
  final artistEarningsTrendData = <double>[].obs;
  final riderEarningsTrendData = <double>[].obs;
  final refundTrendData = <double>[].obs;
  final withdrawalTrendData = <double>[].obs;
  final chartLabels = <String>[].obs;

  // ─── PERFORMANCE ANALYTICS ────────────────────────────────────────────
  final topCustomers = <TopPerformerEntry>[].obs;
  final highestPayingCustomers = <TopPerformerEntry>[].obs;
  final averageDeliveryTime = 0.0.obs;
  final averageStitchingTime = 0.0.obs;
  final activeOrders = 0.obs;
  final completedOrders = 0.obs;
  final cancelledOrders = 0.obs;

  // ─── NEW: CUSTOMER RETENTION ANALYTICS ────────────────────────────────
  final repeatCustomersCount = 0.obs;
  final newCustomersCount = 0.obs;
  final returningCustomersCount = 0.obs;
  final newVsReturningTrend = <Map<String, int>>[].obs;

  // ─── NEW: PEAK ORDER HOURS ─────────────────────────────────────────────
  final peakOrderHours = <int, int>{}.obs;
  final peakHourLabel = ''.obs;

  // ─── NEW: PAYMENT METHOD ANALYTICS ─────────────────────────────────────
  final paymentMethodBreakdown = <String, int>{}.obs;
  final hasPaymentMethodData = false.obs;

  // ─── DATA STORAGE ─────────────────────────────────────────────────────
  final Map<String, Map<String, dynamic>> _orderDocs = {};
  final Map<String, Map<String, dynamic>> _bookingDocs = {};
  final Map<String, Map<String, dynamic>> _refundDocs = {};
  final Map<String, Map<String, dynamic>> _withdrawalDocs = {};
  final Map<String, Map<String, dynamic>> _userById = {};
  final Map<String, dynamic> _settings = {};

  List<Map<String, dynamic>> _userDocs = [];

  StreamSubscription? _ordersSub;
  StreamSubscription? _bookingsSub;
  StreamSubscription? _usersSub;
  StreamSubscription? _refundsSub;
  StreamSubscription? _withdrawalsSub;
  StreamSubscription? _settingsSub;

  @override
  void onInit() {
    super.onInit();
    _listenSettings();
    _listenUsers();
    _listenOrdersAndBookings();
    _listenFinancialData();
    ever(selectedFilter, (_) => _recalculate());
  }

  @override
  void onClose() {
    _ordersSub?.cancel();
    _bookingsSub?.cancel();
    _usersSub?.cancel();
    _refundsSub?.cancel();
    _withdrawalsSub?.cancel();
    _settingsSub?.cancel();
    super.onClose();
  }

  void setFilter(AnalyticsFilter filter) {
    selectedFilter.value = filter;
  }

  void setCustomRange(DateTime start, DateTime end) {
    customStart.value = start;
    customEnd.value = end;
    selectedFilter.value = AnalyticsFilter.custom;
  }

  /// Manual refresh hook — wire this to PremiumDashboardHeader's onRefresh.
  /// Streams already keep data live, so this just forces a recompute
  /// (useful for a pull-to-refresh / refresh-button UX).
  Future<void> refreshAnalytics() async {
    _recalculate();
  }

  DateTime _rangeStart() {
    final now = DateTime.now();
    switch (selectedFilter.value) {
      case AnalyticsFilter.today:
        return DateTime(now.year, now.month, now.day);
      case AnalyticsFilter.last7Days:
        return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      case AnalyticsFilter.last30Days:
        return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
      case AnalyticsFilter.last6Months:
        return DateTime(now.year, now.month - 5, 1);
      case AnalyticsFilter.lastYear:
        return DateTime(now.year - 1, now.month, now.day);
      case AnalyticsFilter.custom:
        return customStart.value ?? DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    }
  }

  DateTime _rangeEnd() {
    if (selectedFilter.value == AnalyticsFilter.custom) {
      final e = customEnd.value ?? DateTime.now();
      return DateTime(e.year, e.month, e.day, 23, 59, 59, 999);
    }
    return DateTime.now();
  }

  // ─── LOAD-STATE HELPER ─────────────────────────────────────────────────
  // isLoading only clears once every source has reported in (success or
  // error). This avoids the dashboard spinner getting stuck forever if,
  // say, the users listener throws before orders/bookings ever load.
  void _checkAllLoaded() {
    final allDone = _settingsLoaded.value &&
        _usersLoaded.value &&
        _ordersLoaded.value &&
        _bookingsLoaded.value &&
        _refundsLoaded.value &&
        _withdrawalsLoaded.value;
    if (allDone) {
      isLoading.value = false;
    }
  }

  void _listenSettings() {
    _settingsSub = _db.collection('settings').doc('platform').snapshots().listen(
      (snap) {
        // ignore: avoid_print
        print('✅ [analytics] settings/platform fetched (exists: ${snap.exists})');
        _settings.clear();
        _settings.addAll(snap.data() ?? {});
        _settingsLoaded.value = true;
        _recalculate();
        _checkAllLoaded();
      },
      onError: (e) {
        // ignore: avoid_print
        print('❌ [analytics] SETTINGS ERROR: $e');
        lastError.value = 'settings: $e';
        _settingsLoaded.value = true; // don't block the UI forever
        _checkAllLoaded();
      },
    );
  }

  void _listenUsers() {
    _usersSub = _db.collection('users').snapshots().listen(
      (snap) {
        // ignore: avoid_print
        print('✅ [analytics] users fetched: ${snap.docs.length} docs');
        _userDocs = snap.docs.map((d) {
          final data = d.data();
          data['_docId'] = d.id;
          return data;
        }).toList();

        _userById.clear();
        for (final u in _userDocs) {
          final id = (u['_docId'] ?? '').toString();
          if (id.isNotEmpty) _userById[id] = u;
        }

        _usersLoaded.value = true;
        _recalculate();
        _checkAllLoaded();
      },
      onError: (e) {
        // ignore: avoid_print
        print('❌ [analytics] USERS ERROR: $e');
        lastError.value = 'users: $e';
        _usersLoaded.value = true;
        _checkAllLoaded();
      },
    );
  }

  void _listenOrdersAndBookings() {
    _ordersSub = _db.collection('orders').snapshots().listen(
      (snap) {
        // ignore: avoid_print
        print('✅ [analytics] orders fetched: ${snap.docs.length} docs');
        _orderDocs.clear();
        for (final doc in snap.docs) {
          _orderDocs[doc.id] = {...doc.data(), '_docId': doc.id};
        }
        _ordersLoaded.value = true;
        _recalculate();
        _checkAllLoaded();
      },
      onError: (e) {
        // ignore: avoid_print
        print('❌ [analytics] ORDERS ERROR: $e');
        lastError.value = 'orders: $e';
        _ordersLoaded.value = true;
        _checkAllLoaded();
      },
    );

    _bookingsSub = _db.collection('bookings').snapshots().listen(
      (snap) {
        // ignore: avoid_print
        print('✅ [analytics] bookings fetched: ${snap.docs.length} docs');
        _bookingDocs.clear();
        for (final doc in snap.docs) {
          final data = doc.data();
          _bookingDocs[doc.id] = {
            ...data,
            'totalAmount': (data['servicePrice'] ?? 0).toDouble(),
            '_docId': doc.id,
          };
        }
        _bookingsLoaded.value = true;
        _recalculate();
        _checkAllLoaded();
      },
      onError: (e) {
        // ignore: avoid_print
        print('❌ [analytics] BOOKINGS ERROR: $e');
        lastError.value = 'bookings: $e';
        _bookingsLoaded.value = true;
        _checkAllLoaded();
      },
    );
  }

  void _listenFinancialData() {
    _refundsSub = _db.collection('refunds').snapshots().listen(
      (snap) {
        // ignore: avoid_print
        print('✅ [analytics] refunds fetched: ${snap.docs.length} docs');
        _refundDocs.clear();
        for (final doc in snap.docs) {
          _refundDocs[doc.id] = {...doc.data(), '_docId': doc.id};
        }
        _refundsLoaded.value = true;
        _recalculate();
        _checkAllLoaded();
      },
      onError: (e) {
        // ignore: avoid_print
        print('❌ [analytics] REFUNDS ERROR: $e');
        lastError.value = 'refunds: $e';
        _refundsLoaded.value = true;
        _checkAllLoaded();
      },
    );

    _withdrawalsSub = _db.collection('withdrawal_requests').snapshots().listen(
      (snap) {
        // ignore: avoid_print
        print('✅ [analytics] withdrawal_requests fetched: ${snap.docs.length} docs');
        _withdrawalDocs.clear();
        for (final doc in snap.docs) {
          _withdrawalDocs[doc.id] = {...doc.data(), '_docId': doc.id};
        }
        _withdrawalsLoaded.value = true;
        _recalculate();
        _checkAllLoaded();
      },
      onError: (e) {
        // ignore: avoid_print
        print('❌ [analytics] WITHDRAWALS ERROR: $e');
        lastError.value = 'withdrawal_requests: $e';
        _withdrawalsLoaded.value = true;
        _checkAllLoaded();
      },
    );
  }

  bool _isDeliveredStatus(String status) =>
      status == 'delivered' || status == 'completed';

  bool _isActiveStatus(String status) =>
      status == 'pending' ||
      status == 'accepted' ||
      status == 'in_progress' ||
      status == 'processing' ||
      status == 'assigned';

  bool _isCancelledStatus(String status) =>
      status == 'cancelled' || status == 'canceled';

  bool _isApprovedOrCompleted(String status) =>
      status == 'approved' ||
      status == 'completed' ||
      status == 'paid' ||
      status == 'success';

  String _getUserIdFromDoc(Map<String, dynamic> doc) {
    final customerId = ParserHelper.parseString(doc['customerId']);
    if (customerId.isNotEmpty) return customerId;
    final userId = ParserHelper.parseString(doc['userId']);
    if (userId.isNotEmpty) return userId;
    return ParserHelper.parseString(doc['customer']);
  }

  String _getArtistIdFromDoc(Map<String, dynamic> doc) =>
      ParserHelper.parseString(doc['artistId']);

  String _getRiderIdFromDoc(Map<String, dynamic> doc) =>
      ParserHelper.parseString(doc['riderId']);

  Map<String, dynamic>? _userFromId(String id) =>
      id.isEmpty ? null : _userById[id];

  String _displayNameFromUser(Map<String, dynamic>? user, {String fallback = 'User'}) {
    if (user == null) return fallback;
    var name = ParserHelper.parseString(user['name']);
    if (name.isNotEmpty) return name;
    name = ParserHelper.parseString(user['fullName']);
    if (name.isNotEmpty) return name;
    name = ParserHelper.parseString(user['displayName']);
    return name.isNotEmpty ? name : fallback;
  }

  String? _avatarFromUser(Map<String, dynamic>? user) {
    if (user == null) return null;
    var image = ParserHelper.parseString(user['photoUrl']);
    if (image.isNotEmpty) return image;
    image = ParserHelper.parseString(user['profileImage']);
    return image.isNotEmpty ? image : null;
  }

  void _recalculate() {
    final rangeStart = _rangeStart();
    final rangeEnd = _rangeEnd();
    final bucketConfig = BucketConfig.build(rangeStart, rangeEnd, selectedFilter.value);

    final allTransactions = <Map<String, dynamic>>[
      ..._orderDocs.values,
      ..._bookingDocs.values,
    ];

    // ignore: avoid_print
    print('🔄 [analytics] recalculating with ${allTransactions.length} '
        'transactions (${_orderDocs.length} orders + ${_bookingDocs.length} bookings), '
        '${_userDocs.length} users, ${_refundDocs.length} refunds, '
        '${_withdrawalDocs.length} withdrawals');

    final metrics = _calculateAllMetrics(allTransactions, rangeStart, rangeEnd, bucketConfig);

    dailyRevenue.value = metrics.dailyRevenue;
    weeklyRevenue.value = metrics.weeklyRevenue;
    monthlyRevenue.value = metrics.monthlyRevenue;
    yearlyRevenue.value = metrics.yearlyRevenue;

    cancellationRate.value = metrics.cancellationRate;
    deliverySuccessRate.value = metrics.deliverySuccessRate;
    avgOrderValue.value = metrics.avgOrderValue;

    completedOrders.value = metrics.completedCount;
    activeOrders.value = metrics.activeCount;
    cancelledOrders.value = metrics.cancelledCount;

    averageDeliveryTime.value = metrics.avgDeliveryTime;
    averageStitchingTime.value = metrics.avgStitchingTime;

    topArtists.value = metrics.topArtists;
    topRiders.value = metrics.topRiders;
    topCustomers.value = metrics.topCustomers;
    highestPayingCustomers.value = metrics.highestPayingCustomers;
    mostOrderedServices.value = metrics.mostOrderedServices;

    highestRevenueCategory.value =
        metrics.highestRevenueCategory.isEmpty ? 'N/A' : metrics.highestRevenueCategory;
    servicePopularity.value = metrics.servicePopularitySlices;

    grossSales.value = metrics.grossSales;
    totalPlatformRevenue.value = metrics.platformRevenue;
    adminCommission.value = metrics.adminCommission;
    totalArtistEarnings.value = metrics.artistEarnings;
    totalRiderEarnings.value = metrics.riderEarnings;

    final refundMetrics = _processRefunds(rangeStart, rangeEnd, bucketConfig);
    totalRefunds.value = refundMetrics.totalRefunds;

    netSales.value = metrics.grossSales - refundMetrics.totalRefunds;

    for (int i = 0; i < bucketConfig.bucketCount; i++) {
      metrics.refundTrend[i] += refundMetrics.refundTrend[i];
    }

    final withdrawalMetrics = _processWithdrawals(rangeStart, rangeEnd, bucketConfig);
    totalWithdrawals.value = withdrawalMetrics.totalWithdrawals;
    for (int i = 0; i < bucketConfig.bucketCount; i++) {
      metrics.withdrawalTrend[i] += withdrawalMetrics.withdrawalTrend[i];
    }

    final profitLoss = FinancialService.calculateProfitLoss(
      platformRevenue: metrics.platformRevenue,
      refunds: refundMetrics.totalRefunds,
      couponDiscounts: metrics.couponDiscountsTotal,
      chargebacks: metrics.chargebacksTotal,
      failedPayments: metrics.failedPaymentsTotal,
      platformRevenueTrend: metrics.platformRevenueTrend,
      refundTrend: refundMetrics.refundTrend,
      settings: _settings,
    );

    platformProfit.value = profitLoss.profit;
    platformLoss.value = profitLoss.loss;

    revenueLineData.value = metrics.revenueTrend;
    revenueLineLabels.value = bucketConfig.labels();
    ordersTrendData.value = metrics.ordersTrend;

    adminCommissionTrendData.value = metrics.commissionTrend;
    artistEarningsTrendData.value = metrics.artistTrend;
    riderEarningsTrendData.value = metrics.riderTrend;
    refundTrendData.value = refundMetrics.refundTrend;
    withdrawalTrendData.value = withdrawalMetrics.withdrawalTrend;

    profitVsLossData.value = List.generate(bucketConfig.bucketCount, (i) {
      return {'profit': profitLoss.profitTrend[i], 'loss': profitLoss.lossTrend[i]};
    });

    chartLabels.value = bucketConfig.labels();

    final growthSeries = GrowthService.calculateGrowthSeries(_userDocs);
    customerGrowthData.value = growthSeries['customers'] ?? [];
    artistGrowthData.value = growthSeries['artists'] ?? [];
    riderGrowthData.value = growthSeries['riders'] ?? [];

    _computeCustomerRetention(allTransactions, rangeStart, rangeEnd, bucketConfig);
    _computePeakOrderHours(allTransactions, rangeStart, rangeEnd);
    _computePaymentMethodAnalytics(allTransactions, rangeStart, rangeEnd);

    // ignore: avoid_print
    print('📊 [analytics] grossSales=${grossSales.value} '
        'orders(completed/active/cancelled)='
        '${completedOrders.value}/${activeOrders.value}/${cancelledOrders.value}');
  }

  _AnalyticsMetricsInternal _calculateAllMetrics(
    List<Map<String, dynamic>> transactions,
    DateTime rangeStart,
    DateTime rangeEnd,
    BucketConfig bucketConfig,
  ) {
    final metrics = _AnalyticsMetricsInternal(bucketConfig.bucketCount);

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final weekAgo = startOfDay.subtract(const Duration(days: 6));
    final monthAgo = startOfDay.subtract(const Duration(days: 29));
    final yearAgo = DateTime(now.year - 1, now.month, now.day);

    for (final doc in transactions) {
      final createdAt = ParserHelper.parseDate(doc['createdAt']);
      final status = ParserHelper.parseString(doc['status']).toLowerCase();
      final amount = ParserHelper.parseDouble(doc['totalAmount'] ?? doc['servicePrice']);

      if (createdAt == null) continue;

      if (_isDeliveredStatus(status)) {
        if (!createdAt.isBefore(startOfDay)) metrics.dailyRevenue += amount;
        if (!createdAt.isBefore(weekAgo)) metrics.weeklyRevenue += amount;
        if (!createdAt.isBefore(monthAgo)) metrics.monthlyRevenue += amount;
        if (!createdAt.isBefore(yearAgo)) metrics.yearlyRevenue += amount;
      }

      final inRange = !createdAt.isBefore(rangeStart) && !createdAt.isAfter(rangeEnd);
      if (!inRange) continue;

      metrics.totalOrders++;

      if (_isCancelledStatus(status)) {
        metrics.cancelledCount++;
        final category = ParserHelper.parseString(doc['category'] ?? doc['serviceCategory'], fallback: 'General');
        metrics.cancelledByCategory[category] = (metrics.cancelledByCategory[category] ?? 0) + 1;
      } else if (_isActiveStatus(status)) {
        metrics.activeCount++;
      }

      if (_isDeliveredStatus(status)) {
        metrics.deliveredCount++;
        metrics.completedCount++;
        metrics.revenueForAvg += amount;
      }

      final bucketIndex = bucketConfig.indexOf(createdAt);
      if (bucketIndex != -1) {
        metrics.ordersTrend[bucketIndex]++;
      }

      if (_isDeliveredStatus(status)) {
        metrics.grossSales += amount;

        final commissionRate = SettingsHelper.getCommissionRate(_settings);
        final adminFee = amount * commissionRate;
        final artistEarnings = math.max(0.0, amount - adminFee);
        final riderEarnings = ParserHelper.parseDouble(doc['deliveryFee']);

        metrics.adminCommission += adminFee;
        metrics.artistEarnings += artistEarnings;
        metrics.riderEarnings += riderEarnings;

        final convenienceFee = ParserHelper.parseDouble(doc['convenienceFee']);
        final serviceFee = ParserHelper.parseDouble(doc['serviceFee']);
        final platformCharges = ParserHelper.parseDouble(doc['platformCharges']);
        final surgeCharges = ParserHelper.parseDouble(doc['surgeCharges']);
        final otherIncome = ParserHelper.parseDouble(doc['otherPlatformIncome']);

        metrics.convenienceFeeTotal += convenienceFee;
        metrics.serviceFeeTotal += serviceFee;

        final platformChargeVal = platformCharges > 0 ? platformCharges : amount * SettingsHelper.getPlatformChargeRate(_settings);
        final surgeChargeVal = surgeCharges > 0 ? surgeCharges : amount * SettingsHelper.getSurgeChargeRate(_settings);

        metrics.platformChargesTotal += platformChargeVal;
        metrics.surgeChargesTotal += surgeChargeVal;
        metrics.otherPlatformIncomeTotal += otherIncome;

        final orderPlatformRevenue = adminFee +
            platformChargeVal +
            convenienceFee +
            serviceFee +
            surgeChargeVal +
            otherIncome;

        metrics.platformRevenue += orderPlatformRevenue;

        metrics.couponDiscountsTotal += ParserHelper.parseDouble(doc['couponDiscount']);
        metrics.chargebacksTotal += ParserHelper.parseDouble(doc['chargeback']);
        metrics.failedPaymentsTotal += ParserHelper.parseDouble(doc['failedPayment']);

        final category = ParserHelper.parseString(doc['category'] ?? doc['serviceCategory'], fallback: 'General');
        metrics.categoryRevenue[category] = (metrics.categoryRevenue[category] ?? 0) + amount;

        final serviceName = ParserHelper.parseString(doc['serviceName'], fallback: 'Service');
        metrics.serviceCount[serviceName] = (metrics.serviceCount[serviceName] ?? 0) + 1;

        final customerId = _getUserIdFromDoc(doc);
        if (customerId.isNotEmpty) {
          metrics.customerOrders[customerId] = (metrics.customerOrders[customerId] ?? 0) + 1;
          metrics.customerSpending[customerId] = (metrics.customerSpending[customerId] ?? 0) + amount;
          final customer = _userFromId(customerId);
          if (customer != null) {
            metrics.customerNames[customerId] = _displayNameFromUser(customer, fallback: customerId);
            final av = _avatarFromUser(customer);
            if (av != null) metrics.customerAvatars[customerId] = av;
          }
        }

        if (bucketIndex != -1) {
          metrics.revenueTrend[bucketIndex] += amount;
          metrics.platformRevenueTrend[bucketIndex] += orderPlatformRevenue;
          metrics.commissionTrend[bucketIndex] += adminFee;
          metrics.artistTrend[bucketIndex] += artistEarnings;
          metrics.riderTrend[bucketIndex] += riderEarnings;
        }

        final artistId = _getArtistIdFromDoc(doc);
        if (artistId.isNotEmpty) {
          metrics.artistRevenue[artistId] = (metrics.artistRevenue[artistId] ?? 0) + amount;
          final artist = _userFromId(artistId);
          metrics.artistNames[artistId] = _displayNameFromUser(artist, fallback: ParserHelper.parseString(doc['artistName'], fallback: 'Artist'));
          final av = _avatarFromUser(artist);
          if (av != null) metrics.artistAvatars[artistId] = av;
        }

        final riderId = _getRiderIdFromDoc(doc);
        if (riderId.isNotEmpty) {
          metrics.riderDeliveries[riderId] = (metrics.riderDeliveries[riderId] ?? 0) + 1;
          final rider = _userFromId(riderId);
          metrics.riderNames[riderId] = _displayNameFromUser(rider, fallback: ParserHelper.parseString(doc['riderName'], fallback: 'Rider'));
          final av = _avatarFromUser(rider);
          if (av != null) metrics.riderAvatars[riderId] = av;
        }

        final deliveredAt = ParserHelper.parseDate(doc['deliveredAt']);
        if (deliveredAt != null) {
          metrics.totalDeliveryTime += deliveredAt.difference(createdAt).inMinutes.toDouble();
          metrics.deliveryTimeCount++;
        }

        final completedAt = ParserHelper.parseDate(doc['completedAt']);
        if (completedAt != null) {
          metrics.totalStitchingTime += completedAt.difference(createdAt).inMinutes.toDouble();
          metrics.stitchingTimeCount++;
        }
      }
    }

    metrics.calcCancellationRate();
    metrics.calcDeliverySuccessRate();
    metrics.calcAvgOrderValue();
    metrics.calcAvgDeliveryTime();
    metrics.calcAvgStitchingTime();

    metrics.topArtists = _topPerformersFromDouble(
      metrics.artistRevenue,
      nameResolver: (id) => metrics.artistNames[id] ?? id,
      imageResolver: (id) => metrics.artistAvatars[id],
      subtitleBuilder: (value) => 'Rs. ${value.toStringAsFixed(0)} revenue',
    );

    metrics.topRiders = _topPerformersFromCount(
      metrics.riderDeliveries,
      nameResolver: (id) => metrics.riderNames[id] ?? id,
      imageResolver: (id) => metrics.riderAvatars[id],
      subtitleBuilder: (value) => '$value deliveries',
    );

    metrics.topCustomers = _topPerformersFromCount(
      metrics.customerOrders,
      nameResolver: (id) => metrics.customerNames[id] ?? id,
      imageResolver: (id) => metrics.customerAvatars[id],
      subtitleBuilder: (count) => '$count orders',
    );

    metrics.highestPayingCustomers = _topPerformersFromDouble(
      metrics.customerSpending,
      nameResolver: (id) => metrics.customerNames[id] ?? id,
      imageResolver: (id) => metrics.customerAvatars[id],
      subtitleBuilder: (amount) => 'Rs. ${amount.toStringAsFixed(0)}',
    );

    metrics.mostOrderedServices = _topServices(metrics.serviceCount);

    if (metrics.categoryRevenue.isNotEmpty) {
      metrics.highestRevenueCategory = metrics.categoryRevenue.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    metrics.servicePopularitySlices = _serviceSlices(metrics.serviceCount);

    return metrics;
  }

  _RefundMetricsInternal _processRefunds(
    DateTime rangeStart,
    DateTime rangeEnd,
    BucketConfig bucketConfig,
  ) {
    final metrics = _RefundMetricsInternal(bucketConfig.bucketCount);

    for (final refund in _refundDocs.values) {
      final status = ParserHelper.parseString(refund['status']).toLowerCase();
      final amount = ParserHelper.parseDouble(refund['amount'] ?? refund['refundAmount']);
      final createdAt = ParserHelper.parseDate(refund['createdAt']);

      if (createdAt == null || createdAt.isBefore(rangeStart) || createdAt.isAfter(rangeEnd)) {
        continue;
      }

      if (!_isApprovedOrCompleted(status)) continue;

      metrics.totalRefunds += amount;

      final bucketIndex = bucketConfig.indexOf(createdAt);
      if (bucketIndex != -1) {
        metrics.refundTrend[bucketIndex] += amount;
      }
    }

    return metrics;
  }

  _WithdrawalMetricsInternal _processWithdrawals(
    DateTime rangeStart,
    DateTime rangeEnd,
    BucketConfig bucketConfig,
  ) {
    final metrics = _WithdrawalMetricsInternal(bucketConfig.bucketCount);

    for (final withdrawal in _withdrawalDocs.values) {
      final status = ParserHelper.parseString(withdrawal['status']).toLowerCase();
      final amount = ParserHelper.parseDouble(withdrawal['amount']);
      final createdAt = ParserHelper.parseDate(withdrawal['createdAt']);

      if (createdAt == null || createdAt.isBefore(rangeStart) || createdAt.isAfter(rangeEnd)) {
        continue;
      }

      if (!_isApprovedOrCompleted(status)) continue;

      metrics.totalWithdrawals += amount;

      final bucketIndex = bucketConfig.indexOf(createdAt);
      if (bucketIndex != -1) {
        metrics.withdrawalTrend[bucketIndex] += amount;
      }
    }

    return metrics;
  }

  void _computeCustomerRetention(
    List<Map<String, dynamic>> transactions,
    DateTime rangeStart,
    DateTime rangeEnd,
    BucketConfig bucketConfig,
  ) {
    final Map<String, List<DateTime>> completedOrderDatesByCustomer = {};

    for (final doc in transactions) {
      final status = ParserHelper.parseString(doc['status']).toLowerCase();
      if (!_isDeliveredStatus(status)) continue;

      final createdAt = ParserHelper.parseDate(doc['createdAt']);
      if (createdAt == null) continue;

      final customerId = _getUserIdFromDoc(doc);
      if (customerId.isEmpty) continue;

      completedOrderDatesByCustomer.putIfAbsent(customerId, () => []).add(createdAt);
    }

    for (final list in completedOrderDatesByCustomer.values) {
      list.sort();
    }

    int repeatCustomers = 0;
    int newInRange = 0;
    int returningInRange = 0;

    final newReturningBuckets = List.generate(
      bucketConfig.bucketCount,
      (_) => {'new': 0, 'returning': 0},
    );

    completedOrderDatesByCustomer.forEach((customerId, dates) {
      if (dates.length >= 2) repeatCustomers++;

      for (int i = 0; i < dates.length; i++) {
        final orderDate = dates[i];
        final inRange = !orderDate.isBefore(rangeStart) && !orderDate.isAfter(rangeEnd);
        if (!inRange) continue;

        final isFirstOrderEver = i == 0;
        if (isFirstOrderEver) {
          newInRange++;
        } else {
          returningInRange++;
        }

        final bucketIndex = bucketConfig.indexOf(orderDate);
        if (bucketIndex != -1) {
          final key = isFirstOrderEver ? 'new' : 'returning';
          newReturningBuckets[bucketIndex][key] = (newReturningBuckets[bucketIndex][key] ?? 0) + 1;
        }
      }
    });

    repeatCustomersCount.value = repeatCustomers;
    newCustomersCount.value = newInRange;
    returningCustomersCount.value = returningInRange;
    newVsReturningTrend.value = newReturningBuckets;
  }

  void _computePeakOrderHours(
    List<Map<String, dynamic>> transactions,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final Map<int, int> hourCounts = {for (var h = 0; h < 24; h++) h: 0};

    for (final doc in transactions) {
      final createdAt = ParserHelper.parseDate(doc['createdAt']);
      if (createdAt == null) continue;

      final inRange = !createdAt.isBefore(rangeStart) && !createdAt.isAfter(rangeEnd);
      if (!inRange) continue;

      hourCounts[createdAt.hour] = (hourCounts[createdAt.hour] ?? 0) + 1;
    }

    peakOrderHours.value = hourCounts;

    if (hourCounts.values.every((v) => v == 0)) {
      peakHourLabel.value = 'N/A';
    } else {
      final topHourEntry = hourCounts.entries.reduce((a, b) => b.value > a.value ? b : a);
      final hour = topHourEntry.key;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      peakHourLabel.value = '$displayHour:00 $period';
    }
  }

  void _computePaymentMethodAnalytics(
    List<Map<String, dynamic>> transactions,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final Map<String, int> breakdown = {};
    bool fieldExists = false;

    for (final doc in transactions) {
      if (!doc.containsKey('paymentMethod')) continue;

      final createdAt = ParserHelper.parseDate(doc['createdAt']);
      if (createdAt == null) continue;

      final inRange = !createdAt.isBefore(rangeStart) && !createdAt.isAfter(rangeEnd);
      if (!inRange) continue;

      final method = ParserHelper.parseString(doc['paymentMethod']);
      if (method.isEmpty) continue;

      fieldExists = true;
      breakdown[method] = (breakdown[method] ?? 0) + 1;
    }

    hasPaymentMethodData.value = fieldExists;
    paymentMethodBreakdown.value = breakdown;
  }

  List<TopPerformerEntry> _topPerformersFromCount(
    Map<String, int> map, {
    required String Function(String id) nameResolver,
    String? Function(String id)? imageResolver,
    required String Function(int value) subtitleBuilder,
  }) {
    if (map.isEmpty) return <TopPerformerEntry>[];
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(5)
        .map((e) => TopPerformerEntry(
              name: nameResolver(e.key),
              subtitle: subtitleBuilder(e.value),
              value: e.value.toDouble(),
              imageUrl: imageResolver?.call(e.key),
            ))
        .toList();
  }

  List<TopPerformerEntry> _topPerformersFromDouble(
    Map<String, double> map, {
    required String Function(String id) nameResolver,
    String? Function(String id)? imageResolver,
    required String Function(double value) subtitleBuilder,
  }) {
    if (map.isEmpty) return <TopPerformerEntry>[];
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(5)
        .map((e) => TopPerformerEntry(
              name: nameResolver(e.key),
              subtitle: subtitleBuilder(e.value),
              value: e.value,
              imageUrl: imageResolver?.call(e.key),
            ))
        .toList();
  }

  List<TopPerformerEntry> _topServices(Map<String, int> serviceCount) {
    if (serviceCount.isEmpty) return <TopPerformerEntry>[];
    final entries = serviceCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(5)
        .map((e) => TopPerformerEntry(
              name: e.key,
              subtitle: '${e.value} orders',
              value: e.value.toDouble(),
            ))
        .toList();
  }

  List<ServiceSlice> _serviceSlices(Map<String, int> servicePopularityMap) {
    if (servicePopularityMap.isEmpty) return <ServiceSlice>[];
    final entries = servicePopularityMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(6)
        .toList()
        .asMap()
        .entries
        .map((e) => ServiceSlice(
              label: e.value.key,
              value: e.value.value.toDouble(),
              colorIndex: e.key,
            ))
        .toList();
  }
}

class _AnalyticsMetricsInternal {
  double dailyRevenue = 0;
  double weeklyRevenue = 0;
  double monthlyRevenue = 0;
  double yearlyRevenue = 0;
  double grossSales = 0;

  int totalOrders = 0;
  int deliveredCount = 0;
  int completedCount = 0;
  int activeCount = 0;
  int cancelledCount = 0;

  double cancellationRate = 0;
  double deliverySuccessRate = 0;
  double avgOrderValue = 0;
  double avgDeliveryTime = 0;
  double avgStitchingTime = 0;

  double revenueForAvg = 0;
  double totalDeliveryTime = 0;
  double totalStitchingTime = 0;
  int deliveryTimeCount = 0;
  int stitchingTimeCount = 0;

  double platformRevenue = 0;
  double adminCommission = 0;
  double artistEarnings = 0;
  double riderEarnings = 0;
  double convenienceFeeTotal = 0;
  double serviceFeeTotal = 0;
  double platformChargesTotal = 0;
  double surgeChargesTotal = 0;
  double otherPlatformIncomeTotal = 0;
  double couponDiscountsTotal = 0;
  double chargebacksTotal = 0;
  double failedPaymentsTotal = 0;

  List<TopPerformerEntry> topArtists = [];
  List<TopPerformerEntry> topRiders = [];
  List<TopPerformerEntry> topCustomers = [];
  List<TopPerformerEntry> highestPayingCustomers = [];
  List<TopPerformerEntry> mostOrderedServices = [];

  String highestRevenueCategory = '';
  List<ServiceSlice> servicePopularitySlices = [];

  late final List<double> revenueTrend;
  late final List<double> platformRevenueTrend;
  late final List<int> ordersTrend;
  late final List<double> commissionTrend;
  late final List<double> artistTrend;
  late final List<double> riderTrend;
  late final List<double> refundTrend;
  late final List<double> withdrawalTrend;

  final Map<String, double> categoryRevenue = {};
  final Map<String, int> serviceCount = {};
  final Map<String, double> artistRevenue = {};
  final Map<String, String> artistNames = {};
  final Map<String, String> artistAvatars = {};
  final Map<String, int> riderDeliveries = {};
  final Map<String, String> riderNames = {};
  final Map<String, String> riderAvatars = {};
  final Map<String, int> customerOrders = {};
  final Map<String, double> customerSpending = {};
  final Map<String, String> customerNames = {};
  final Map<String, String> customerAvatars = {};
  final Map<String, int> cancelledByCategory = {};

  _AnalyticsMetricsInternal(int bucketCount) {
    revenueTrend = List<double>.filled(bucketCount, 0);
    platformRevenueTrend = List<double>.filled(bucketCount, 0);
    ordersTrend = List<int>.filled(bucketCount, 0);
    commissionTrend = List<double>.filled(bucketCount, 0);
    artistTrend = List<double>.filled(bucketCount, 0);
    riderTrend = List<double>.filled(bucketCount, 0);
    refundTrend = List<double>.filled(bucketCount, 0);
    withdrawalTrend = List<double>.filled(bucketCount, 0);
  }

  void calcCancellationRate() {
    cancellationRate = totalOrders == 0 ? 0 : (cancelledCount / totalOrders) * 100;
  }

  void calcDeliverySuccessRate() {
    deliverySuccessRate = totalOrders == 0 ? 0 : (deliveredCount / totalOrders) * 100;
  }

  void calcAvgOrderValue() {
    avgOrderValue = deliveredCount == 0 ? 0 : revenueForAvg / deliveredCount;
  }

  void calcAvgDeliveryTime() {
    avgDeliveryTime = deliveryTimeCount == 0 ? 0 : totalDeliveryTime / deliveryTimeCount;
  }

  void calcAvgStitchingTime() {
    avgStitchingTime = stitchingTimeCount == 0 ? 0 : totalStitchingTime / stitchingTimeCount;
  }
}

class _RefundMetricsInternal {
  double totalRefunds = 0;
  late final List<double> refundTrend;

  _RefundMetricsInternal(int bucketCount) {
    refundTrend = List<double>.filled(bucketCount, 0);
  }
}

class _WithdrawalMetricsInternal {
  double totalWithdrawals = 0;
  late final List<double> withdrawalTrend;

  _WithdrawalMetricsInternal(int bucketCount) {
    withdrawalTrend = List<double>.filled(bucketCount, 0);
  }
}