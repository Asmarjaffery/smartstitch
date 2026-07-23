import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Reusable screen that opens Stripe's hosted onboarding form.
/// Works for BOTH artist and rider — just pass the onboarding [url].
///
/// Add this to pubspec.yaml if not already present:
///   webview_flutter: ^4.7.0
class StripeOnboardingScreen extends StatefulWidget {
  final String onboardingUrl;

  /// Called when the user is redirected back after finishing
  /// (or leaving) the Stripe form — matches the `returnUrl` /
  /// `refreshUrl` you passed when creating the onboarding link.
  final VoidCallback? onFinished;

  const StripeOnboardingScreen({
    super.key,
    required this.onboardingUrl,
    this.onFinished,
  });

  @override
  State<StripeOnboardingScreen> createState() =>
      _StripeOnboardingScreenState();
}

class _StripeOnboardingScreenState extends State<StripeOnboardingScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            // Detect our own return/refresh URL to know the form is done.
            if (request.url.contains('onboarding-complete') ||
                request.url.contains('reauth')) {
              widget.onFinished?.call();
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.onboardingUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Payout Setup')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
