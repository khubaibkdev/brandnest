import 'package:flutter/material.dart';

/// What the address strip says about the page currently loaded.
///
/// The host is always shown: it is the shopper's own proof that they are on the
/// brand's site and paying the brand, not us.
class AddressBarState {
  const AddressBarState({
    required this.host,
    required this.isSecure,
    required this.isBrandCheckout,
  });

  factory AddressBarState.forUrl(Uri url, List<String> checkoutDomains) {
    return AddressBarState(
      host: url.host,
      isSecure: url.scheme == 'https',
      isBrandCheckout: checkoutDomains.any(
        (domain) => url.host == domain || url.host.endsWith('.$domain'),
      ),
    );
  }

  final String host;
  final bool isSecure;

  /// True on a payment host that is not the brand's own — where an unexplained
  /// hostname change would otherwise read as a hand-off to a stranger.
  final bool isBrandCheckout;
}

class AddressBar extends StatelessWidget {
  const AddressBar({
    super.key,
    required this.state,
    required this.brandName,
    required this.onClose,
    this.watchAction,
    this.historyAction,
    this.pinAction,
  });

  final AddressBarState state;
  final String brandName;
  final VoidCallback onClose;

  /// The Watch toggle (US-13), shown only while the toolbar has detected a
  /// product on the current page — the address bar itself stays ignorant of
  /// what a watch even is, same as it doesn't know about offer chips.
  final Widget? watchAction;

  /// The price-graph button (US-12), shown on the same condition as the Watch
  /// toggle: a product on screen that we have actually crawled.
  final Widget? historyAction;

  /// Pin to a Shaadi Squad (US-21). Unlike the two above, any detected
  /// product page qualifies — family can pin things we have not crawled.
  final Widget? pinAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          children: [
            Icon(
              state.isSecure ? Icons.lock : Icons.lock_open,
              size: 16,
              color: state.isSecure
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // A popup has no host until its first navigation resolves.
                    state.host.isEmpty ? 'Loading…' : state.host,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (state.isBrandCheckout)
                    Text(
                      // No possessive: brand names ending in s ("Outfitters")
                      // and in punctuation ("Junaid Jamshed (J.)") both read badly.
                      'Paying securely on the official $brandName checkout',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            ?pinAction,
            ?historyAction,
            ?watchAction,
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close),
              tooltip: 'Close $brandName',
            ),
          ],
        ),
      ),
    );
  }
}
