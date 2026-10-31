import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/finance_models.dart';

class ChallengeCsvExportService {
  static const List<String> headers = [
    'Challenge ID',
    'Challenge Name',
    'Target Amount',
    'Amount Saved',
    'Remaining Amount',
    'Progress Percentage',
    'Status',
  ];

  /// Converts challenge records into RFC-4180-style CSV rows.
  static String toCsv(List<SavingsChallenge> challenges) {
    final rows = <List<String>>[
      headers,
      ...challenges.map((challenge) {
        final remaining =
            (challenge.target - challenge.saved).clamp(0.0, double.infinity);
        final progress = challenge.target <= 0
            ? 0.0
            : (challenge.saved / challenge.target * 100).clamp(0.0, 100.0);

        return [
          challenge.id?.toString() ?? '',
          challenge.title,
          challenge.target.toStringAsFixed(2),
          challenge.saved.toStringAsFixed(2),
          remaining.toStringAsFixed(2),
          progress.toStringAsFixed(1),
          challenge.status,
        ];
      }),
    ];

    return '${rows.map((row) => row.map(_escape).join(',')).join('\r\n')}\r\n';
  }

  static String _escape(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n') ||
        escaped.contains('\r')) {
      return '"$escaped"';
    }
    return escaped;
  }

  /// Saves a UTF-8 CSV file in the app's documents directory.
  static Future<File> export(List<SavingsChallenge> challenges) async {
    if (challenges.isEmpty) {
      throw ArgumentError('There are no savings challenges to export.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${directory.path}/pennypilot_challenges_$timestamp.csv');

    // UTF-8 BOM helps spreadsheet applications detect UTF-8 correctly.
    await file.writeAsBytes(
      [0xEF, 0xBB, 0xBF, ...utf8.encode(toCsv(challenges))],
      flush: true,
    );
    return file;
  }
}
