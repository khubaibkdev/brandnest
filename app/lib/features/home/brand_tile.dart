import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/image_urls.dart';
import 'package:brandnest/core/theme/app_colors.dart';
import 'package:brandnest/core/theme/theme.dart';
import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/data/display_prefs_repository.dart';

/// Brands have no logos in the catalog yet, so tiles fall back to a monogram.
const _monogramColors = <Color>[
  Color(0xFF7B1E3A),
  Color(0xFF1F4E5F),
  Color(0xFF4A5043),
  Color(0xFF8C5A2B),
  Color(0xFF3B3355),
  Color(0xFF5B7065),
];

class BrandTile extends StatelessWidget {
  const BrandTile({super.key, required this.brand, required this.onTap});

  final Brand brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          // A fixed dark frame around every logo — the same dark brand tone as
          // the bottom nav — rather than a full-bleed white plate: it reads as
          // a deliberate, moody catalog treatment instead of a generic bright
          // grid, and the inset white chip still guarantees every logo (dark
          // wordmark or light) stays legible regardless of its own source
          // colours.
          child: Material(
            color: colors.navBackground,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              onTap: onTap,
              splashColor: colors.saleAccent.withValues(alpha: 0.18),
              highlightColor: Colors.white.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: _BrandMark(brand: brand),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          brand.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends ConsumerWidget {
  const _BrandMark({required this.brand});

  final Brand brand;

  /// A tile is about a quarter of a phone's width; 512 is what the curated
  /// logos ship at, and 180 still covers that at full pixel density.
  static const _saverWidth = 180;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoUrl = brand.logoUrl;
    if (logoUrl == null) return _Monogram(brand: brand);
    final url = ref.watch(saveImageDataProvider)
        ? sizedImageUrl(logoUrl, width: _saverWidth)!
        : logoUrl;
    return Image.network(
      url,
      fit: BoxFit.contain,
      // Logos are a mix of transparent PNG and white-background JPEG; a white
      // chip plus padding makes both sit consistently, whatever the tile
      // frame around it looks like.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) => ColoredBox(
        color: Colors.white,
        child: Padding(padding: const EdgeInsets.all(8), child: child),
      ),
      // Logos are hotlinked, so offline they fail and the monogram takes over.
      errorBuilder: (context, error, stackTrace) => _Monogram(brand: brand),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.brand});

  final Brand brand;

  @override
  Widget build(BuildContext context) {
    final color =
        _monogramColors[_stableHash(brand.slug) % _monogramColors.length];
    return ColoredBox(
      color: color,
      child: Center(
        child: Text(
          _initials(brand.name),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final words = name
      .split(RegExp(r'[^A-Za-z]+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  return words.take(2).map((word) => word[0].toUpperCase()).join();
}

/// String.hashCode is not stable across runs; tile colours must not flicker.
int _stableHash(String value) =>
    value.codeUnits.fold(0, (hash, unit) => (hash * 31 + unit) & 0x7fffffff);
