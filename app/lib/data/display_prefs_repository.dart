import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/data/app_database.dart';

/// Data Saver (US-17), device-local like the notification opt-out — there is no
/// account-level reason for it to sync, and it describes this phone's
/// connection, not this shopper.
class DisplayPrefsRepository {
  DisplayPrefsRepository(this._database);

  final AppDatabase _database;

  Stream<DisplayPref> watch() => _database.watchDisplayPrefs();

  Future<void> setDataSaver(bool enabled) => _database.setDataSaver(enabled);

  Future<void> setDarkMode(bool enabled) => _database.setDarkMode(enabled);
}

final displayPrefsRepositoryProvider = Provider<DisplayPrefsRepository>(
  (ref) => DisplayPrefsRepository(ref.watch(appDatabaseProvider)),
);

final displayPrefsProvider = StreamProvider<DisplayPref>(
  (ref) => ref.watch(displayPrefsRepositoryProvider).watch(),
);

/// Whether this device is currently on mobile data.
///
/// Only mobile counts as metered: Wi-Fi, ethernet and VPN are treated as free,
/// and so is `none` — offline, every image fails the same way regardless, and
/// guessing "metered" would leave the wrong size cached for when it returns.
final onMobileDataProvider = StreamProvider<bool>(
  (ref) => Connectivity().onConnectivityChanged.map(
    (results) => results.contains(ConnectivityResult.mobile),
  ),
);

/// Should images be requested small right now?
///
/// Data Saver says "on cellular", so on Wi-Fi it changes nothing — there is no
/// data to save there. Until connectivity reports in, images load full size:
/// briefly serving a good image is a better failure than briefly serving a
/// blurry one that then has to be replaced.
final saveImageDataProvider = Provider<bool>((ref) {
  final enabled = ref.watch(displayPrefsProvider).value?.dataSaver ?? false;
  final onMobile = ref.watch(onMobileDataProvider).value ?? false;
  return enabled && onMobile;
});

/// Dark theme, on by default — the product's own call, not the device's.
/// `main.dart` maps this to a [ThemeMode]; kept a plain bool here so this
/// data-layer file has no Flutter UI-layer dependency.
final darkModeEnabledProvider = Provider<bool>(
  (ref) => ref.watch(displayPrefsProvider).value?.darkMode ?? true,
);
