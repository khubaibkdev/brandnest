import 'package:flutter_test/flutter_test.dart';

import 'package:brandnest/data/search_repository.dart';

Map<String, dynamic> _payload({
  List<Map<String, dynamic>>? hits,
  double? maxPrice,
}) => {
  'hits':
      hits ??
      [
        {
          'product_id': 11,
          'title': 'LIGHT BROWN SEMI-FORMAL KURTA',
          'brand_slug': 'junaid-jamshed',
          'brand_name': 'Junaid Jamshed',
          'category': 'Kurta & Kurti',
          'raw_category': 'Kurta',
          'audience': 'Men',
          'price': 2390.0,
          'url': 'https://www.junaidjamshed.com/products/x',
          'image': null,
        },
      ],
  'total': 1369,
  'page': 1,
  'query_text': 'kurta',
  'min_price': null,
  'max_price': maxPrice,
  'brands': [
    {'value': 'zellbury', 'count': 959},
    {'value': 'junaid-jamshed', 'count': 192},
  ],
  'categories': [
    {'value': 'Kurta & Kurti', 'count': 1091},
  ],
  'audiences': [
    {'value': 'Women', 'count': 800},
  ],
  'raw_categories': [
    {'value': 'Essential Pret', 'count': 400},
  ],
};

void main() {
  group('reading a search response', () {
    test('keeps the brand’s own category alongside the canonical one', () {
      final hit = SearchResults.fromJson(_payload()).hits.single;

      expect(hit.category, 'Kurta & Kurti');
      expect(hit.rawCategory, 'Kurta');
      expect(hit.brandName, 'Junaid Jamshed');
      expect(hit.price, 2390.0);
    });

    test('reports the price ceiling the server lifted out of the query', () {
      final results = SearchResults.fromJson(_payload(maxPrice: 3000));

      expect(results.queryText, 'kurta');
      expect(results.maxPrice, 3000);
    });

    test('carries every facet the filter sheet offers', () {
      final results = SearchResults.fromJson(_payload());

      expect(results.brands.first.value, 'zellbury');
      expect(results.brands.first.count, 959);
      expect(results.rawCategories.single.value, 'Essential Pret');
    });

    test('a response with no results parses to an empty list', () {
      final results = SearchResults.fromJson(_payload(hits: []));

      expect(results.hits, isEmpty);
    });
  });

  group('filters', () {
    test('start empty', () {
      expect(const SearchFilters().isEmpty, isTrue);
      expect(const SearchFilters().count, 0);
    });

    test('toggling adds then removes a value', () {
      final once = const SearchFilters().toggled(SearchFacet.brand, 'zellbury');
      expect(once.brandSlugs, {'zellbury'});

      final twice = once.toggled(SearchFacet.brand, 'zellbury');
      expect(twice.brandSlugs, isEmpty);
    });

    test('several values of one facet stack up', () {
      final filters = const SearchFilters()
          .toggled(SearchFacet.brand, 'zellbury')
          .toggled(SearchFacet.brand, 'edenrobe');

      expect(filters.brandSlugs, {'zellbury', 'edenrobe'});
      expect(filters.count, 2);
    });

    test('changing category drops the brand shelves picked under the old one', () {
      // Those shelves belong to a category that is no longer in play; keeping
      // them would AND two disjoint filters and return nothing at all.
      final filters = const SearchFilters()
          .toggled(SearchFacet.category, 'Kurta & Kurti')
          .toggled(SearchFacet.rawCategory, 'Kurta')
          .toggled(SearchFacet.category, 'Bottoms');

      expect(filters.categories, {'Kurta & Kurti', 'Bottoms'});
      expect(filters.rawCategories, isEmpty);
    });

    test('a maximum price counts as a filter and can be cleared', () {
      final withPrice = const SearchFilters().copyWith(maxPrice: 3000);
      expect(withPrice.count, 1);
      expect(withPrice.isEmpty, isFalse);

      expect(withPrice.copyWith(clearMaxPrice: true).maxPrice, isNull);
    });
  });
}
