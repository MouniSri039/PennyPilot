import '../models/finance_models.dart';

/// Produces explainable, offline financial insights from local transactions.
///
/// The service is independent of Flutter, Provider, and SQLite.
/// All calculations use locally recorded transaction data.
class FinancialIntelligenceService {
  const FinancialIntelligenceService();

  FinancialInsights analyze({
    required Iterable<MoneyTransaction> transactions,
    required double monthlyBudget,
    DateTime? now,
  }) {
    final currentDate = now ?? DateTime.now();

    // Only analyze expenses recorded up to the current date and time.
    final expenses = transactions
        .where(
          (transaction) =>
              transaction.type == 'expense' &&
              !transaction.date.isAfter(currentDate),
        )
        .toList();

    return FinancialInsights(
      forecast: _forecast(
        expenses: expenses,
        monthlyBudget: monthlyBudget,
        now: currentDate,
      ),
      anomalies: _detectAnomalies(
        expenses,
        now: currentDate,
      ),
      trends: _calculateCategoryTrends(
        expenses: expenses,
        now: currentDate,
      ),
    );
  }

  MonthlySpendingForecast _forecast({
    required List<MoneyTransaction> expenses,
    required double monthlyBudget,
    required DateTime now,
  }) {
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final monthExpenses = expenses.where((transaction) {
      return transaction.date.year == now.year &&
          transaction.date.month == now.month;
    });

    final spent = monthExpenses.fold<double>(
      0,
      (total, transaction) => total + transaction.amount,
    );

    final dailyAverage = spent / now.day;
    final projectedTotal = dailyAverage * daysInMonth;

    final budgetUtilization =
        monthlyBudget > 0 ? projectedTotal / monthlyBudget : null;

    String explanation;

    if (spent == 0) {
      explanation = 'No expenses have been recorded this month yet.';
    } else {
      explanation = 'Based on ${now.day} days of recorded spending, '
          'the projected monthly expense is '
          '${projectedTotal.toStringAsFixed(2)}.';
    }

    return MonthlySpendingForecast(
      spentSoFar: spent,
      dailyAverage: dailyAverage,
      projectedTotal: projectedTotal,
      monthlyBudget: monthlyBudget,
      budgetUtilization: budgetUtilization,
      daysElapsed: now.day,
      daysInMonth: daysInMonth,
      explanation: explanation,
    );
  }

  List<SpendingAnomaly> _detectAnomalies(
    List<MoneyTransaction> expenses, {
    required DateTime now,
  }) {
    final sorted = [...expenses]..sort((a, b) => a.date.compareTo(b.date));

    final previousByCategory = <int, List<double>>{};
    final anomalies = <SpendingAnomaly>[];

    for (final transaction in sorted) {
      // Future transactions must never affect historical analysis.
      if (transaction.date.isAfter(now)) {
        continue;
      }

      final history = previousByCategory[transaction.categoryId] ?? <double>[];

      // Require at least three earlier transactions in the same category.
      if (history.length >= 3) {
        final baseline = _median(history);

        final deviations =
            history.map((amount) => (amount - baseline).abs()).toList();

        final medianDeviation = _median(deviations);

        // Median absolute deviation is resistant to historical outliers.
        final robustDeviation = 1.4826 * medianDeviation;

        final threshold = baseline +
            [
              3 * robustDeviation,
              baseline * 0.75,
              1.0,
            ].reduce((a, b) => a > b ? a : b);

        if (transaction.amount > threshold) {
          anomalies.add(
            SpendingAnomaly(
              transaction: transaction,
              historicalMedian: baseline,
              detectionThreshold: threshold,
              explanation:
                  'This expense is ${transaction.amount.toStringAsFixed(2)}, '
                  'above the category threshold of '
                  '${threshold.toStringAsFixed(2)}. '
                  'The previous category median was '
                  '${baseline.toStringAsFixed(2)}.',
            ),
          );
        }
      }

      previousByCategory
          .putIfAbsent(transaction.categoryId, () => [])
          .add(transaction.amount);
    }

    return anomalies.reversed.toList();
  }

  List<CategorySpendingTrend> _calculateCategoryTrends({
    required List<MoneyTransaction> expenses,
    required DateTime now,
  }) {
    final currentMonth = <int, double>{};
    final previousMonth = <int, double>{};

    final previousDate = DateTime(now.year, now.month - 1);

    for (final transaction in expenses) {
      final date = transaction.date;
      final categoryId = transaction.categoryId;

      // Exclude any future-dated transaction.
      if (date.isAfter(now)) {
        continue;
      }

      if (date.year == now.year && date.month == now.month) {
        currentMonth[categoryId] =
            (currentMonth[categoryId] ?? 0) + transaction.amount;
      } else if (date.year == previousDate.year &&
          date.month == previousDate.month) {
        previousMonth[categoryId] =
            (previousMonth[categoryId] ?? 0) + transaction.amount;
      }
    }

    final categoryIds = {
      ...currentMonth.keys,
      ...previousMonth.keys,
    };

    final trends = categoryIds.map((categoryId) {
      final current = currentMonth[categoryId] ?? 0;
      final previous = previousMonth[categoryId] ?? 0;

      final percentageChange =
          previous > 0 ? ((current - previous) / previous) * 100 : null;

      return CategorySpendingTrend(
        categoryId: categoryId,
        currentMonthTotal: current,
        previousMonthTotal: previous,
        percentageChange: percentageChange,
      );
    }).toList();

    trends.sort(
      (a, b) => b.currentMonthTotal.compareTo(a.currentMonthTotal),
    );

    return trends;
  }

  double _median(List<double> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;

    if (sorted.length.isOdd) {
      return sorted[middle];
    }

    return (sorted[middle - 1] + sorted[middle]) / 2;
  }
}

class FinancialInsights {
  final MonthlySpendingForecast forecast;
  final List<SpendingAnomaly> anomalies;
  final List<CategorySpendingTrend> trends;

  const FinancialInsights({
    required this.forecast,
    required this.anomalies,
    required this.trends,
  });
}

class MonthlySpendingForecast {
  final double spentSoFar;
  final double dailyAverage;
  final double projectedTotal;
  final double monthlyBudget;
  final double? budgetUtilization;
  final int daysElapsed;
  final int daysInMonth;
  final String explanation;

  const MonthlySpendingForecast({
    required this.spentSoFar,
    required this.dailyAverage,
    required this.projectedTotal,
    required this.monthlyBudget,
    required this.budgetUtilization,
    required this.daysElapsed,
    required this.daysInMonth,
    required this.explanation,
  });

  bool get projectedOverBudget =>
      budgetUtilization != null && budgetUtilization! > 1;
}

class SpendingAnomaly {
  final MoneyTransaction transaction;
  final double historicalMedian;
  final double detectionThreshold;
  final String explanation;

  const SpendingAnomaly({
    required this.transaction,
    required this.historicalMedian,
    required this.detectionThreshold,
    required this.explanation,
  });
}

class CategorySpendingTrend {
  final int categoryId;
  final double currentMonthTotal;
  final double previousMonthTotal;
  final double? percentageChange;

  const CategorySpendingTrend({
    required this.categoryId,
    required this.currentMonthTotal,
    required this.previousMonthTotal,
    required this.percentageChange,
  });
}
