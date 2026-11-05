import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/api_client.dart';

/// The webview slice of a brand's server-side config (`GET /brands/{slug}/config`).
///
/// Not cached: shopping needs the network anyway, and [defaults] keeps a brand
/// openable when our own API is down but the brand's site is up.
class BrandConfig {
  const BrandConfig({
    this.webviewUserAgent,
    this.checkoutDomains = const [],
    this.productUrlRegex,
    this.orderConfirmPatterns = const [],
  });

  /// Empty user agent means "keep the system default".
  static const defaults = BrandConfig();

  final String? webviewUserAgent;

  /// Hosts other than the brand's own that legitimately carry its checkout.
  final List<String> checkoutDomains;

  /// Cheap product-page detection (US-13): null means the toolbar's Watch
  /// toggle never bothers checking this brand's pages.
  final String? productUrlRegex;

  /// URL patterns that mean the shopper just completed an order (US-18).
  /// Server-side so a brand changing its checkout needs no app release.
  final List<String> orderConfirmPatterns;

  factory BrandConfig.fromJson(Map<String, dynamic> json) => BrandConfig(
    webviewUserAgent: json['webview_user_agent'] as String?,
    checkoutDomains: (json['checkout_domains'] as List).cast<String>(),
    productUrlRegex: json['product_url_regex'] as String?,
    orderConfirmPatterns:
        (json['order_confirm_patterns'] as List?)?.cast<String>() ?? const [],
  );
}

final brandConfigProvider = FutureProvider.family<BrandConfig, String>(
  (ref, slug) async =>
      BrandConfig.fromJson(await ref.watch(apiClientProvider).fetchBrandConfig(slug)),
);
