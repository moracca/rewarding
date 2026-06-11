import 'package:flutter/material.dart';
import '../../models/prize.dart';
import '../../services/firestore_service.dart';
import '../../theme/emoji_sets.dart';
import '../../widgets/emoji_picker_dialog.dart';

class ManagePrizesScreen extends StatelessWidget {
  const ManagePrizesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Prizes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPrizeDialog(context, db),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Prize>>(
        stream: db.prizesStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final prizes = snap.data ?? [];
          if (prizes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.card_giftcard, size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 12),
                  Text('No prizes yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Tap + to add one',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prizes.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final reordered = List<Prize>.from(prizes);
              final item = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, item);
              db.reorderPrizes(reordered);
            },
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) => Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(16),
                  child: child,
                ),
                child: child,
              );
            },
            itemBuilder: (context, i) {
              final p = prizes[i];
              return Card(
                key: ValueKey(p.id),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(p.emoji ?? '🎁',
                        style: const TextStyle(fontSize: 24)),
                  ),
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: p.description != null && p.description!.isNotEmpty
                      ? Text(p.description!)
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${p.cost} dbux',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.drag_handle, color: cs.onSurfaceVariant),
                    ],
                  ),
                  onTap: () => _showPrizeDialog(context, db, existing: p),
                  onLongPress: () => _confirmDelete(context, db, p),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPrizeDialog(BuildContext context, FirestoreService db,
      {Prize? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final costCtrl =
        TextEditingController(text: existing != null ? '${existing.cost}' : '');
    String emoji = existing?.emoji ?? '🎁';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Edit Prize' : 'New Prize'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await showEmojiPicker(
                      ctx,
                      emojis: EmojiSets.prizes,
                      title: 'Pick a prize icon',
                      selected: emoji,
                    );
                    if (picked != null) setDialogState(() => emoji = picked);
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 4),
                Text('Tap to change', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Prize name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Description (optional)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: costCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cost (dbux)',
                  ),
                  keyboardType: TextInputType.number,
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
                final cost = int.tryParse(costCtrl.text.trim());
                if (nameCtrl.text.trim().isEmpty || cost == null || cost <= 0) {
                  return;
                }
                if (existing != null) {
                  await db.updatePrize(existing.id, {
                    'name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'cost': cost,
                    'emoji': emoji,
                  });
                } else {
                  await db.createPrize(Prize(
                    id: '',
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    cost: cost,
                    emoji: emoji,
                  ));
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(existing != null ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FirestoreService db, Prize p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete prize?'),
        content: Text('Remove "${p.name}" from the prize list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await db.deletePrize(p.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
