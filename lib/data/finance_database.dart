import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/finance_models.dart';

class FinanceDatabase {
  FinanceDatabase._({String? databasePath}) : _databasePath = databasePath;

  static final FinanceDatabase instance = FinanceDatabase._();

  /// Creates an isolated database instance for tests.
  factory FinanceDatabase.forTesting({
    required String databasePath,
  }) {
    return FinanceDatabase._(databasePath: databasePath);
  }

  final String? _databasePath;
  Database? _db;

  static const expenseDefaults = [
    'Food',
    'Groceries',
    'Shopping',
    'Transport',
    'Rent',
    'Utilities',
    'Entertainment',
    'Healthcare',
    'Education',
    'Other',
  ];

  static const incomeDefaults = [
    'Salary',
    'Part-Time Job',
    'Freelance',
    'Business Income',
    'Bonus',
    'Tips',
    'Gift',
    'Refund',
    'Interest',
    'Investment Income',
    'Scholarship/Grant',
    'Other Income',
  ];

  Future<void> _seed(DatabaseExecutor db) async {
    for (final name in expenseDefaults) {
      await db.insert(
        'categories',
        {
          'name': name,
          'icon': 'category',
          'budget_limit': 0.0,
          'kind': 'expense',
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    for (final name in incomeDefaults) {
      await db.insert(
        'categories',
        {
          'name': name,
          'icon': 'category',
          'budget_limit': 0.0,
          'kind': 'income',
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _createForecastSnapshotsTable(
    DatabaseExecutor db,
  ) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS forecast_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        forecast_month TEXT NOT NULL,
        snapshot_date TEXT NOT NULL,
        predicted_total REAL NOT NULL CHECK(predicted_total >= 0),
        UNIQUE(forecast_month, snapshot_date)
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_forecast_snapshots_month
      ON forecast_snapshots(forecast_month)
    ''');
  }

  Future<void> _createChallengeProgressTable(
    DatabaseExecutor db,
  ) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS challenge_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        challenge_id INTEGER NOT NULL
          REFERENCES challenges(id) ON DELETE CASCADE,
        amount REAL NOT NULL CHECK(amount > 0),
        recorded_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_challenge_progress_history
      ON challenge_progress(challenge_id, recorded_at DESC, id DESC)
    ''');
  }

  Future<Database> get database async {
    if (_db != null) return _db!;

    final path =
        _databasePath ?? join(await getDatabasesPath(), 'pennypilot.db');

    _db = await openDatabase(
      path,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            budget_limit REAL NOT NULL DEFAULT 0,
            kind TEXT NOT NULL DEFAULT 'expense'
              CHECK(kind IN ('expense','income')),
            UNIQUE(name, kind)
          )
        ''');

        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category_id INTEGER NOT NULL
              REFERENCES categories(id) ON DELETE RESTRICT,
            type TEXT NOT NULL CHECK(type IN ('expense','income')),
            amount REAL NOT NULL CHECK(amount > 0),
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
            target REAL NOT NULL CHECK(target > 0),
            saved REAL NOT NULL DEFAULT 0,
            status TEXT NOT NULL
          )
        ''');

        await _createChallengeProgressTable(db);
        await _createForecastSnapshotsTable(db);
        await _seed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE categories ADD COLUMN kind "
            "TEXT NOT NULL DEFAULT 'expense'",
          );

          await db.execute(
            "ALTER TABLE transactions ADD COLUMN received_into "
            "TEXT NOT NULL DEFAULT ''",
          );

          for (final name in incomeDefaults) {
            await db.insert(
              'categories',
              {
                'name': name,
                'icon': 'category',
                'budget_limit': 0.0,
                'kind': 'income',
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }

          for (final name in expenseDefaults) {
            await db.insert(
              'categories',
              {
                'name': name,
                'icon': 'category',
                'budget_limit': 0.0,
                'kind': 'expense',
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }

          final incomeOther = await db.query(
            'categories',
            columns: ['id'],
            where: 'name = ? AND kind = ?',
            whereArgs: ['Other Income', 'income'],
            limit: 1,
          );

          if (incomeOther.isNotEmpty) {
            await db.update(
              'transactions',
              {'category_id': incomeOther.first['id']},
              where: "type = 'income'",
            );
          }
        }

        if (oldVersion < 3) {
          await _createForecastSnapshotsTable(db);
        }

        if (oldVersion < 4) {
          await _createChallengeProgressTable(db);
        }
      },
    );

    return _db!;
  }

  /// Closes this database instance. Used by tests and cleanup workflows.
  Future<void> close() async {
    final current = _db;
    _db = null;

    if (current != null && current.isOpen) {
      await current.close();
    }
  }

  Future<List<BudgetCategory>> categories() async {
    final rows = await (await database).query(
      'categories',
      orderBy: 'kind, name',
    );

    return rows.map(BudgetCategory.fromMap).toList();
  }

  Future<List<MoneyTransaction>> transactions() async {
    final rows = await (await database).query(
      'transactions',
      orderBy: 'date DESC, id DESC',
    );

    return rows.map(MoneyTransaction.fromMap).toList();
  }

  Future<List<SavingsChallenge>> challenges() async {
    final rows = await (await database).query(
      'challenges',
      orderBy: 'id DESC',
    );

    return rows.map(SavingsChallenge.fromMap).toList();
  }

  /// Records a contribution and updates its challenge balance atomically.
  Future<int> addChallengeProgress(
    ChallengeProgressEntry entry,
  ) async {
    if (!entry.amount.isFinite || entry.amount <= 0) {
      throw ArgumentError.value(
        entry.amount,
        'amount',
        'Contribution amount must be a positive finite number.',
      );
    }

    final db = await database;

    return db.transaction((txn) async {
      final challengeRows = await txn.query(
        'challenges',
        columns: ['target', 'saved'],
        where: 'id = ?',
        whereArgs: [entry.challengeId],
        limit: 1,
      );

      if (challengeRows.isEmpty) {
        throw StateError('Savings challenge does not exist.');
      }

      final target = (challengeRows.first['target'] as num).toDouble();

      final currentSaved = (challengeRows.first['saved'] as num).toDouble();

      final updatedSaved = currentSaved + entry.amount;

      if (!updatedSaved.isFinite) {
        throw ArgumentError('Updated savings balance is invalid.');
      }

      final progressId = await txn.insert(
        'challenge_progress',
        entry.toMap(),
      );

      await txn.update(
        'challenges',
        {
          'saved': updatedSaved,
          'status': updatedSaved >= target ? 'finished' : 'active',
        },
        where: 'id = ?',
        whereArgs: [entry.challengeId],
      );

      return progressId;
    });
  }

  /// Returns a challenge's contributions from newest to oldest.
  Future<List<ChallengeProgressEntry>> challengeProgressFor(
    int challengeId,
  ) async {
    final rows = await (await database).query(
      'challenge_progress',
      where: 'challenge_id = ?',
      whereArgs: [challengeId],
      orderBy: 'recorded_at DESC, id DESC',
    );

    return rows.map(ChallengeProgressEntry.fromMap).toList();
  }

  Future<void> saveForecastSnapshot(
    ForecastSnapshot snapshot,
  ) async {
    final db = await database;

    await db.insert(
      'forecast_snapshots',
      snapshot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ForecastSnapshot>> forecastSnapshots() async {
    final rows = await (await database).query(
      'forecast_snapshots',
      orderBy: 'forecast_month ASC, snapshot_date ASC',
    );

    return rows.map(ForecastSnapshot.fromMap).toList();
  }

  Future<void> saveCategory(BudgetCategory c) async {
    final db = await database;

    if (c.id == null) {
      await db.insert('categories', c.toMap());
    } else {
      final count = Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM transactions WHERE category_id = ?',
              [c.id],
            ),
          ) ??
          0;

      if (count > 0) {
        final old = (await db.query(
          'categories',
          columns: ['kind'],
          where: 'id = ?',
          whereArgs: [c.id],
        ))
            .first['kind'];

        if (old != c.kind) {
          throw StateError(
            'Move linked transactions before changing category type.',
          );
        }
      }

      await db.update(
        'categories',
        c.toMap(),
        where: 'id = ?',
        whereArgs: [c.id],
      );
    }
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;

    final count = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM transactions WHERE category_id = ?',
            [id],
          ),
        ) ??
        0;

    if (count > 0) {
      throw StateError(
        'Move or delete linked transactions before deleting this category.',
      );
    }

    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> saveTransaction(MoneyTransaction t) async {
    final db = await database;

    final category = await db.query(
      'categories',
      columns: ['kind'],
      where: 'id = ?',
      whereArgs: [t.categoryId],
      limit: 1,
    );

    if (category.isEmpty || category.first['kind'] != t.type) {
      throw StateError(
        'Select a category matching the transaction type.',
      );
    }

    if (t.id == null) {
      await db.insert('transactions', t.toMap());
    } else {
      await db.update(
        'transactions',
        t.toMap(),
        where: 'id = ?',
        whereArgs: [t.id],
      );
    }
  }

  Future<void> deleteTransaction(int id) async {
    await (await database).delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> saveChallenge(SavingsChallenge c) async {
    final db = await database;

    if (c.id == null) {
      await db.insert('challenges', c.toMap());
    } else {
      await db.update(
        'challenges',
        c.toMap(),
        where: 'id = ?',
        whereArgs: [c.id],
      );
    }
  }

  Future<void> deleteChallenge(int id) async {
    await (await database).delete(
      'challenges',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('forecast_snapshots');
      await txn.delete('transactions');
      await txn.delete('categories');
      await txn.delete('challenge_progress');
      await txn.delete('challenges');

      await _seed(txn);
    });
  }
}
