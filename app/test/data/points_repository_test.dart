import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/data/points_repository.dart';

const _statusJson = {
  'balance': 30,
  'streak_days': 2,
  'checked_in_today': true,
  'rewarded_ads_remaining_today': 4,
};

PointsRepository _repositoryFor(
  http.Response Function(http.Request) respond,
) => PointsRepository(
  ApiClient(httpClient: MockClient((request) async => respond(request))),
  () async => 'fake-id-token',
);

void main() {
  group('fetch', () {
    test('parses the account status', () async {
      final repository = _repositoryFor(
        (_) => http.Response(jsonEncode(_statusJson), 200),
      );

      final status = await repository.fetch();

      expect(status.balance, 30);
      expect(status.streakDays, 2);
      expect(status.checkedInToday, true);
      expect(status.rewardedAdsRemainingToday, 4);
    });

    test('without a signed-in shopper it refuses rather than calling the API', () async {
      final repository = PointsRepository(
        ApiClient(httpClient: MockClient((_) async => fail('should not be called'))),
      );

      expect(repository.fetch(), throwsStateError);
    });
  });

  group('checkIn', () {
    test('reports whether this call actually paid out', () async {
      final repository = _repositoryFor(
        (request) => http.Response(
          jsonEncode({..._statusJson, 'awarded': false}),
          200,
        ),
      );

      final result = await repository.checkIn();

      expect(result.awarded, false);
      expect(result.balance, 30);
    });

    test('posts to the checkin route with the bearer token', () async {
      http.Request? seen;
      final repository = _repositoryFor((request) {
        seen = request;
        return http.Response(jsonEncode({..._statusJson, 'awarded': true}), 200);
      });

      await repository.checkIn();

      expect(seen!.method, 'POST');
      expect(seen!.url.path, '/me/points/checkin');
      expect(seen!.headers['Authorization'], 'Bearer fake-id-token');
    });
  });

  group('reportRewardedAd', () {
    test('sends the client ref so a retry cannot double-pay', () async {
      http.Request? seen;
      final repository = _repositoryFor((request) {
        seen = request;
        return http.Response(jsonEncode({..._statusJson, 'awarded': true}), 200);
      });

      await repository.reportRewardedAd('watch-123');

      expect(jsonDecode(seen!.body), {'client_ref': 'watch-123'});
    });
  });

  group('reportOrder (US-18)', () {
    test('reports the brand and the confirmation URL it landed on', () async {
      late http.Request seen;
      final repository = _repositoryFor((request) {
        seen = request;
        return http.Response(
          jsonEncode({..._statusJson, 'pending': 100, 'awarded': true}),
          200,
        );
      });

      final result = await repository.reportOrder(
        'outfitters',
        'https://outfitters.com.pk/checkouts/c/abc/thank_you',
      );

      expect(seen.url.path, '/me/points/order');
      expect(jsonDecode(seen.body)['brand_slug'], 'outfitters');
      expect(result!.awarded, true);
      expect(result.pending, 100);
    });

    test('a 400 is an answer, not an error', () async {
      // The server, not the app, decides what counts as a confirmation page;
      // "no" has to be survivable while someone is mid-checkout.
      final repository = _repositoryFor((_) => http.Response('{}', 400));

      expect(
        await repository.reportOrder('outfitters', 'https://outfitters.com.pk/x'),
        isNull,
      );
    });

    test('pending defaults to zero when the server omits it', () async {
      final repository = _repositoryFor(
        (_) => http.Response(jsonEncode(_statusJson), 200),
      );

      expect((await repository.fetch()).pending, 0);
    });
  });
}
