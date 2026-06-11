import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class ParentHistoryScreen extends StatelessWidget {
  const ParentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: StreamBuilder<List<DbuxTransaction>>(
        stream: db.transactionsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final txs = snap.data ?? [];
          if (txs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 12),
                  Text('No transactions yet',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: txs.length,
            itemBuilder: (context, i) => _TxTile(tx: txs[i]),
          );
        },
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final DbuxTransaction tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isEarned = tx.type == TransactionType.earned;
    final color = isEarned ? AppTheme.earnedColor : AppTheme.redeemedColor;
    final sign = isEarned ? '+' : '-';
    final fmt = DateFormat('MMM d, h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isEarned ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
            size: 20,
          ),
        ),
        title: Text(tx.description,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('${tx.childName} · ${fmt.format(tx.createdAt)}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        trailing: Text(
          '$sign${tx.amount}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ),
    );
  }
}
