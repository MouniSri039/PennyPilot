import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/finance_database.dart';
import '../models/finance_models.dart';
import '../services/financial_intelligence_service.dart';
import '../services/spending_helper.dart';

class FinanceState extends ChangeNotifier {
  final FinanceDatabase db = FinanceDatabase.instance;

  final FinancialIntelligenceService _intelligenceService =
      const FinancialIntelligenceService();

  final ForecastAccuracyEvaluator _accuracyEvaluator =
      const ForecastAccuracyEvaluator();

  List<BudgetCategory> categories = [];
  List<MoneyTransaction> transactions = [];
  List<SavingsChallenge> challenges = [];

  List<ForecastSnapshot> forecastSnapshots = [];

  FinancialInsights? insights;

  ForecastAccuracyReport forecastAccuracy = const ForecastAccuracyReport(
    evaluations: [],
    meanAbsoluteError: null,
    meanAbsolutePercentageError: null,
    zeroActualCount: 0,
  );

  double monthlyBudget = 500;
  bool remindersEnabled = false;
  bool loading = true;
  String? error;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      monthlyBudget = prefs.getDouble('monthly_budget') ?? 500;
      remindersEnabled = prefs.getBool('reminders_enabled') ?? false;

      await reload();
    } catch (e) {
      error = '$e';
      loading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    categories = await db.categories();
    transactions = await db.transactions();
    challenges = await db.challenges();

    final now = DateTime.now();

    _refreshInsights(now);

    await _saveCurrentForecastSnapshot(now);

    await _refreshForecastAccuracy(now);

    loading = false;
    error = null;

    notifyListeners();
  }

  void _refreshInsights(DateTime now) {
    insights = _intelligenceService.analyze(
      transactions: transactions,
      monthlyBudget: monthlyBudget,
      now: now,
    );
  }

  Future<void> _saveCurrentForecastSnapshot(DateTime now) async {
    final forecast = insights?.forecast;

    if (forecast == null) return;

    final snapshot = ForecastSnapshot(
      forecastMonth: DateTime(now.year, now.month),
      snapshotDate: DateTime(now.year, now.month, now.day),
      predictedTotal: forecast.projectedTotal,
    );

    await db.saveForecastSnapshot(snapshot);
  }

  Future<void> _refreshForecastAccuracy(DateTime now) async {
    forecastSnapshots = await db.forecastSnapshots();

    forecastAccuracy = _accuracyEvaluator.evaluate(
      snapshots: forecastSnapshots,
      transactions: transactions,
      now: now,
    );
  }

  Future<void> _perform(Future<void> Function() operation) async {
    try {
      await operation();
      await reload();
    } catch (e) {
      error = '$e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> saveCategory(BudgetCategory c) =>
      _perform(() => db.saveCategory(c));

  Future<void> deleteCategory(int id) => _perform(() => db.deleteCategory(id));

  Future<void> saveTransaction(MoneyTransaction t) =>
      _perform(() => db.saveTransaction(t));

  Future<void> deleteTransaction(int id) =>
      _perform(() => db.deleteTransaction(id));

  Future<void> saveChallenge(SavingsChallenge c) =>
      _perform(() => db.saveChallenge(c));

  Future<void> deleteChallenge(int id) =>
      _perform(() => db.deleteChallenge(id));

  Future<void> clearAll() => _perform(db.clearAll);

  Future<void> setBudget(double value) async {
    monthlyBudget = value;

    _refreshInsights(DateTime.now());
    notifyListeners();

    await (await SharedPreferences.getInstance())
        .setDouble('monthly_budget', value);
  }

  Future<void> setReminders(bool value) async {
    remindersEnabled = value;

    notifyListeners();

    await (await SharedPreferences.getInstance())
        .setBool('reminders_enabled', value);
  }

  double get spent => SpendingHelper.expenses(
        transactions,
        DateTime.now(),
      );

  double get remaining => monthlyBudget - spent;

  String get tip => SpendingHelper.advice(
        spent: spent,
        limit: monthlyBudget,
      );

  MonthlySpendingForecast? get spendingForecast => insights?.forecast;

  List<SpendingAnomaly> get spendingAnomalies => insights?.anomalies ?? [];

  List<CategorySpendingTrend> get categoryTrends => insights?.trends ?? [];

  String categoryName(int id) {
    for (final category in categories) {
      if (category.id == id) {
        return category.name;
      }
    }

    return 'Unknown';
  }
}
