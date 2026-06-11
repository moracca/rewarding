import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/transaction.dart';
import '../../services/firestore_service.dart';
import '../../services/session_provider.dart';
import '../../theme/app_theme.dart';

class ChildHistoryScreen extends StatelessWidget {
  const ChildHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final session = context.read<SessionProvider>();
    final user = session.currentUser!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My History')),
      body: StreamBuilder<List<DbuxTransaction>>(
        stream: db.transactionsStream(childId: user.id),
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
                  Icon(Icons.history, size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 12),
                  Text('No history yet',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: txs.length,
            itemBuilder: (context, i) {
              final tx = txs[i];
              final isEarned = tx.type == TransactionType.earned;
              final color =
                  isEarned ? AppTheme.earnedColor : AppTheme.redeemedColor;
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
                  subtitle: Text(fmt.format(tx.createdAt),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
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
            },
          );
        },
      ),
    );
  }
}
