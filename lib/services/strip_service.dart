import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';

class StripePaymentResult {
  final bool success;
  final bool isCancelled;
  final String message;
  final String? transactionId;

  StripePaymentResult({
    required this.success,
    this.isCancelled = false,
    this.message = '',
    this.transactionId,
  });
}

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  static const String backendBaseUrl = 'https://smartstitch-backend.vercel.app';

  Future<StripePaymentResult> makePayment({
    required double amount,
    required String currency,
    required String bookingId,
    String? customerEmail,
  }) async {

    if (kIsWeb) {
      return _makeWebPayment(
        amount: amount,
        currency: currency,
        bookingId: bookingId,
        customerEmail: customerEmail,
      );
    }

    try {
      final clientSecret = await _createPaymentIntent(
        amount: amount,
        currency: currency,
        bookingId: bookingId,
        customerEmail: customerEmail,
      );

      if (clientSecret == null) {
        return StripePaymentResult(
          success: false,
          message: 'Could not initialize payment.',
        );
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'SmartStitch',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final transactionId = clientSecret.split('_secret_').first;
      return StripePaymentResult(success: true, transactionId: transactionId);
    } on StripeException catch (e) {
      final isCancelled = e.error.code == FailureCode.Canceled;
      return StripePaymentResult(
        success: false,
        isCancelled: isCancelled,
        message: isCancelled
            ? 'Payment cancelled.'
            : (e.error.localizedMessage ?? 'Payment failed.'),
      );
    } catch (e) {
      return StripePaymentResult(
        success: false,
        message: 'Payment failed: $e',
      );
    }
  }

  /// Web-only flow: opens Stripe's hosted Checkout page in a new tab,
  /// then polls the backend until the session is marked paid/cancelled.
  Future<StripePaymentResult> _makeWebPayment({
    required double amount,
    required String currency,
    required String bookingId,
    String? customerEmail,
  }) async {
    final dio = Dio();

    try {
      final response = await dio.post(
        '$backendBaseUrl/api/stripe/create-checkout-session',
        data: {
          'amount': amount,
          'currency': currency,
          'bookingId': bookingId,
          'customerEmail': customerEmail,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final sessionId = response.data['sessionId'] as String?;
      final url = response.data['url'] as String?;

      if (sessionId == null || url == null) {
        return StripePaymentResult(
          success: false,
          message: 'Could not start web checkout.',
        );
      }

      final launched = await launchUrl(
        Uri.parse(url),
        webOnlyWindowName: '_blank',
      );

      if (!launched) {
        return StripePaymentResult(
          success: false,
          message: 'Could not open the payment page.',
        );
      }
      for (int i = 0; i < 60; i++) {
        await Future.delayed(const Duration(seconds: 3));

        // ✅ Each poll attempt gets its own try/catch. A single transient
        // network hiccup (very likely right after switching back from the
        // payment tab) used to throw and abort the WHOLE loop, wrongly
        // reporting "payment failed" even when Stripe had already
        // succeeded. Now we just skip a failed attempt and keep polling.
        try {
          final statusRes = await dio.get(
            '$backendBaseUrl/api/stripe/session-status',
            queryParameters: {'sessionId': sessionId},
          );
          final status = statusRes.data['status'] as String?;

          if (status == 'paid') {
            // The Checkout Session id (sessionId, "cs_...") is NOT usable for
            // refunds — refunds need the actual PaymentIntent id ("pi_...").
            // The backend's /api/stripe/session-status endpoint should return
            // that as `paymentIntentId` (from Stripe's
            // session.payment_intent field) once the session is paid. Until
            // that backend change ships, this falls back to sessionId so the
            // booking still completes — but refunds on web-originated
            // bookings won't work until the backend is updated.
            final piFromBackend =
                statusRes.data['paymentIntentId'] as String?;
            return StripePaymentResult(
              success: true,
              transactionId: piFromBackend ?? sessionId,
            );
          }

          if (status == 'expired' || status == 'canceled') {
            return StripePaymentResult(
              success: false,
              isCancelled: true,
              message: 'Payment was cancelled.',
            );
          }
        } catch (e) {
          // Transient network error during this single poll — log and
          // retry on the next loop iteration instead of giving up.
          debugPrint('⚠️ session-status poll #$i failed, retrying: $e');
        }
      }

      return StripePaymentResult(
        success: false,
        isCancelled: true,
        message: 'Payment not completed. Please try again.',
      );
    } catch (e) {
      return StripePaymentResult(
        success: false,
        message: 'Payment failed: $e',
      );
    }
  }

  Future<String?> _createPaymentIntent({
    required double amount,
    required String currency,
    required String bookingId,
    String? customerEmail,
  }) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        '$backendBaseUrl/api/stripe/create-payment-intent',
        data: {
          'amount': amount,
          'currency': currency,
          'bookingId': bookingId,
          'customerEmail': customerEmail,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final data = response.data;
      final secret = (data is Map)
          ? (data['clientSecret'] ?? data['client_secret'])
          : null;

      if (secret == null) {
        print('⚠️ Stripe backend responded but no client secret found. '
            'Raw response: $data');
      }

      return secret as String?;
    } on DioException catch (e) {
      print('❌ create-payment-intent failed. '
          'Status: ${e.response?.statusCode}, '
          'Body: ${e.response?.data}, '
          'Message: ${e.message}');
      return null;
    } catch (e) {
      print('❌ create-payment-intent unexpected error: $e');
      return null;
    }
  }
}