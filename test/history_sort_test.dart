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
        date: DateTime(currentMonth.year, currentMonth.month, 10),
        description: 'Bus Ticket',
      ),
      MoneyTransaction(
        id: 3,
        categoryId: 3,
        type: 'income',
        amount: 1500,
        date: DateTime(currentMonth.year, currentMonth.month, 15),
        description: 'Monthly Pay',
      ),
      MoneyTransaction(
        id: 4,
        categoryId: 3,
        type: 'income',
        amount: 200,
        date: DateTime(currentMonth.year, currentMonth.month, 20),
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
    tester.view.physicalSize = const Size(800, 1800);
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

  Future<void> selectSort(
    WidgetTester tester,
    String option,
  ) async {
    final dropdown = find.byKey(
      const Key('transaction-sort'),
    );

    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();

    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    await tester.tap(find.text(option).last);
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

  List<String> visibleTransactionOrder(WidgetTester tester) {
    final descriptions = [
      'Grocery Shopping',
      'Bus Ticket',
      'Monthly Pay',
      'Freelance Payment',
    ];

    final visible = <String>[];

    for (final element in find.byType(ListTile).evaluate()) {
      final tile = element.widget as ListTile;
      final title = tile.title;

      if (title is Text) {
        final value = title.data;

        if (value != null && descriptions.contains(value)) {
          visible.add(value);
        }
      }
    }

    return visible;
  }

  group('History transaction sorting', () {
    testWidgets(
      'defaults to newest first',
      (tester) async {
        await openHistory(tester);

        expect(
          visibleTransactionOrder(tester),
          [
            'Freelance Payment',
            'Monthly Pay',
            'Bus Ticket',
            'Grocery Shopping',
          ],
        );

        expect(
          find.text('Previous Grocery'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'sorts transactions oldest first',
      (tester) async {
        await openHistory(tester);
        await selectSort(tester, 'Oldest first');

        expect(
          visibleTransactionOrder(tester),
          [
            'Grocery Shopping',
            'Bus Ticket',
            'Monthly Pay',
            'Freelance Payment',
          ],
        );
      },
    );

    testWidgets(
      'sorts transactions highest amount first',
      (tester) async {
        await openHistory(tester);
        await selectSort(tester, 'Highest amount first');

        expect(
          visibleTransactionOrder(tester),
          [
            'Monthly Pay',
            'Freelance Payment',
            'Grocery Shopping',
            'Bus Ticket',
          ],
        );
      },
    );

    testWidgets(
      'sorts transactions lowest amount first',
      (tester) async {
        await openHistory(tester);
        await selectSort(tester, 'Lowest amount first');

        expect(
          visibleTransactionOrder(tester),
          [
            'Bus Ticket',
            'Grocery Shopping',
            'Freelance Payment',
            'Monthly Pay',
          ],
        );
      },
    );

    testWidgets(
      'sorting works with income filtering',
      (tester) async {
        await openHistory(tester);
        await selectType(tester, 'income');
        await selectSort(tester, 'Highest amount first');

        expect(
          visibleTransactionOrder(tester),
          [
            'Monthly Pay',
            'Freelance Payment',
          ],
        );

        expect(
          find.text('2 matching transaction(s)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'sorting works with transaction search',
      (tester) async {
        await openHistory(tester);
        await search(tester, 'pay');
        await selectSort(tester, 'Oldest first');

        expect(
          visibleTransactionOrder(tester),
          [
            'Monthly Pay',
            'Freelance Payment',
          ],
        );

        expect(
          find.text('2 matching transaction(s)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'sorting preserves the monthly financial summary',
      (tester) async {
        await openHistory(tester);

        // Four transactions belong to the selected month.
        expect(find.text('4'), findsOneWidget);

        await selectSort(tester, 'Lowest amount first');

        expect(find.text('4'), findsOneWidget);

        await selectSort(tester, 'Highest amount first');

        expect(find.text('4'), findsOneWidget);

        await selectType(tester, 'expense');

        // Type filtering and sorting do not alter monthly totals.
        expect(find.text('4'), findsOneWidget);
        expect(
          find.text('2 matching transaction(s)'),
          findsOneWidget,
        );
      },
    );
  });
}
