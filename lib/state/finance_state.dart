import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/finance_database.dart';
import '../models/finance_models.dart';
import '../services/spending_helper.dart';

class FinanceState extends ChangeNotifier {
  final FinanceDatabase db = FinanceDatabase.instance;
  List<BudgetCategory> categories = [];
  List<MoneyTransaction> transactions = [];
  List<SavingsChallenge> challenges = [];
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
    loading = false;
    error = null;
    notifyListeners();
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

  double get spent => SpendingHelper.expenses(transactions, DateTime.now());
  double get remaining => monthlyBudget - spent;
  String get tip => SpendingHelper.advice(spent: spent, limit: monthlyBudget);
  String categoryName(int id) {
    for (final c in categories) {
      if (c.id == id) return c.name;
    }
    return 'Unknown';
  }
}
