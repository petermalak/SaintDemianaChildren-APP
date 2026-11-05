import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../viewmodel/scoring_cubit/scoring_cubit.dart';
import '../../viewmodel/scoring_cubit/scoring_state.dart';
import '../../model/scoring_models.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String userId;
  final String classId;

  const TransactionHistoryScreen({
    Key? key,
    required this.userId,
    required this.classId,
  }) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    context.read<ScoringCubit>().getTransactionHistory(
          widget.userId,
          widget.classId,
          limit: 100,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المعاملات'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadTransactions();
        },
        child: BlocBuilder<ScoringCubit, ScoringState>(
          builder: (context, state) {
            if (state is ScoringLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ScoringError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadTransactions,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            if (state is TransactionsLoaded) {
              if (state.transactions.isEmpty) {
                return const Center(
                  child: Text('لا توجد معاملات بعد'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.transactions.length,
                itemBuilder: (context, index) {
                  final transaction = state.transactions[index];
                  return _buildTransactionCard(transaction);
                },
              );
            }

            return const Center(child: Text('لا توجد بيانات'));
          },
        ),
      ),
    );
  }

  Widget _buildTransactionCard(ScoreTransactionModel transaction) {
    final isPositive = transaction.isPositive;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.add_circle : Icons.remove_circle;
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          transaction.getTransactionTypeLabel(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.reason != null) ...[
              const SizedBox(height: 4),
              Text(transaction.reason!),
            ],
            if (transaction.awardedBy != null) ...[
              const SizedBox(height: 4),
              Text(
                'بواسطة: ${transaction.awardedBy!.name}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              dateFormat.format(transaction.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Text(
          '${isPositive ? '+' : ''}${transaction.points}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
