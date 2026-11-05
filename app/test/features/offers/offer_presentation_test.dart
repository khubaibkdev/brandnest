import 'package:flutter_test/flutter_test.dart';

import 'package:brandnest/features/offers/offer_presentation.dart';

import '../../fixtures.dart';

void main() {
  group('chip label', () {
    test('leads with the bank and the saving', () {
      expect(offerChipLabel(offerWith()), 'UBL 12% off');
    });

    test('drops a meaningless trailing zero', () {
      expect(formatPercent(15), '15%');
      expect(formatPercent(12.5), '12.5%');
    });

    test('falls back to the bank alone when the saving is not a percentage', () {
      expect(offerChipLabel(offerWith(discountPct: null)), 'UBL');
    });
  });

  group('detail text', () {
    test('groups rupees in thousands', () {
      expect(formatRupees(6000), 'PKR 6,000');
      expect(formatRupees(750), 'PKR 750');
      expect(formatRupees(1250000), 'PKR 1,250,000');
    });

    test('spells out every card the offer accepts', () {
      expect(
        offerCardTypes(offerWith(cardTypes: ['credit', 'islamic'])),
        'Credit, Islamic',
      );
    });

    test('says so when any card of the bank qualifies', () {
      expect(offerCardTypes(offerWith(cardTypes: [])), 'Any card from this bank');
    });

    test('states the minimum spend, or that there is none', () {
      expect(offerMinSpend(offerWith(minSpend: 3000)), 'Minimum spend PKR 3,000');
      expect(offerMinSpend(offerWith()), 'No minimum spend');
    });

    test('gives the shopper the deadline', () {
      expect(
        offerValidity(offerWith(validTo: DateTime(2026, 8, 16))),
        'Valid till 16 Aug 2026',
      );
      expect(offerValidity(offerWith()), 'No end date announced');
    });

    test('translates the channel', () {
      expect(offerChannel(offerWith(channel: 'online')), 'Online only');
      expect(offerChannel(offerWith(channel: 'instore')), 'In store only');
      expect(offerChannel(offerWith(channel: 'both')), 'Online and in store');
    });
  });

  group('directory wording', () {
    test('names the brand, or says the offer works at all of them', () {
      expect(offerBrand(offerWith(brandName: 'Outfitters')), 'Outfitters');
      expect(offerBrand(offerWith()), 'All brands');
    });

    test('states the saving alone, since the bank is the heading above it', () {
      expect(offerSaving(offerWith(discountPct: 15)), '15% off');
      expect(offerSaving(offerWith(discountPct: null)), 'Cardholder offer');
    });
  });
}
