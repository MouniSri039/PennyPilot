import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String money(num amount) =>
    NumberFormat.simpleCurrency(name: 'USD').format(amount);
String shortDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);
Future<bool> confirmDelete(BuildContext context, String name) async =>
    await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Confirm deletion'),
                content: Text('Delete $name? This action cannot be undone.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'))
                ])) ??
    false;
void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(error.toString())));
}
