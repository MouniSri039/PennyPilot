import 'package:flutter_test/flutter_test.dart';
import 'package:pennypilot/services/spending_helper.dart';

// Five held-out valid examples for the rule-based helper. These are new
// examples, distinct from the five cases described in AI_FEATURE.md.
// Ground truth is the expected budget-status category under the stated policy.
String label(String message) {
  if (message.startsWith('You have reached')) return 'limit_reached';
  if (message.startsWith('You have used')) return 'approaching';
  if (message.startsWith('You are within')) return 'on_track';
  return 'other';
}

void main() {
  final cases = <({String id, double spent, double budget, String expected})>[
    (id: 'H1', spent: 125, budget: 500, expected: 'on_track'),
    (id: 'H2', spent: 395, budget: 500, expected: 'on_track'),
    (id: 'H3', spent: 401, budget: 500, expected: 'approaching'),
    (id: 'H4', spent: 490, budget: 500, expected: 'approaching'),
    (id: 'H5', spent: 525, budget: 500, expected: 'limit_reached'),
  ];

  test('held-out comparison: helper versus constant-message baseline', () {
    var helperCorrect = 0;
    var baselineCorrect = 0;
    for (final item in cases) {
      final actual = label(SpendingHelper.advice(
        spent: item.spent,
        limit: item.budget,
      ));
      final baseline = label(SpendingHelper.baseline());
      if (actual == item.expected) helperCorrect++;
      if (baseline == item.expected) baselineCorrect++;
      // Each case must match the stated policy, not merely aggregate accuracy.
      expect(actual, item.expected, reason: item.id);
    }
    expect(helperCorrect, 5);
    expect(baselineCorrect, 0);
  });
}
