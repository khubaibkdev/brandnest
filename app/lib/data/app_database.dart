import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

class Brands extends Table {
  IntColumn get id => integer()();
  TextColumn get slug => text()();
  TextColumn get name => text()();
  TextColumn get logoUrl => text().nullable()();
  TextColumn get categories => text().map(const StringListConverter())();
  TextColumn get websiteUrl => text()();
  TextColumn get platform => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The sale calendar, cached so it reads on a train with no signal.
///
/// Dates are nullable: a brand often announces "sale is live" without saying
/// when it ends, and inventing an end date would be a lie with a countdown on it.
class SaleEvents extends Table {
  IntColumn get id => integer()();
  TextColumn get brandSlug => text()();
  TextColumn get brandName => text()();
  TextColumn get title => text()();
  TextColumn get discountText => text().nullable()();
  DateTimeColumn get startsAt => dateTime().nullable()();
  DateTimeColumn get endsAt => dateTime().nullable()();
  TextColumn get status => text()();
  TextColumn get proofUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The cross-brand bank-discount directory, cached so it reads with no signal
/// like the brand grid and the calendar do.
///
/// `brandSlug` and `brandName` are null for a multi-brand offer — one the bank
/// runs across every brand rather than at one of them.
class DirectoryOffers extends Table {
  IntColumn get id => integer()();
  TextColumn get bankSlug => text()();
  TextColumn get bankName => text()();
  TextColumn get brandSlug => text().nullable()();
  TextColumn get brandName => text().nullable()();
  TextColumn get cardTypes => text().map(const StringListConverter())();
  RealColumn get discountPct => real().nullable()();
  RealColumn get maxDiscountAmount => real().nullable()();
  RealColumn get minSpend => real().nullable()();
  TextColumn get channel => text()();
  DateTimeColumn get validFrom => dateTime().nullable()();
  DateTimeColumn get validTo => dateTime().nullable()();
  TextColumn get proofUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The banks and card types the shopper says they carry.
///
/// Device-local: `user.my_banks` is where this belongs once US-9 gives us an
/// account to hang it on, and building half of Firebase auth now would mean
/// building it twice. A reinstall costs the shopper a few taps.
class MyCards extends Table {
  TextColumn get bankSlug => text()();
  TextColumn get cardType => text()();

  @override
  Set<Column> get primaryKey => {bankSlug, cardType};
}

/// One row, id 0. Set when [MyCards] changes locally and cleared once that
/// change has been pushed to `/me/banks` (US-9).
///
/// Without this, a card ticked while offline could be silently overwritten by
/// an older server set the next time the app reconciles on launch — the
/// account is meant to win only when the device has nothing unpushed of its own.
class SyncState extends Table {
  IntColumn get id => integer()();
  BoolColumn get myCardsDirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row, id 0. The per-category push opt-out (US-6): both default on, since
/// there is nothing to opt into — sale and offer topics start subscribed the
/// moment the app has something to subscribe to.
class NotificationPrefs extends Table {
  IntColumn get id => integer()();
  BoolColumn get salesEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get offersEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row, id 0. Data Saver (US-17) off by default: quietly serving someone
/// smaller images than they asked for is a choice they should make, not one
/// made for them on first launch. Dark theme defaults **on** — the opposite
/// call, made deliberately for this product rather than left as whatever the
/// framework or device happens to default to.
class DisplayPrefs extends Table {
  IntColumn get id => integer()();
  BoolColumn get dataSaver => boolean().withDefault(const Constant(false))();
  BoolColumn get darkMode => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Brands,
  SaleEvents,
  DirectoryOffers,
  MyCards,
  SyncState,
  NotificationPrefs,
  DisplayPrefs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'brandnest'));

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      // v2 (US-4) added the sale calendar; the brand grid stays as it was.
      if (from < 2) await migrator.createTable(saleEvents);
      // v3 (US-5) added the bank-discount directory and the shopper's own cards.
      if (from < 3) {
        await migrator.createTable(directoryOffers);
        await migrator.createTable(myCards);
      }
      // v4 (US-9) added the dirty flag that guards syncing my_cards with /me/banks.
      if (from < 4) await migrator.createTable(syncState);
      // v5 (US-6) added the sale/offer push opt-out.
      if (from < 5) await migrator.createTable(notificationPrefs);
      // v6 (US-17) added Data Saver.
      if (from < 6) await migrator.createTable(displayPrefs);
      // v7 added the dark theme toggle.
      if (from < 7) await migrator.addColumn(displayPrefs, displayPrefs.darkMode);
    },
  );

  Stream<DisplayPref> watchDisplayPrefs() =>
      (select(displayPrefs)..where((prefs) => prefs.id.equals(0)))
          .watchSingleOrNull()
          .map(
            (row) => row ?? const DisplayPref(id: 0, dataSaver: false, darkMode: true),
          );

  Future<void> setDataSaver(bool enabled) => into(displayPrefs).insertOnConflictUpdate(
    DisplayPrefsCompanion.insert(id: const Value(0), dataSaver: Value(enabled)),
  );

  Future<void> setDarkMode(bool enabled) => into(displayPrefs).insertOnConflictUpdate(
    DisplayPrefsCompanion.insert(id: const Value(0), darkMode: Value(enabled)),
  );

  Stream<List<Brand>> watchBrands() =>
      (select(brands)..orderBy([(brand) => OrderingTerm(expression: brand.name)]))
          .watch();

  Future<void> replaceBrands(List<BrandsCompanion> rows) =>
      transaction(() async {
        await delete(brands).go();
        await batch((batch) => batch.insertAll(brands, rows));
      });

  /// Undated sales first — those are the ones running right now.
  Stream<List<SaleEvent>> watchSaleEvents() => (select(saleEvents)
        ..orderBy([
          (sale) => OrderingTerm(expression: sale.startsAt, nulls: NullsOrder.first),
          (sale) => OrderingTerm(expression: sale.id),
        ]))
      .watch();

  Future<void> replaceSaleEvents(List<SaleEventsCompanion> rows) =>
      transaction(() async {
        await delete(saleEvents).go();
        await batch((batch) => batch.insertAll(saleEvents, rows));
      });

  /// Grouped by bank, best saving first within each — the order the directory
  /// renders in, and the order the API already sorted them into.
  Stream<List<DirectoryOffer>> watchDirectoryOffers() => (select(directoryOffers)
        ..orderBy([
          (offer) => OrderingTerm(expression: offer.bankName),
          (offer) => OrderingTerm(
            expression: offer.discountPct,
            mode: OrderingMode.desc,
            nulls: NullsOrder.last,
          ),
          (offer) => OrderingTerm(expression: offer.id),
        ]))
      .watch();

  Future<void> replaceDirectoryOffers(List<DirectoryOffersCompanion> rows) =>
      transaction(() async {
        await delete(directoryOffers).go();
        await batch((batch) => batch.insertAll(directoryOffers, rows));
      });

  Stream<List<MyCard>> watchMyCards() => (select(myCards)
        ..orderBy([
          (card) => OrderingTerm(expression: card.bankSlug),
          (card) => OrderingTerm(expression: card.cardType),
        ]))
      .watch();

  Future<List<MyCard>> readMyCards() => select(myCards).get();

  Future<void> setCardHeld(String bankSlug, String cardType, bool held) async {
    await transaction(() async {
      if (held) {
        await into(myCards).insert(
          MyCardsCompanion.insert(bankSlug: bankSlug, cardType: cardType),
          mode: InsertMode.insertOrIgnore,
        );
      } else {
        await (delete(myCards)..where(
          (card) =>
              card.bankSlug.equals(bankSlug) & card.cardType.equals(cardType),
        )).go();
      }
      await markMyCardsDirty();
    });
  }

  /// Overwrites the local set with the server's — used when reconciling and
  /// the account has a saved set of its own and nothing local is unpushed.
  Future<void> replaceMyCards(List<MyCardsCompanion> rows) =>
      transaction(() async {
        await delete(myCards).go();
        await batch((batch) => batch.insertAll(myCards, rows));
      });

  Future<bool> isMyCardsDirty() async {
    final row = await (select(
      syncState,
    )..where((state) => state.id.equals(0))).getSingleOrNull();
    return row?.myCardsDirty ?? false;
  }

  Future<void> markMyCardsDirty() => into(syncState).insertOnConflictUpdate(
    SyncStateCompanion.insert(id: const Value(0), myCardsDirty: const Value(true)),
  );

  Future<void> clearMyCardsDirty() => into(syncState).insertOnConflictUpdate(
    SyncStateCompanion.insert(id: const Value(0), myCardsDirty: const Value(false)),
  );

  Stream<NotificationPref> watchNotificationPrefs() =>
      (select(notificationPrefs)..where((prefs) => prefs.id.equals(0)))
          .watchSingleOrNull()
          .map((row) => row ?? const NotificationPref(id: 0, salesEnabled: true, offersEnabled: true));

  Future<void> setSalesEnabled(bool enabled) => _upsertNotificationPref(
    (prefs) => prefs.copyWith(salesEnabled: enabled),
  );

  Future<void> setOffersEnabled(bool enabled) => _upsertNotificationPref(
    (prefs) => prefs.copyWith(offersEnabled: enabled),
  );

  Future<void> _upsertNotificationPref(
    NotificationPref Function(NotificationPref) apply,
  ) async {
    final current =
        await (select(
          notificationPrefs,
        )..where((prefs) => prefs.id.equals(0))).getSingleOrNull() ??
        const NotificationPref(id: 0, salesEnabled: true, offersEnabled: true);
    await into(
      notificationPrefs,
    ).insertOnConflictUpdate(apply(current).toCompanion(false));
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
