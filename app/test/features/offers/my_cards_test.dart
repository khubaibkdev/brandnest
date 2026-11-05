import 'package:flutter_test/flutter_test.dart';

import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/features/offers/my_cards.dart';

import '../../fixtures.dart';

MyCard card(String bankSlug, String cardType) =>
    MyCard(bankSlug: bankSlug, cardType: cardType);

void main() {
  group('matching an offer to my cards', () {
    test('matches a card of the right type from the right bank', () {
      final offer = offerWith(bankSlug: 'meezan', cardTypes: ['islamic']);

      expect(offerMatchesMyCards(offer, [card('meezan', 'islamic')]), isTrue);
    });

    test('a card type I hold at another bank does not unlock this one', () {
      final offer = offerWith(bankSlug: 'meezan', cardTypes: ['credit']);

      expect(offerMatchesMyCards(offer, [card('ubl', 'credit')]), isFalse);
    });

    test('the right bank with the wrong card type is still no good', () {
      final offer = offerWith(bankSlug: 'meezan', cardTypes: ['credit']);

      expect(offerMatchesMyCards(offer, [card('meezan', 'debit')]), isFalse);
    });

    test('an offer naming no card types takes any card from its bank', () {
      final offer = offerWith(bankSlug: 'meezan', cardTypes: []);

      expect(offerMatchesMyCards(offer, [card('meezan', 'debit')]), isTrue);
    });

    test('one qualifying card out of several is enough', () {
      final offer = offerWith(bankSlug: 'ubl', cardTypes: ['debit']);

      expect(
        offerMatchesMyCards(offer, [card('meezan', 'islamic'), card('ubl', 'debit')]),
        isTrue,
      );
    });

    test('nothing matches when the shopper has saved no cards', () {
      expect(offerMatchesMyCards(offerWith(), []), isFalse);
    });
  });

  group('picker options', () {
    test('offers each bank with the card types its offers mention', () {
      final options = bankCardOptions([
        offerWith(id: 1, bankSlug: 'ubl', bankName: 'UBL', cardTypes: ['credit']),
        offerWith(id: 2, bankSlug: 'ubl', bankName: 'UBL', cardTypes: ['debit']),
        offerWith(
          id: 3,
          bankSlug: 'meezan',
          bankName: 'Meezan Bank',
          cardTypes: ['islamic'],
        ),
      ]);

      expect(options.map((bank) => bank.name), ['Meezan Bank', 'UBL']);
      expect(options.last.cardTypes, ['credit', 'debit']);
    });

    test('does not ask about a bank we carry nothing from', () {
      final options = bankCardOptions([offerWith(bankSlug: 'ubl')]);

      expect(options.map((bank) => bank.slug), ['ubl']);
    });

    test('leaves out a bank whose offers name no card types to tick', () {
      final options = bankCardOptions([offerWith(bankSlug: 'ubl', cardTypes: [])]);

      expect(options, isEmpty);
    });

    test('lists card types most commonly held first, not alphabetically', () {
      final options = bankCardOptions([
        offerWith(cardTypes: ['bnpl', 'debit', 'credit']),
      ]);

      expect(options.single.cardTypes, ['credit', 'debit', 'bnpl']);
    });
  });
}
