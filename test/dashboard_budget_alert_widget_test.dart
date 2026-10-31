import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pennypilot/models/finance_models.dart';
import 'package:pennypilot/screens/dashboard_screen.dart';
import 'package:pennypilot/state/finance_state.dart';

void main() {
  late FinanceState financeState;

  setUp(() {
    financeState = FinanceState();
    financeState.monthlyBudget = 500;
    financeState.transactions = [];
  });

  tearDown(() {
    financeState.dispose();
  });

  void setSpending(double amount) {
    financeState.transactions = [
      MoneyTransaction(
        id: 1,
        categoryId: 1,
        type: 'expense',
        amount: amount,
        date: DateTime.now(),
        description: 'Test expense',
      ),
    ];
  }

  Future<void> openDashboard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<FinanceState>.value(
        value: financeState,
        child: MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              onAdd: () {},
              onHistory: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  LinearProgressIndicator progressIndicator(
    WidgetTester tester,
  ) {
    return tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('monthly-budget-progress')),
    );
  }

  group('Dashboard budget alert widget tests', () {
    testWidgets('shows on-track alert below 80 percent', (
      tester,
    ) async {
      setSpending(200);

      await openDashboard(tester);

      expect(find.text('Budget on track'), findsOneWidget);
      expect(find.text('40% used'), findsOneWidget);
      expect(progressIndicator(tester).value, 0.4);
      expect(
        find.byKey(const Key('budget-alert-card')),
        findsOneWidget,
      );
    });

    testWidgets('shows approaching alert at 80 percent', (
      tester,
    ) async {
      setSpending(400);

      await openDashboard(tester);

      expect(
        find.text('Approaching budget limit'),
        findsOneWidget,
      );
      expect(find.text('80% used'), findsOneWidget);
      expect(progressIndicator(tester).value, 0.8);
      expect(
        progressIndicator(tester).color,
        Colors.amber,
      );
    });

    testWidgets('shows reached alert at exactly 100 percent', (
      tester,
    ) async {
      setSpending(500);

      await openDashboard(tester);

      expect(
        find.text('Budget limit reached'),
        findsOneWidget,
      );
      expect(find.text('100% used'), findsOneWidget);
      expect(progressIndicator(tester).value, 1.0);
      expect(
        progressIndicator(tester).color,
        Colors.redAccent,
      );
    });

    testWidgets('shows overspending alert above 100 percent', (
      tester,
    ) async {
      setSpending(650);

      await openDashboard(tester);

      expect(find.text('Over budget'), findsOneWidget);
      expect(find.text('130% used'), findsOneWidget);
      expect(find.text('\$150.00 over'), findsOneWidget);

      // The progress bar must never exceed its valid range.
      expect(progressIndicator(tester).value, 1.0);
      expect(
        progressIndicator(tester).color,
        Colors.redAccent,
      );
    });

    testWidgets('prompts user when monthly budget is zero', (
      tester,
    ) async {
      financeState.monthlyBudget = 0;

      await openDashboard(tester);

      expect(
        find.text('Set your monthly budget'),
        findsOneWidget,
      );
      expect(find.text('0% used'), findsOneWidget);
      expect(progressIndicator(tester).value, 0.0);
    });

    testWidgets('shows empty transaction state', (
      tester,
    ) async {
      await openDashboard(tester);

      expect(
        find.text('No transactions yet'),
        findsOneWidget,
      );
      expect(find.text('Budget on track'), findsOneWidget);
    });
  });
}
