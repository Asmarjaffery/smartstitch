import 'dart:async';
import 'dart:convert' as convert;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'safepay_mobile_checkout.dart'
    if (dart.library.html) 'safepay_web_stub.dart';

class SafepayService {
  // ================= CONFIG =================

  static const bool _isSandbox = true;

  static String get environment => _isSandbox ? 'sandbox' : 'production';

  static bool get isSandbox => _isSandbox;

  // ================= NODE BACKEND =================
  static const String _functionsBaseUrl =
      'https://regally-vicinity-rubdown.ngrok-free.dev';

  // ================= SINGLETON =================

  static final SafepayService _instance = SafepayService._internal();
  factory SafepayService() => _instance;
  SafepayService._internal();

  // ================= LOGGER =================

  void _log(String msg, {bool error = false}) {
    debugPrint('${error ? "❌ Safepay" : "✅ Safepay"}: $msg');
  }

  // ================= CREATE SESSION (shared by mobile + web) =========

  Future<Map<String, dynamic>?> _createSession({
    required double amount,
    required String orderId,
    required String source, // "mobile" or "hosted"
    String? customerEmail,
  }) async {
    try {
      final url = '$_functionsBaseUrl/createSafepaySession';
      _log('Creating session at: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: convert.jsonEncode({
          'amount': amount,
          'orderId': orderId,
          'customerEmail': customerEmail ?? '',
          'source': source,
        }),
      );

      _log('SESSION STATUS: ${response.statusCode}');
      _log('SESSION BODY: ${response.body}');

      final json = convert.jsonDecode(response.body);
      if (response.statusCode != 200 || json['success'] != true) {
        _log('Session failed: ${json['message']}', error: true);
        return null;
      }
      return json as Map<String, dynamic>;
    } catch (e) {
      _log('SESSION ERROR: $e', error: true);
      return null;
    }
  }

  // ================= VERIFY PAYMENT =================
  // ✅ FIX: verify using the BOOKING ID (orderId), not the Safepay tracker.
  // The webhook updates Firestore using orderId as the document ID,
  // so we must check the same field here.

  Future<bool> _verifyPayment(String bookingId) async {
    try {
      _log('Verifying payment for booking: $bookingId');

      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (bookingDoc.exists) {
        final paymentStatus = bookingDoc.get('paymentStatus');
        if (paymentStatus == 'paid') {
          _log('✅ Payment verified in Firestore!');
          return true;
        }
      }

      _log('Payment not yet confirmed', error: true);
      return false;
    } catch (e) {
      _log('VERIFY ERROR: $e', error: true);
      return false;
    }
  }

  // ================= START PAYMENT =================

  Future<SafepayResult> startPayment({
    required BuildContext context,
    required double amount,
    required String orderId,
    String? customerEmail,
    String? customerCnic,
  }) async {
    _log('START PAYMENT — orderId: $orderId, amount: $amount');

    if (kIsWeb) {
      return _launchWebCheckout(
        context: context,
        amount: amount,
        orderId: orderId,
        customerEmail: customerEmail,
      );
    }

    // ── MOBILE: Node backend → tracker → SDK WebView ──
    try {
      final session = await _createSession(
        amount: amount,
        orderId: orderId,
        source: 'mobile',
        customerEmail: customerEmail,
      );

      if (session == null) {
        return SafepayResult(
          success: false,
          message: 'Payment init failed. Check your internet connection.',
        );
      }

      final tracker = session['tracker'] as String?;

      if (tracker == null) {
        return SafepayResult(
          success: false,
          message: 'Payment session failed. Try again.',
        );
      }

      _log('Tracker: $tracker');

      if (!context.mounted) {
        return SafepayResult(success: false, message: 'Context unmounted');
      }

      return await openMobileCheckout(
        context: context,
        tracker: tracker,
        tbt: '',
        isSandbox: _isSandbox,
      );
    } catch (e) {
      _log('MOBILE PAYMENT ERROR: $e', error: true);
      return SafepayResult(success: false, message: e.toString());
    }
  }

  // ================= WEB CHECKOUT =================

  Future<SafepayResult> _launchWebCheckout({
    required BuildContext context,
    required double amount,
    required String orderId,
    String? customerEmail,
  }) async {
    try {
      _log('WEB: requesting session from Node backend...');

      final session = await _createSession(
        amount: amount,
        orderId: orderId,
        source: 'hosted',
        customerEmail: customerEmail,
      );

      if (session == null || session['checkoutUrl'] == null) {
        return SafepayResult(
          success: false,
          message: 'Could not start payment session. Please try again.',
        );
      }

      final checkoutUrl = session['checkoutUrl'] as String;
      final uri = Uri.parse(checkoutUrl);

      _log('WEB CHECKOUT URL: $uri');

      if (!await canLaunchUrl(uri)) {
        return SafepayResult(
            success: false, message: 'Could not open payment page.');
      }

      // Open in a new browser tab — NOT an iframe (Safepay blocks framing).
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!context.mounted) {
        return SafepayResult(success: false, message: 'Context unmounted');
      }

      // ✅ FIX: pass orderId (bookingId) for verification, not tracker.
      return await _watchPaymentDialog(context: context, bookingId: orderId);
    } catch (e) {
      _log('WEB CHECKOUT ERROR: $e', error: true);
      return SafepayResult(
        success: false,
        message: 'Something went wrong starting the payment.',
      );
    }
  }

  // ================= WATCH PAYMENT DIALOG =================

  Future<SafepayResult> _watchPaymentDialog({
    required BuildContext context,
    required String bookingId,
  }) async {
    final completer = Completer<SafepayResult>();
    Timer? pollTimer;
    bool finished = false;

    void finish(SafepayResult result) {
      if (finished) return;
      finished = true;
      pollTimer?.cancel();
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!completer.isCompleted) completer.complete(result);
    }

    // Poll in the background every 3 seconds.
    pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final verified = await _verifyPayment(bookingId);
      if (verified) {
        _log('AUTO-DETECTED payment success via polling.');
        finish(SafepayResult(
          success: true,
          message: 'Payment verified',
          transactionId: bookingId,
        ));
      }
    });

    if (!context.mounted) {
      pollTimer.cancel();
      return SafepayResult(success: false, message: 'Context unmounted');
    }

    String? inlineMessage;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.open_in_new_rounded,
                color: Color(0xFF0E8F95), size: 32),
            title: const Text(
              'Complete Your Payment',
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'A Safepay payment page has opened in a new tab.\n\n'
                  'Complete the payment there — this screen will continue '
                  'automatically once we detect it, or you can confirm manually below.',
                  textAlign: TextAlign.center,
                ),
                if (inlineMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    inlineMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              OutlinedButton(
                onPressed: () {
                  finish(SafepayResult(
                    success: false,
                    message: 'Payment cancelled',
                    isCancelled: true,
                  ));
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0E8F95)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel',
                    style: TextStyle(color: Color(0xFF0E8F95))),
              ),
              const SizedBox(width: 8),
              _PaymentDoneButton(
                onPressed: () async {
                  // Manual fallback: verify immediately on tap.
                  final verified = await _verifyPayment(bookingId);
                  if (verified) {
                    finish(SafepayResult(
                      success: true,
                      message: 'Payment verified',
                      transactionId: bookingId,
                    ));
                  } else {
                    setDialogState(() {
                      inlineMessage =
                          'Payment not confirmed yet. Please finish it in the other tab, then tap again.';
                    });
                  }
                },
              ),
            ],
          );
        },
      ),
    );

    return completer.future;
  }
}

// ================= PAYMENT DONE BUTTON =================

class _PaymentDoneButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  const _PaymentDoneButton({required this.onPressed});

  @override
  State<_PaymentDoneButton> createState() => _PaymentDoneButtonState();
}

class _PaymentDoneButtonState extends State<_PaymentDoneButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _busy
          ? null
          : () async {
              setState(() => _busy = true);
              await widget.onPressed();
              if (mounted) setState(() => _busy = false);
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0E8F95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('Payment Done ✓', style: TextStyle(color: Colors.white)),
    );
  }
}

// ================= RESULT MODEL =================

class SafepayResult {
  final bool success;
  final String message;
  final String? transactionId;
  final bool isCancelled;

  SafepayResult({
    required this.success,
    required this.message,
    this.transactionId,
    this.isCancelled = false,
  });

  @override
  String toString() => 'SafepayResult(success: $success, message: $message, '
      'transactionId: $transactionId, isCancelled: $isCancelled)';
}