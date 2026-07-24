import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Result of a Stripe refund call
class RefundResult {
  final bool success;
  final String message;
  final String? refundId;
  final String? stripeStatus;
  final String? errorCode;
  final String? debugInfo;

  const RefundResult({
    required this.success,
    this.message = '',
    this.refundId,
    this.stripeStatus,
    this.errorCode,
    this.debugInfo,
  });
}

/// Production-ready RefundService with retry logic & detailed logging
class RefundService {
  RefundService._();
  static final RefundService instance = RefundService._();

  // 🔧 Backend URL - update if needed
  static const String _baseUrl = 'https://smartstitch-backend.vercel.app';
  
  // ⏱️ Timeouts
  static const int _initialTimeoutSeconds = 45;
  static const int _maxRetries = 3;

  /// Refunds a previously captured PaymentIntent through the backend.
  /// Includes retry logic for network failures.
  Future<RefundResult> refundPayment({
    required String paymentIntentId,
    double? amount,
    String reason = 'requested_by_customer',
    String? refundRequestId,
  }) async {
    debugPrint('💰 ===== REFUND INITIATED =====');
    debugPrint('🔑 PaymentIntent: $paymentIntentId');
    debugPrint('💵 Amount: ${amount ?? "Full refund"}');
    debugPrint('📝 Reason: $reason');
    debugPrint('🎫 RefundRequestId: $refundRequestId');

    // Validate inputs
    if (paymentIntentId.trim().isEmpty) {
      const result = RefundResult(
        success: false,
        message: 'Invalid payment intent ID',
        debugInfo: 'paymentIntentId is empty',
      );
      debugPrint('❌ Validation failed: ${result.debugInfo}');
      return result;
    }

    int attemptCount = 0;

    while (attemptCount < _maxRetries) {
      attemptCount++;
      debugPrint(
          '🔄 Attempt $attemptCount/$_maxRetries at ${DateTime.now().toIso8601String()}');

      try {
        final response = await http
            .post(
              Uri.parse('$_baseUrl/api/stripe/refund-payment'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({
                'paymentIntentId': paymentIntentId,
                if (amount != null) 'amount': amount,
                'reason': reason,
                if (refundRequestId != null) 'refundRequestId': refundRequestId,
              }),
            )
            .timeout(
              Duration(seconds: _initialTimeoutSeconds),
              onTimeout: () {
                debugPrint(
                    '⏱️ Request timeout after $_initialTimeoutSeconds seconds');
                throw TimeoutException(
                  'Backend did not respond within $_initialTimeoutSeconds seconds',
                );
              },
            );

        debugPrint('📡 Response status: ${response.statusCode}');
        debugPrint('📦 Response body: ${response.body.substring(0, math.min(200, response.body.length))}');

        // ────────── Parse Response ──────────
        late Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('❌ JSON parse error: $e');
          return RefundResult(
            success: false,
            message: 'Invalid response from server',
            debugInfo:
                'Status: ${response.statusCode} | Body: ${response.body}',
          );
        }

        // ────────── Success Response ──────────
        if (response.statusCode == 200 && data['success'] == true) {
          final refundId = data['refundId']?.toString() ?? '';
          final stripeStatus = data['status']?.toString() ?? '';

          debugPrint('✅ Refund succeeded!');
          debugPrint('   Refund ID: $refundId');
          debugPrint('   Status: $stripeStatus');
          debugPrint('💰 ===== END REFUND =====\n');

          return RefundResult(
            success: true,
            message: 'Refund processed successfully',
            refundId: refundId,
            stripeStatus: stripeStatus,
          );
        }

        // ────────── Error Response ──────────
        final errorMsg = data['error']?.toString() ?? 'Unknown error';
        final errorCode = data['code']?.toString();
        final errorType = data['type']?.toString();

        debugPrint('❌ Refund failed');
        debugPrint('   Error: $errorMsg');
        debugPrint('   Code: $errorCode');
        debugPrint('   Type: $errorType');
        debugPrint('   Status: ${response.statusCode}');

        // Check if it's a retryable error
        if (_isRetryable(response.statusCode, errorCode)) {
          if (attemptCount < _maxRetries) {
            debugPrint(
                '🔄 Retryable error, waiting before retry attempt ${attemptCount + 1}...');
            await Future.delayed(Duration(seconds: 2 * attemptCount));
            continue; // Retry
          }
        }

        // Non-retryable or max retries reached
        return RefundResult(
          success: false,
          message: errorMsg,
          errorCode: errorCode,
          debugInfo:
              'Status: ${response.statusCode} | Type: $errorType | Attempts: $attemptCount',
        );
      } on TimeoutException catch (e) {
        debugPrint('⏱️ Timeout error: $e');
        if (attemptCount < _maxRetries) {
          debugPrint('🔄 Retrying after timeout...');
          await Future.delayed(Duration(seconds: 3 * attemptCount));
          continue;
        }
        return RefundResult(
          success: false,
          message: 'Request timed out. Please try again.',
          debugInfo: 'Timeout after $_initialTimeoutSeconds seconds | Attempts: $attemptCount',
        );
      } on http.ClientException catch (e) {
        debugPrint('🌐 Network error: $e');
        if (attemptCount < _maxRetries) {
          debugPrint('🔄 Retrying after network error...');
          await Future.delayed(Duration(seconds: 2 * attemptCount));
          continue;
        }
        return RefundResult(
          success: false,
          message: 'Network error. Check your connection and try again.',
          debugInfo: 'ClientException: ${e.message} | Attempts: $attemptCount',
        );
      } catch (e) {
        debugPrint('❌ Unexpected error: $e');
        if (attemptCount < _maxRetries) {
          debugPrint('🔄 Retrying after unexpected error...');
          await Future.delayed(Duration(seconds: 2 * attemptCount));
          continue;
        }
        return RefundResult(
          success: false,
          message: 'An unexpected error occurred. Please try again.',
          debugInfo: 'Exception: $e | Attempts: $attemptCount',
        );
      }
    }

    debugPrint('❌ Max retries reached ($attemptCount/$_maxRetries)');
    debugPrint('💰 ===== END REFUND =====\n');

    return const RefundResult(
      success: false,
      message:
          'Could not reach payment server after multiple attempts. Please try again later.',
      debugInfo: 'Max retries exceeded',
    );
  }

  /// Determine if an error is retryable
  bool _isRetryable(int statusCode, String? errorCode) {
    // Retry on 5xx errors (server errors)
    if (statusCode >= 500) return true;

    // Retry on 429 (rate limit)
    if (statusCode == 429) return true;

    // Retry on timeout-like Stripe errors
    final retryableStripeErrors = [
      'api_connection_error',
      'api_error',
      'rate_limit_error',
    ];
    if (errorCode != null && retryableStripeErrors.contains(errorCode)) {
      return true;
    }

    return false;
  }
}
