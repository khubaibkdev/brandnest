import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Schemes the WebView renders itself. Anything else — `whatsapp:`, `tel:`,
/// `mailto:`, `intent:` — belongs to another app on the phone.
const _inAppSchemes = {
  'http',
  'https',
  'about',
  'data',
  'blob',
  'file',
  'javascript',
};

bool opensInAnotherApp(Uri url) => !_inAppSchemes.contains(url.scheme);

/// False when nothing on the phone can handle [url].
Future<bool> openInAnotherApp(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } on PlatformException {
    return false;
  }
}
