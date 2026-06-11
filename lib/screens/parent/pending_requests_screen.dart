import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/redemption_request.dart';
import '../../services/firestore_service.dart';
import '../../services/session_provider.dart';
import '../../theme/app_theme.dart';

class PendingRequestsScreen extends StatelessWidget {
  const PendingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Requests')),
      body: StreamBuilder<List<RedemptionRequest>>(
        stream: db.redemptionsStream(status: RedemptionStatus.pending),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snap.data ?? [];
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 12),
                  Text('All clear!',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('No pending requests',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, i) {
              final r = requests[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.childName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                                Text(
                                  r.prizeName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.redeemedColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${r.cost} dbux',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.redeemedColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _resolve(
                                  context, r, RedemptionStatus.denied),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Deny'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: cs.error,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _resolve(
                                  context, r, RedemptionStatus.approved),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _resolve(BuildContext context, RedemptionRequest r,
      RedemptionStatus status) async {
    final session = context.read<SessionProvider>();
    final db = FirestoreService();

    await db.resolveRedemption(
      requestId: r.id,
      status: status,
      resolvedBy: session.currentUser!.name,
      childId: r.childId,
      cost: r.cost,
      childName: r.childName,
      prizeName: r.prizeName,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == RedemptionStatus.approved
              ? 'Approved! ${r.cost} dbux deducted.'
              : 'Denied.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
