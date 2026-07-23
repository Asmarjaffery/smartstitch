// Mobile implementation — uses safepay_checkout SDK (WebView)
import 'package:flutter/material.dart';
import 'package:safepay_checkout/safepay_payment_gateway.dart';
import 'safepay_service.dart';

Future<SafepayResult> openMobileCheckout({
  required BuildContext context,
  required String tracker,
  required String tbt,
  required bool isSandbox,
}) async {
  final result = await Navigator.of(context).push<SafepayResult>(
    MaterialPageRoute(
      builder: (_) => _SafepayMobilePage(
        tracker: tracker,
        tbt: tbt,
        environment: isSandbox
            ? SafePayEnvironment.sandbox
            : SafePayEnvironment.production,
      ),
    ),
  );
  return result ??
      SafepayResult(
        success: false,
        message: 'Payment cancelled',
        isCancelled: true,
      );
}

class _SafepayMobilePage extends StatelessWidget {
  final String tracker;
  final String tbt;
  final SafePayEnvironment environment;

  const _SafepayMobilePage({
    required this.tracker,
    required this.tbt,
    required this.environment,
  });

  @override
  Widget build(BuildContext context) {
    final baseUrl = environment == SafePayEnvironment.sandbox
        ? 'https://sandbox.api.getsafepay.com'
        : 'https://api.getsafepay.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Payment'),
        backgroundColor: const Color(0xFF0E8F95),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(
            context,
            SafepayResult(
              success: false,
              message: 'Payment cancelled',
              isCancelled: true,
            ),
          ),
        ),
      ),
      body: SafepayCheckout(
        tracker: tracker,
        tbt: tbt,
        environment: environment,
        // Per Safepay docs, the SDK watches for these paths internally:
        // success -> /embedded/external/complete
        // cancel  -> /embedded/external/error
        successUrl: '$baseUrl/embedded/external/complete',
        failUrl: '$baseUrl/embedded/external/error',
        onPaymentCompleted: () {
          debugPrint('✅ Safepay: PAYMENT SUCCESS');
          Navigator.pop(
            context,
            SafepayResult(
              success: true,
              message: 'Payment successful',
              transactionId: tracker,
            ),
          );
        },
        onPaymentFailed: () {
          debugPrint('❌ Safepay: PAYMENT FAILED');
          Navigator.pop(
            context,
            SafepayResult(
              success: false,
              message: 'Payment failed',
            ),
          );
        },
      ),
    );
  }
}