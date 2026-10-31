import 'package:flutter_test/flutter_test.dart';
import 'package:pennypilot/models/finance_models.dart';
import 'package:pennypilot/services/challenge_csv_export_service.dart';

void main() {
  group('ChallengeCsvExportService.toCsv', () {
    test('writes the header and challenge financial fields', () {
      final csv = ChallengeCsvExportService.toCsv([
        const SavingsChallenge(
          id: 7,
          title: 'Emergency Fund',
          target: 500,
          saved: 125,
          status: 'active',
        ),
      ]);

      expect(csv, contains('Challenge ID,Challenge Name,Target Amount'));
      expect(csv, contains('7,Emergency Fund,500.00,125.00,375.00,25.0,active'));
    });

    test('escapes commas, quotes, and line breaks in challenge names', () {
      final csv = ChallengeCsvExportService.toCsv([
        const SavingsChallenge(
          id: 2,
          title: 'Trip, "Summer"\n2027',
          target: 100,
          saved: 100,
          status: 'finished',
        ),
      ]);

      expect(csv, contains('"Trip, ""Summer""\n2027"'));
      expect(csv, contains('100.0,finished'));
    });

    test('caps progress at 100 percent and remaining amount at zero', () {
      final csv = ChallengeCsvExportService.toCsv([
        const SavingsChallenge(
          id: 3,
          title: 'Overfunded',
          target: 50,
          saved: 75,
          status: 'finished',
        ),
      ]);

      expect(csv, contains('50.00,75.00,0.00,100.0,finished'));
    });

    test('returns only the header for an empty list', () {
      final csv = ChallengeCsvExportService.toCsv([]);

      expect(csv, 'Challenge ID,Challenge Name,Target Amount,Amount Saved,'
          'Remaining Amount,Progress Percentage,Status\r\n');
    });
  });
}
