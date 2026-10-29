import '../models/finance_models.dart';

class SpendingHelper {
  static String baseline() => 'Review your expenses regularly.';
  static String advice({required double spent, required double limit}) {
    if (limit <= 0) return 'Set a monthly budget to receive a spending check.';
    final ratio = spent / limit;
    if (ratio >= 1)
      return 'You have reached your monthly budget. Review upcoming purchases.';
    if (ratio >= .8)
      return 'You have used ${(ratio * 100).round()}% of your budget. Consider slowing down spending.';
    return 'You are within your budget. Keep tracking your purchases.';
  }

  static double expenses(
          Iterable<MoneyTransaction> transactions, DateTime month) =>
      transactions
          .where((t) =>
              t.type == 'expense' &&
              t.date.year == month.year &&
              t.date.month == month.month)
          .fold(0.0, (sum, t) => sum + t.amount);
}
