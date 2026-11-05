import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/image_urls.dart';
import 'package:brandnest/core/theme/app_colors.dart';
import 'package:brandnest/core/theme/theme.dart';
import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/data/brand_repository.dart';
import 'package:brandnest/data/display_prefs_repository.dart';
import 'package:brandnest/data/sale_repository.dart';
import 'package:brandnest/features/calendar/sale_phase.dart';
import 'package:brandnest/features/home/home_tab_index.dart';

/// The verified/live sales worth leading with, running first, soonest-starting
/// next, capped so the carousel stays a highlight reel, not the whole calendar.
List<SaleEvent> _featuredSales(List<SaleEvent> sales, DateTime now) {
  final eligible = sales.where(isVerified).where(
    (sale) => salePhase(sale, now) != SalePhase.ended,
  ).toList();
  eligible.sort((a, b) {
    final phaseRank = _phaseRank(salePhase(a, now)).compareTo(
      _phaseRank(salePhase(b, now)),
    );
    if (phaseRank != 0) return phaseRank;
    return (a.startsAt ?? now).compareTo(b.startsAt ?? now);
  });
  return eligible.take(5).toList();
}

int _phaseRank(SalePhase phase) => switch (phase) {
  SalePhase.running => 0,
  SalePhase.upcoming => 1,
  SalePhase.ended => 2,
};

Brand? _brandFor(List<Brand> brands, String slug) {
  for (final brand in brands) {
    if (brand.slug == slug) return brand;
  }
  return null;
}

/// The hero carousel: BrandNest's answer to a generic promo banner — every
/// card is a real, desk-verified sale, never stock imagery, per
/// docs/frontend-designer/02 and 05.
class HeroSaleCarousel extends ConsumerWidget {
  const HeroSaleCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(saleEventsProvider);
    final brands = ref.watch(brandsProvider).value ?? const [];
    return switch (sales) {
      AsyncData(:final value) => _Carousel(
        sales: _featuredSales(value, DateTime.now()),
        brands: brands,
      ),
      _ => const _Carousel(sales: [], brands: []),
    };
  }
}

class _Carousel extends StatefulWidget {
  const _Carousel({required this.sales, required this.brands});

  final List<SaleEvent> sales;
  final List<Brand> brands;

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  late final PageController _controller = PageController(viewportFraction: 0.87);
  final ValueNotifier<int> _page = ValueNotifier(0);

  @override
  void dispose() {
    _controller.dispose();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sales.isEmpty) return const _NoLiveSalesCard();
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.sales.length,
            onPageChanged: (index) => _page.value = index,
            itemBuilder: (context, index) {
              final sale = widget.sales[index];
              final brand = _brandFor(widget.brands, sale.brandSlug);
              return AnimatedBuilder(
                animation: _controller,
                child: _HeroSaleCard(sale: sale, brand: brand),
                // The next card recedes — smaller and dimmer — echoing a
                // fanned card stack rather than a flat swipeable strip.
                builder: (context, child) {
                  final page = _controller.hasClients
                      ? (_controller.page ?? _controller.initialPage.toDouble())
                      : index.toDouble();
                  final distance = (page - index).abs().clamp(0.0, 1.0);
                  final scale = 1 - (distance * 0.08);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: 1 - (distance * 0.35),
                        child: child,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (widget.sales.length > 1) ...[
          const SizedBox(height: AppSpace.s),
          ValueListenableBuilder<int>(
            valueListenable: _page,
            builder: (context, page, _) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.sales.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == page ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == page
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroSaleCard extends ConsumerWidget {
  const _HeroSaleCard({required this.sale, required this.brand});

  final SaleEvent sale;
  final Brand? brand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final running = salePhase(sale, DateTime.now()) == SalePhase.running;
    final subtitle = sale.discountText ?? saleCountdown(sale, DateTime.now());

    return GestureDetector(
      onTap: () => ref.read(homeTabIndexProvider.notifier).state = 2,
      child: Container(
        decoration: BoxDecoration(
          color: Color.lerp(theme.colorScheme.surfaceContainerLow, theme.colorScheme.primary, 0.05),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      running ? 'VERIFIED SALE' : 'STARTING SOON',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sale.brandName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  Text(
                    sale.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.saleAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _HeroBrandMark(brand: brand),
          ],
        ),
      ),
    );
  }
}

class _HeroBrandMark extends ConsumerWidget {
  const _HeroBrandMark({required this.brand});

  final Brand? brand;

  static const _saverWidth = 320;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final logoUrl = brand?.logoUrl;
    final url = logoUrl == null
        ? null
        : (ref.watch(saveImageDataProvider)
            ? sizedImageUrl(logoUrl, width: _saverWidth)
            : logoUrl);

    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        color: colors.saleAccent.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: url == null
          ? Icon(Icons.storefront_rounded, color: colors.saleAccent, size: 40)
          : ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.storefront_rounded, color: colors.saleAccent, size: 40),
              ),
            ),
    );
  }
}

class _NoLiveSalesCard extends StatelessWidget {
  const _NoLiveSalesCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(
      builder: (context, ref, _) => GestureDetector(
        onTap: () => ref.read(homeTabIndexProvider.notifier).state = 2,
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.event_available_outlined, color: theme.colorScheme.outline),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('No live sales right now', style: theme.textTheme.titleSmall),
                    Text(
                      'Check the calendar for what\'s coming up',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
