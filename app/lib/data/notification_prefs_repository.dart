import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/data/app_database.dart';

/// The per-category push opt-out (US-6), device-local like [MyCards] — there is
/// no account-level reason for it to sync, and a reinstall resetting it to "on"
/// is a reasonable default, not a loss.
class NotificationPrefsRepository {
  NotificationPrefsRepository(this._database);

  final AppDatabase _database;

  Stream<NotificationPref> watch() => _database.watchNotificationPrefs();

  Future<void> setSalesEnabled(bool enabled) =>
      _database.setSalesEnabled(enabled);

  Future<void> setOffersEnabled(bool enabled) =>
      _database.setOffersEnabled(enabled);
}

final notificationPrefsRepositoryProvider = Provider<NotificationPrefsRepository>(
  (ref) => NotificationPrefsRepository(ref.watch(appDatabaseProvider)),
);

final notificationPrefsProvider = StreamProvider<NotificationPref>(
  (ref) => ref.watch(notificationPrefsRepositoryProvider).watch(),
);
