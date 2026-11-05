import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/data/brand_repository.dart';
import 'package:brandnest/data/search_repository.dart';
import 'package:brandnest/features/offers/offer_presentation.dart';

/// US-11's filters. Every value shown is a facet of the *current* results with
/// its own count, so nothing on offer here leads to an empty list.
///
/// Category is two levels on purpose. The brands between them use 423
/// different category names — unusable as a flat list — so the top level is our
/// canonical one, and picking it reveals the brands' own names underneath, which
/// is the detail someone drilling in is actually after.
Future<SearchFilters?> showFilterSheet(
  BuildContext context, {
  required SearchResults results,
  required SearchFilters filters,
}) => showModalBottomSheet<SearchFilters>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _FilterSheet(results: results, filters: filters),
);

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.results, required this.filters});

  final SearchResults results;
  final SearchFilters filters;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late SearchFilters _filters = widget.filters;
  late final TextEditingController _maxPrice = TextEditingController(
    text: widget.filters.maxPrice?.round().toString() ?? '',
  );

  @override
  void dispose() {
    _maxPrice.dispose();
    super.dispose();
  }

  void _toggle(SearchFacet facet, String value) =>
      setState(() => _filters = _filters.toggled(facet, value));

  void _apply() {
    final typed = double.tryParse(_maxPrice.text.trim());
    Navigator.of(context).pop(
      _maxPrice.text.trim().isEmpty
          ? _filters.copyWith(clearMaxPrice: true)
          : _filters.copyWith(maxPrice: typed),
    );
  }

  /// Facets come back keyed by brand slug, because that is what the index
  /// filters on. Nobody shops for "junaid-jamshed".
  String _brandLabel(String slug) =>
      (ref.read(brandsProvider).value ?? const [])
          .where((brand) => brand.slug == slug)
          .firstOrNull
          ?.name ??
      slug;

  @override
  Widget build(BuildContext context) {
    final results = widget.results;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FacetGroup(
                      title: 'Category',
                      facet: SearchFacet.category,
                      values: results.categories,
                      selected: _filters.categories,
                      onToggle: _toggle,
                    ),
                    // Only once a category is chosen: the brands' own names are
                    // the drill-down under it, not a second flat list of 423.
                    if (_filters.categories.isNotEmpty)
                      _FacetGroup(
                        title: 'Within that, by the brand’s own name',
                        facet: SearchFacet.rawCategory,
                        values: results.rawCategories,
                        selected: _filters.rawCategories,
                        onToggle: _toggle,
                      ),
                    _FacetGroup(
                      title: 'Brand',
                      facet: SearchFacet.brand,
                      values: results.brands,
                      selected: _filters.brandSlugs,
                      onToggle: _toggle,
                      labelFor: _brandLabel,
                    ),
                    _FacetGroup(
                      title: 'For',
                      facet: SearchFacet.audience,
                      values: results.audiences,
                      selected: _filters.audiences,
                      onToggle: _toggle,
                    ),
                    const SizedBox(height: 8),
                    Text('Maximum price', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _maxPrice,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: 'PKR ',
                        hintText: 'Any',
                        border: const OutlineInputBorder(),
                        helperText: results.maxPrice == null
                            ? null
                            // Says where a ceiling the shopper never typed into
                            // this box came from.
                            : 'Your search already said under '
                                  '${formatRupees(results.maxPrice!)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => _filters = const SearchFilters());
                    _maxPrice.clear();
                  },
                  child: const Text('Clear all'),
                ),
                const Spacer(),
                FilledButton(onPressed: _apply, child: const Text('Show results')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FacetGroup extends StatelessWidget {
  const _FacetGroup({
    required this.title,
    required this.facet,
    required this.values,
    required this.selected,
    required this.onToggle,
    this.labelFor,
  });

  final String title;
  final SearchFacet facet;
  final List<FacetValue> values;
  final Set<String> selected;
  final void Function(SearchFacet, String) onToggle;

  /// Turns a facet value into what it should read as, where the two differ.
  final String Function(String)? labelFor;

  /// Enough to choose from without turning the sheet into a directory; the
  /// values arrive biggest-first, so what is cut is the tail nobody picks.
  static const _maxShown = 12;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final shown = values.take(_maxShown);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final value in shown)
              FilterChip(
                label: Text(
                  '${labelFor?.call(value.value) ?? value.value} '
                  '(${value.count})',
                ),
                selected: selected.contains(value.value),
                onSelected: (_) => onToggle(facet, value.value),
              ),
          ],
        ),
      ],
    );
  }
}
