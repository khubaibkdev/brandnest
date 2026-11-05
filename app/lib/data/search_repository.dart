import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/api_client.dart';

/// One product from the cross-brand index (US-11).
class SearchHit {
  const SearchHit({
    required this.productId,
    required this.title,
    required this.brandSlug,
    required this.brandName,
    required this.category,
    required this.rawCategory,
    required this.audience,
    required this.price,
    required this.url,
    required this.image,
  });

  final int productId;
  final String title;
  final String brandSlug;
  final String brandName;

  /// The canonical category the filter offers.
  final String category;

  /// The brand's own name for the same shelf — kept so a result still shows the
  /// detail someone drilled in for, rather than only our tidied-up label.
  final String? rawCategory;

  final String? audience;
  final double price;
  final String url;
  final String? image;

  factory SearchHit.fromJson(Map<String, dynamic> json) => SearchHit(
    productId: json['product_id'] as int,
    title: json['title'] as String,
    brandSlug: json['brand_slug'] as String,
    brandName: json['brand_name'] as String,
    category: json['category'] as String,
    rawCategory: json['raw_category'] as String?,
    audience: json['audience'] as String?,
    price: (json['price'] as num).toDouble(),
    url: json['url'] as String,
    image: json['image'] as String?,
  );
}

/// A filter value and how many of the current results it would leave.
class FacetValue {
  const FacetValue({required this.value, required this.count});

  final String value;
  final int count;

  factory FacetValue.fromJson(Map<String, dynamic> json) =>
      FacetValue(value: json['value'] as String, count: json['count'] as int);
}

class SearchResults {
  const SearchResults({
    required this.hits,
    required this.total,
    required this.page,
    required this.queryText,
    required this.minPrice,
    required this.maxPrice,
    required this.brands,
    required this.categories,
    required this.audiences,
    required this.rawCategories,
  });

  final List<SearchHit> hits;
  final int total;
  final int page;

  /// What the query became once a price phrase was lifted out of it, so the UI
  /// can show that "under 3000" was understood rather than silently dropped.
  final String queryText;
  final double? minPrice;
  final double? maxPrice;

  final List<FacetValue> brands;
  final List<FacetValue> categories;
  final List<FacetValue> audiences;
  final List<FacetValue> rawCategories;

  static const empty = SearchResults(
    hits: [],
    total: 0,
    page: 1,
    queryText: '',
    minPrice: null,
    maxPrice: null,
    brands: [],
    categories: [],
    audiences: [],
    rawCategories: [],
  );

  factory SearchResults.fromJson(Map<String, dynamic> json) => SearchResults(
    hits: [
      for (final hit in json['hits'] as List)
        SearchHit.fromJson(hit as Map<String, dynamic>),
    ],
    total: json['total'] as int,
    page: json['page'] as int,
    queryText: json['query_text'] as String,
    minPrice: (json['min_price'] as num?)?.toDouble(),
    maxPrice: (json['max_price'] as num?)?.toDouble(),
    brands: _facets(json['brands']),
    categories: _facets(json['categories']),
    audiences: _facets(json['audiences']),
    rawCategories: _facets(json['raw_categories']),
  );

  static List<FacetValue> _facets(Object? raw) => [
    for (final facet in (raw as List? ?? const []))
      FacetValue.fromJson(facet as Map<String, dynamic>),
  ];
}

/// What the shopper has narrowed to. Immutable so a stale in-flight response
/// can be told apart from the current one.
class SearchFilters {
  const SearchFilters({
    this.brandSlugs = const {},
    this.categories = const {},
    this.rawCategories = const {},
    this.audiences = const {},
    this.maxPrice,
  });

  final Set<String> brandSlugs;
  final Set<String> categories;
  final Set<String> rawCategories;
  final Set<String> audiences;
  final double? maxPrice;

  bool get isEmpty =>
      brandSlugs.isEmpty &&
      categories.isEmpty &&
      rawCategories.isEmpty &&
      audiences.isEmpty &&
      maxPrice == null;

  int get count =>
      brandSlugs.length +
      categories.length +
      rawCategories.length +
      audiences.length +
      (maxPrice == null ? 0 : 1);

  SearchFilters toggled(SearchFacet facet, String value) {
    Set<String> flip(Set<String> current) => current.contains(value)
        ? (current.toSet()..remove(value))
        : (current.toSet()..add(value));
    return switch (facet) {
      SearchFacet.brand => copyWith(brandSlugs: flip(brandSlugs)),
      // Narrowing to a different canonical category abandons the brand-specific
      // shelves picked underneath the old one — they belong to a category that
      // is no longer in play, and leaving them would return nothing.
      SearchFacet.category => copyWith(
        categories: flip(categories),
        rawCategories: const {},
      ),
      SearchFacet.rawCategory => copyWith(rawCategories: flip(rawCategories)),
      SearchFacet.audience => copyWith(audiences: flip(audiences)),
    };
  }

  SearchFilters copyWith({
    Set<String>? brandSlugs,
    Set<String>? categories,
    Set<String>? rawCategories,
    Set<String>? audiences,
    double? maxPrice,
    bool clearMaxPrice = false,
  }) => SearchFilters(
    brandSlugs: brandSlugs ?? this.brandSlugs,
    categories: categories ?? this.categories,
    rawCategories: rawCategories ?? this.rawCategories,
    audiences: audiences ?? this.audiences,
    maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
  );
}

enum SearchFacet { brand, category, rawCategory, audience }

class SearchRepository {
  SearchRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<SearchResults> search(
    String query,
    SearchFilters filters, {
    int page = 1,
  }) async => SearchResults.fromJson(
    await _apiClient.searchProducts(
      query: query,
      brandSlugs: filters.brandSlugs.toList(),
      categories: filters.categories.toList(),
      rawCategories: filters.rawCategories.toList(),
      audiences: filters.audiences.toList(),
      maxPrice: filters.maxPrice,
      page: page,
    ),
  );
}

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(apiClientProvider)),
);
