import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pennypilot/data/finance_database.dart';
import 'package:pennypilot/models/finance_models.dart';

void main() {
  late Directory temporaryDirectory;
  late FinanceDatabase database;
  late String databasePath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    temporaryDirectory =
        await Directory.systemTemp.createTemp('pennypilot_test_');
    databasePath = path.join(temporaryDirectory.path, 'test.db');

    database = FinanceDatabase.forTesting(
      databasePath: databasePath,
    );
  });

  tearDown(() async {
    await database.close();

    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  ForecastSnapshot snapshot({
    required DateTime month,
    required DateTime date,
    required double total,
  }) {
    return ForecastSnapshot(
      forecastMonth: month,
      snapshotDate: date,
      predictedTotal: total,
    );
  }

  group('Forecast snapshot persistence', () {
    test('creates database version 3 and snapshot table', () async {
      final db = await database.database;

      final version = await db.getVersion();
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master "
        "WHERE type = 'table' AND name = 'forecast_snapshots'",
      );

      expect(version, 3);
      expect(tables, isNotEmpty);
    });

    test('saves and retrieves a forecast snapshot', () async {
      await database.saveForecastSnapshot(
        snapshot(
          month: DateTime(2026, 10, 1),
          date: DateTime(2026, 10, 15),
          total: 1250.50,
        ),
      );

      final snapshots = await database.forecastSnapshots();

      expect(snapshots, hasLength(1));
      expect(snapshots.first.forecastMonth, DateTime(2026, 10));
      expect(snapshots.first.snapshotDate, DateTime(2026, 10, 15));
      expect(snapshots.first.predictedTotal, 1250.50);
      expect(snapshots.first.id, isNotNull);
    });

    test('updates an existing snapshot for the same month and date', () async {
      await database.saveForecastSnapshot(
        snapshot(
          month: DateTime(2026, 10, 1),
          date: DateTime(2026, 10, 15, 9),
          total: 1000,
        ),
      );

      await database.saveForecastSnapshot(
        snapshot(
          month: DateTime(2026, 10, 20),
          date: DateTime(2026, 10, 15, 18),
          total: 1400,
        ),
      );

      final snapshots = await database.forecastSnapshots();

      expect(snapshots, hasLength(1));
      expect(snapshots.single.predictedTotal, 1400);
      expect(snapshots.single.forecastMonth, DateTime(2026, 10));
      expect(snapshots.single.snapshotDate, DateTime(2026, 10, 15));
    });

    test('keeps separate snapshots for different dates', () async {
      await database.saveForecastSnapshot(
        snapshot(
          month: DateTime(2026, 10),
          date: DateTime(2026, 10, 15),
          total: 1000,
        ),
      );

      await database.saveForecastSnapshot(
        snapshot(
          month: DateTime(2026, 10),
          date: DateTime(2026, 10, 16),
          total: 1100,
        ),
      );

      final snapshots = await database.forecastSnapshots();

      expect(snapshots, hasLength(2));
    });

    test('returns snapshots in chronological order', () async {
      await database.saveForecastSnapshot(
        snapshot(
          month: DateTime(2026, 11),
          date: DateTime(2026, 11, 2),
          total: 2000,
        ),
      );

      await database.saveForecastSnapshot(
        snapshot(
          month: DateTime(2026, 10),
          date: DateTime(2026, 10, 20),
          total: 1200,
        ),
      );

      await database.saveForecastSnapshot(
        snapshot(
          month: DateTime(2026, 10),
          date: DateTime(2026, 10, 5),
          total: 900,
        ),
      );

      final snapshots = await database.forecastSnapshots();

      expect(snapshots, hasLength(3));
      expect(snapshots[0].snapshotDate, DateTime(2026, 10, 5));
      expect(snapshots[1].snapshotDate, DateTime(2026, 10, 20));
      expect(snapshots[2].snapshotDate, DateTime(2026, 11, 2));
    });

    test('persists snapshots after closing and reopening database', () async {
      await database.saveForecastSnapshot(
        snapshot(
          month: DateTime(2026, 10),
          date: DateTime(2026, 10, 15),
          total: 1750,
        ),
      );

      await database.close();

      database = FinanceDatabase.forTesting(
        databasePath: databasePath,
      );

      final snapshots = await database.forecastSnapshots();

      expect(snapshots, hasLength(1));
      expect(snapshots.single.predictedTotal, 1750);
    });

    test('rejects a negative predicted total', () async {
      await expectLater(
        database.saveForecastSnapshot(
          snapshot(
            month: DateTime(2026, 10),
            date: DateTime(2026, 10, 15),
            total: -100,
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('Database clearing', () {
    test('clearAll removes snapshots and reseeds default categories', () async {
      await database.saveForecastSnapshot(
        snapshot(
          month: DateTime(2026, 10),
          date: DateTime(2026, 10, 15),
          total: 1500,
        ),
      );

      await database.clearAll();

      final snapshots = await database.forecastSnapshots();
      final categories = await database.categories();
      final transactions = await database.transactions();
      final challenges = await database.challenges();

      expect(snapshots, isEmpty);
      expect(transactions, isEmpty);
      expect(challenges, isEmpty);
      expect(
          categories,
          hasLength(
            FinanceDatabase.expenseDefaults.length +
                FinanceDatabase.incomeDefaults.length,
          ));
    });
  });

  group('Version 2 to version 3 migration', () {
    test('creates forecast table and preserves existing user data', () async {
      // Create a database with the version 2 schema.
      final legacyDatabase = await openDatabase(
        databasePath,
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              icon TEXT NOT NULL,
              budget_limit REAL NOT NULL DEFAULT 0,
              kind TEXT NOT NULL DEFAULT 'expense'
            )
          ''');

          await db.execute('''
            CREATE TABLE transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category_id INTEGER NOT NULL,
              type TEXT NOT NULL,
              amount REAL NOT NULL,
              date TEXT NOT NULL,
              description TEXT NOT NULL,
              payment_method TEXT NOT NULL,
              received_into TEXT NOT NULL DEFAULT ''
            )
          ''');

          await db.execute('''
            CREATE TABLE challenges (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              target REAL NOT NULL,
              saved REAL NOT NULL DEFAULT 0,
              status TEXT NOT NULL
            )
          ''');

          await db.insert('categories', {
            'id': 1,
            'name': 'Education',
            'icon': 'school',
            'budget_limit': 500,
            'kind': 'expense',
          });

          await db.insert('transactions', {
            'id': 1,
            'category_id': 1,
            'type': 'expense',
            'amount': 250,
            'date': '2026-10-10T12:00:00.000',
            'description': 'Books',
            'payment_method': 'Card',
            'received_into': '',
          });

          await db.insert('challenges', {
            'id': 1,
            'title': 'Emergency Fund',
            'target': 1000,
            'saved': 200,
            'status': 'active',
          });
        },
      );

      await legacyDatabase.close();

      // Opening through FinanceDatabase upgrades version 2 to version 3.
      final upgradedDb = await database.database;

      expect(await upgradedDb.getVersion(), 3);

      final tables = await upgradedDb.rawQuery(
        "SELECT name FROM sqlite_master "
        "WHERE type = 'table' AND name = 'forecast_snapshots'",
      );

      expect(tables, isNotEmpty);

      final categories = await database.categories();
      final transactions = await database.transactions();
      final challenges = await database.challenges();

      final education = categories.firstWhere(
        (category) => category.name == 'Education',
      );

      expect(education.id, 1);
      expect(education.limit, 500);
      expect(education.kind, 'expense');

      expect(transactions, hasLength(1));
      expect(transactions.single.id, 1);
      expect(transactions.single.categoryId, 1);
      expect(transactions.single.amount, 250);
      expect(transactions.single.description, 'Books');

      expect(challenges, hasLength(1));
      expect(challenges.single.title, 'Emergency Fund');
      expect(challenges.single.saved, 200);

      expect(await database.forecastSnapshots(), isEmpty);
    });
  });
}
