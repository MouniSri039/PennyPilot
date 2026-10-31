import 'package:flutter_test/flutter_test.dart';
import 'package:pennypilot/models/finance_models.dart';
import 'package:pennypilot/services/transaction_csv_service.dart';

void main() {
  const service = TransactionCsvService();

  const categories = [
    BudgetCategory(id: 1, name: 'Food'),
    BudgetCategory(id: 2, name: 'Salary', kind: 'income'),
  ];

  MoneyTransaction transaction({
    int? id,
    int categoryId = 1,
    String type = 'expense',
    double amount = 25.5,
    String description = 'Lunch',
    String paymentMethod = 'Cash',
    String receivedInto = '',
    DateTime? date,
  }) {
    return MoneyTransaction(
      id: id,
      categoryId: categoryId,
      type: type,
      amount: amount,
      date: date ?? DateTime(2026, 10, 31),
      description: description,
      paymentMethod: paymentMethod,
      receivedInto: receivedInto,
    );
  }

  group('Transaction CSV export', () {
    test('exports a header when there are no transactions', () {
      final csv = service.generate(
        transactions: [],
        categories: categories,
      );

      expect(csv, '${TransactionCsvService.header}\r\n');
    });

    test('exports expense transaction fields correctly', () {
      final csv = service.generate(
        transactions: [transaction()],
        categories: categories,
      );

      expect(
        csv,
        contains('2026-10-31,expense,Food,25.50,Lunch,Cash,'),
      );
    });

    test('exports income and received-into account', () {
      final csv = service.generate(
        transactions: [
          transaction(
            categoryId: 2,
            type: 'income',
            amount: 1500,
            description: 'October salary',
            receivedInto: 'Checking',
          ),
        ],
        categories: categories,
      );

      expect(
        csv,
        contains(
          '2026-10-31,income,Salary,1500.00,'
          'October salary,Cash,Checking',
        ),
      );
    });

    test('escapes commas and quotation marks', () {
      final csv = service.generate(
        transactions: [
          transaction(description: 'Lunch, "special"'),
        ],
        categories: categories,
      );

      expect(csv, contains('"Lunch, ""special"""'));
    });

    test('preserves multiline descriptions', () {
      final csv = service.generate(
        transactions: [
          transaction(description: 'Lunch\nwith friends'),
        ],
        categories: categories,
      );

      expect(csv, contains('"Lunch\nwith friends"'));
    });

    test('protects against spreadsheet formula injection', () {
      final csv = service.generate(
        transactions: [
          transaction(description: '=SUM(1,2)'),
        ],
        categories: categories,
      );

      expect(csv, contains('"\'=SUM(1,2)"'));
    });

    test('uses Unknown for missing categories', () {
      final csv = service.generate(
        transactions: [
          transaction(categoryId: 999),
        ],
        categories: categories,
      );

      expect(csv, contains(',Unknown,25.50,'));
    });

    test('sorts newest transactions first', () {
      final csv = service.generate(
        transactions: [
          transaction(
            description: 'Older',
            date: DateTime(2026, 9, 1),
          ),
          transaction(
            description: 'Newer',
            date: DateTime(2026, 10, 31),
          ),
        ],
        categories: categories,
      );

      expect(csv.indexOf('Newer'), lessThan(csv.indexOf('Older')));
    });

    test('does not modify the original transaction list', () {
      final transactions = [
        transaction(id: 1, date: DateTime(2026, 9, 1)),
        transaction(id: 2, date: DateTime(2026, 10, 31)),
      ];

      service.generate(
        transactions: transactions,
        categories: categories,
      );

      expect(transactions.first.id, 1);
      expect(transactions.last.id, 2);
    });
  });
}
