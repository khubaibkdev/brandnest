import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:brandnest/core/theme/app_colors.dart';
import 'package:brandnest/core/theme/theme.dart';
import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/data/brand_repository.dart';
import 'package:brandnest/data/points_repository.dart';
import 'package:brandnest/features/brand_webview/brand_webview_screen.dart';
import 'package:brandnest/features/home/brand_tile.dart';
import 'package:brandnest/features/home/hero_sale_carousel.dart';
import 'package:brandnest/features/home/home_tab_index.dart';
import 'package:brandnest/features/points/points_sheet.dart';
import 'package:brandnest/features/settings/settings_sheet.dart';

/// Tab order; a category no seeded brand carries is not shown.
/// "Sale Now" joins this list once sale events land (US-4).
const _categoryOrder = <String>[
  'women',
  'men',
  'kids',
  'unstitched',
  'shoes',
  'accessories',
];

class BrandGridScreen extends ConsumerStatefulWidget {
  const BrandGridScreen({super.key});

  @override
  ConsumerState<BrandGridScreen> createState() => _BrandGridScreenState();
}

class _BrandGridScreenState extends ConsumerState<BrandGridScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      await ref.read(brandRepositoryProvider).refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline — showing saved brands.')),
      );
    }
  }

  void _openBrand(Brand brand) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BrandWebViewScreen(brand: brand),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(brandsProvider);
    return Scaffold(
      appBar: const _HomeTopBar(),
      body: switch (brands) {
        AsyncData(:final value) when value.isEmpty => _EmptyState(
          onRetry: _refresh,
        ),
        AsyncData(:final value) => _CategorisedGrid(
          brands: value,
          onRefresh: _refresh,
          onOpenBrand: _openBrand,
        ),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _HomeTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const _HomeTopBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final points = ref.watch(pointsProvider).value;
    return AppBar(
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        tooltip: 'Settings',
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          builder: (_) => const SettingsSheet(),
        ),
      ),
      title: Text(
        'BRANDNEST',
        // Heavier than the shared titleLarge role (which "Sale calendar" and
        // "Bank discounts" also use) — the wordmark earns a bolder, more
        // confident weight than a routine screen title.
        style: GoogleFonts.playfairDisplay(
          textStyle: theme.textTheme.titleLarge,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Search',
          onPressed: () => ref.read(homeTabIndexProvider.notifier).state = 1,
        ),
        _RewardsAction(balance: points?.balance),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// Points balance shown where a generic template would put a decorative cart
/// icon — per docs/frontend-designer/05, gamification state should stay
/// visible at all times, not buried in a sheet.
class _RewardsAction extends StatelessWidget {
  const _RewardsAction({required this.balance});

  final int? balance;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.emoji_events_outlined),
          tooltip: 'Points',
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (_) => const PointsSheet(),
          ),
        ),
        if (balance != null && balance! > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 16),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  balance! > 99 ? '99+' : '${balance!}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategorisedGrid extends StatelessWidget {
  const _CategorisedGrid({
    required this.brands,
    required this.onRefresh,
    required this.onOpenBrand,
  });

  final List<Brand> brands;
  final Future<void> Function() onRefresh;
  final void Function(Brand) onOpenBrand;

  @override
  Widget build(BuildContext context) {
    final tabs = <String>['all', ..._visibleCategories(brands)];
    return DefaultTabController(
      key: ValueKey(tabs.join()),
      length: tabs.length,
      child: Column(
        children: [
          const SizedBox(height: AppSpace.s),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpace.m),
            child: HeroSaleCarousel(),
          ),
          const SizedBox(height: AppSpace.m),
          const _ValuePropStrip(),
          const SizedBox(height: AppSpace.m),
          _CategoryFilterBar(tabs: tabs),
          const SizedBox(height: AppSpace.s),
          Expanded(
            child: TabBarView(
              children: [
                for (final tab in tabs)
                  _BrandGrid(
                    brands: _forCategory(brands, tab),
                    onRefresh: onRefresh,
                    onOpenBrand: onOpenBrand,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The category switcher, restyled as a pill/chip row instead of Material's
/// underline [TabBar] — same [DefaultTabController], same swipeable
/// [TabBarView], only the indicator widget changes.
class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({required this.tabs});

  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    return SizedBox(
      height: 40,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
          itemCount: tabs.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpace.s),
          itemBuilder: (context, index) => _FilterPill(
            label: _label(tabs[index]),
            selected: controller.index == index,
            onTap: () => controller.animateTo(index),
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected ? theme.colorScheme.surface : theme.colorScheme.onSurface;
    return Material(
      color: selected ? theme.colorScheme.onSurface : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? Colors.transparent : theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.m, vertical: 8),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ValuePropStrip extends StatelessWidget {
  const _ValuePropStrip();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: double.infinity,
      color: colors.announcementBackground,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        'VERIFIED SALES · NO FAKE DISCOUNTS',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.announcementForeground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _BrandGrid extends StatelessWidget {
  const _BrandGrid({
    required this.brands,
    required this.onRefresh,
    required this.onOpenBrand,
  });

  final List<Brand> brands;
  final Future<void> Function() onRefresh;
  final void Function(Brand) onOpenBrand;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.m,
          0,
          AppSpace.m,
          AppSpace.l,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: AppSpace.s,
          crossAxisSpacing: AppSpace.s,
          childAspectRatio: 0.78,
        ),
        itemCount: brands.length,
        itemBuilder: (context, index) => BrandTile(
          brand: brands[index],
          onTap: () => onOpenBrand(brands[index]),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('No brands cached yet.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

List<Brand> _forCategory(List<Brand> brands, String category) => category == 'all'
    ? brands
    : brands.where((brand) => brand.categories.contains(category)).toList();

List<String> _visibleCategories(List<Brand> brands) {
  final present = brands.expand((brand) => brand.categories).toSet();
  return _categoryOrder.where(present.contains).toList();
}

String _label(String category) =>
    category[0].toUpperCase() + category.substring(1);
