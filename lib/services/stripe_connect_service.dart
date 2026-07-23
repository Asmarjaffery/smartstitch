import 'package:dio/dio.dart';

class PayoutResult {
  final bool success;
  final String? transferId;

  /// User-facing, friendly message (safe to show to artists/riders).
  final String? errorMessage;

  /// Raw technical message from Stripe/server — for admin screens & logs only.
  final String? rawError;

  const PayoutResult.success(this.transferId)
      : success = true,
        errorMessage = null,
        rawError = null;

  const PayoutResult.failure(this.errorMessage, {this.rawError})
      : success = false,
        transferId = null;
}

/// Shared Stripe Connect service — used by BOTH Artist and Rider wallets.
///
/// This talks to your Vercel backend (never to Stripe directly), so the
/// secret key stays safely on the server.
class StripeConnectService {
  StripeConnectService._();
  static final StripeConnectService instance = StripeConnectService._();

  final Dio _dio = Dio();

  static const String _baseUrl = 'https://smartstitch-backend.vercel.app';

  /// Extracts the backend's `{ "error": "..." }` message from a failed
  /// response, if present, so logs show the real Stripe/server reason
  /// instead of just "status code 500".
  String _extractServerError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
      return e.message ?? e.toString();
    }
    return e.toString();
  }

  /// Maps raw Stripe/server error text into a short, non-technical message
  /// that's safe to show to artists/riders. Falls back to a generic message
  /// for anything unrecognized, so we never leak Stripe internals to users.
  String _friendlyMessage(String raw) {
    final r = raw.toLowerCase();

    if (r.contains('insufficient available funds') ||
        r.contains('insufficient funds')) {
      return 'Payout could not be processed right now due to a temporary '
          'balance issue on our end. Our team has been notified — please '
          'try again shortly.';
    }
    if (r.contains('account') &&
        (r.contains('not eligible') ||
            r.contains('not ready') ||
            r.contains('capabilities'))) {
      return 'Your payout account setup isn\'t fully complete yet. Please '
          'finish onboarding to receive payouts.';
    }
    if (r.contains('no such account') || r.contains('account_invalid')) {
      return 'We couldn\'t find your payout account. Please contact support.';
    }
    if (r.contains('rate limit')) {
      return 'Too many requests right now. Please try again in a moment.';
    }
    if (r.contains('network') ||
        r.contains('timeout') ||
        r.contains('connection')) {
      return 'Network issue while processing payout. Please try again.';
    }

    return 'Payout could not be processed. Our team has been notified.';
  }

  /// Step 1: Create a Stripe Connect Express account for a user
  /// (artist OR rider — pass whichever id/email/name applies).
  Future<String?> createConnectAccount({
    required String userId,
    required String email,
    required String name,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/create-connect-account',
        data: {
          'artistId': userId, // generic id field, works for riders too
          'email': email,
          'name': name,
        },
      );
      return response.data['accountId'] as String?;
    } catch (e) {
      print('❌ createConnectAccount error: ${_extractServerError(e)}');
      return null;
    }
  }

  /// Step 2: Get the Stripe-hosted onboarding form URL for a given account.
  Future<String?> createOnboardingLink({
    required String accountId,
    String? refreshUrl,
    String? returnUrl,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/create-onboarding-link',
        data: {
          'accountId': accountId,
          'refreshUrl': refreshUrl,
          'returnUrl': returnUrl,
        },
      );
      return response.data['url'] as String?;
    } catch (e) {
      print('❌ createOnboardingLink error: ${_extractServerError(e)}');
      return null;
    }
  }

  /// Step 3: Check if the user finished filling the form and can
  /// receive payouts yet.
  Future<bool> isReadyForPayouts(String accountId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/account-status',
        queryParameters: {'accountId': accountId},
      );
      return response.data['readyForPayouts'] == true;
    } catch (e) {
      print('❌ isReadyForPayouts error: ${_extractServerError(e)}');
      return false;
    }
  }

  /// Step 4 (admin use): Send a payout to the user's account.
  ///
  /// [idempotencyKey] should be the withdrawal request's Firestore
  /// document id. Passing the same key twice guarantees Stripe will
  /// only ever send the money ONCE, even if this method is accidentally
  /// triggered twice (double tap, network retry, etc.).
  ///
  /// On failure, [PayoutResult.errorMessage] is a friendly message safe to
  /// show to artists/riders. [PayoutResult.rawError] carries the raw
  /// Stripe/server message — use it in admin screens & logs only.
  Future<PayoutResult> sendPayout({
    required String accountId,
    required double amount,
    required String idempotencyKey,
    String currency = 'usd',
    String? withdrawalId,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/create-payout',
        data: {
          'accountId': accountId,
          'amount': amount,
          'currency': currency,
          'withdrawalId': withdrawalId,
          'idempotencyKey': idempotencyKey,
        },
      );

      if (response.data['success'] == true) {
        return PayoutResult.success(response.data['transferId'] as String?);
      }

      final rawError = response.data['error']?.toString() ?? 'Unknown error';
      print('❌ sendPayout error: $rawError');
      return PayoutResult.failure(
        _friendlyMessage(rawError),
        rawError: rawError,
      );
    } catch (e) {
      final rawError = _extractServerError(e);
      print('❌ sendPayout error: $rawError');
      return PayoutResult.failure(
        _friendlyMessage(rawError),
        rawError: rawError,
      );
    }
  }
}