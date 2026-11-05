import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:brandnest/features/brand_webview/address_bar.dart';

/// A `window.open` target, kept inside the app and sharing the parent's cookie
/// session — which is what makes bank 3DS/OTP steps complete instead of dying
/// in an external browser.
class PopupWebView extends StatefulWidget {
  const PopupWebView({
    super.key,
    required this.windowId,
    required this.initialUrl,
    required this.brandName,
    required this.checkoutDomains,
  });

  final int windowId;
  final Uri? initialUrl;
  final String brandName;
  final List<String> checkoutDomains;

  @override
  State<PopupWebView> createState() => _PopupWebViewState();
}

class _PopupWebViewState extends State<PopupWebView> {
  late Uri _url = widget.initialUrl ?? Uri.parse('about:blank');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AddressBar(
              state: AddressBarState.forUrl(_url, widget.checkoutDomains),
              brandName: widget.brandName,
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: InAppWebView(
                windowId: widget.windowId,
                onLoadStart: (controller, url) => _setUrl(url),
                onUpdateVisitedHistory: (controller, url, _) => _setUrl(url),
                onCloseWindow: (controller) {
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setUrl(WebUri? url) {
    if (url == null) return;
    setState(() => _url = url);
  }
}
