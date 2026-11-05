import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/data/bank_offer.dart';
import 'package:brandnest/data/brand_config.dart';
import 'package:brandnest/data/points_repository.dart';
import 'package:brandnest/data/watch_repository.dart';
import 'package:brandnest/features/brand_webview/address_bar.dart';
import 'package:brandnest/features/brand_webview/external_links.dart';
import 'package:brandnest/features/brand_webview/offer_chips.dart';
import 'package:brandnest/features/brand_webview/popup_webview.dart';
import 'package:brandnest/features/brand_webview/price_graph_sheet.dart';
import 'package:brandnest/features/brand_webview/product_reader.dart';
import 'package:brandnest/features/squad/pin_to_squad_sheet.dart';

/// Shopping and checkout both happen on the brand's own site. We never touch
/// their page — all we add is the address strip and the bank-offer chips above it.
class BrandWebViewScreen extends ConsumerWidget {
  const BrandWebViewScreen({super.key, required this.brand, this.initialUrl});

  final Brand brand;

  /// Where to open. Null means the brand's home page; a search result (US-11)
  /// passes the product's own URL so the shopper lands on the item they picked.
  final String? initialUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(brandConfigProvider(brand.slug));
    // Watched here rather than deeper down so the request goes out alongside the
    // config one, long before the brand's own page has finished loading.
    final offers = ref.watch(brandOffersProvider(brand.slug));
    return Scaffold(
      body: SafeArea(
        child: switch (config) {
          AsyncData(:final value) => _BrandBrowser(
            brand: brand,
            config: value,
            offers: offers.value ?? const [],
            initialUrl: initialUrl,
          ),
          // Our API being down is no reason someone can't shop.
          AsyncError() => _BrandBrowser(
            brand: brand,
            config: BrandConfig.defaults,
            offers: offers.value ?? const [],
            initialUrl: initialUrl,
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _BrandBrowser extends ConsumerStatefulWidget {
  const _BrandBrowser({
    required this.brand,
    required this.config,
    required this.offers,
    this.initialUrl,
  });

  final Brand brand;
  final BrandConfig config;
  final List<BankOffer> offers;
  final String? initialUrl;

  @override
  ConsumerState<_BrandBrowser> createState() => _BrandBrowserState();
}

class _BrandBrowserState extends ConsumerState<_BrandBrowser> {
  InAppWebViewController? _controller;
  late Uri _url = Uri.parse(widget.initialUrl ?? widget.brand.websiteUrl);
  double _progress = 0;
  DetectedPage _detectedPage = DetectedPage.none;

  /// Confirmation URLs already sent this session — the reader re-fires on
  /// every navigation, including back onto the same page.
  final Set<String> _reportedOrderUrls = {};
  WatchStatus? _watchStatus;
  bool _watchBusy = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _goBack(didPop),
      child: Column(
        children: [
          AddressBar(
            state: AddressBarState.forUrl(_url, widget.config.checkoutDomains),
            brandName: widget.brand.name,
            onClose: () => Navigator.of(context).pop(),
            watchAction: _buildWatchAction(),
            historyAction: _buildHistoryAction(),
            pinAction: _buildPinAction(),
          ),
          OfferChips(offers: widget.offers),
          if (_progress < 1) LinearProgressIndicator(value: _progress),
          Expanded(child: _webView()),
        ],
      ),
    );
  }

  /// Only present once the toolbar has both detected a product on screen and
  /// heard back from the API that it is one we have crawled — a product our
  /// crawler has not seen yet has nothing to watch.
  Widget? _buildWatchAction() {
    final status = _watchStatus;
    if (_knownProductId() == null) return null;
    return IconButton(
      onPressed: _watchBusy ? null : _toggleWatch,
      icon: Icon(
        status!.watching
            ? Icons.notifications_active
            : Icons.notifications_none,
      ),
      tooltip: status.watching ? 'Stop watching this price' : 'Watch this price',
    );
  }

  /// Shown on the same condition as the Watch toggle — both need a product
  /// our crawler knows, and both learn that from the one watch-status call.
  Widget? _buildHistoryAction() {
    final productId = _knownProductId();
    if (productId == null) return null;
    return IconButton(
      onPressed: () => showPriceGraphSheet(
        context,
        productId: productId,
        productTitle: _watchStatus?.title ?? _detectedPage.title,
      ),
      icon: const Icon(Icons.show_chart),
      tooltip: 'See price history',
    );
  }

  Widget? _buildPinAction() {
    if (!_detectedPage.isProduct) return null;
    return IconButton(
      onPressed: _pinToSquad,
      icon: const Icon(Icons.push_pin_outlined),
      tooltip: 'Pin to a squad',
    );
  }

  Future<void> _pinToSquad() async {
    final squadName = await showPinToSquadSheet(
      context,
      brandSlug: widget.brand.slug,
      page: _detectedPage,
    );
    if (squadName != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pinned to $squadName')),
      );
    }
  }

  int? _knownProductId() =>
      _detectedPage.isProduct ? _watchStatus?.productId : null;

  void _handlePageMessage(Map<String, dynamic> payload) {
    final page = DetectedPage.fromJs(payload);
    setState(() {
      _detectedPage = page;
      _watchStatus = null;
    });
    if (page.isProduct) _fetchWatchStatus(page);
    if (page.isOrderConfirmation) _reportOrder(page);
  }

  /// US-18. The server decides whether this really is a confirmation page and
  /// whether it has already been counted, so the app reports and reports only
  /// once per detection — a shopper who reloads the page is not paid twice.
  Future<void> _reportOrder(DetectedPage page) async {
    if (_reportedOrderUrls.contains(page.url)) return;
    _reportedOrderUrls.add(page.url);
    try {
      final result = await ref
          .read(pointsRepositoryProvider)
          .reportOrder(widget.brand.slug, page.url);
      if (!mounted || result == null || !result.awarded) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Order confirmed — points added, and they unlock once your '
            'return window closes.',
          ),
        ),
      );
    } catch (_) {
      // Never interrupt a shopper who has just paid. The order is lost to us,
      // not to them, and the page can be revisited.
    }
  }

  Future<void> _fetchWatchStatus(DetectedPage page) async {
    try {
      final status = await ref
          .read(watchRepositoryProvider)
          .fetchStatus(widget.brand.slug, page.url);
      // The shopper may have already navigated on by the time this returns.
      if (mounted && identical(_detectedPage, page)) {
        setState(() => _watchStatus = status);
      }
    } catch (_) {
      // Our API being down is no reason someone can't shop — the toggle
      // just stays hidden for this page.
    }
  }

  Future<void> _toggleWatch() async {
    final status = _watchStatus;
    final productId = status?.productId;
    if (productId == null) return;
    setState(() => _watchBusy = true);
    try {
      if (status!.watching) {
        await ref.read(watchRepositoryProvider).stopWatching(productId);
      } else {
        await ref.read(watchRepositoryProvider).startWatching(productId);
      }
      if (mounted) {
        setState(() {
          _watchStatus = WatchStatus(
            productId: productId,
            title: status.title,
            watching: !status.watching,
          );
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update the watch — try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _watchBusy = false);
    }
  }

  void _injectReaderScript(InAppWebViewController controller) {
    controller.evaluateJavascript(
      source: buildReaderScript(
        widget.config.productUrlRegex,
        orderConfirmPatterns: widget.config.orderConfirmPatterns,
      ),
    );
  }

  /// System back walks the brand's own history first, and only leaves the brand
  /// once there is nothing left to go back to.
  Future<void> _goBack(bool didPop) async {
    if (didPop) return;
    if (await _controller?.canGoBack() ?? false) {
      await _controller?.goBack();
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Widget _webView() => InAppWebView(
    initialUrlRequest: URLRequest(
      url: WebUri(widget.initialUrl ?? widget.brand.websiteUrl),
    ),
    initialSettings: InAppWebViewSettings(
      // Empty keeps the system default; a brand gets an override only once its
      // site is shown to misbehave for in-app browsers.
      userAgent: widget.config.webviewUserAgent ?? '',
      // Bank 3DS/OTP steps arrive as window.open popups.
      supportMultipleWindows: true,
      javaScriptCanOpenWindowsAutomatically: true,
      useShouldOverrideUrlLoading: true,
    ),
    onWebViewCreated: (controller) {
      _controller = controller;
      // Read-only (ARCHITECTURE.md §6): reports page/product identity, never
      // touches the DOM.
      controller.addJavaScriptHandler(
        handlerName: 'brandnest',
        callback: (args) => _handlePageMessage(args.first as Map<String, dynamic>),
      );
    },
    onLoadStart: (controller, url) => _setUrl(url),
    onUpdateVisitedHistory: (controller, url, _) => _setUrl(url),
    // `onLoadStop` doesn't reliably fire on this WebView engine version, so
    // progress reaching 100% is the injection trigger instead — the reader
    // script is read-only, so firing it more than once per page is harmless.
    onProgressChanged: (controller, progress) {
      setState(() => _progress = progress / 100);
      if (progress == 100) _injectReaderScript(controller);
    },
    onLoadStop: (controller, url) => _injectReaderScript(controller),
    shouldOverrideUrlLoading: (controller, action) async {
      final url = action.request.url;
      if (url == null || !opensInAnotherApp(url)) {
        return NavigationActionPolicy.ALLOW;
      }
      if (!await openInAnotherApp(url) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No app can open ${url.scheme}: links')),
        );
      }
      return NavigationActionPolicy.CANCEL;
    },
    onCreateWindow: (controller, action) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PopupWebView(
            windowId: action.windowId,
            initialUrl: action.request.url,
            brandName: widget.brand.name,
            checkoutDomains: widget.config.checkoutDomains,
          ),
        ),
      );
      return Future.value(true);
    },
  );

  void _setUrl(WebUri? url) {
    if (url == null) return;
    setState(() => _url = url);
  }
}
