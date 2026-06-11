import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/emoji_picker_dialog.dart';

class ManageFamilyScreen extends StatelessWidget {
  const ManageFamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Family')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMemberDialog(context, db),
        child: const Icon(Icons.person_add),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: db.usersStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snap.data ?? [];
          final parents = users.where((u) => u.role == UserRole.parent).toList();
          final children = users.where((u) => u.role == UserRole.child).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Parents', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...parents.map((u) => _MemberTile(user: u, db: db)),
              const SizedBox(height: 24),
              Text('Children', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...children.map((u) => _MemberTile(user: u, db: db)),
              if (children.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No children added yet.',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, FirestoreService db) {
    final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    UserRole role = UserRole.child;
    String emoji = '😊';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Add Family Member'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<UserRole>(
                    segments: const [
                      ButtonSegment(value: UserRole.parent, label: Text('Parent'), icon: Icon(Icons.person)),
                      ButtonSegment(value: UserRole.child, label: Text('Child'), icon: Icon(Icons.child_care)),
                    ],
                    selected: {role},
                    onSelectionChanged: (s) => setDialogState(() => role = s.first),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showAvatarPicker(ctx, selected: emoji);
                      if (picked != null) setDialogState(() => emoji = picked);
                    },
                    child: AvatarWidget(avatar: emoji, size: 64, fontSize: 36),
                  ),
                  const SizedBox(height: 4),
                  Text('Tap to change', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pinCtrl,
                    decoration: const InputDecoration(labelText: '4-digit PIN'),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || pinCtrl.text.length != 4) return;
                  await db.createUser(AppUser(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    role: role,
                    pin: pinCtrl.text.trim(),
                    avatarEmoji: emoji,
                    balance: 0,
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final AppUser user;
  final FirestoreService db;

  const _MemberTile({required this.user, required this.db});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: AvatarWidget(avatar: user.avatarEmoji ?? '😊'),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(user.role == UserRole.parent ? 'Parent' : 'Child'),
        trailing: user.role == UserRole.child
            ? Text('${user.balance} dbux',
                style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold))
            : null,
        onTap: () => _showEditDialog(context, user),
      ),
    );
  }

  void _showEditDialog(BuildContext context, AppUser user) {
    final nameCtrl = TextEditingController(text: user.name);
    final pinCtrl = TextEditingController(text: user.pin);
    String emoji = user.avatarEmoji ?? '😊';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit ${user.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await showAvatarPicker(ctx, selected: emoji);
                    if (picked != null) setDialogState(() => emoji = picked);
                  },
                  child: AvatarWidget(avatar: emoji, size: 64, fontSize: 36),
                ),
                const SizedBox(height: 4),
                Text('Tap to change', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pinCtrl,
                  decoration: const InputDecoration(labelText: '4-digit PIN'),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || pinCtrl.text.length != 4) return;
                await db.createUser(user.copyWith(
                  name: nameCtrl.text.trim(),
                  pin: pinCtrl.text.trim(),
                  avatarEmoji: emoji,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
