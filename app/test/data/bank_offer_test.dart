import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/data/bank_offer.dart';

import '../fixtures.dart';

void main() {
  test('parses an offer payload', () {
    final offer = BankOffer.fromJson(offersJson.first);

    expect(offer.id, 1);
    expect(offer.bankName, 'Standard Chartered');
    expect(offer.cardTypes, ['credit']);
    expect(offer.channel, 'online');
    expect(offer.discountPct, 15);
    expect(offer.maxDiscountAmount, 3000);
    expect(offer.minSpend, 5000);
    expect(offer.validTo, DateTime(2026, 9, 24));
    expect(offer.proofUrl, 'https://www.sc.com/pk/promotions/');
  });

  test('an offer can leave everything but the bank and card unstated', () {
    final offer = BankOffer.fromJson(offersJson.last);

    expect(offer.bankName, 'Meezan Bank');
    expect(offer.discountPct, isNull);
    expect(offer.minSpend, isNull);
    expect(offer.maxDiscountAmount, isNull);
    expect(offer.validTo, isNull);
    expect(offer.proofUrl, isNull);
  });

  test('a failed request surfaces as an error, not an empty offer list', () {
    final client = ApiClient(
      httpClient: MockClient((_) async => http.Response('boom', 500)),
    );

    expect(() => client.fetchBrandOffers('outfitters'), throwsException);
  });
}
