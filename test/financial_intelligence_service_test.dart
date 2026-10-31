import 'package:flutter_test/flutter_test.dart';
import 'package:pennypilot/models/finance_models.dart';
import 'package:pennypilot/services/financial_intelligence_service.dart';

void main() {
  const service = FinancialIntelligenceService();

  MoneyTransaction expense({
    required int categoryId,
    required double amount,
    required DateTime date,
  }) {
    return MoneyTransaction(
      categoryId: categoryId,
      type: 'expense',
      amount: amount,
      date: date,
      description: 'Test expense',
    );
  }

  MoneyTransaction income({
    required int categoryId,
    required double amount,
    required DateTime date,
  }) {
    return MoneyTransaction(
      categoryId: categoryId,
      type: 'income',
      amount: amount,
      date: date,
      description: 'Test income',
    );
  }

  group('Monthly spending forecast', () {
    test('projects month-end expenses from average daily spending', () {
      final transactions = [
        expense(
          categoryId: 1,
          amount: 60,
          date: DateTime(2026, 10, 5),
        ),
        expense(
          categoryId: 1,
          amount: 40,
          date: DateTime(2026, 10, 10),
        ),
      ];

      final result = service.analyze(
        transactions: transactions,
        monthlyBudget: 500,
        now: DateTime(2026, 10, 15),
      );

      expect(result.forecast.spentSoFar, 100);
      expect(result.forecast.dailyAverage, closeTo(100 / 15, 0.001));
      expect(result.forecast.projectedTotal, closeTo(206.6667, 0.001));
      expect(result.forecast.projectedOverBudget, false);
    });

    test('does not divide by zero when budget is not configured', () {
      final result = service.analyze(
        transactions: [],
        monthlyBudget: 0,
        now: DateTime(2026, 10, 15),
      );

      expect(result.forecast.budgetUtilization, isNull);
      expect(result.forecast.projectedOverBudget, false);
    });

    test('excludes future transactions from the monthly forecast', () {
      final transactions = [
        expense(
          categoryId: 1,
          amount: 50,
          date: DateTime(2026, 10, 10),
        ),
        expense(
          categoryId: 1,
          amount: 500,
          date: DateTime(2026, 10, 20),
        ),
      ];

      final result = service.analyze(
        transactions: transactions,
        monthlyBudget: 500,
        now: DateTime(2026, 10, 15),
      );

      expect(result.forecast.spentSoFar, 50);
    });

    test('excludes income from the monthly spending forecast', () {
      final transactions = [
        expense(
          categoryId: 1,
          amount: 50,
          date: DateTime(2026, 10, 10),
        ),
        income(
          categoryId: 2,
          amount: 1000,
          date: DateTime(2026, 10, 11),
        ),
      ];

      final result = service.analyze(
        transactions: transactions,
        monthlyBudget: 500,
        now: DateTime(2026, 10, 15),
      );

      expect(result.forecast.spentSoFar, 50);
    });
  });

  group('Spending anomaly detection', () {
    test('detects a large expense after sufficient category history', () {
      final transactions = [
        expense(
          categoryId: 1,
          amount: 10,
          date: DateTime(2026, 10, 1),
        ),
        expense(
          categoryId: 1,
          amount: 12,
          date: DateTime(2026, 10, 2),
        ),
        expense(
          categoryId: 1,
          amount: 11,
          date: DateTime(2026, 10, 3),
        ),
        expense(
          categoryId: 1,
          amount: 13,
          date: DateTime(2026, 10, 4),
        ),
        expense(
          categoryId: 1,
          amount: 100,
          date: DateTime(2026, 10, 5),
        ),
      ];

      final result = service.analyze(
        transactions: transactions,
        monthlyBudget: 500,
        now: DateTime(2026, 10, 31),
      );

      expect(result.anomalies, hasLength(1));
      expect(result.anomalies.first.transaction.amount, 100);
      expect(result.anomalies.first.explanation, contains('threshold'));
    });

    test('does not flag a transaction without sufficient history', () {
      final transactions = [
        expense(
          categoryId: 1,
          amount: 10,
          date: DateTime(2026, 10, 1),
        ),
        expense(
          categoryId: 1,
          amount: 500,
          date: DateTime(2026, 10, 2),
        ),
      ];

      final result = service.analyze(
        transactions: transactions,
        monthlyBudget: 500,
        now: DateTime(2026, 10, 31),
      );

      expect(result.anomalies, isEmpty);
    });

    test('ignores future transactions during anomaly detection', () {
      final transactions = [
        expense(
          categoryId: 1,
          amount: 10,
          date: DateTime(2026, 10, 1),
        ),
        expense(
          categoryId: 1,
          amount: 12,
          date: DateTime(2026, 10, 2),
        ),
        expense(
          categoryId: 1,
          amount: 11,
          date: DateTime(2026, 10, 3),
        ),
        expense(
          categoryId: 1,
          amount: 13,
          date: DateTime(2026, 10, 4),
        ),
        expense(
          categoryId: 1,
          amount: 500,
          date: DateTime(2026, 10, 20),
        ),
      ];

      final result = service.analyze(
        transactions: transactions,
        monthlyBudget: 500,
        now: DateTime(2026, 10, 15),
      );

      expect(result.anomalies, isEmpty);
    });

    test('does not use income as anomaly history', () {
      final transactions = [
        income(
          categoryId: 1,
          amount: 1000,
          date: DateTime(2026, 10, 1),
        ),
        income(
          categoryId: 1,
          amount: 1200,
          date: DateTime(2026, 10, 2),
        ),
        income(
          categoryId: 1,
          amount: 1100,
          date: DateTime(2026, 10, 3),
        ),
        expense(
          categoryId: 1,
          amount: 100,
          date: DateTime(2026, 10, 4),
        ),
      ];

      final result = service.analyze(
        transactions: transactions,
        monthlyBudget: 500,
        now: DateTime(2026, 10, 15),
      );

      expect(result.anomalies, isEmpty);
    });
  });

  group('Category spending trends', () {
    test('compares current and previous month by category', () {
      final transactions = [
        expense(
          categoryId: 1,
          amount: 100,
          date: DateTime(2026, 9, 10),
        ),
        expense(
          categoryId: 1,
          amount: 150,
          date: DateTime(2026, 10, 10),
        ),
      ];

      final result = service.analyze(
        transactions: transactions,
        monthlyBudget: 500,
        now: DateTime(2026, 10, 31),
      );

      final trend = result.trends.single;

      expect(trend.categoryId, 1);
      expect(trend.currentMonthTotal, 150);
      expect(trend.previousMonthTotal, 100);
      expect(trend.percentageChange, 50);
    });

    test('ignores future transactions in category trends', () {
      final transactions = [
        expense(
          categoryId: 1,
          amount: 100,
          date: DateTime(2026, 9, 10),
        ),
        expense(
          categoryId: 1,
          amount: 150,
          date: DateTime(2026, 10, 10),
        ),
        expense(
          categoryId: 1,
          amount: 500,
          date: DateTime(2026, 10, 20),
        ),
      ];

      final result = service.analyze(
        transactions: transactions,
        monthlyBudget: 500,
        now: DateTime(2026, 10, 15),
      );

      final trend = result.trends.single;

      expect(trend.currentMonthTotal, 150);
      expect(trend.previousMonthTotal, 100);
    });

    test('handles year boundaries when comparing monthly trends', () {
      final transactions = [
        expense(
          categoryId: 1,
          amount: 80,
          date: DateTime(2025, 12, 10),
        ),
        expense(
          categoryId: 1,
          amount: 120,
          date: DateTime(2026, 1, 10),
        ),
      ];

      final result = service.analyze(
        transactions: transactions,
        monthlyBudget: 500,
        now: DateTime(2026, 1, 20),
      );

      final trend = result.trends.single;

      expect(trend.currentMonthTotal, 120);
      expect(trend.previousMonthTotal, 80);
      expect(trend.percentageChange, 50);
    });
  });
}
