import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/services/stripe_onboarding_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class PayoutSetupCard extends StatelessWidget {
  final bool isReady;
  final bool isLoading;
  final Future<String?> Function() onSetup;
  final Future<bool> Function() onRefreshStatus;

  const PayoutSetupCard({
    super.key,
    required this.isReady,
    required this.isLoading,
    required this.onSetup,
    required this.onRefreshStatus,
  });

  static const _brand = Color(0xFF635BFF); // Stripe's own indigo
  static const _successGreen = Color(0xFF17A673);
  static const _warningAmber = Color(0xFFB7791F);

Future<void> _handleTap(BuildContext context) async {
  final url = await onSetup();

  if (url == null) {
    Get.snackbar(
      'Error',
      'Unable to create Stripe onboarding link.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return;
  }

  // Flutter Web (Chrome)
  if (kIsWeb) {
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!launched) {
      Get.snackbar(
        'Error',
        'Could not open Stripe onboarding.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    return;
  }

  // Android / iOS
  if (!context.mounted) return;

  final completed = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => StripeOnboardingScreen(
        onboardingUrl: url,
      ),
    ),
  );

  if (completed == true) {
    await onRefreshStatus();
  }
}

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReady
            ? _successGreen.withOpacity(0.08)
            : _brand.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isReady
              ? _successGreen.withOpacity(0.25)
              : _brand.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isReady ? _successGreen : _brand,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isReady ? Icons.check_rounded : Icons.account_balance_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReady ? 'Payouts ready' : 'Set up payouts',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isReady
                      ? 'Your account can now receive withdrawals'
                      : 'Link your bank details to enable withdrawals',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isReady)
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _handleTap(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Set up',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
