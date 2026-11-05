import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/data/offer_directory_repository.dart';

import '../fixtures.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  OfferDirectoryRepository repositoryFor(List<Map<String, dynamic>> payload) =>
      OfferDirectoryRepository(
        ApiClient(
          httpClient: MockClient((_) async => http.Response(jsonEncode(payload), 200)),
        ),
        database,
      );

  group('the cached directory', () {
    test('refresh caches every offer for offline reading', () async {
      final repository = repositoryFor(directoryOffersJson);

      await repository.refresh();

      final cached = await repository.watchOffers().first;
      expect(cached.map((offer) => offer.bankName), [
        'Bank Alfalah',
        'Meezan Bank',
        'Standard Chartered',
      ]);
      expect(cached.first.brandName, 'Limelight');
      expect(cached.first.maxDiscountAmount, 5000);
      expect(cached.first.validTo, DateTime(2026, 8, 16));
    });

    test('a multi-brand offer keeps no brand of its own', () async {
      await repositoryFor(directoryOffersJson).refresh();

      final cached = await database.watchDirectoryOffers().first;
      final everyones = cached.firstWhere((offer) => offer.bankSlug == 'meezan');
      expect(everyones.brandSlug, isNull);
      expect(everyones.brandName, isNull);
    });

    test('refresh drops offers the desk has taken down', () async {
      await repositoryFor(directoryOffersJson).refresh();
      await repositoryFor([directoryOffersJson.first]).refresh();

      final cached = await database.watchDirectoryOffers().first;
      expect(cached.map((offer) => offer.id), [4]);
    });
  });

  group('an offer that ran out while it was cached', () {
    test('is hidden even though the API once served it', () {
      final expired = offerWith(validTo: DateTime(2026, 8, 16));

      expect(isOfferCurrent(expired, DateTime(2026, 8, 17)), isFalse);
    });

    test('lasts the whole of its final day', () {
      final offer = offerWith(validTo: DateTime(2026, 8, 16));

      expect(isOfferCurrent(offer, DateTime(2026, 8, 16, 23, 59)), isTrue);
    });

    test('is not shown before it starts', () {
      final offer = offerWith(validFrom: DateTime(2026, 8, 16));

      expect(isOfferCurrent(offer, DateTime(2026, 8, 15)), isFalse);
      expect(isOfferCurrent(offer, DateTime(2026, 8, 16)), isTrue);
    });

    test('runs forever when no dates were announced', () {
      expect(isOfferCurrent(offerWith(), DateTime(2030, 1, 1)), isTrue);
    });

    test('never reaches the screen from the cache', () async {
      await repositoryFor([
        {...directoryOffersJson.first, 'valid_to': '2020-01-01'},
        directoryOffersJson.last,
      ]).refresh();

      final served = await repositoryFor([]).watchOffers().first;
      expect(served.map((offer) => offer.id), [1]);
    });
  });

  group('my cards', () {
    test('are saved as they are ticked and survive being read back', () async {
      final repository = repositoryFor([]);

      await repository.setCardHeld('meezan', 'islamic', true);
      await repository.setCardHeld('ubl', 'credit', true);

      final held = await repository.watchMyCards().first;
      expect(held.map((card) => '${card.bankSlug}/${card.cardType}'), [
        'meezan/islamic',
        'ubl/credit',
      ]);
    });

    test('unticking removes only that one card', () async {
      final repository = repositoryFor([]);
      await repository.setCardHeld('ubl', 'credit', true);
      await repository.setCardHeld('ubl', 'debit', true);

      await repository.setCardHeld('ubl', 'credit', false);

      final held = await repository.watchMyCards().first;
      expect(held.map((card) => card.cardType), ['debit']);
    });

    test('ticking the same card twice keeps one row', () async {
      final repository = repositoryFor([]);

      await repository.setCardHeld('ubl', 'credit', true);
      await repository.setCardHeld('ubl', 'credit', true);

      expect(await repository.watchMyCards().first, hasLength(1));
    });
  });
}
