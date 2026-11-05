import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/image_urls.dart';
import 'package:brandnest/data/brand_repository.dart';
import 'package:brandnest/data/display_prefs_repository.dart';
import 'package:brandnest/data/search_repository.dart';
import 'package:brandnest/features/brand_webview/brand_webview_screen.dart';
import 'package:brandnest/features/offers/offer_presentation.dart';
import 'package:brandnest/features/search/filter_sheet.dart';

/// US-11: one box across every brand we crawl.
///
/// The price phrase is parsed server-side, so "kurta under 3000" narrows by
/// price without the shopper opening the filter sheet at all — the sheet then
/// shows the ceiling that was understood, rather than the query silently
/// meaning something the UI never admits to.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  SearchFilters _filters = const SearchFilters();
  SearchResults? _results;
  bool _loading = false;
  bool _failed = false;

  /// Every request carries the generation it was issued in, so a slow reply to
  /// an earlier keystroke cannot overwrite the results of a later one.
  int _generation = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    // Long enough that a typed word is one request rather than six.
    _debounce = Timer(const Duration(milliseconds: 300), _runSearch);
  }

  Future<void> _runSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty && _filters.isEmpty) {
      setState(() {
        _results = null;
        _failed = false;
      });
      return;
    }
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final results = await ref
          .read(searchRepositoryProvider)
          .search(query, _filters);
      if (mounted && generation == _generation) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _openFilters() async {
    final results = _results;
    if (results == null) return;
    final updated = await showFilterSheet(
      context,
      results: results,
      filters: _filters,
    );
    if (updated != null) {
      setState(() => _filters = updated);
      _runSearch();
    }
  }

  void _openHit(SearchHit hit) {
    final brand = (ref.read(brandsProvider).value ?? const [])
        .where((candidate) => candidate.slug == hit.brandSlug)
        .firstOrNull;
    if (brand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${hit.brandName} is not available right now')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // Straight to the product, not the brand's home page — the shopper
        // already chose the item here.
        builder: (_) => BrandWebViewScreen(brand: brand, initialUrl: hit.url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          onChanged: _onQueryChanged,
          onSubmitted: (_) => _runSearch(),
          textInputAction: TextInputAction.search,
          autocorrect: false,
          decoration: const InputDecoration(
            hintText: 'Search every brand — try "kurta under 3000"',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (results != null)
            IconButton(
              onPressed: _openFilters,
              icon: Badge(
                isLabelVisible: _filters.count > 0,
                label: Text('${_filters.count}'),
                child: const Icon(Icons.tune),
              ),
              tooltip: 'Filters',
            ),
        ],
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: _body(results),
    );
  }

  Widget _body(SearchResults? results) {
    if (_failed) {
      return const _Message('Search is unavailable right now.');
    }
    if (results == null) {
      return const _Message(
        'Search kurtas, lawn, shoes and more across every brand at once.',
      );
    }
    if (results.hits.isEmpty) {
      return const _Message('Nothing matched. Try fewer words or filters.');
    }
    return Column(
      children: [
        _ResultSummary(results: results, filters: _filters),
        Expanded(
          child: ListView.separated(
            itemCount: results.hits.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) => _HitTile(
              hit: results.hits[index],
              onTap: () => _openHit(results.hits[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.results, required this.filters});

  final SearchResults results;
  final SearchFilters filters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The ceiling the server lifted out of the query, if the shopper did not
    // set one themselves — worth saying out loud, since they never saw a slider.
    final ceiling = results.maxPrice;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${results.total} ${results.total == 1 ? 'result' : 'results'}'
              '${ceiling == null ? '' : ' under ${formatRupees(ceiling)}'}',
              style: theme.textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit, required this.onTap});

  final SearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: _Thumbnail(url: hit.image),
      title: Text(hit.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        // Brand first, then the brand's own shelf name — the detail our tidy
        // category label deliberately does not replace.
        [hit.brandName, hit.rawCategory ?? hit.category].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        formatRupees(hit.price),
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Thumbnail extends ConsumerWidget {
  const _Thumbnail({required this.url});

  final String? url;

  /// The tile is 48dp wide; 160 covers it on the densest phone screen, against
  /// product images that are routinely 1200px and hundreds of kilobytes.
  static const _saverWidth = 160;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final placeholder = Container(
      width: 48,
      height: 64,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.checkroom,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    if (url == null) return placeholder;
    final source = ref.watch(saveImageDataProvider)
        ? sizedImageUrl(url, width: _saverWidth)!
        : url!;
    return SizedBox(
      width: 48,
      height: 64,
      // Hotlinked like the brand logos are, and failing the same way: the row
      // still reads without it.
      child: Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
