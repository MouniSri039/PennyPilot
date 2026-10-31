import 'package:flutter/material.dart';
import '../services/transaction_validation.dart';
import 'package:provider/provider.dart';
import '../models/finance_models.dart';
import '../state/finance_state.dart';
import '../widgets/common.dart';

class TransactionFormScreen extends StatefulWidget {
  final MoneyTransaction? existing;
  const TransactionFormScreen({super.key, this.existing});
  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController();
  final description = TextEditingController();
  String type = 'expense';
  String payment = 'Debit Card';
  String receivedInto = '';
  int? categoryId;
  DateTime date = DateTime.now();
  bool saving = false;

  static const incomeMethods = [
    'Direct Deposit',
    'Bank Transfer (ACH/Wire)',
    'Zelle',
    'Check',
    'Money Order',
    'Cash',
    'PayPal',
    'Venmo',
    'Cash App',
    'Other'
  ];
  static const expenseMethods = [
    'Debit Card',
    'Credit Card',
    'Bank Transfer (ACH/Wire)',
    'Zelle',
    'Check',
    'Money Order',
    'Cash',
    'Apple Pay',
    'Google Pay',
    'PayPal',
    'Venmo',
    'Cash App',
    'Other'
  ];
  static const destinations = [
    'Bank Account',
    'Cash',
    'Digital Wallet',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      amount.text = t.amount.toStringAsFixed(2);
      description.text = t.description;
      type = t.type;
      payment = t.paymentMethod;
      receivedInto = t.receivedInto;
      categoryId = t.categoryId;
      date = t.date;
    }
  }

  @override
  void dispose() {
    amount.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving) return;
    if (!formKey.currentState!.validate()) return;
    final state = context.read<FinanceState>();
    final available = state.categories.where((c) => c.kind == type).toList();
    final selected = available.any((c) => c.id == categoryId)
        ? categoryId
        : (available.isNotEmpty ? available.first.id : null);
    if (selected == null) {
      showError(context, 'Create a $type category in Settings first.');
      return;
    }
    setState(() => saving = true);
    try {
      await state.saveTransaction(MoneyTransaction(
        id: widget.existing?.id,
        categoryId: selected,
        type: type,
        amount: double.parse(amount.text.trim()),
        date: date,
        description: description.text.trim(),
        paymentMethod: payment,
        receivedInto: type == 'income' ? receivedInto : '',
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved')),
      );
      if (widget.existing != null) {
        Navigator.pop(context);
      } else {
        amount.clear();
        description.clear();
        setState(() => date = DateTime.now());
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context
        .watch<FinanceState>()
        .categories
        .where((c) => c.kind == type)
        .toList();
    final effectiveId = categories.any((c) => c.id == categoryId)
        ? categoryId
        : (categories.isNotEmpty ? categories.first.id : null);
    final methods = type == 'income' ? incomeMethods : expenseMethods;
    // Keep legacy values selectable when editing an existing transaction.
    final visibleMethods = [
      ...methods,
      if (!methods.contains(payment)) payment,
    ];
    final visibleDestinations = [
      ...destinations,
      if (receivedInto.isNotEmpty && !destinations.contains(receivedInto))
        receivedInto,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.existing == null ? 'Add Transaction' : 'Edit Transaction'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey('type-$type'),
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'expense', child: Text('Expense')),
                DropdownMenuItem(value: 'income', child: Text('Income')),
              ],
              onChanged: (v) {
                if (v == null || v == type) return;
                setState(() {
                  type = v;
                  categoryId = null;
                  payment = type == 'income' ? 'Direct Deposit' : 'Debit Card';
                  receivedInto = '';
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amount,
              decoration: const InputDecoration(
                labelText: 'Amount (USD)',
                prefixText: '\$',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: TransactionValidation.validateAmount,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey('category-$type-$effectiveId'),
              initialValue: effectiveId,
              decoration: InputDecoration(
                labelText:
                    type == 'income' ? 'Income Category' : 'Expense Category',
              ),
              items: categories
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ))
                  .toList(),
              validator: (_) =>
                  effectiveId == null ? 'Add a category first' : null,
              onChanged: (v) => setState(() => categoryId = v),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(shortDate(date)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => date = picked);
              },
            ),
            TextFormField(
              controller: description,
              decoration: const InputDecoration(
                labelText: 'Description / Notes',
                helperText: 'Required · Maximum 120 characters',
              ),
              maxLength: TransactionValidation.maxDescriptionLength,
              validator: TransactionValidation.validateDescription,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('method-$type-$payment'),
              initialValue: payment,
              decoration: InputDecoration(
                labelText: type == 'income' ? 'Received Via' : 'Paid Via',
              ),
              isExpanded: true,
              items: visibleMethods
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => payment = v!),
            ),
            if (type == 'income') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('destination-$receivedInto'),
                initialValue: receivedInto.isEmpty ? null : receivedInto,
                decoration: const InputDecoration(
                  labelText: 'Deposited To / Received In (Optional)',
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                      value: '', child: Text('Not specified')),
                  ...visibleDestinations.map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(d),
                      )),
                ],
                onChanged: (v) => setState(() => receivedInto = v ?? ''),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: saving ? null : save,
              child: Text(saving ? 'Saving…' : 'Save Transaction'),
            ),
            if (widget.existing != null)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
          ],
        ),
      ),
    );
  }
}
