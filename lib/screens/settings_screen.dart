import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/transaction_csv_service.dart';
import '../state/finance_state.dart';
import '../widgets/common.dart';
import 'category_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _exporting = false;

  Future<void> _exportTransactions() async {
    final state = context.read<FinanceState>();

    if (state.transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions available to export.'),
        ),
      );
      return;
    }

    setState(() => _exporting = true);

    try {
      final csv = const TransactionCsvService().generate(
        transactions: state.transactions,
        categories: state.categories,
      );

      final now = DateTime.now();
      final date = '${now.year.toString().padLeft(4, '0')}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';

      final filename = 'pennypilot_transactions_$date.csv';

      final bytes = Uint8List.fromList(
        utf8.encode('\uFEFF$csv'),
      );

      if (!mounted) return;

      final box = context.findRenderObject() as RenderBox?;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'text/csv',
              name: filename,
            ),
          ],
          fileNameOverrides: [filename],
          subject: 'PennyPilot Transaction Export',
          sharePositionOrigin:
              box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Budget Settings',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          ListTile(
            title: const Text('Monthly Budget (USD)'),
            trailing: Text(money(state.monthlyBudget)),
          ),
          Slider(
            value: state.monthlyBudget.clamp(100.0, 2000.0),
            min: 100,
            max: 2000,
            divisions: 38,
            label: money(state.monthlyBudget),
            onChanged: (value) => state.setBudget(value),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Manage Categories'),
            subtitle: const Text(
              'Add, edit, and remove expense categories',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CategoryScreen(),
              ),
            ),
          ),
          const Divider(),
          const Text(
            'Reminders',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          SwitchListTile(
            title: const Text('Reminder preference'),
            subtitle: const Text(
              'Saves your preference locally; notification scheduling is not yet enabled.',
            ),
            value: state.remindersEnabled,
            onChanged: state.setReminders,
          ),
          const Divider(),
          const Text(
            'Data Management',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          ListTile(
            key: const Key('export-transactions-csv'),
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export Transactions (CSV)'),
            subtitle: const Text(
              'Save or share all your income and expense transactions',
            ),
            trailing: _exporting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _exporting ? null : _exportTransactions,
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.red,
            ),
            title: const Text('Clear All Data'),
            subtitle: const Text(
              'Removes records and restores default categories',
            ),
            onTap: () async {
              if (!await confirmDelete(
                context,
                'all your local records',
              )) {
                return;
              }

              try {
                await state.clearAll();
              } catch (error) {
                if (context.mounted) {
                  showError(context, error);
                }
              }
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Offline-first: your finance records stay on this device. No account or cloud sync is required.',
          ),
        ],
      ),
    );
  }
}
