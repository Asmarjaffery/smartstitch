import 'dart:math' as math;
import 'package:smartstitch/core/utils/bucket_helper.dart';
import 'package:smartstitch/core/utils/parser_helper.dart';
import 'package:smartstitch/core/utils/settings_helper.dart';

import '../models/analytics_metrics.dart';

import 'performer_service.dart';
import 'chart_service.dart';

class AnalyticsService {
  static AnalyticsMetrics aggregateMetrics({
    required List<Map<String, dynamic>> orders,
    required List<Map<String, dynamic>> bookings,
    required List<Map<String, dynamic>> users,
    required Map<String, dynamic> settings,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required BucketConfig bucketConfig,
  }) {
    final metrics = AnalyticsMetrics(
      revenueTrend: List<double>.filled(bucketConfig.bucketCount, 0.0),
      ordersTrend: List<int>.filled(bucketConfig.bucketCount, 0),
    );

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final weekAgo = startOfDay.subtract(const Duration(days: 6));
    final monthAgo = startOfDay.subtract(const Duration(days: 29));
    final yearAgo = DateTime(now.year - 1, now.month, now.day);

    final Map<String, Map<String, dynamic>> userMap = {
      for (var u in users) ParserHelper.parseString(u['_docId'] ?? u['uid']): u
    };

    final allTx = <Map<String, dynamic>>[];
    for (var o in orders) {
      allTx.add(o);
    }
    for (var b in bookings) {
      final bAmount = ParserHelper.parseDouble(b['servicePrice'] ?? b['totalAmount']);
      allTx.add({
        ...b,
        'totalAmount': bAmount,
      });
    }

    final Map<String, double> categoryRevenues = {};
    final Map<String, int> serviceCounts = {};
    final Map<String, double> artistRevenues = {};
    final Map<String, String> artistNames = {};
    final Map<String, String> artistAvatars = {};
    final Map<String, int> riderDeliveries = {};
    final Map<String, String> riderNames = {};
    final Map<String, String> riderAvatars = {};
    final Map<String, int> customerOrders = {};
    final Map<String, double> customerSpending = {};
    final Map<String, String> customerNames = {};
    final Map<String, String> customerAvatars = {};

    double totalDeliveryTime = 0.0;
    int deliveryTimeCount = 0;
    double totalStitchingTime = 0.0;
    int stitchingTimeCount = 0;
    double revenueForAvg = 0.0;

    final commRate = SettingsHelper.getCommissionRate(settings);
    final platformChargeRate = SettingsHelper.getPlatformChargeRate(settings);
    final surgeChargeRate = SettingsHelper.getSurgeChargeRate(settings);

    for (final doc in allTx) {
      final createdAt = ParserHelper.parseDate(doc['createdAt']);
      final status = ParserHelper.parseString(doc['status']).toLowerCase();
      final amount = ParserHelper.parseDouble(doc['totalAmount']);

      if (createdAt == null) continue;

      final isDelivered = status == 'delivered' || status == 'completed';
      if (isDelivered) {
        if (!createdAt.isBefore(startOfDay)) metrics.dailyRevenue += amount;
        if (!createdAt.isBefore(weekAgo)) metrics.weeklyRevenue += amount;
        if (!createdAt.isBefore(monthAgo)) metrics.monthlyRevenue += amount;
        if (!createdAt.isBefore(yearAgo)) metrics.yearlyRevenue += amount;
      }

      final inRange = !createdAt.isBefore(rangeStart) && !createdAt.isAfter(rangeEnd);
      if (!inRange) continue;

      metrics.totalOrders++;

      if (status == 'cancelled' || status == 'canceled') {
        metrics.cancelledCount++;
      } else if (status == 'pending' ||
          status == 'accepted' ||
          status == 'in_progress' ||
          status == 'processing' ||
          status == 'assigned') {
        metrics.activeCount++;
      }

      if (isDelivered) {
        metrics.deliveredCount++;
        metrics.completedCount++;
        metrics.grossSales += amount;
        revenueForAvg += amount;

        final commission = amount * commRate;
        final artistShare = math.max(0.0, amount - commission);
        final riderShare = ParserHelper.parseDouble(doc['deliveryFee']);

        metrics.adminCommission += commission;
        metrics.artistEarnings += artistShare;
        metrics.riderEarnings += riderShare;

        final convenienceFee = ParserHelper.parseDouble(doc['convenienceFee']);
        final serviceFee = ParserHelper.parseDouble(doc['serviceFee']);
        final platformCharges = ParserHelper.parseDouble(doc['platformCharges']) > 0
            ? ParserHelper.parseDouble(doc['platformCharges'])
            : amount * platformChargeRate;
        final surgeCharges = ParserHelper.parseDouble(doc['surgeCharges']) > 0
            ? ParserHelper.parseDouble(doc['surgeCharges'])
            : amount * surgeChargeRate;
        final otherIncome = ParserHelper.parseDouble(doc['otherPlatformIncome']);

        metrics.platformRevenue += (commission + platformCharges + convenienceFee + serviceFee + surgeCharges + otherIncome);

        final cat = ParserHelper.parseString(doc['category'] ?? doc['serviceCategory'], fallback: 'General');
        categoryRevenues[cat] = (categoryRevenues[cat] ?? 0) + amount;

        final serviceName = ParserHelper.parseString(doc['serviceName'], fallback: 'Service');
        serviceCounts[serviceName] = (serviceCounts[serviceName] ?? 0) + 1;

        final customerId = ParserHelper.parseString(doc['customerId'] ?? doc['userId'] ?? doc['customer']);
        if (customerId.isNotEmpty) {
          customerOrders[customerId] = (customerOrders[customerId] ?? 0) + 1;
          customerSpending[customerId] = (customerSpending[customerId] ?? 0) + amount;
          final cust = userMap[customerId];
          if (cust != null) {
            customerNames[customerId] = ParserHelper.parseString(cust['name'] ?? cust['fullName'] ?? cust['displayName'], fallback: customerId);
            customerAvatars[customerId] = ParserHelper.parseString(cust['photoUrl'] ?? cust['profileImage']);
          }
        }

        final artistId = ParserHelper.parseString(doc['artistId']);
        if (artistId.isNotEmpty) {
          artistRevenues[artistId] = (artistRevenues[artistId] ?? 0) + amount;
          final art = userMap[artistId];
          if (art != null) {
            artistNames[artistId] = ParserHelper.parseString(art['name'] ?? art['fullName'], fallback: artistId);
            artistAvatars[artistId] = ParserHelper.parseString(art['photoUrl'] ?? art['profileImage']);
          }
        }

        final riderId = ParserHelper.parseString(doc['riderId']);
        if (riderId.isNotEmpty) {
          riderDeliveries[riderId] = (riderDeliveries[riderId] ?? 0) + 1;
          final rid = userMap[riderId];
          if (rid != null) {
            riderNames[riderId] = ParserHelper.parseString(rid['name'] ?? rid['fullName'], fallback: riderId);
            riderAvatars[riderId] = ParserHelper.parseString(rid['photoUrl'] ?? rid['profileImage']);
          }
        }

        final deliveredAt = ParserHelper.parseDate(doc['deliveredAt']);
        if (deliveredAt != null) {
          totalDeliveryTime += deliveredAt.difference(createdAt).inMinutes.toDouble();
          deliveryTimeCount++;
        }

        final completedAt = ParserHelper.parseDate(doc['completedAt']);
        if (completedAt != null) {
          totalStitchingTime += completedAt.difference(createdAt).inMinutes.toDouble();
          stitchingTimeCount++;
        }
      }

      final bucketIdx = bucketConfig.indexOf(createdAt);
      if (bucketIdx != -1) {
        metrics.ordersTrend[bucketIdx]++;
        if (isDelivered) {
          metrics.revenueTrend[bucketIdx] += amount;
        }
      }
    }

    metrics.cancellationRate = metrics.totalOrders == 0 ? 0.0 : (metrics.cancelledCount / metrics.totalOrders) * 100;
    metrics.deliverySuccessRate = metrics.totalOrders == 0 ? 0.0 : (metrics.deliveredCount / metrics.totalOrders) * 100;
    metrics.avgOrderValue = metrics.deliveredCount == 0 ? 0.0 : revenueForAvg / metrics.deliveredCount;
    metrics.avgDeliveryTime = deliveryTimeCount == 0 ? 0.0 : totalDeliveryTime / deliveryTimeCount;
    metrics.avgStitchingTime = stitchingTimeCount == 0 ? 0.0 : totalStitchingTime / stitchingTimeCount;

    metrics.topArtists = PerformerService.getTopPerformersFromDouble(
      artistRevenues,
      names: artistNames,
      avatars: artistAvatars,
      subtitleBuilder: (val) => 'Rs. ${val.toStringAsFixed(0)} revenue',
    );

    metrics.topRiders = PerformerService.getTopPerformersFromInt(
      riderDeliveries,
      names: riderNames,
      avatars: riderAvatars,
      subtitleBuilder: (val) => '$val deliveries',
    );

    metrics.topCustomers = PerformerService.getTopPerformersFromInt(
      customerOrders,
      names: customerNames,
      avatars: customerAvatars,
      subtitleBuilder: (val) => '$val orders',
    );

    metrics.highestPayingCustomers = PerformerService.getTopPerformersFromDouble(
      customerSpending,
      names: customerNames,
      avatars: customerAvatars,
      subtitleBuilder: (val) => 'Rs. ${val.toStringAsFixed(0)}',
    );

    if (categoryRevenues.isNotEmpty) {
      metrics.highestRevenueCategory = categoryRevenues.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    metrics.servicePopularitySlices = ChartService.buildServiceSlices(serviceCounts);

    return metrics;
  }
}
