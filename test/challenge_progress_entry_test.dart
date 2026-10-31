import 'package:flutter_test/flutter_test.dart';
import 'package:pennypilot/models/finance_models.dart';

void main() {
  group('ChallengeProgressEntry', () {
    final recordedAt = DateTime.parse('2026-10-31T09:30:00.000');

    test('serializes contribution fields to a database map', () {
      final entry = ChallengeProgressEntry(
        challengeId: 12,
        amount: 25.50,
        recordedAt: DateTime(2026, 10, 31, 9, 30),
      );

      expect(entry.toMap(), {
        'challenge_id': 12,
        'amount': 25.50,
        'recorded_at': recordedAt.toIso8601String(),
      });
    });

    test('creates an entry from a database row', () {
      final entry = ChallengeProgressEntry.fromMap({
        'id': 7,
        'challenge_id': 12,
        'amount': 25.50,
        'recorded_at': recordedAt.toIso8601String(),
      });

      expect(entry.id, 7);
      expect(entry.challengeId, 12);
      expect(entry.amount, 25.50);
      expect(entry.recordedAt, recordedAt);
    });

    test('supports a not-yet-persisted entry without an id', () {
      final entry = ChallengeProgressEntry(
        challengeId: 3,
        amount: 10,
        recordedAt: recordedAt,
      );

      expect(entry.id, isNull);
      expect(entry.toMap().containsKey('id'), isFalse);
    });
  });
}
