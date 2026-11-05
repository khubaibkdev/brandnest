import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brandnest/core/image_urls.dart';
import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/data/display_prefs_repository.dart';

void main() {
  group('asking a CDN for a smaller image', () {
    test('adds a width to a Shopify image', () {
      final url = sizedImageUrl(
        'https://cdn.shopify.com/s/files/1/0702/2487/1584/files/39726JCKP_1.jpg?v=1783668095',
        width: 160,
      );

      expect(url, contains('width=160'));
      // The cache-busting version has to survive, or the CDN serves whatever
      // it had before the brand last replaced the image.
      expect(url, contains('v=1783668095'));
    });

    test('replaces a width that is already there', () {
      // The curated brand logos ship at width=512; asking for two widths at
      // once is not a URL the CDN can answer.
      final url = sizedImageUrl(
        'https://cdn.shopify.com/s/files/1/1/files/logo.png?width=512',
        width: 240,
      );

      expect(url, contains('width=240'));
      expect(url, isNot(contains('512')));
    });

    test('leaves a host that cannot resize alone', () {
      // Sending `width` to a CDN that ignores it costs a cache miss and saves
      // nothing.
      const url = 'https://images.sapphireonline.pk/product/1.jpg';

      expect(sizedImageUrl(url, width: 160), url);
    });

    test('a product with no image stays without one', () {
      expect(sizedImageUrl(null, width: 160), isNull);
    });

    test('an unparseable url is passed through rather than dropped', () {
      expect(sizedImageUrl('not a url at all', width: 160), 'not a url at all');
    });
  });

  group('deciding when to save data', () {
    Future<bool> saving({
      required bool dataSaver,
      required bool onMobile,
    }) async {
      final container = ProviderContainer(
        overrides: [
          displayPrefsProvider.overrideWith(
            (ref) => Stream.value(
              DisplayPref(id: 0, dataSaver: dataSaver, darkMode: true),
            ),
          ),
          onMobileDataProvider.overrideWith((ref) => Stream.value(onMobile)),
        ],
      );
      addTearDown(container.dispose);
      // Listening keeps the two stream providers alive long enough to emit;
      // an unlistened one is disposed mid-load and its future never completes.
      container.listen(saveImageDataProvider, (_, _) {});
      // Both must have emitted before reading: a stream provider that is still
      // loading reports its default, which would make every case here pass
      // whatever the inputs were.
      await container.read(displayPrefsProvider.future);
      await container.read(onMobileDataProvider.future);
      return container.read(saveImageDataProvider);
    }

    test('saves only when the setting is on AND the phone is on mobile data', () async {
      expect(await saving(dataSaver: true, onMobile: true), isTrue);
    });

    test('changes nothing on Wi-Fi, where there is no data to save', () async {
      expect(await saving(dataSaver: true, onMobile: false), isFalse);
    });

    test('never downgrades images the shopper did not ask to downgrade', () async {
      expect(await saving(dataSaver: false, onMobile: true), isFalse);
      expect(await saving(dataSaver: false, onMobile: false), isFalse);
    });

    test('images stay full size until connectivity has reported in', () async {
      // Briefly serving a good image beats briefly serving a blurry one that
      // then has to be replaced.
      final container = ProviderContainer(
        overrides: [
          displayPrefsProvider.overrideWith(
            (ref) => Stream.value(
              const DisplayPref(id: 0, dataSaver: true, darkMode: true),
            ),
          ),
          onMobileDataProvider.overrideWith((ref) => const Stream<bool>.empty()),
        ],
      );
      addTearDown(container.dispose);
      container.listen(saveImageDataProvider, (_, _) {});
      await container.read(displayPrefsProvider.future);

      expect(container.read(saveImageDataProvider), isFalse);
    });
  });
}
