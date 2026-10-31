import 'package:flutter_test/flutter_test.dart';
import 'package:pennypilot/services/budget_alert_service.dart';

void main() {
  const service = BudgetAlertService();

  group('Budget alerts', () {
    test('handles a missing budget', () {
      final alert = service.evaluate(spent: 50, budget: 0);

      expect(alert.level, BudgetAlertLevel.noBudget);
      expect(alert.progress, 0);
    });

    test('shows on-track status below 80 percent', () {
      final alert = service.evaluate(spent: 79, budget: 100);

      expect(alert.level, BudgetAlertLevel.onTrack);
      expect(alert.percentage, 79);
      expect(alert.remaining, 21);
    });

    test('warns at exactly 80 percent', () {
      final alert = service.evaluate(spent: 80, budget: 100);

      expect(alert.level, BudgetAlertLevel.approaching);
      expect(alert.progress, 0.8);
    });

    test('warns between 80 and 100 percent', () {
      final alert = service.evaluate(spent: 95, budget: 100);

      expect(alert.level, BudgetAlertLevel.approaching);
      expect(alert.remaining, 5);
    });

    test('identifies an exactly reached budget', () {
      final alert = service.evaluate(spent: 100, budget: 100);

      expect(alert.level, BudgetAlertLevel.exceeded);
      expect(alert.title, 'Budget limit reached');
      expect(alert.progress, 1);
    });

    test('identifies overspending', () {
      final alert = service.evaluate(spent: 125, budget: 100);

      expect(alert.level, BudgetAlertLevel.exceeded);
      expect(alert.remaining, -25);
      expect(alert.progress, 1);
      expect(alert.message, contains('25.00'));
    });

    test('handles negative spending safely', () {
      final alert = service.evaluate(spent: -20, budget: 100);

      expect(alert.level, BudgetAlertLevel.onTrack);
      expect(alert.percentage, 0);
      expect(alert.remaining, 100);
    });

    test('handles negative budgets safely', () {
      final alert = service.evaluate(spent: 20, budget: -100);

      expect(alert.level, BudgetAlertLevel.noBudget);
    });
  });
}
