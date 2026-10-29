import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/finance_models.dart';
import '../state/finance_state.dart';
import '../widgets/common.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});
  Future<void> create(BuildContext context) async {
    final title = TextEditingController(text: '7-day savings challenge');
    final target = TextEditingController(text: '50');
    final key = GlobalKey<FormState>();
    final result = await showDialog<SavingsChallenge>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Start a savings challenge'),
                content: Form(
                    key: key,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextFormField(
                          controller: title,
                          decoration: const InputDecoration(
                              labelText: 'Challenge name'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter a name'
                              : null),
                      TextFormField(
                          controller: target,
                          decoration:
                              const InputDecoration(labelText: 'Target amount'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            return n == null || !n.isFinite || n <= 0
                                ? 'Enter a positive target'
                                : null;
                          })
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        if (key.currentState!.validate())
                          Navigator.pop(
                              ctx,
                              SavingsChallenge(
                                  title: title.text.trim(),
                                  target: double.parse(target.text)));
                      },
                      child: const Text('Start'))
                ]));
    title.dispose();
    target.dispose();
    if (result == null || !context.mounted) return;
    try {
      await context.read<FinanceState>().saveChallenge(result);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> addProgress(BuildContext context, SavingsChallenge c) async {
    final amount = TextEditingController();
    final result = await showDialog<double>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Add savings progress'),
                content: TextField(
                    controller: amount,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Amount saved')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        final value = double.tryParse(amount.text);
                        if (value != null && value.isFinite && value > 0)
                          Navigator.pop(ctx, value);
                      },
                      child: const Text('Add'))
                ]));
    amount.dispose();
    if (result == null || !context.mounted) return;
    final saved = c.saved + result;
    try {
      await context.read<FinanceState>().saveChallenge(SavingsChallenge(
          id: c.id,
          title: c.title,
          target: c.target,
          saved: saved,
          status: saved >= c.target ? 'finished' : 'active'));
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> reset(BuildContext context, SavingsChallenge c) async {
    if (!await confirmDelete(context, 'the progress for ${c.title}')) return;
    if (!context.mounted) return;
    await context.read<FinanceState>().saveChallenge(
        SavingsChallenge(id: c.id, title: c.title, target: c.target, saved: 0));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();
    return Scaffold(
        appBar: AppBar(title: const Text('Savings Challenges')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => create(context),
            icon: const Icon(Icons.add),
            label: const Text('Start Challenge')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Text(
              'Start a goal, record progress, finish it, or reset it. All progress is stored offline.'),
          const SizedBox(height: 16),
          if (state.challenges.isEmpty)
            const Card(child: ListTile(title: Text('No challenges yet'))),
          for (final c in state.challenges)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.title,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                              '${money(c.saved)} of ${money(c.target)} · ${c.status}'),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                              value: (c.saved / c.target).clamp(0.0, 1.0),
                              minHeight: 9),
                          Wrap(spacing: 8, children: [
                            TextButton(
                                onPressed: c.status == 'finished'
                                    ? null
                                    : () => addProgress(context, c),
                                child: const Text('Add progress')),
                            TextButton(
                                onPressed: () => reset(context, c),
                                child: const Text('Reset')),
                            TextButton(
                                onPressed: () async {
                                  if (!await confirmDelete(context, c.title))
                                    return;
                                  try {
                                    await state.deleteChallenge(c.id!);
                                  } catch (e) {
                                    if (context.mounted) showError(context, e);
                                  }
                                },
                                child: const Text('Delete'))
                          ])
                        ]))),
          const SizedBox(height: 80)
        ]));
  }
}
