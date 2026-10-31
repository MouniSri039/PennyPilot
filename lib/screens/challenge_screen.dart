import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/finance_models.dart';
import '../services/challenge_csv_export_service.dart';
import '../state/finance_state.dart';
import '../widgets/common.dart';

enum ChallengeFilter { all, active, completed }

enum ChallengeSort { name, target, progress }

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  ChallengeFilter _filter = ChallengeFilter.all;
  ChallengeSort _sort = ChallengeSort.progress;

  Future<void> _showChallengeForm(
    BuildContext context, {
    SavingsChallenge? existing,
  }) async {
    final formKey = GlobalKey<FormState>();

    String title = existing?.title ?? '7-day savings challenge';
    String targetText = existing?.target.toString() ?? '50';

    final result = await showDialog<SavingsChallenge>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            existing == null ? 'Start a savings challenge' : 'Edit challenge',
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: title,
                  autofocus: true,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Challenge name',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  onChanged: (value) => title = value,
                  validator: (value) {
                    final input = value?.trim() ?? '';

                    if (input.isEmpty) {
                      return 'Enter a challenge name';
                    }

                    if (input.length < 3) {
                      return 'Use at least 3 characters';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: targetText,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Target amount',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  onChanged: (value) => targetText = value,
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');

                    if (amount == null || !amount.isFinite || amount <= 0) {
                      return 'Enter a valid positive amount';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final target = double.parse(targetText.trim());
                final saved = existing?.saved ?? 0;

                Navigator.of(dialogContext).pop(
                  SavingsChallenge(
                    id: existing?.id,
                    title: title.trim(),
                    target: target,
                    saved: saved,
                    status: saved >= target ? 'finished' : 'active',
                  ),
                );
              },
              child: Text(existing == null ? 'Start' : 'Save changes'),
            ),
          ],
        );
      },
    );

    if (result == null || !context.mounted) return;

    try {
      await context.read<FinanceState>().saveChallenge(result);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'Savings challenge created.'
                : 'Savings challenge updated.',
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        showError(context, e);
      }
    }
  }

  Future<void> addProgress(
    BuildContext context,
    SavingsChallenge challenge,
  ) async {
    final formKey = GlobalKey<FormState>();
    String amountText = '';

    final contribution = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add savings progress'),
          content: Form(
            key: formKey,
            child: TextFormField(
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount saved',
                prefixIcon: Icon(Icons.attach_money),
              ),
              onChanged: (value) => amountText = value,
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');

                if (amount == null || !amount.isFinite || amount <= 0) {
                  return 'Enter a valid positive amount';
                }

                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                Navigator.of(dialogContext).pop(
                  double.parse(amountText.trim()),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (contribution == null || !context.mounted) return;

    final updatedSaved = challenge.saved + contribution;

    if (!updatedSaved.isFinite) {
      showError(context, 'Contribution is too large.');
      return;
    }

    try {
      await context.read<FinanceState>().saveChallenge(
            SavingsChallenge(
              id: challenge.id,
              title: challenge.title,
              target: challenge.target,
              saved: updatedSaved,
              status: updatedSaved >= challenge.target ? 'finished' : 'active',
            ),
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedSaved >= challenge.target
                ? 'Congratulations! You completed ${challenge.title}!'
                : 'Savings progress updated.',
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        showError(context, e);
      }
    }
  }

  Future<void> reset(
    BuildContext context,
    SavingsChallenge challenge,
  ) async {
    if (!await confirmDelete(
      context,
      'the progress for ${challenge.title}',
    )) {
      return;
    }

    if (!context.mounted) return;

    try {
      await context.read<FinanceState>().saveChallenge(
            SavingsChallenge(
              id: challenge.id,
              title: challenge.title,
              target: challenge.target,
              saved: 0,
              status: 'active',
            ),
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challenge progress reset.'),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        showError(context, e);
      }
    }
  }

  Future<void> delete(
    BuildContext context,
    SavingsChallenge challenge,
  ) async {
    if (!await confirmDelete(context, challenge.title)) return;

    if (!context.mounted) return;

    try {
      await context.read<FinanceState>().deleteChallenge(challenge.id!);
    } catch (e) {
      if (context.mounted) {
        showError(context, e);
      }
    }
  }

  Future<void> _exportChallenges(
    BuildContext context,
    List<SavingsChallenge> challenges,
  ) async {
    try {
      final file = await ChallengeCsvExportService.export(challenges);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV exported: ${file.path}'),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        showError(context, 'Could not export challenges: $e');
      }
    }
  }

  double _progress(SavingsChallenge challenge) {
    if (challenge.target <= 0) return 0;

    return (challenge.saved / challenge.target).clamp(0.0, 1.0);
  }

  List<SavingsChallenge> _filteredChallenges(
    List<SavingsChallenge> challenges,
  ) {
    final result = challenges.where((challenge) {
      final isCompleted = challenge.status.toLowerCase() == 'finished';

      switch (_filter) {
        case ChallengeFilter.all:
          return true;
        case ChallengeFilter.active:
          return !isCompleted;
        case ChallengeFilter.completed:
          return isCompleted;
      }
    }).toList();

    switch (_sort) {
      case ChallengeSort.name:
        result.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;

      case ChallengeSort.target:
        result.sort((a, b) => b.target.compareTo(a.target));
        break;

      case ChallengeSort.progress:
        result.sort(
          (a, b) => _progress(b).compareTo(_progress(a)),
        );
        break;
    }

    return result;
  }

  Widget _filterChip(String label, ChallengeFilter filter) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == filter,
      onSelected: (selected) {
        if (!selected) return;
        setState(() => _filter = filter);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();
    final challenges = _filteredChallenges(state.challenges);

    final activeCount = state.challenges
        .where((c) => c.status.toLowerCase() != 'finished')
        .length;

    final completedCount = state.challenges
        .where((c) => c.status.toLowerCase() == 'finished')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Challenges'),
        actions: [
          IconButton(
            tooltip: 'Export challenges as CSV',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: state.challenges.isEmpty
                ? null
                : () => _exportChallenges(context, state.challenges),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showChallengeForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Start Challenge'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Set a savings goal, record your progress, '
            'and track your achievements. All progress is stored offline.',
          ),
          const SizedBox(height: 20),

          // Challenge overview
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  'Total',
                  state.challenges.length.toString(),
                  Icons.flag_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryCard(
                  'Active',
                  activeCount.toString(),
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryCard(
                  'Completed',
                  completedCount.toString(),
                  Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text(
            'Filter challenges',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            children: [
              _filterChip('All', ChallengeFilter.all),
              _filterChip('Active', ChallengeFilter.active),
              _filterChip('Completed', ChallengeFilter.completed),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sort by',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DropdownButton<ChallengeSort>(
                value: _sort,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sort = value);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: ChallengeSort.progress,
                    child: Text('Progress'),
                  ),
                  DropdownMenuItem(
                    value: ChallengeSort.name,
                    child: Text('Name A–Z'),
                  ),
                  DropdownMenuItem(
                    value: ChallengeSort.target,
                    child: Text('Highest target'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (state.challenges.isEmpty)
            _emptyState(
              Icons.savings_outlined,
              'No challenges yet',
              'Start your first savings challenge.',
            )
          else if (challenges.isEmpty)
            _emptyState(
              _filter == ChallengeFilter.active
                  ? Icons.trending_up
                  : Icons.check_circle_outline,
              _filter == ChallengeFilter.active
                  ? 'No active challenges'
                  : 'No completed challenges',
              _filter == ChallengeFilter.active
                  ? 'All your current challenges are completed.'
                  : 'Complete a savings goal to see it here.',
            )
          else
            ...challenges.map(_challengeCard),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _summaryCard(
    String label,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 8,
        ),
        child: Column(
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(
    IconData icon,
    String title,
    String message,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _challengeCard(SavingsChallenge challenge) {
    final progress = _progress(challenge);
    final completed = challenge.status.toLowerCase() == 'finished';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (completed)
                  const Chip(
                    avatar: Icon(Icons.check_circle, size: 16),
                    label: Text('Completed'),
                  )
                else
                  const Chip(
                    label: Text('Active'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${money(challenge.saved)} of ${money(challenge.target)}',
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 9,
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% completed',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _showChallengeForm(
                    context,
                    existing: challenge,
                  ),
                  child: const Text('Edit'),
                ),
                TextButton(
                  onPressed:
                      completed ? null : () => addProgress(context, challenge),
                  child: const Text('Add progress'),
                ),
                TextButton(
                  onPressed: () => reset(context, challenge),
                  child: const Text('Reset'),
                ),
                TextButton(
                  onPressed: () => delete(context, challenge),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
