import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pennypilot/models/finance_models.dart';
import 'package:pennypilot/state/finance_state.dart';
import 'package:pennypilot/screens/challenge_screen.dart';

void main() {
  late FinanceState financeState;

  setUp(() {
    financeState = FinanceState();

    financeState.challenges = [
      const SavingsChallenge(
        id: 1,
        title: 'Emergency Fund',
        target: 1000,
        saved: 200,
        status: 'active',
      ),
      const SavingsChallenge(
        id: 2,
        title: 'New Laptop',
        target: 2000,
        saved: 2000,
        status: 'completed',
      ),
      const SavingsChallenge(
        id: 3,
        title: 'Vacation',
        target: 500,
        saved: 350,
        status: 'active',
      ),
    ];
  });

  Future<void> pumpChallengeScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<FinanceState>.value(
        value: financeState,
        child: const MaterialApp(
          home: ChallengeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> scrollToText(
    WidgetTester tester,
    String text,
  ) async {
    final finder = find.text(text);

    if (finder.evaluate().isNotEmpty) {
      return;
    }

    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.pumpAndSettle();
  }

  group('Savings Challenge Screen', () {
    testWidgets('displays the screen title and main controls', (tester) async {
      await pumpChallengeScreen(tester);

      expect(find.text('Savings Challenges'), findsOneWidget);
      expect(find.text('Start Challenge'), findsOneWidget);
      expect(find.text('Filter challenges'), findsOneWidget);
      expect(find.text('Sort by'), findsOneWidget);

      expect(find.byType(ChoiceChip), findsNWidgets(3));

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Active'), findsNWidgets(3));
      expect(find.text('Completed'), findsNWidgets(2));
    });

    testWidgets('displays all saved challenge titles', (tester) async {
      await pumpChallengeScreen(tester);

      await scrollToText(tester, 'Emergency Fund');
      expect(find.text('Emergency Fund'), findsOneWidget);

      await scrollToText(tester, 'New Laptop');
      expect(find.text('New Laptop'), findsOneWidget);

      await scrollToText(tester, 'Vacation');
      expect(find.text('Vacation'), findsOneWidget);
    });

    testWidgets('displays the challenge summary section', (tester) async {
      await pumpChallengeScreen(tester);

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Active').first, findsOneWidget);
      expect(find.text('Completed').first, findsOneWidget);
    });

    testWidgets('displays progress indicators for challenges', (tester) async {
      await pumpChallengeScreen(tester);

      expect(
        find.byType(LinearProgressIndicator),
        findsWidgets,
      );
    });
  });
}
