import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/redemption_request.dart';
import '../../services/firestore_service.dart';
import '../../services/session_provider.dart';
import '../../theme/app_theme.dart';

class ChildRequestsScreen extends StatelessWidget {
  const ChildRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final session = context.read<SessionProvider>();
    final user = session.currentUser!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: StreamBuilder<List<RedemptionRequest>>(
        stream: db.redemptionsStream(childId: user.id),
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
                  Icon(Icons.inbox, size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 12),
                  Text('No requests yet',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, i) {
              final r = requests[i];
              final fmt = DateFormat('MMM d');
              Color statusColor;
              IconData statusIcon;
              String statusLabel;
              switch (r.status) {
                case RedemptionStatus.pending:
                  statusColor = cs.tertiary;
                  statusIcon = Icons.hourglass_top;
                  statusLabel = 'Pending';
                case RedemptionStatus.approved:
                  statusColor = AppTheme.earnedColor;
                  statusIcon = Icons.check_circle;
                  statusLabel = 'Approved';
                case RedemptionStatus.denied:
                  statusColor = cs.error;
                  statusIcon = Icons.cancel;
                  statusLabel = 'Denied';
              }
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(statusIcon, color: statusColor),
                  title: Text(r.prizeName,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    '${r.cost} dbux · ${fmt.format(r.createdAt)}',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
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
