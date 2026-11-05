import 'package:flutter/material.dart';

import 'package:brandnest/data/bank_offer.dart';
import 'package:brandnest/features/offers/offer_presentation.dart';

/// The bank offers for the brand being browsed, sitting directly under the
/// address strip. Nothing renders when the brand has none.
class OfferChips extends StatelessWidget {
  const OfferChips({super.key, required this.offers});

  final List<BankOffer> offers;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          for (final offer in offers)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _OfferChip(offer: offer),
            ),
        ],
      ),
    );
  }
}

class _OfferChip extends StatelessWidget {
  const _OfferChip({required this.offer});

  final BankOffer offer;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.credit_card, size: 16),
      label: Text(offerChipLabel(offer)),
      visualDensity: VisualDensity.compact,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        builder: (_) => OfferDetailSheet(offer: offer),
      ),
    );
  }
}
