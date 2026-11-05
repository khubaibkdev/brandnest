import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/data/offer_directory_repository.dart';
import 'package:brandnest/features/offers/my_cards.dart';
import 'package:brandnest/features/offers/offer_presentation.dart';

/// Where the shopper says which cards they carry. Saved on the device as they
/// tick, so there is nothing to submit and nothing to lose by backing out.
class MyCardsSheet extends ConsumerWidget {
  const MyCardsSheet({super.key, required this.options});

  final List<BankCardOptions> options;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final held = ref.watch(myCardsProvider).value ?? const [];
    final heldKeys = {for (final card in held) '${card.bankSlug}/${card.cardType}'};

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My cards', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Tick the cards you carry and the directory will show only the '
                  'discounts you can actually claim. Stays on this phone.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final bank in options) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Text(bank.name, style: theme.textTheme.titleSmall),
                  ),
                  for (final cardType in bank.cardTypes)
                    CheckboxListTile(
                      dense: true,
                      title: Text(cardTypeLabel(cardType)),
                      value: heldKeys.contains('${bank.slug}/$cardType'),
                      onChanged: (held) => ref
                          .read(offerDirectoryRepositoryProvider)
                          .setCardHeld(bank.slug, cardType, held ?? false),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
