import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../services/session_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_widget.dart';

class AwardDbuxScreen extends StatefulWidget {
  final bool isRedeem;
  const AwardDbuxScreen({super.key, this.isRedeem = false});

  @override
  State<AwardDbuxScreen> createState() => _AwardDbuxScreenState();
}

class _AwardDbuxScreenState extends State<AwardDbuxScreen> {
  final _db = FirestoreService();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _selectedChildren = <String>{};
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRedeem ? 'Manual Redeem' : 'Award dbux'),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: _db.usersStream,
        builder: (context, snap) {
          final children = (snap.data ?? [])
              .where((u) => u.role == UserRole.child)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.isRedeem ? 'Who to deduct from?' : 'Who earned it?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  // Select all button
                  if (children.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            if (_selectedChildren.length == children.length) {
                              _selectedChildren.clear();
                            } else {
                              _selectedChildren.addAll(children.map((c) => c.id));
                            }
                          });
                        },
                        child: Text(
                          _selectedChildren.length == children.length
                              ? 'Deselect all'
                              : 'Select all',
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: children.map((child) {
                      final selected = _selectedChildren.contains(child.id);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedChildren.remove(child.id);
                            } else {
                              _selectedChildren.add(child.id);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? cs.primaryContainer
                                : cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: selected
                                ? Border.all(color: cs.primary, width: 2)
                                : Border.all(color: cs.outlineVariant),
                          ),
                          child: Column(
                            children: [
                              AvatarWidget(
                                  avatar: child.avatarEmoji ?? '😊',
                                  size: 48,
                                  fontSize: 32),
                              const SizedBox(height: 4),
                              Text(child.name),
                              Text(
                                '${child.balance} dbux',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _amountCtrl,
                    decoration: InputDecoration(
                      labelText: 'Amount (dbux)',
                      prefixIcon: Icon(
                        widget.isRedeem
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline,
                        color: widget.isRedeem
                            ? AppTheme.redeemedColor
                            : AppTheme.earnedColor,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  // Quick-amount chips
                  Wrap(
                    spacing: 8,
                    children: [5, 10, 25, 50, 100].map((v) {
                      return ActionChip(
                        label: Text('$v'),
                        onPressed: () => _amountCtrl.text = '$v',
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'What for?',
                      prefixIcon: Icon(Icons.edit_note),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : () => _save(session, children),
                    icon: Icon(widget.isRedeem ? Icons.remove : Icons.add),
                    label: Text(
                      _saving
                          ? 'Saving...'
                          : widget.isRedeem
                              ? 'Deduct dbux'
                              : 'Award dbux',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _save(SessionProvider session, List<AppUser> children) async {
    final amount = int.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      _showSnack('Enter a valid amount');
      return;
    }
    if (_selectedChildren.isEmpty) {
      _showSnack('Select at least one child');
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _showSnack('Add a description');
      return;
    }

    setState(() => _saving = true);

    for (final childId in _selectedChildren) {
      final child = children.firstWhere((c) => c.id == childId);
      if (widget.isRedeem) {
        await _db.manualRedeem(
          childId: childId,
          childName: child.name,
          amount: amount,
          description: _descCtrl.text.trim(),
          redeemedBy: session.currentUser!.name,
        );
      } else {
        await _db.awardDbux(
          childId: childId,
          childName: child.name,
          amount: amount,
          description: _descCtrl.text.trim(),
          awardedBy: session.currentUser!.name,
        );
      }
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isRedeem
              ? 'Deducted $amount dbux'
              : 'Awarded $amount dbux!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}
