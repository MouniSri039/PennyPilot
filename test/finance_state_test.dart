import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

import 'package:pennypilot/data/finance_database.dart';
import 'package:pennypilot/models/finance_models.dart';
import 'package:pennypilot/state/finance_state.dart';

void main() {
  late Directory tempDirectory;
  late FinanceDatabase database;
  late FinanceState state;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    tempDirectory =
        await Directory.systemTemp.createTemp('finance_state_test_');

    database = FinanceDatabase.forTesting(
      databasePath: path.join(tempDirectory.path, 'finance_test.db'),
    );

    state = FinanceState(database: database);
  });

  tearDown(() async {
    state.dispose();
    await database.close();

    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  group('FinanceState initialization', () {
    test('loads default preferences and database data', () async {
      await state.initialize();

      expect(state.monthlyBudget, 500);
      expect(state.remindersEnabled, false);
      expect(state.darkModeEnabled, false);
      expect(state.loading, false);
      expect(state.error, isNull);
      expect(state.categories, isNotEmpty);
      expect(state.transactions, isEmpty);
      expect(state.challenges, isEmpty);
    });

    test('loads previously saved preferences', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_budget': 1200.0,
        'reminders_enabled': true,
        'dark_mode_enabled': true,
      });

      await state.initialize();

      expect(state.monthlyBudget, 1200);
      expect(state.remindersEnabled, true);
      expect(state.darkModeEnabled, true);
      expect(state.loading, false);
    });

    test('reload refreshes database-backed state', () async {
      await state.initialize();

      await database.saveCategory(
        const BudgetCategory(
          name: 'Books',
          kind: 'expense',
        ),
      );

      await state.reload();

      expect(
        state.categories.any((category) => category.name == 'Books'),
        true,
      );
      expect(state.loading, false);
      expect(state.error, isNull);
    });
  });

  group('Preference persistence', () {
    test('saves monthly budget', () async {
      await state.setBudget(1500);

      final prefs = await SharedPreferences.getInstance();

      expect(state.monthlyBudget, 1500);
      expect(prefs.getDouble('monthly_budget'), 1500);
    });

    test('saves reminder preference', () async {
      await state.setReminders(true);

      final prefs = await SharedPreferences.getInstance();

      expect(state.remindersEnabled, true);
      expect(prefs.getBool('reminders_enabled'), true);
    });

    test('saves dark mode preference', () async {
      await state.setDarkMode(true);

      final prefs = await SharedPreferences.getInstance();

      expect(state.darkModeEnabled, true);
      expect(prefs.getBool('dark_mode_enabled'), true);
    });

    test('notifies listeners when preferences change', () async {
      var notifications = 0;
      state.addListener(() => notifications++);

      await state.setBudget(900);
      await state.setReminders(true);
      await state.setDarkMode(true);

      expect(notifications, 3);
    });
  });

  group('Finance calculations and lookups', () {
    test('returns unknown for a missing category', () {
      expect(state.categoryName(999), 'Unknown');
    });

    test('returns category name for an existing category', () async {
      await state.initialize();

      final category = state.categories.first;

      expect(
        state.categoryName(category.id!),
        category.name,
      );
    });

    test('calculates remaining budget', () async {
      await state.initialize();

      await state.setBudget(1000);

      expect(state.spent, 0);
      expect(state.remaining, 1000);
    });

    test('exposes empty insights collections safely', () {
      expect(state.spendingAnomalies, isEmpty);
      expect(state.categoryTrends, isEmpty);
      expect(state.spendingForecast, isNull);
    });
  });

  group('Challenge progress validation', () {
    test('rejects a challenge without a saved ID', () async {
      const challenge = SavingsChallenge(
        title: 'Emergency Fund',
        target: 1000,
      );

      await expectLater(
        state.addChallengeProgress(challenge, 100),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects zero contribution', () async {
      const challenge = SavingsChallenge(
        id: 1,
        title: 'Emergency Fund',
        target: 1000,
      );

      await expectLater(
        state.addChallengeProgress(challenge, 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative contribution', () async {
      const challenge = SavingsChallenge(
        id: 1,
        title: 'Emergency Fund',
        target: 1000,
      );

      await expectLater(
        state.addChallengeProgress(challenge, -50),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects infinite contribution', () async {
      const challenge = SavingsChallenge(
        id: 1,
        title: 'Emergency Fund',
        target: 1000,
      );

      await expectLater(
        state.addChallengeProgress(challenge, double.infinity),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects NaN contribution', () async {
      const challenge = SavingsChallenge(
        id: 1,
        title: 'Emergency Fund',
        target: 1000,
      );

      await expectLater(
        state.addChallengeProgress(challenge, double.nan),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Challenge progress operations', () {
    test('records and retrieves a valid contribution', () async {
      await state.initialize();

      const challenge = SavingsChallenge(
        title: 'Emergency Fund',
        target: 1000,
      );

      await state.saveChallenge(challenge);

      final savedChallenge = state.challenges.first;

      await state.addChallengeProgress(savedChallenge, 100);

      final history = await state.challengeProgressFor(
        savedChallenge.id!,
      );

      expect(history, hasLength(1));
      expect(history.first.amount, 100);
      expect(history.first.challengeId, savedChallenge.id);
    });

    test('returns empty history for a challenge without contributions',
        () async {
      await state.initialize();

      const challenge = SavingsChallenge(
        title: 'Vacation Fund',
        target: 2000,
      );

      await state.saveChallenge(challenge);

      final savedChallenge = state.challenges.first;

      final history = await state.challengeProgressFor(
        savedChallenge.id!,
      );

      expect(history, isEmpty);
    });
  });

  group('CRUD operations through FinanceState', () {
    test('saves and deletes a category', () async {
      await state.initialize();

      await state.saveCategory(
        const BudgetCategory(name: 'Books'),
      );

      expect(
        state.categories.any((category) => category.name == 'Books'),
        true,
      );

      final category = state.categories.firstWhere(
        (item) => item.name == 'Books',
      );

      await state.deleteCategory(category.id!);

      expect(
        state.categories.any((item) => item.name == 'Books'),
        false,
      );
    });

    test('saves and deletes a challenge', () async {
      await state.initialize();

      await state.saveChallenge(
        const SavingsChallenge(
          title: 'New Laptop',
          target: 1500,
        ),
      );

      expect(state.challenges, hasLength(1));

      final id = state.challenges.first.id!;

      await state.deleteChallenge(id);

      expect(state.challenges, isEmpty);
    });

    test('saves and deletes a transaction', () async {
      await state.initialize();

      final category = state.categories.firstWhere(
        (item) => item.kind == 'expense',
      );

      await state.saveTransaction(
        MoneyTransaction(
          categoryId: category.id!,
          type: 'expense',
          amount: 50,
          date: DateTime.now(),
          description: 'Test purchase',
        ),
      );

      expect(state.transactions, hasLength(1));

      final id = state.transactions.first.id!;

      await state.deleteTransaction(id);

      expect(state.transactions, isEmpty);
    });

    test('clearAll resets financial data', () async {
      await state.initialize();

      await state.saveChallenge(
        const SavingsChallenge(
          title: 'Emergency Fund',
          target: 1000,
        ),
      );

      await state.clearAll();

      expect(state.transactions, isEmpty);
      expect(state.challenges, isEmpty);
      expect(state.categories, isNotEmpty);
      expect(state.error, isNull);
    });
  });
}
