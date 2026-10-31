import '../models/finance_models.dart';

/// Produces explainable, offline financial insights from local transactions.
class FinancialIntelligenceService {
  const FinancialIntelligenceService();

  FinancialInsights analyze({
    required Iterable<MoneyTransaction> transactions,
    required double monthlyBudget,
    DateTime? now,
  }) {
    final currentDate = now ?? DateTime.now();

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
      anomalies: _detectAnomalies(expenses, now: currentDate),
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

    final monthExpenses = expenses.where(
      (transaction) =>
          transaction.date.year == now.year &&
          transaction.date.month == now.month,
    );

    final spent = monthExpenses.fold<double>(
      0,
      (total, transaction) => total + transaction.amount,
    );

    final dailyAverage = spent / now.day;
    final projectedTotal = dailyAverage * daysInMonth;

    final budgetUtilization =
        monthlyBudget > 0 ? projectedTotal / monthlyBudget : null;

    final explanation = spent == 0
        ? 'No expenses have been recorded this month yet.'
        : 'Based on ${now.day} days of recorded spending, '
            'the projected monthly expense is '
            '${projectedTotal.toStringAsFixed(2)}.';

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
      if (transaction.date.isAfter(now)) continue;

      final history = previousByCategory[transaction.categoryId] ?? <double>[];

      if (history.length >= 3) {
        final baseline = _median(history);

        final deviations =
            history.map((amount) => (amount - baseline).abs()).toList();

        final medianDeviation = _median(deviations);
        final robustDeviation = 1.4826 * medianDeviation;

        final threshold = baseline +
            [
              3 * robustDeviation,
              baseline * 0.75,
              1.0,
            ].reduce((a, b) => a > b ? a : b);

        if (transaction.amount > threshold) {
          final amountAboveMedian = transaction.amount - baseline;

          anomalies.add(
            SpendingAnomaly(
              transaction: transaction,
              historicalMedian: baseline,
              detectionThreshold: threshold,
              historicalSampleSize: history.length,
              amountAboveMedian: amountAboveMedian,
              percentageAboveMedian:
                  baseline > 0 ? (amountAboveMedian / baseline) * 100 : null,
              thresholdExcess: transaction.amount - threshold,
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

      if (date.isAfter(now)) continue;

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

    if (sorted.length.isOdd) return sorted[middle];

    return (sorted[middle - 1] + sorted[middle]) / 2;
  }
}

/// Evaluates saved forecasts against completed-month expense totals.
class ForecastAccuracyEvaluator {
  const ForecastAccuracyEvaluator();

  ForecastAccuracyReport evaluate({
    required Iterable<ForecastSnapshot> snapshots,
    required Iterable<MoneyTransaction> transactions,
    required DateTime now,
  }) {
    final currentMonth = DateTime(now.year, now.month);

    final actualsByMonth = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type != 'expense') continue;
      if (transaction.date.isAfter(now)) continue;

      final date = transaction.date;
      final key = _monthKey(date.year, date.month);

      actualsByMonth[key] = (actualsByMonth[key] ?? 0) + transaction.amount;
    }

    final evaluations = <ForecastEvaluation>[];

    for (final snapshot in snapshots) {
      final month = DateTime(
        snapshot.forecastMonth.year,
        snapshot.forecastMonth.month,
      );

      // A forecast can only be evaluated after its month has ended.
      if (!month.isBefore(currentMonth)) continue;

      if (!snapshot.predictedTotal.isFinite || snapshot.predictedTotal < 0) {
        continue;
      }

      final key = _monthKey(month.year, month.month);
      final actual = actualsByMonth[key] ?? 0;

      evaluations.add(
        ForecastEvaluation(
          snapshot: snapshot,
          actualTotal: actual,
          absoluteError: (snapshot.predictedTotal - actual).abs(),
          percentageError: actual > 0
              ? ((snapshot.predictedTotal - actual).abs() / actual) * 100
              : null,
        ),
      );
    }

    if (evaluations.isEmpty) {
      return const ForecastAccuracyReport(
        evaluations: [],
        meanAbsoluteError: null,
        meanAbsolutePercentageError: null,
        zeroActualCount: 0,
      );
    }

    final mae = evaluations.fold<double>(
          0,
          (total, evaluation) => total + evaluation.absoluteError,
        ) /
        evaluations.length;

    final percentageEvaluations = evaluations
        .where((evaluation) => evaluation.percentageError != null)
        .toList();

    final mape = percentageEvaluations.isEmpty
        ? null
        : percentageEvaluations.fold<double>(
              0,
              (total, evaluation) => total + evaluation.percentageError!,
            ) /
            percentageEvaluations.length;

    return ForecastAccuracyReport(
      evaluations: evaluations,
      meanAbsoluteError: mae,
      meanAbsolutePercentageError: mape,
      zeroActualCount: evaluations.length - percentageEvaluations.length,
    );
  }

  String _monthKey(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';
}

class ForecastAccuracyReport {
  final List<ForecastEvaluation> evaluations;
  final double? meanAbsoluteError;
  final double? meanAbsolutePercentageError;
  final int zeroActualCount;

  const ForecastAccuracyReport({
    required this.evaluations,
    required this.meanAbsoluteError,
    required this.meanAbsolutePercentageError,
    required this.zeroActualCount,
  });

  int get evaluatedForecastCount => evaluations.length;

  bool get hasResults => evaluations.isNotEmpty;
}

class ForecastEvaluation {
  final ForecastSnapshot snapshot;
  final double actualTotal;
  final double absoluteError;
  final double? percentageError;

  const ForecastEvaluation({
    required this.snapshot,
    required this.actualTotal,
    required this.absoluteError,
    required this.percentageError,
  });
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
  final int historicalSampleSize;
  final double amountAboveMedian;
  final double? percentageAboveMedian;
  final double thresholdExcess;
  final String explanation;

  const SpendingAnomaly({
    required this.transaction,
    required this.historicalMedian,
    required this.detectionThreshold,
    required this.historicalSampleSize,
    required this.amountAboveMedian,
    required this.percentageAboveMedian,
    required this.thresholdExcess,
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
