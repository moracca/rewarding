import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/prize.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../services/session_provider.dart';
import '../../theme/app_theme.dart';

class ChildPrizesScreen extends StatelessWidget {
  const ChildPrizesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final session = context.read<SessionProvider>();
    final user = session.currentUser!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Prize Shop')),
      body: StreamBuilder<AppUser?>(
        stream: db.userStream(user.id),
        builder: (context, userSnap) {
          final balance = userSnap.data?.balance ?? user.balance;

          return StreamBuilder<List<Prize>>(
            stream: db.prizesStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final prizes =
                  (snap.data ?? []).where((p) => p.active).toList();
              if (prizes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront,
                          size: 64, color: cs.outlineVariant),
                      const SizedBox(height: 12),
                      Text('No prizes available',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Ask a parent to add some!',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: prizes.length,
                itemBuilder: (context, i) {
                  final p = prizes[i];
                  final canAfford = balance >= p.cost;
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: canAfford
                          ? () => _requestRedeem(context, db, user, p)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(p.emoji ?? '🎁',
                                style: const TextStyle(fontSize: 40)),
                            const SizedBox(height: 8),
                            Text(
                              p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (p.description != null &&
                                p.description!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                p.description!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: canAfford
                                    ? AppTheme.earnedColor.withValues(alpha: 0.12)
                                    : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${p.cost} dbux',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: canAfford
                                          ? AppTheme.earnedColor
                                          : cs.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (!canAfford)
                                    Text(
                                      'Need ${p.cost - balance} more',
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _requestRedeem(
      BuildContext context, FirestoreService db, AppUser user, Prize prize) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${prize.emoji ?? "🎁"} ${prize.name}'),
        content: Text(
            'Request to redeem for ${prize.cost} dbux?\n\nA parent will need to approve this.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await db.requestRedemption(
                childId: user.id,
                childName: user.name,
                prize: prize,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request sent! Waiting for approval.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }
}
