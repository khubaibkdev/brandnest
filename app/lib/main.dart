import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/auth_service.dart';
import 'package:brandnest/core/notifications_service.dart';
import 'package:brandnest/core/rewarded_ad_service.dart';
import 'package:brandnest/core/theme/theme.dart';
import 'package:brandnest/data/display_prefs_repository.dart';
import 'package:brandnest/data/offer_directory_repository.dart';
import 'package:brandnest/features/home/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final container = ProviderContainer();
  await container.read(authServiceProvider).ensureSignedIn();
  await container.read(offerDirectoryRepositoryProvider).reconcileMyCards();
  await container.read(notificationsServiceProvider).requestPermission();
  await container.read(notificationsServiceProvider).registerDeviceToken();
  await container.read(rewardedAdServiceProvider).initialize();

  runApp(
    UncontrolledProviderScope(container: container, child: const BrandNestApp()),
  );
}

class BrandNestApp extends ConsumerWidget {
  const BrandNestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeEnabledProvider);
    return MaterialApp(
      title: 'BrandNest',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeShell(),
    );
  }
}
