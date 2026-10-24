import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum PaymentResult { success, failed, closed }

/// Opens the Xendit payment page (invoice_url) and watches for the
/// success / failure redirect URLs that create-invoice gave to Xendit.
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key, required this.invoiceUrl});

  final String invoiceUrl;

  // These MUST match the defaults inside the create-invoice Edge Function
  // (SUCCESS_URL / FAILURE_URL).
  static const successUrl = 'https://example.com/payment-success';
  static const failureUrl = 'https://example.com/payment-failed';

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;

            if (url.startsWith(PaymentWebViewScreen.successUrl)) {
              Navigator.of(context).pop(PaymentResult.success);
              return NavigationDecision.prevent;
            }
            if (url.startsWith(PaymentWebViewScreen.failureUrl)) {
              Navigator.of(context).pop(PaymentResult.failed);
              return NavigationDecision.prevent;
            }
            // Ignore app deep links (gcash://, intent://, ...) for now
            if (!url.startsWith('http')) return NavigationDecision.prevent;

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.invoiceUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(PaymentResult.closed),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}