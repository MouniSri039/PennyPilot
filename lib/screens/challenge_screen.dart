
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/finance_models.dart';
import '../state/finance_state.dart';
import '../widgets/common.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  Future<void> create(BuildContext context) async {
    final titleController =
        TextEditingController(text: '7-day savings challenge');
    final targetController = TextEditingController(text: '50');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<SavingsChallenge>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start a savings challenge'),
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
                  hintText: 'e.g. Vacation savings',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validator: (value) {
                  final title = value?.trim() ?? '';

                  if (title.isEmpty) {
                    return 'Enter a challenge name';
                  }

                  if (title.length < 3) {
                    return 'Name must contain at least 3 characters';
                  }

                  if (title.length > 50) {
                    return 'Name cannot exceed 50 characters';
                  }

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
                  hintText: 'Enter your savings goal',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');

                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a target amount';
                  }

                  if (amount == null || !amount.isFinite) {
                    return 'Enter a valid number';
                  }

                  if (amount <= 0) {
                    return 'Target must be greater than zero';
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

              Navigator.pop(
                ctx,
                SavingsChallenge(
                  title: titleController.text.trim(),
                  target: double.parse(targetController.text.trim()),
                ),
              );
            },
            child: const Text('Start Challenge'),
          ),
        ],
      ),
    );

    titleController.dispose();
    targetController.dispose();

    if (result == null || !context.mounted) return;

    try {
      await context.read<FinanceState>().saveChallenge(result);
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
            decoration: const InputDecoration(
              labelText: 'Amount saved',
              hintText: 'Enter contribution amount',
              prefixIcon: Icon(Icons.savings_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter a contribution amount';
              }

              final amount = double.tryParse(value.trim());

              if (amount == null || !amount.isFinite) {
                return 'Enter a valid number';
              }

              if (amount <= 0) {
                return 'Contribution must be greater than zero';
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
            child: const Text('Add Contribution'),
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

    final updatedChallenge = SavingsChallenge(
      id: challenge.id,
      title: challenge.title,
      target: challenge.target,
      saved: updatedSaved,
      status: updatedSaved >= challenge.target ? 'finished' : 'active',
    );

    try {
      await context.read<FinanceState>().saveChallenge(updatedChallenge);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedSaved >= challenge.target
                  ? 'Congratulations! You completed ${challenge.title}!'
                  : 'Savings progress updated successfully.',
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
      appBar: AppBar(
        title: const Text('Savings Challenges'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => create(context),
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
                subtitle: Text(
                  'Start your first savings challenge to track your goals.',
                ),
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
