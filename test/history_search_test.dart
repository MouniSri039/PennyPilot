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
    // Provide enough screen height to display all test transactions.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;

    // Restore the default viewport after each test.
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

  group('History transaction search', () {
    testWidgets(
      'displays current-month transactions initially',
      (tester) async {
        await openHistory(tester);

        expect(find.text('Grocery Shopping'), findsOneWidget);
        expect(find.text('Bus Ticket'), findsOneWidget);
        expect(find.text('Monthly Pay'), findsOneWidget);
        expect(find.text('Previous Grocery'), findsNothing);
      },
    );

    testWidgets(
      'searches descriptions case-insensitively',
      (tester) async {
        await openHistory(tester);
        await search(tester, 'gRoCeRy');

        expect(find.text('Grocery Shopping'), findsOneWidget);
        expect(find.text('Bus Ticket'), findsNothing);
        expect(find.text('Monthly Pay'), findsNothing);
        expect(
          find.text('1 matching transaction(s)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'searches category names case-insensitively',
      (tester) async {
        await openHistory(tester);
        await search(tester, 'TRANSPORT');

        expect(find.text('Bus Ticket'), findsOneWidget);
        expect(find.text('Grocery Shopping'), findsNothing);
        expect(find.text('Monthly Pay'), findsNothing);
      },
    );

    testWidgets(
      'trims surrounding whitespace in search',
      (tester) async {
        await openHistory(tester);
        await search(tester, '  monthly pay  ');

        expect(find.text('Monthly Pay'), findsOneWidget);
        expect(find.text('Bus Ticket'), findsNothing);
      },
    );

    testWidgets(
      'shows empty state when no transactions match',
      (tester) async {
        await openHistory(tester);
        await search(tester, 'unmatched description');

        expect(
          find.text('No matching transactions'),
          findsOneWidget,
        );
        expect(
          find.text('0 matching transaction(s)'),
          findsOneWidget,
        );
        expect(find.text('Grocery Shopping'), findsNothing);
      },
    );

    testWidgets(
      'clearing search restores transactions',
      (tester) async {
        await openHistory(tester);

        await search(tester, 'grocery');

        expect(find.text('Grocery Shopping'), findsOneWidget);
        expect(find.text('Bus Ticket'), findsNothing);

        await search(tester, '');

        expect(find.text('Grocery Shopping'), findsOneWidget);
        expect(find.text('Bus Ticket'), findsOneWidget);
        expect(find.text('Monthly Pay'), findsOneWidget);
      },
    );

    testWidgets(
      'search excludes transactions from another month',
      (tester) async {
        await openHistory(tester);
        await search(tester, 'grocery');

        expect(find.text('Grocery Shopping'), findsOneWidget);
        expect(find.text('Previous Grocery'), findsNothing);
        expect(
          find.text('1 matching transaction(s)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'search preserves monthly financial summary',
      (tester) async {
        await openHistory(tester);

        // Three transactions exist in the current month.
        expect(find.text('3'), findsOneWidget);

        await search(tester, 'bus');

        expect(find.text('Bus Ticket'), findsOneWidget);
        expect(find.text('Grocery Shopping'), findsNothing);

        // Search must not change the monthly transaction count.
        expect(find.text('3'), findsOneWidget);
        expect(
          find.text('1 matching transaction(s)'),
          findsOneWidget,
        );
      },
    );
  });
}
