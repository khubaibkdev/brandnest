import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/data/bank_offer.dart';

/// The order card types are worth reading in, most commonly held first.
const _knownCardTypes = ['credit', 'debit', 'islamic', 'wallet', 'bnpl'];

/// An offer the shopper can actually pay with: they hold a card from that bank,
/// and it is a type the offer accepts.
///
/// A saved card is a (bank, type) pair rather than two independent lists,
/// because holding a Meezan debit card does not make a Standard Chartered debit
/// offer usable — and showing a discount someone cannot claim is the failure
/// this whole feature exists to avoid.
///
/// An offer naming no card types accepts any card from its bank.
bool offerMatchesMyCards(BankOffer offer, List<MyCard> cards) => cards.any(
  (card) =>
      card.bankSlug == offer.bankSlug &&
      (offer.cardTypes.isEmpty || offer.cardTypes.contains(card.cardType)),
);

/// One bank as the "my cards" picker shows it.
typedef BankCardOptions = ({String slug, String name, List<String> cardTypes});

/// The picker is built from the offers on hand, not a fixed list, so it never
/// asks about a bank we carry nothing from.
///
/// A bank whose offers name no card types therefore has nothing to tick and is
/// left out; its offers stay reachable by browsing unfiltered.
List<BankCardOptions> bankCardOptions(List<BankOffer> offers) {
  final namesBySlug = <String, String>{};
  final typesBySlug = <String, Set<String>>{};
  for (final offer in offers) {
    namesBySlug[offer.bankSlug] = offer.bankName;
    typesBySlug.putIfAbsent(offer.bankSlug, () => {}).addAll(offer.cardTypes);
  }

  final options = [
    for (final entry in typesBySlug.entries)
      if (entry.value.isNotEmpty)
        (
          slug: entry.key,
          name: namesBySlug[entry.key]!,
          cardTypes: entry.value.toList()..sort(_byFamiliarity),
        ),
  ];
  return options..sort((a, b) => a.name.compareTo(b.name));
}

int _byFamiliarity(String a, String b) {
  final ranks = (_knownCardTypes.indexOf(a), _knownCardTypes.indexOf(b));
  return switch (ranks) {
    (-1, -1) => a.compareTo(b),
    (-1, _) => 1,
    (_, -1) => -1,
    (final left, final right) => left.compareTo(right),
  };
}
