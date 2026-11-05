import 'package:flutter_test/flutter_test.dart';

import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/features/calendar/sale_phase.dart';

final _now = DateTime(2026, 7, 26, 14, 30);

SaleEvent saleWith({
  DateTime? startsAt,
  DateTime? endsAt,
  String status = 'live',
}) => SaleEvent(
  id: 1,
  brandSlug: 'outfitters',
  brandName: 'Outfitters',
  title: 'Summer Sale',
  status: status,
  startsAt: startsAt,
  endsAt: endsAt,
);

void main() {
  group('phase', () {
    test('a sale that has not started is upcoming', () {
      final sale = saleWith(startsAt: DateTime(2026, 8, 1));

      expect(salePhase(sale, _now), SalePhase.upcoming);
    });

    test('a sale whose end has passed is over', () {
      final sale = saleWith(
        startsAt: DateTime(2026, 7, 1),
        endsAt: DateTime(2026, 7, 20),
      );

      expect(salePhase(sale, _now), SalePhase.ended);
    });

    test('a sale with no dates at all is simply on', () {
      expect(salePhase(saleWith(), _now), SalePhase.running);
    });
  });

  group('countdown', () {
    test('counts whole days, not 24-hour blocks', () {
      // 14:30 today to 09:00 tomorrow is under 24 hours but still "tomorrow".
      final sale = saleWith(startsAt: DateTime(2026, 7, 27, 9));

      expect(saleCountdown(sale, _now), 'Starts tomorrow');
    });

    test('reads out the days until a sale opens', () {
      final sale = saleWith(startsAt: DateTime(2026, 8, 1));

      expect(saleCountdown(sale, _now), 'Starts in 6 days');
    });

    test('switches to the deadline once a sale is on', () {
      final sale = saleWith(
        startsAt: DateTime(2026, 7, 20),
        endsAt: DateTime(2026, 7, 29),
      );

      expect(saleCountdown(sale, _now), 'Ends in 3 days');
    });

    test('says today when the sale ends today', () {
      final sale = saleWith(
        startsAt: DateTime(2026, 7, 20),
        endsAt: DateTime(2026, 7, 26, 23, 59),
      );

      expect(saleCountdown(sale, _now), 'Ends today');
    });

    test('does not invent a deadline the brand never gave', () {
      expect(saleCountdown(saleWith(), _now), 'Live now');
    });

    test('looks backwards once a sale is over', () {
      final sale = saleWith(
        startsAt: DateTime(2026, 7, 1),
        endsAt: DateTime(2026, 7, 25, 23, 59),
      );

      expect(saleCountdown(sale, _now), 'Ended yesterday');
    });
  });

  group('badge', () {
    test('verified and live events carry it', () {
      expect(isVerified(saleWith(status: 'verified')), isTrue);
      expect(isVerified(saleWith(status: 'live')), isTrue);
    });

    test('an event that has ended keeps its row but loses the tick', () {
      expect(isVerified(saleWith(status: 'expired')), isFalse);
    });
  });

  group('month grid', () {
    final sale = saleWith(
      startsAt: DateTime(2026, 7, 20, 10),
      endsAt: DateTime(2026, 7, 22, 23, 59),
    );

    test('covers every day it runs on, inclusive of both ends', () {
      expect(coversDay(sale, DateTime(2026, 7, 20)), isTrue);
      expect(coversDay(sale, DateTime(2026, 7, 21)), isTrue);
      expect(coversDay(sale, DateTime(2026, 7, 22)), isTrue);
    });

    test('covers nothing outside its run', () {
      expect(coversDay(sale, DateTime(2026, 7, 19)), isFalse);
      expect(coversDay(sale, DateTime(2026, 7, 23)), isFalse);
    });

    test('an open-ended sale covers every day from its start', () {
      final openEnded = saleWith(startsAt: DateTime(2026, 7, 20));

      expect(coversDay(openEnded, DateTime(2027, 1, 1)), isTrue);
      expect(coversDay(openEnded, DateTime(2026, 7, 19)), isFalse);
    });

    test('an undated sale belongs to no square', () {
      expect(coversDay(saleWith(), DateTime(2026, 7, 26)), isFalse);
      expect(isUndated(saleWith()), isTrue);
    });
  });
}
