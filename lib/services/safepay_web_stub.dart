// Web stub — safepay_checkout SDK is not available on web.
// safepay_service.dart handles web via url_launcher instead,
// so this function should never be called on web.
import 'package:flutter/material.dart';
import 'safepay_service.dart';

Future<SafepayResult> openMobileCheckout({
  required BuildContext context,
  required String tracker,
  required String tbt,
  required bool isSandbox,
}) async {
  // Should never reach here on web — safepay_service.dart uses _launchWebCheckout
  throw UnsupportedError('openMobileCheckout is not supported on web.');
}