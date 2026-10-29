import 'package:flutter_test/flutter_test.dart';
import 'package:pennypilot/models/finance_models.dart';
import 'package:pennypilot/services/spending_helper.dart';

void main() {
  group('Spending Check', () {
    test('requires a budget', () {
      expect(SpendingHelper.advice(spent: 10, limit: 0),
          contains('Set a monthly budget'));
    });
    test('warns near limit', () {
      expect(SpendingHelper.advice(spent: 85, limit: 100), contains('85%'));
    });
    test('warns at and above limit', () {
      expect(
          SpendingHelper.advice(spent: 100, limit: 100), contains('reached'));
      expect(
          SpendingHelper.advice(spent: 130, limit: 100), contains('reached'));
    });
    test('gives reassuring message under threshold', () {
      expect(SpendingHelper.advice(spent: 30, limit: 100), contains('within'));
    });
    test('monthly expense sum ignores income and other months', () {
      final items = [
        MoneyTransaction(
            categoryId: 1,
            type: 'expense',
            amount: 25,
            date: DateTime(2026, 10, 18)),
        MoneyTransaction(
            categoryId: 1,
            type: 'expense',
            amount: 15,
            date: DateTime(2026, 10, 19)),
        MoneyTransaction(
            categoryId: 1,
            type: 'income',
            amount: 100,
            date: DateTime(2026, 10, 19)),
        MoneyTransaction(
            categoryId: 1,
            type: 'expense',
            amount: 50,
            date: DateTime(2026, 9, 19))
      ];
      expect(SpendingHelper.expenses(items, DateTime(2026, 10)), 40);
    });
  });
}
