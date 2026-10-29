import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/finance_models.dart';
import '../state/finance_state.dart';
import '../widgets/common.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  Future<void> edit(BuildContext context, [BudgetCategory? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final budget = TextEditingController(
      text: (existing?.limit ?? 0).toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();
    String kind = existing?.kind ?? 'expense';
    final result = await showDialog<BudgetCategory>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'New Category' : 'Edit Category'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: kind,
                  decoration: const InputDecoration(labelText: 'Category Type'),
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text('Expense')),
                    DropdownMenuItem(value: 'income', child: Text('Income')),
                  ],
                  onChanged: (v) => setDialogState(() => kind = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: budget,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: kind == 'expense'
                        ? 'Category budget (0 = none)'
                        : 'Target amount (0 = none)',
                  ),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return n == null || !n.isFinite || n < 0
                        ? 'Enter zero or a positive number'
                        : null;
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
                if (formKey.currentState!.validate()) {
                  Navigator.pop(
                      ctx,
                      BudgetCategory(
                        id: existing?.id,
                        name: name.text.trim(),
                        limit: double.parse(budget.text),
                        kind: kind,
                      ));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    budget.dispose();
    if (result == null || !context.mounted) return;
    try {
      await context.read<FinanceState>().saveCategory(result);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => edit(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Categories with transactions cannot be deleted until those transactions are moved or removed.',
          ),
          for (final kind in ['expense', 'income']) ...[
            const SizedBox(height: 20),
            Text(
              kind == 'expense' ? 'Expense Categories' : 'Income Categories',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final c in state.categories.where((c) => c.kind == kind))
              Card(
                child: ListTile(
                  title: Text(c.name),
                  subtitle: Text(kind == 'expense'
                      ? 'Category budget: ${money(c.limit)}'
                      : 'Target amount: ${money(c.limit)}'),
                  onTap: () => edit(context, c),
                  trailing: IconButton(
                    tooltip: 'Delete ${c.name}',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      if (!await confirmDelete(context, c.name)) return;
                      try {
                        await state.deleteCategory(c.id!);
                      } catch (e) {
                        if (context.mounted) showError(context, e);
                      }
                    },
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
