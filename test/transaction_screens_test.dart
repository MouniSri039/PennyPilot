import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pennypilot/models/finance_models.dart';
import 'package:pennypilot/state/finance_state.dart';
import 'package:pennypilot/screens/transaction_form_screen.dart';
import 'package:pennypilot/screens/transaction_detail_screen.dart';

void main() {
  late FinanceState state;

  setUp(() {
    state = FinanceState();
    state.categories = [
      const BudgetCategory(
        id: 1,
        name: 'Food',
        kind: 'expense',
      ),
      const BudgetCategory(
        id: 2,
        name: 'Salary',
        kind: 'income',
      ),
    ];
  });

  Widget app(Widget screen) {
    return ChangeNotifierProvider<FinanceState>.value(
      value: state,
      child: MaterialApp(home: screen),
    );
  }

  group('Transaction form screen', () {
    testWidgets('displays required form fields', (tester) async {
      await tester.pumpWidget(app(const TransactionFormScreen()));

      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.text('Amount (USD)'), findsOneWidget);
      expect(find.text('Description / Notes'), findsOneWidget);
      expect(find.text('Save Transaction'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('switches from expense to income fields', (tester) async {
      await tester.pumpWidget(app(const TransactionFormScreen()));

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Income').last);
      await tester.pumpAndSettle();

      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Received Via'), findsOneWidget);
      expect(
          find.text('Deposited To / Received In (Optional)'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty submission', (tester) async {
      await tester.pumpWidget(app(const TransactionFormScreen()));

      await tester.tap(find.text('Save Transaction'));
      await tester.pumpAndSettle();

      expect(find.text('Enter an amount'), findsOneWidget);
    });
  });

  group('Transaction detail screen', () {
    testWidgets('displays expense details and empty notes', (tester) async {
      final transaction = MoneyTransaction(
        id: 1,
        categoryId: 1,
        type: 'expense',
        amount: 25,
        date: DateTime(2026, 10, 20),
        description: '',
        paymentMethod: 'Debit Card',
      );

      await tester.pumpWidget(
        app(TransactionDetailScreen(transaction: transaction)),
      );

      expect(find.text('Transaction Detail'), findsOneWidget);
      expect(find.text('Food'), findsWidgets);
      expect(find.text('-\$25.00'), findsOneWidget);
      expect(find.text('Paid Via'), findsOneWidget);
      expect(find.text('Debit Card'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);
    });

    testWidgets('displays income destination and notes', (tester) async {
      final transaction = MoneyTransaction(
        id: 2,
        categoryId: 2,
        type: 'income',
        amount: 1500,
        date: DateTime(2026, 10, 20),
        description: 'Monthly salary',
        paymentMethod: 'Direct Deposit',
        receivedInto: 'Bank Account',
      );

      await tester.pumpWidget(
        app(TransactionDetailScreen(transaction: transaction)),
      );

      expect(find.text('+\$1,500.00'), findsOneWidget);
      expect(find.text('Received Via'), findsOneWidget);
      expect(find.text('Direct Deposit'), findsOneWidget);
      expect(find.text('Deposited To / Received In'), findsOneWidget);
      expect(find.text('Bank Account'), findsOneWidget);
      expect(find.text('Monthly salary'), findsOneWidget);
    });
  });
}
