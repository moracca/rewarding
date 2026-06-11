import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../models/redemption_request.dart';
import '../../services/firestore_service.dart';
import '../../services/session_provider.dart';
import '../../theme/app_theme.dart';
import 'award_dbux_screen.dart';
import 'manage_prizes_screen.dart';
import 'parent_history_screen.dart';
import 'pending_requests_screen.dart';
import 'manage_family_screen.dart';
import '../../widgets/avatar_widget.dart';
import '../child/child_stats_screen.dart';

class ParentHome extends StatelessWidget {
  const ParentHome({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final user = session.currentUser!;
    final cs = Theme.of(context).colorScheme;
    final db = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user.name}!'),
        actions: [
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Children balances
            Text('Balances', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            StreamBuilder<List<AppUser>>(
              stream: db.usersStream,
              builder: (context, snap) {
                final children = (snap.data ?? [])
                    .where((u) => u.role == UserRole.child)
                    .toList();
                if (children.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No children added yet.'),
                    ),
                  );
                }
                return Row(
                  children: children.map((child) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChildStatsScreen(
                              childId: child.id,
                              childName: child.name,
                            ),
                          ),
                        ),
                        child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.balanceGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            AvatarWidget(
                              avatar: child.avatarEmoji ?? '😊',
                              size: 48,
                              fontSize: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              child.name,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${child.balance}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'dbux',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Pending requests badge
            StreamBuilder<List<RedemptionRequest>>(
              stream: db.redemptionsStream(status: RedemptionStatus.pending),
              builder: (context, snap) {
                final pending = snap.data ?? [];
                if (pending.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    color: cs.tertiaryContainer,
                    child: ListTile(
                      leading: Badge(
                        label: Text('${pending.length}'),
                        child: Icon(Icons.redeem, color: cs.tertiary),
                      ),
                      title: Text(
                        '${pending.length} pending redemption${pending.length == 1 ? '' : 's'}',
                        style: TextStyle(color: cs.onTertiaryContainer),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PendingRequestsScreen()),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Quick actions
            Text('Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _ActionCard(
              icon: Icons.add_circle_outline,
              color: AppTheme.earnedColor,
              title: 'Award dbux',
              subtitle: 'Give points for tasks & chores',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AwardDbuxScreen()),
              ),
            ),
            _ActionCard(
              icon: Icons.remove_circle_outline,
              color: AppTheme.redeemedColor,
              title: 'Manual redeem',
              subtitle: 'Deduct points (already paid)',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AwardDbuxScreen(isRedeem: true)),
              ),
            ),
            _ActionCard(
              icon: Icons.card_giftcard,
              color: cs.primary,
              title: 'Manage prizes',
              subtitle: 'Add or edit available rewards',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManagePrizesScreen()),
              ),
            ),
            _ActionCard(
              icon: Icons.checklist,
              color: cs.tertiary,
              title: 'Pending requests',
              subtitle: 'Approve or deny redemptions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PendingRequestsScreen()),
              ),
            ),
            _ActionCard(
              icon: Icons.history,
              color: cs.secondary,
              title: 'History',
              subtitle: 'All dbux transactions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ParentHistoryScreen()),
              ),
            ),
            _ActionCard(
              icon: Icons.family_restroom,
              color: cs.onSurfaceVariant,
              title: 'Manage family',
              subtitle: 'Add or edit family members',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageFamilyScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
