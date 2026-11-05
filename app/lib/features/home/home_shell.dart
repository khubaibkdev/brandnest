import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/notifications_service.dart';
import 'package:brandnest/data/brand_repository.dart';
import 'package:brandnest/data/notification_prefs_repository.dart';
import 'package:brandnest/data/offer_directory_repository.dart';
import 'package:brandnest/data/squad_repository.dart';
import 'package:brandnest/features/calendar/calendar_screen.dart';
import 'package:brandnest/features/home/brand_grid_screen.dart';
import 'package:brandnest/features/home/floating_nav_bar.dart';
import 'package:brandnest/features/home/home_tab_index.dart';
import 'package:brandnest/features/offers/directory_screen.dart';
import 'package:brandnest/features/search/search_screen.dart';
import 'package:brandnest/features/squad/squads_screen.dart';

const _destinations = [
  NavDestinationSpec(
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view_rounded,
    label: 'Brands',
  ),
  NavDestinationSpec(
    icon: Icons.search_outlined,
    selectedIcon: Icons.search_rounded,
    label: 'Search',
  ),
  NavDestinationSpec(
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
    label: 'Sales',
  ),
  NavDestinationSpec(
    icon: Icons.credit_card_outlined,
    selectedIcon: Icons.credit_card_rounded,
    label: 'Discounts',
  ),
  NavDestinationSpec(
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups_rounded,
    label: 'Squads',
  ),
];

const _squadsTab = 4;

/// The app's five destinations. An `IndexedStack` keeps each one's scroll
/// position and cached data alive while the others are on screen.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    // Also delivers the link that cold-started the app.
    _links = AppLinks().uriLinkStream.listen(_openLink);
    FirebaseMessaging.onMessage.listen(_showForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _openFromMessage(message);
    });
    ref.read(notificationsServiceProvider).listenForTokenRefresh();

    // Re-synced whenever what a device should be subscribed to could have
    // changed: the active brand list, the shopper's saved banks, or the
    // opt-out toggles.
    ref.listenManual(brandsProvider, (_, _) => _syncTopics());
    ref.listenManual(myCardsProvider, (_, _) => _syncTopics());
    ref.listenManual(notificationPrefsProvider, (_, _) => _syncTopics());
    _syncTopics();
  }

  @override
  void dispose() {
    _links?.cancel();
    super.dispose();
  }

  /// A squad invite (US-21) opens the Squads tab, which shows the join sheet.
  void _openLink(Uri uri) {
    final inviteCode = inviteCodeFromLink(uri);
    if (inviteCode == null) return;
    ref.read(homeTabIndexProvider.notifier).state = _squadsTab;
    ref.read(pendingInviteProvider.notifier).arrive(inviteCode);
  }

  void _syncTopics() {
    final notifications = ref.read(notificationsServiceProvider);
    final prefs = ref.read(notificationPrefsProvider).value;
    final brandSlugs = (ref.read(brandsProvider).value ?? const [])
        .map((brand) => brand.slug);
    final bankSlugs = (ref.read(myCardsProvider).value ?? const [])
        .map((card) => card.bankSlug)
        .toSet();
    notifications.syncSaleTopics(brandSlugs, prefs?.salesEnabled ?? true);
    notifications.syncOfferTopics(bankSlugs, prefs?.offersEnabled ?? true);
  }

  void _openFromMessage(RemoteMessage message) {
    final index = homeTabIndexForNotification(message.data);
    if (index != null) ref.read(homeTabIndexProvider.notifier).state = index;
  }

  void _showForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null || !mounted) return;
    final index = homeTabIndexForNotification(message.data);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${notification.title}: ${notification.body}'),
        action: index == null
            ? null
            : SnackBarAction(
                label: 'View',
                onPressed: () =>
                    ref.read(homeTabIndexProvider.notifier).state = index,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(homeTabIndexProvider);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          BrandGridScreen(),
          SearchScreen(),
          CalendarScreen(),
          DirectoryScreen(),
          SquadsScreen(),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        destinations: _destinations,
        selectedIndex: index,
        onDestinationSelected: (value) =>
            ref.read(homeTabIndexProvider.notifier).state = value,
      ),
    );
  }
}
