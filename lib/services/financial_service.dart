import 'package:smartstitch/core/utils/settings_helper.dart';

import '../models/profit_metrics.dart';


class FinancialService {
  static ProfitMetrics calculateProfitLoss({
    required double platformRevenue,
    required double refunds,
    required double couponDiscounts,
    required double chargebacks,
    required double failedPayments,
    required List<double> platformRevenueTrend,
    required List<double> refundTrend,
    required Map<String, dynamic> settings,
  }) {
    final bucketCount = platformRevenueTrend.length;
    final opExpenseRate = SettingsHelper.getOperationalExpenseRate(settings);
    final marketingCostRate = SettingsHelper.getMarketingCostRate(settings);

    final opExpenses = platformRevenue * opExpenseRate;
    final marketingCosts = platformRevenue * marketingCostRate;

    // Profit = Platform Revenue - Refunds - Operational Expenses - Marketing Expenses - Coupon Discounts - Chargebacks - Failed Payments
    final profit = platformRevenue -
        refunds -
        opExpenses -
        marketingCosts -
        couponDiscounts -
        chargebacks -
        failedPayments;

    // Loss = Refunds + Coupon Discounts + Marketing Costs + Chargebacks + Operational Expenses + Failed Payments
    final loss = refunds +
        couponDiscounts +
        marketingCosts +
        chargebacks +
        opExpenses +
        failedPayments;

    final profitTrend = List<double>.filled(bucketCount, 0.0);
    final lossTrend = List<double>.filled(bucketCount, 0.0);

    for (int i = 0; i < bucketCount; i++) {
      final pRev = platformRevenueTrend[i];
      final ref = refundTrend[i];
      final bucketOpExp = pRev * opExpenseRate;
      final bucketMkt = pRev * marketingCostRate;

      profitTrend[i] = pRev - ref - bucketOpExp - bucketMkt;
      lossTrend[i] = ref + bucketOpExp + bucketMkt;
    }

    return ProfitMetrics(
      profit: profit,
      loss: loss,
      profitTrend: profitTrend,
      lossTrend: lossTrend,
    );
  }
}
