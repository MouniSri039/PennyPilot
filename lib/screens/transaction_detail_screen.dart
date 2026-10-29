import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/finance_models.dart';
import '../state/finance_state.dart';
import '../widgets/common.dart';
import 'transaction_form_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final MoneyTransaction transaction;
  const TransactionDetailScreen({super.key, required this.transaction});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();
    return Scaffold(
        appBar: AppBar(title: const Text('Transaction Detail'), actions: [
          IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            TransactionFormScreen(existing: transaction)));
                if (context.mounted) Navigator.pop(context);
              }),
          IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                if (!await confirmDelete(context, 'this transaction')) return;
                try {
                  await state.deleteTransaction(transaction.id!);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              })
        ]),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Text(state.categoryName(transaction.categoryId),
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 8),
                    Text(
                        '${transaction.type == 'expense' ? '-' : '+'}${money(transaction.amount)}',
                        style: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold)),
                    Text(shortDate(transaction.date))
                  ]))),
          Card(
              child: Column(children: [
            ListTile(
                title: const Text('Type'), trailing: Text(transaction.type)),
            ListTile(
                title: const Text('Category'),
                trailing: Text(state.categoryName(transaction.categoryId))),
            ListTile(
                title: Text(
                    transaction.type == 'income' ? 'Received Via' : 'Paid Via'),
                trailing: Text(transaction.paymentMethod)),
            if (transaction.type == 'income' &&
                transaction.receivedInto.isNotEmpty)
              ListTile(
                  title: const Text('Deposited To / Received In'),
                  trailing: Text(transaction.receivedInto)),
            ListTile(
                title: const Text('Notes'),
                subtitle: Text(transaction.description.isEmpty
                    ? 'None'
                    : transaction.description))
          ]))
        ]));
  }
}
