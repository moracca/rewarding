import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../models/redemption_request.dart';
import '../../models/transaction.dart';
import '../../services/firestore_service.dart';
import '../../services/session_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/emoji_picker_dialog.dart';
import 'child_prizes_screen.dart';
import 'child_history_screen.dart';
import 'child_requests_screen.dart';
import 'child_stats_screen.dart';

class ChildHome extends StatelessWidget {
  const ChildHome({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final user = session.currentUser!;
    final db = FirestoreService();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                final picked = await showAvatarPicker(
                  context,
                  selected: user.avatarEmoji,
                );
                if (picked != null) {
                  await db.createUser(user.copyWith(avatarEmoji: picked));
                  if (context.mounted) {
                    await session.refreshCurrentUser();
                  }
                }
              },
              child: AvatarWidget(avatar: user.avatarEmoji ?? '😊', size: 32, fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(user.name),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.key_rounded),
            tooltip: 'Change PIN',
            onPressed: () => _showChangePinDialog(context, user, db, session),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () => session.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Balance card
            StreamBuilder<AppUser?>(
              stream: db.userStream(user.id),
              builder: (context, snap) {
                final balance = snap.data?.balance ?? user.balance;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    gradient: AppTheme.balanceGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$balance',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'dbux',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Pending requests
            StreamBuilder<List<RedemptionRequest>>(
              stream: db.redemptionsStream(
                childId: user.id,
                status: RedemptionStatus.pending,
              ),
              builder: (context, snap) {
                final pending = snap.data ?? [];
                if (pending.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    color: cs.tertiaryContainer,
                    child: ListTile(
                      leading: Icon(Icons.hourglass_top, color: cs.tertiary),
                      title: Text(
                        '${pending.length} pending request${pending.length == 1 ? '' : 's'}',
                        style: TextStyle(color: cs.onTertiaryContainer),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChildRequestsScreen()),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Actions
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.card_giftcard,
                    label: 'Prizes',
                    color: cs.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChildPrizesScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.bar_chart,
                    label: 'Stats',
                    color: cs.tertiary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ChildStatsScreen(
                                childId: user.id,
                                childName: user.name,
                              )),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.history,
                    label: 'History',
                    color: cs.secondary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChildHistoryScreen()),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent activity
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<DbuxTransaction>>(
              stream: db.transactionsStream(childId: user.id),
              builder: (context, snap) {
                final txs = snap.data ?? [];
                if (txs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No activity yet. Start earning dbux!',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  );
                }
                final recent = txs.take(5).toList();
                return Column(
                  children: recent.map((tx) {
                    final isEarned = tx.type == TransactionType.earned;
                    final color = isEarned
                        ? AppTheme.earnedColor
                        : AppTheme.redeemedColor;
                    final sign = isEarned ? '+' : '-';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEarned
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: color,
                            size: 18,
                          ),
                        ),
                        title: Text(tx.description,
                            style: const TextStyle(fontSize: 14)),
                        trailing: Text(
                          '$sign${tx.amount}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

void _showChangePinDialog(
  BuildContext context,
  AppUser user,
  FirestoreService db,
  SessionProvider session,
) {
  final currentPinCtrl = TextEditingController();
  final newPinCtrl = TextEditingController();
  final confirmPinCtrl = TextEditingController();
  String? error;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPinCtrl,
              decoration: const InputDecoration(labelText: 'Current PIN'),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPinCtrl,
              decoration: const InputDecoration(labelText: 'New PIN'),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmPinCtrl,
              decoration: const InputDecoration(labelText: 'Confirm new PIN'),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (currentPinCtrl.text != user.pin) {
                setDialogState(() => error = 'Current PIN is wrong');
                return;
              }
              if (newPinCtrl.text.length != 4) {
                setDialogState(() => error = 'New PIN must be 4 digits');
                return;
              }
              if (newPinCtrl.text != confirmPinCtrl.text) {
                setDialogState(() => error = 'New PINs don\'t match');
                return;
              }
              await db.createUser(user.copyWith(pin: newPinCtrl.text));
              await session.refreshCurrentUser();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN changed!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
