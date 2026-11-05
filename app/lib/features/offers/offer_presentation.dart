import 'package:flutter/material.dart';

import 'package:brandnest/data/bank_offer.dart';
import 'package:brandnest/features/brand_webview/external_links.dart';

/// How an offer is worded wherever it appears — as a toolbar chip on the brand
/// being browsed (US-3), and as a card in the directory (US-5). One set of
/// formatters, so the same offer never reads two different ways.

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const _cardTypeLabels = {
  'credit': 'Credit',
  'debit': 'Debit',
  'islamic': 'Islamic',
  'wallet': 'Wallet',
  'bnpl': 'Buy now pay later',
};

/// What a shopper needs to recognise their own card at a glance.
String offerChipLabel(BankOffer offer) {
  final pct = offer.discountPct;
  return pct == null ? offer.bankName : '${offer.bankName} ${formatPercent(pct)} off';
}

String formatPercent(double value) =>
    value == value.roundToDouble() ? '${value.round()}%' : '$value%';

String formatRupees(double amount) {
  final digits = amount.round().toString();
  final grouped = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) grouped.write(',');
    grouped.write(digits[index]);
  }
  return 'PKR $grouped';
}

String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

String cardTypeLabel(String cardType) => _cardTypeLabels[cardType] ?? cardType;

String offerCardTypes(BankOffer offer) => offer.cardTypes.isEmpty
    ? 'Any card from this bank'
    : offer.cardTypes.map(cardTypeLabel).join(', ');

String offerMinSpend(BankOffer offer) {
  final minSpend = offer.minSpend;
  return minSpend == null
      ? 'No minimum spend'
      : 'Minimum spend ${formatRupees(minSpend)}';
}

String offerValidity(BankOffer offer) {
  final validTo = offer.validTo;
  // The API only serves offers whose window is open today, so the end date is
  // the only half a shopper still has to act on.
  return validTo == null
      ? 'No end date announced'
      : 'Valid till ${formatDate(validTo)}';
}

String offerChannel(BankOffer offer) => switch (offer.channel) {
  'online' => 'Online only',
  'instore' => 'In store only',
  _ => 'Online and in store',
};

/// Where the offer can be spent. A multi-brand offer carries no brand at all.
String offerBrand(BankOffer offer) => offer.brandName ?? 'All brands';

/// The saving on its own, for the directory, where the bank is already the
/// heading above the row.
String offerSaving(BankOffer offer) {
  final pct = offer.discountPct;
  return pct == null ? 'Cardholder offer' : '${formatPercent(pct)} off';
}

class OfferDetailSheet extends StatelessWidget {
  const OfferDetailSheet({super.key, required this.offer});

  final BankOffer offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxDiscount = offer.maxDiscountAmount;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Verified offer',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(offerChipLabel(offer), style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            _Detail(icon: Icons.credit_card, text: offerCardTypes(offer)),
            _Detail(icon: Icons.shopping_bag_outlined, text: offerMinSpend(offer)),
            if (maxDiscount != null)
              _Detail(
                icon: Icons.savings_outlined,
                text: 'Up to ${formatRupees(maxDiscount)} off',
              ),
            _Detail(icon: Icons.event_outlined, text: offerValidity(offer)),
            _Detail(icon: Icons.storefront_outlined, text: offerChannel(offer)),
            if (offer.proofUrl != null) _ProofLink(url: offer.proofUrl!),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// The bank's own page. It opens outside the app on purpose: checking our claim
/// should not disturb the shopping session behind the sheet.
class _ProofLink extends StatelessWidget {
  const _ProofLink({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.open_in_new, size: 18),
      label: const Text('See this offer on the bank site'),
    );
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await openInAnotherApp(Uri.parse(url))) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No browser to open the offer page')),
      );
    }
  }
}
