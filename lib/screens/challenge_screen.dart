
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/finance_models.dart';
import '../state/finance_state.dart';
import '../widgets/common.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  Future<void> _showChallengeForm(
    BuildContext context, {
    SavingsChallenge? existing,
  }) async {
    final titleController = TextEditingController(
      text: existing?.title ?? '7-day savings challenge',
    );
    final targetController = TextEditingController(
      text: existing?.target.toString() ?? '50',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<SavingsChallenge>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing == null ? 'Start a savings challenge' : 'Edit challenge',
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                autofocus: true,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Challenge name',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validator: (value) {
                  final title = value?.trim() ?? '';

                  if (title.isEmpty) return 'Enter a challenge name';
                  if (title.length < 3) return 'Use at least 3 characters';

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: targetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target amount',
                  prefixIcon: Icon(Icons.attach_money),
                ),
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;

              final target = double.parse(targetController.text.trim());
              final saved = existing?.saved ?? 0;

              Navigator.pop(
                ctx,
                SavingsChallenge(
                  id: existing?.id,
                  title: titleController.text.trim(),
                  target: target,
                  saved: saved,
                  status: saved >= target ? 'finished' : 'active',
                ),
              );
            },
            child: Text(existing == null ? 'Start' : 'Save changes'),
          ),
        ],
      ),
    );

    titleController.dispose();
    targetController.dispose();

    if (result == null || !context.mounted) return;

    try {
      await context.read<FinanceState>().saveChallenge(result);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing == null
                  ? 'Savings challenge created.'
                  : 'Savings challenge updated.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> addProgress(
    BuildContext context,
    SavingsChallenge challenge,
  ) async {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final contribution = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add savings progress'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: amountController,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount saved'),
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                ctx,
                double.parse(amountController.text.trim()),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    amountController.dispose();

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
              status: updatedSaved >= challenge.target
                  ? 'finished'
                  : 'active',
            ),
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedSaved >= challenge.target
                  ? 'Congratulations! You completed ${challenge.title}!'
                  : 'Savings progress updated.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge progress reset.')),
        );
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
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
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Savings Challenges')),
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
          const SizedBox(height: 16),
          if (state.challenges.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.savings_outlined),
                title: Text('No challenges yet'),
                subtitle: Text('Start your first savings challenge.'),
              ),
            ),
          for (final challenge in state.challenges)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${money(challenge.saved)} of '
                      '${money(challenge.target)} · ${challenge.status}',
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: challenge.target > 0
                          ? (challenge.saved / challenge.target)
                              .clamp(0.0, 1.0)
                          : 0,
                      minHeight: 9,
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
                          onPressed: challenge.status == 'finished'
                              ? null
                              : () => addProgress(context, challenge),
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
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
