import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/data/display_prefs_repository.dart';
import 'package:brandnest/data/notification_prefs_repository.dart';

/// Everything the shopper can turn on or off.
///
/// It was the notification sheet until US-17 gave it a second thing to hold;
/// renamed rather than having Data Saver hide under a heading that does not
/// describe it.
class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(notificationPrefsProvider).value;
    final repository = ref.read(notificationPrefsRepositoryProvider);
    final display = ref.watch(displayPrefsProvider).value;
    final displayRepository = ref.read(displayPrefsRepositoryProvider);
    final onMobile = ref.watch(onMobileDataProvider).value ?? false;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text('Appearance', style: theme.textTheme.titleSmall),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark theme'),
              value: display?.darkMode ?? true,
              onChanged: displayRepository.setDarkMode,
            ),
            const SizedBox(height: 12),
            Text('Notifications', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sale alerts'),
              subtitle: const Text('When a brand\'s sale goes live'),
              value: prefs?.salesEnabled ?? true,
              onChanged: repository.setSalesEnabled,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Offer alerts'),
              subtitle: const Text('When a bank offer on one of your cards goes live'),
              value: prefs?.offersEnabled ?? true,
              onChanged: repository.setOffersEnabled,
            ),
            const SizedBox(height: 12),
            Text('Data', style: theme.textTheme.titleSmall),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data Saver'),
              // Says exactly what it does and when, because a setting that
              // silently changes nothing on Wi-Fi otherwise reads as broken.
              subtitle: Text(
                onMobile
                    ? 'Loading smaller images while you are on mobile data'
                    : 'Loads smaller images when you are on mobile data',
              ),
              value: display?.dataSaver ?? false,
              onChanged: displayRepository.setDataSaver,
            ),
          ],
        ),
      ),
    );
  }
}
