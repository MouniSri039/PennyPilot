import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/finance_state.dart';
import '../widgets/common.dart';
import 'category_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();
    return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(padding: const EdgeInsets.all(18), children: [
          const Text('Budget Settings',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          ListTile(
              title: const Text('Monthly Budget (USD)'),
              trailing: Text(money(state.monthlyBudget))),
          Slider(
              value: state.monthlyBudget.clamp(100.0, 2000.0),
              min: 100,
              max: 2000,
              divisions: 38,
              label: money(state.monthlyBudget),
              onChanged: (v) => state.setBudget(v)),
          const SizedBox(height: 10),
          ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Manage Categories'),
              subtitle: const Text('Add, edit, and remove expense categories'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CategoryScreen()))),
          const Divider(),
          const Text('Reminders',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          SwitchListTile(
              title: const Text('Reminder preference'),
              subtitle: const Text(
                  'Saves your preference locally; notification scheduling is not yet enabled.'),
              value: state.remindersEnabled,
              onChanged: state.setReminders),
          const Divider(),
          const Text('Data Management',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          ListTile(
              leading:
                  const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: const Text('Clear All Data'),
              subtitle:
                  const Text('Removes records and restores default categories'),
              onTap: () async {
                if (!await confirmDelete(context, 'all your local records'))
                  return;
                try {
                  await state.clearAll();
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              }),
          const SizedBox(height: 12),
          const Text(
              'Offline-first: your finance records stay on this device. No account or cloud sync is required.'),
        ]));
  }
}
