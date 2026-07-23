

import 'package:smartstitch/core/utils/parser_helper.dart';

class SettingsHelper {
  static const double defaultCommissionRate = 0.15;
  static const double defaultPlatformChargeRate = 0.02;
  static const double defaultSurgeChargeRate = 0.0;
  static const double defaultOperationalExpenseRate = 0.05;
  static const double defaultMarketingCostRate = 0.02;
  static const double defaultCouponDiscountRate = 0.0;
  static const double defaultChargebackRate = 0.0;
  static const double defaultFailedPaymentRate = 0.0;

  static double getDouble(Map<String, dynamic> settings, String key, double fallback) {
    if (!settings.containsKey(key)) return fallback;
    return ParserHelper.parseDouble(settings[key]);
  }

  static double getCommissionRate(Map<String, dynamic> settings) =>
      getDouble(settings, 'commissionRate', defaultCommissionRate);

  static double getPlatformChargeRate(Map<String, dynamic> settings) =>
      getDouble(settings, 'platformChargeRate', defaultPlatformChargeRate);

  static double getSurgeChargeRate(Map<String, dynamic> settings) =>
      getDouble(settings, 'surgeChargeRate', defaultSurgeChargeRate);

  static double getOperationalExpenseRate(Map<String, dynamic> settings) =>
      getDouble(settings, 'operationalExpenseRate', defaultOperationalExpenseRate);

  static double getMarketingCostRate(Map<String, dynamic> settings) =>
      getDouble(settings, 'marketingCostRate', defaultMarketingCostRate);
}
