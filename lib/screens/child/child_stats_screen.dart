import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/transaction.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/balance_chart.dart';

class ChildStatsScreen extends StatelessWidget {
  final String childId;
  final String childName;

  const ChildStatsScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('$childName Stats')),
      body: StreamBuilder<AppUser?>(
        stream: db.userStream(childId),
        builder: (context, userSnap) {
          final balance = userSnap.data?.balance ?? 0;

          return StreamBuilder<List<DbuxTransaction>>(
            stream: db.transactionsStream(childId: childId),
            builder: (context, txSnap) {
              if (txSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final txs = txSnap.data ?? [];
              final earned = txs
                  .where((t) => t.type == TransactionType.earned)
                  .fold<int>(0, (sum, t) => sum + t.amount);
              final redeemed = txs
                  .where((t) => t.type != TransactionType.earned)
                  .fold<int>(0, (sum, t) => sum + t.amount);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lifetime totals
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Lifetime Earned',
                            value: '$earned',
                            icon: Icons.arrow_upward,
                            color: AppTheme.earnedColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Lifetime Spent',
                            value: '$redeemed',
                            icon: Icons.arrow_downward,
                            color: AppTheme.redeemedColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Current Balance',
                            value: '$balance',
                            icon: Icons.account_balance_wallet,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Transactions',
                            value: '${txs.length}',
                            icon: Icons.receipt_long,
                            color: cs.secondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Chart
                    Text('Balance Over Time',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: BalanceChart(
                          transactions: txs,
                          currentBalance: balance,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Top earnings
                    if (txs.isNotEmpty) ...[
                      Text('Biggest Earnings',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ..._topEarnings(txs).map((tx) => Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.earnedColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.star,
                                    color: AppTheme.earnedColor, size: 18),
                              ),
                              title: Text(tx.description,
                                  style: const TextStyle(fontSize: 14)),
                              trailing: Text(
                                '+${tx.amount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.earnedColor,
                                ),
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<DbuxTransaction> _topEarnings(List<DbuxTransaction> txs) {
    final earned = txs.where((t) => t.type == TransactionType.earned).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return earned.take(5).toList();
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
