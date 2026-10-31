import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pennypilot/models/finance_models.dart';
import 'package:pennypilot/screens/history_screen.dart';
import 'package:pennypilot/state/finance_state.dart';

void main() {
  late FinanceState financeState;
  late DateTime currentMonth;

  setUp(() {
    currentMonth = DateTime.now();
    financeState = FinanceState();

    financeState.categories = const [
      BudgetCategory(id: 1, name: 'Food'),
      BudgetCategory(id: 2, name: 'Transport'),
      BudgetCategory(id: 3, name: 'Salary', kind: 'income'),
    ];

    financeState.transactions = [
      MoneyTransaction(
        id: 1,
        categoryId: 1,
        type: 'expense',
        amount: 25,
        date: DateTime(currentMonth.year, currentMonth.month, 5),
        description: 'Grocery Shopping',
      ),
      MoneyTransaction(
        id: 2,
        categoryId: 2,
        type: 'expense',
        amount: 15,
        date: DateTime(currentMonth.year, currentMonth.month, 6),
        description: 'Bus Ticket',
      ),
      MoneyTransaction(
        id: 3,
        categoryId: 3,
        type: 'income',
        amount: 1500,
        date: DateTime(currentMonth.year, currentMonth.month, 7),
        description: 'Monthly Pay',
      ),
      MoneyTransaction(
        id: 4,
        categoryId: 3,
        type: 'income',
        amount: 200,
        date: DateTime(currentMonth.year, currentMonth.month, 8),
        description: 'Freelance Payment',
      ),
      MoneyTransaction(
        id: 5,
        categoryId: 1,
        type: 'expense',
        amount: 40,
        date: DateTime(currentMonth.year, currentMonth.month - 1, 8),
        description: 'Previous Grocery',
      ),
    ];
  });

  tearDown(() {
    financeState.dispose();
  });

  Future<void> openHistory(WidgetTester tester) async {
    // Keep the chart and transaction list visible during tests.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<FinanceState>.value(
        value: financeState,
        child: const MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> selectType(
    WidgetTester tester,
    String type,
  ) async {
    final filter = find.byKey(
      const Key('transaction-type-filter'),
    );

    await tester.ensureVisible(filter);
    await tester.pumpAndSettle();

    final label = switch (type) {
      'income' => 'Income',
      'expense' => 'Expense',
      _ => 'All',
    };

    final button = find.descendant(
      of: filter,
      matching: find.text(label),
    );

    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> search(
    WidgetTester tester,
    String query,
  ) async {
    final searchField = find.byKey(
      const Key('transaction-search'),
    );

    await tester.ensureVisible(searchField);
    await tester.pumpAndSettle();

    await tester.enterText(searchField, query);
    await tester.pumpAndSettle();
  }

  group('History transaction type filter', () {
    testWidgets(
      'displays all current-month transactions by default',
      (tester) async {
        await openHistory(tester);

        expect(find.text('Grocery Shopping'), findsOneWidget);
        expect(find.text('Bus Ticket'), findsOneWidget);
        expect(find.text('Monthly Pay'), findsOneWidget);
        expect(find.text('Freelance Payment'), findsOneWidget);
        expect(find.text('Previous Grocery'), findsNothing);
      },
    );

    testWidgets(
      'income filter displays only income transactions',
      (tester) async {
        await openHistory(tester);
        await selectType(tester, 'income');

        expect(find.text('Monthly Pay'), findsOneWidget);
        expect(find.text('Freelance Payment'), findsOneWidget);
        expect(find.text('Grocery Shopping'), findsNothing);
        expect(find.text('Bus Ticket'), findsNothing);
        expect(
          find.text('2 matching transaction(s)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'expense filter displays only expense transactions',
      (tester) async {
        await openHistory(tester);
        await selectType(tester, 'expense');

        expect(find.text('Grocery Shopping'), findsOneWidget);
        expect(find.text('Bus Ticket'), findsOneWidget);
        expect(find.text('Monthly Pay'), findsNothing);
        expect(find.text('Freelance Payment'), findsNothing);
        expect(
          find.text('2 matching transaction(s)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'switching back to All restores transactions',
      (tester) async {
        await openHistory(tester);

        await selectType(tester, 'income');
        expect(find.text('Grocery Shopping'), findsNothing);

        await selectType(tester, 'all');

        expect(find.text('Grocery Shopping'), findsOneWidget);
        expect(find.text('Bus Ticket'), findsOneWidget);
        expect(find.text('Monthly Pay'), findsOneWidget);
        expect(find.text('Freelance Payment'), findsOneWidget);
        expect(
          find.text('2 matching transaction(s)'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'type filtering works together with transaction search',
      (tester) async {
        await openHistory(tester);

        await search(tester, 'pay');
        await selectType(tester, 'income');

        expect(find.text('Monthly Pay'), findsOneWidget);
        expect(find.text('Freelance Payment'), findsOneWidget);
        expect(find.text('Grocery Shopping'), findsNothing);
        expect(find.text('Bus Ticket'), findsNothing);
        expect(
          find.text('2 matching transaction(s)'),
          findsOneWidget,
        );

        await selectType(tester, 'expense');

        expect(find.text('Monthly Pay'), findsNothing);
        expect(find.text('Freelance Payment'), findsNothing);
        expect(
          find.text('No matching transactions'),
          findsOneWidget,
        );
        expect(
          find.text('0 matching transaction(s)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'type filtering preserves the monthly summary',
      (tester) async {
        await openHistory(tester);

        // Four transactions belong to the current month.
        expect(find.text('4'), findsOneWidget);

        await selectType(tester, 'income');

        // The summary remains based on all monthly transactions.
        expect(find.text('4'), findsOneWidget);
        expect(
          find.text('2 matching transaction(s)'),
          findsOneWidget,
        );

        await selectType(tester, 'expense');

        expect(find.text('4'), findsOneWidget);
        expect(
          find.text('2 matching transaction(s)'),
          findsOneWidget,
        );
      },
    );
  });
}
