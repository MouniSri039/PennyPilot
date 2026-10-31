

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
        status: 'finished',
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
      await tester.ensureVisible(finder.first);
      await tester.pumpAndSettle();
      return;
    }

    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.pumpAndSettle();
  }

  Future<Finder> challengeButton(
    WidgetTester tester,
    String title,
    String buttonLabel,
  ) async {
    await scrollToText(tester, title);

    final card = find.ancestor(
      of: find.text(title),
      matching: find.byType(Card),
    );

    if (card.evaluate().isEmpty) {
      throw TestFailure('Challenge card not found: $title');
    }

    final button = find.descendant(
      of: card.first,
      matching: find.widgetWithText(TextButton, buttonLabel),
    );

    if (button.evaluate().isEmpty) {
      throw TestFailure(
        'Button "$buttonLabel" not found for "$title".',
      );
    }

    return button.first;
  }

  group('Savings Challenge Screen', () {
    testWidgets('displays screen title and main controls', (tester) async {
      await pumpChallengeScreen(tester);

      expect(find.text('Savings Challenges'), findsOneWidget);
      expect(find.text('Start Challenge'), findsOneWidget);
      expect(find.text('Filter challenges'), findsOneWidget);
      expect(find.text('Sort by'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(3));
      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Active'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Completed'), findsOneWidget);
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

    testWidgets('displays challenge summary section', (tester) async {
      await pumpChallengeScreen(tester);

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);
    });

    testWidgets('displays progress indicators', (tester) async {
      await pumpChallengeScreen(tester);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('filters active challenges correctly', (tester) async {
      await pumpChallengeScreen(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Active'));
      await tester.pumpAndSettle();

      await scrollToText(tester, 'Emergency Fund');
      expect(find.text('Emergency Fund'), findsOneWidget);

      await scrollToText(tester, 'Vacation');
      expect(find.text('Vacation'), findsOneWidget);

      expect(find.text('New Laptop'), findsNothing);
    });

    testWidgets('filters completed challenges correctly', (tester) async {
      await pumpChallengeScreen(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
      await tester.pumpAndSettle();

      expect(find.text('New Laptop'), findsOneWidget);
      expect(find.text('Emergency Fund'), findsNothing);
      expect(find.text('Vacation'), findsNothing);
    });

    testWidgets('returns to all challenges after selecting All',
        (tester) async {
      await pumpChallengeScreen(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();

      await scrollToText(tester, 'Emergency Fund');
      expect(find.text('Emergency Fund'), findsOneWidget);

      await scrollToText(tester, 'New Laptop');
      expect(find.text('New Laptop'), findsOneWidget);

      await scrollToText(tester, 'Vacation');
      expect(find.text('Vacation'), findsOneWidget);
    });

    testWidgets('sort dropdown displays sorting options', (tester) async {
      await pumpChallengeScreen(tester);

      final dropdown = find.byType(DropdownButton<ChallengeSort>);
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      expect(find.text('Name A–Z'), findsOneWidget);
      expect(find.text('Highest target'), findsOneWidget);
    });

    testWidgets('allows selecting name sorting', (tester) async {
      await pumpChallengeScreen(tester);

      await tester.tap(find.byType(DropdownButton<ChallengeSort>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Name A–Z').last);
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<ChallengeSort>>(
        find.byType(DropdownButton<ChallengeSort>),
      );

      expect(dropdown.value, ChallengeSort.name);
    });

    testWidgets('allows selecting target sorting', (tester) async {
      await pumpChallengeScreen(tester);

      await tester.tap(find.byType(DropdownButton<ChallengeSort>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Highest target'));
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<ChallengeSort>>(
        find.byType(DropdownButton<ChallengeSort>),
      );

      expect(dropdown.value, ChallengeSort.target);
    });

    testWidgets('shows empty state when no challenges exist', (tester) async {
      financeState.challenges = [];

      await pumpChallengeScreen(tester);

      expect(find.text('No challenges yet'), findsOneWidget);
      expect(
        find.text('Start your first savings challenge.'),
        findsOneWidget,
      );
    });

    testWidgets('shows empty state when no active challenges exist',
        (tester) async {
      financeState.challenges = [
        const SavingsChallenge(
          id: 10,
          title: 'Finished Goal',
          target: 500,
          saved: 500,
          status: 'finished',
        ),
      ];

      await pumpChallengeScreen(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Active'));
      await tester.pumpAndSettle();

      expect(find.text('No active challenges'), findsOneWidget);
      expect(
        find.text('All your current challenges are completed.'),
        findsOneWidget,
      );
    });

    testWidgets('shows empty state when no completed challenges exist',
        (tester) async {
      financeState.challenges = [
        const SavingsChallenge(
          id: 11,
          title: 'Active Goal',
          target: 500,
          saved: 100,
          status: 'active',
        ),
      ];

      await pumpChallengeScreen(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
      await tester.pumpAndSettle();

      expect(find.text('No completed challenges'), findsOneWidget);
      expect(
        find.text('Complete a savings goal to see it here.'),
        findsOneWidget,
      );
    });

    testWidgets('opens challenge creation form', (tester) async {
      await pumpChallengeScreen(tester);

      await tester.tap(find.text('Start Challenge'));
      await tester.pumpAndSettle();

      expect(find.text('Start a savings challenge'), findsOneWidget);
      expect(find.text('Challenge name'), findsOneWidget);
      expect(find.text('Target amount'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('challenge creation form has default values', (tester) async {
      await pumpChallengeScreen(tester);

      await tester.tap(find.text('Start Challenge'));
      await tester.pumpAndSettle();

      final fields = tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      ).toList();

      expect(fields.length, 2);
      expect(fields[0].initialValue, '7-day savings challenge');
      expect(fields[1].initialValue, '50');
    });

    testWidgets('validates empty challenge name', (tester) async {
      await pumpChallengeScreen(tester);

      await tester.tap(find.text('Start Challenge'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '');

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a challenge name'), findsOneWidget);
    });

    testWidgets('validates short challenge name', (tester) async {
      await pumpChallengeScreen(tester);

      await tester.tap(find.text('Start Challenge'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'AB');

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(find.text('Use at least 3 characters'), findsOneWidget);
    });

    testWidgets('validates invalid challenge target', (tester) async {
      await pumpChallengeScreen(tester);

      await tester.tap(find.text('Start Challenge'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).last, '0');

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter a valid positive amount'),
        findsOneWidget,
      );
    });

    testWidgets('validates non-numeric challenge target', (tester) async {
      await pumpChallengeScreen(tester);

      await tester.tap(find.text('Start Challenge'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).last, 'abc');

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter a valid positive amount'),
        findsOneWidget,
      );
    });

    testWidgets('closes challenge form when Cancel is selected',
        (tester) async {
      await pumpChallengeScreen(tester);

      await tester.tap(find.text('Start Challenge'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Start a savings challenge'), findsNothing);
    });

    testWidgets('opens edit form for an existing challenge', (tester) async {
      await pumpChallengeScreen(tester);

      final button =
          await challengeButton(tester, 'Emergency Fund', 'Edit');

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Edit challenge'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
    });

    testWidgets('edit form loads existing challenge values', (tester) async {
      await pumpChallengeScreen(tester);

      final button =
          await challengeButton(tester, 'Emergency Fund', 'Edit');

      await tester.tap(button);
      await tester.pumpAndSettle();

      final fields = tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      ).toList();

      expect(fields.length, 2);
      expect(fields[0].initialValue, 'Emergency Fund');
      expect(fields[1].initialValue, '1000.0');
    });

    testWidgets('closes edit form when Cancel is selected', (tester) async {
      await pumpChallengeScreen(tester);

      final button =
          await challengeButton(tester, 'Emergency Fund', 'Edit');

      await tester.tap(button);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Edit challenge'), findsNothing);
    });

    testWidgets('opens add progress form for active challenge',
        (tester) async {
      await pumpChallengeScreen(tester);

      final button =
          await challengeButton(tester, 'Emergency Fund', 'Add progress');

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Add savings progress'), findsOneWidget);
      expect(find.text('Amount saved'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('validates empty progress amount', (tester) async {
      await pumpChallengeScreen(tester);

      final button =
          await challengeButton(tester, 'Emergency Fund', 'Add progress');

      await tester.tap(button);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter a valid positive amount'),
        findsOneWidget,
      );
    });

    testWidgets('validates non-positive progress amount', (tester) async {
      await pumpChallengeScreen(tester);

      final button =
          await challengeButton(tester, 'Emergency Fund', 'Add progress');

      await tester.tap(button);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '-10');

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter a valid positive amount'),
        findsOneWidget,
      );
    });

    testWidgets('closes progress form when Cancel is selected',
        (tester) async {
      await pumpChallengeScreen(tester);

      final button =
          await challengeButton(tester, 'Emergency Fund', 'Add progress');

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Add savings progress'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Add savings progress'), findsNothing);
    });

    testWidgets('completed challenge cannot receive progress',
        (tester) async {
      await pumpChallengeScreen(tester);

      final button =
          await challengeButton(tester, 'New Laptop', 'Add progress');

      final widget = tester.widget<TextButton>(button);

      expect(widget.onPressed, isNull);
    });
  });
}
