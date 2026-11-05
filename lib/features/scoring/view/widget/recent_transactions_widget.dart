import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/scoring_models.dart';

/// A stateless widget that displays recent transactions
/// Data should be provided from parent widget, not fetched here
class RecentTransactionsWidget extends StatelessWidget {
  final List<ScoreTransactionModel> transactions;
  final bool isLoading;

  const RecentTransactionsWidget({
    Key? key,
    required this.transactions,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('لا توجد معاملات بعد'),
        ),
      );
    }

    return Column(
      children: transactions.map((transaction) {
        return _buildTransactionTile(transaction);
      }).toList(),
    );
  }

  Widget _buildTransactionTile(ScoreTransactionModel transaction) {
    final isPositive = transaction.isPositive;
    final color = isPositive ? Colors.green : Colors.red;
    final icon =
        isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline;
    final dateFormat = DateFormat('MMM dd, hh:mm a');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        transaction.getTransactionTypeLabel(),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        dateFormat.format(transaction.createdAt),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        '${isPositive ? '+' : ''}${transaction.points}',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
