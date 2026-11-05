import 'package:flutter/material.dart';

import 'package:brandnest/core/theme/app_colors.dart';
import 'package:brandnest/core/theme/theme.dart';

class NavDestinationSpec {
  const NavDestinationSpec({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// A fixed-dark floating pill nav bar with a solid accent circle behind the
/// active icon — not a themed [NavigationBar]. Duration/curve match the
/// component-transition tokens in docs/frontend-designer/04.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<NavDestinationSpec> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpace.m,
        0,
        AppSpace.m,
        AppSpace.s,
      ),
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
        decoration: BoxDecoration(
          color: colors.navBackground,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          // A shadow alone barely reads once the page behind it is also dark
          // (dark theme) — this hairline keeps the bar's edge legible either
          // way instead of it blending into the surface below it.
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < destinations.length; i++)
              _NavItem(
                spec: destinations[i],
                selected: i == selectedIndex,
                accent: colors.saleAccent,
                onAccent: colors.onSaleAccent,
                inactive: colors.navIconInactive,
                onTap: () => onDestinationSelected(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.selected,
    required this.accent,
    required this.onAccent,
    required this.inactive,
    required this.onTap,
  });

  final NavDestinationSpec spec;
  final bool selected;
  final Color accent;
  final Color onAccent;
  final Color inactive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: spec.label,
      selected: selected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        splashColor: accent.withValues(alpha: 0.15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            selected ? spec.selectedIcon : spec.icon,
            color: selected ? onAccent : inactive,
            size: 25,
          ),
        ),
      ),
    );
  }
}
