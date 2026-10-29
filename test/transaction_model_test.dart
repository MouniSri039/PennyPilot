import 'package:flutter_test/flutter_test.dart';
import 'package:pennypilot/models/finance_models.dart';

void main() {
  test('Income transaction round trips with deposit destination', () {
    final t = MoneyTransaction(
      categoryId: 3,
      type: 'income',
      amount: 750,
      date: DateTime(2026, 9, 30),
      description: 'Salary',
      paymentMethod: 'Direct Deposit',
      receivedInto: 'Bank Account',
    );
    final restored = MoneyTransaction.fromMap({...t.toMap(), 'id': 12});
    expect(restored.paymentMethod, 'Direct Deposit');
    expect(restored.receivedInto, 'Bank Account');
    expect(restored.amount, 750);
  });
  test('Older transactions without received_into still load', () {
    final t = MoneyTransaction.fromMap({
      'id': 1,
      'category_id': 2,
      'type': 'expense',
      'amount': 10.0,
      'date': '2026-10-29T12:00:00.000',
      'description': 'Lunch',
      'payment_method': 'Cash',
    });
    expect(t.receivedInto, isEmpty);
  });
  test('Category kind survives mapping', () {
    final c = BudgetCategory(name: 'Salary', kind: 'income');
    final restored = BudgetCategory.fromMap({
      ...c.toMap(),
      'id': 7,
    });
    expect(restored.kind, 'income');
  });
}
