import 'package:flutter/material.dart';

/// Brand-specific roles Material's [ColorScheme] has no slot for. Read via
/// `Theme.of(context).extension<AppColors>()!` rather than a raw hex literal.
///
/// One instance, [brand], used in both the light and dark [ThemeData] — every
/// role here is a deliberate fixed brand accent (a gold badge, a black
/// announcement strip, a dark floating nav bar), not something that should
/// invert with the surrounding theme's brightness.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.saleAccent,
    required this.onSaleAccent,
    required this.announcementBackground,
    required this.announcementForeground,
    required this.navBackground,
    required this.navIconInactive,
  });

  /// Warm gold used for sale/deal moments — the "urgency" hue, deliberately
  /// distinct from the maroon brand primary so a badge or price never fights
  /// with brand chrome for attention.
  final Color saleAccent;
  final Color onSaleAccent;

  final Color announcementBackground;
  final Color announcementForeground;

  /// The floating bottom nav is a fixed dark surface regardless of theme —
  /// it does not derive from `colorScheme.surface`.
  final Color navBackground;
  final Color navIconInactive;

  static const brand = AppColors(
    saleAccent: Color(0xFFC9922B),
    onSaleAccent: Color(0xFF2B1E06),
    announcementBackground: Color(0xFF141414),
    announcementForeground: Colors.white,
    navBackground: Color(0xFF15100F),
    navIconInactive: Color(0xFF938B87),
  );

  @override
  AppColors copyWith({
    Color? saleAccent,
    Color? onSaleAccent,
    Color? announcementBackground,
    Color? announcementForeground,
    Color? navBackground,
    Color? navIconInactive,
  }) => AppColors(
    saleAccent: saleAccent ?? this.saleAccent,
    onSaleAccent: onSaleAccent ?? this.onSaleAccent,
    announcementBackground: announcementBackground ?? this.announcementBackground,
    announcementForeground: announcementForeground ?? this.announcementForeground,
    navBackground: navBackground ?? this.navBackground,
    navIconInactive: navIconInactive ?? this.navIconInactive,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      saleAccent: Color.lerp(saleAccent, other.saleAccent, t)!,
      onSaleAccent: Color.lerp(onSaleAccent, other.onSaleAccent, t)!,
      announcementBackground:
          Color.lerp(announcementBackground, other.announcementBackground, t)!,
      announcementForeground:
          Color.lerp(announcementForeground, other.announcementForeground, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      navIconInactive: Color.lerp(navIconInactive, other.navIconInactive, t)!,
    );
  }
}
