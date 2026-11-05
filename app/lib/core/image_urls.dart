/// Asking a brand's CDN for a smaller image (US-17).
///
/// ARCHITECTURE.md §1 puts thumbnails on R2, which does not exist yet — but
/// every product image in the catalog is served from `cdn.shopify.com`, which
/// resizes on request via a `width` parameter. That is a real thumbnail, not a
/// full image scaled down after it has already crossed the network, so Data
/// Saver can save data today rather than waiting for the R2 pipeline. It is the
/// same trick `seed_brands.py` already uses to fetch brand logos at width=512.
library;

/// Hosts known to resize from a `width` query parameter. A URL anywhere else is
/// returned untouched: sending `width` to a CDN that ignores it would cost a
/// cache miss and save nothing.
const _resizingHosts = {'cdn.shopify.com'};

/// The same URL asking for [width] pixels, where the host can do that.
String? sizedImageUrl(String? url, {required int width}) {
  if (url == null) return null;
  final parsed = Uri.tryParse(url);
  if (parsed == null || !_resizingHosts.contains(parsed.host)) return url;
  // Replaces rather than appends: a URL that already carries a width (the
  // curated logos do) must not end up asking for two different ones.
  return parsed
      .replace(
        queryParameters: {...parsed.queryParameters, 'width': '$width'},
      )
      .toString();
}
