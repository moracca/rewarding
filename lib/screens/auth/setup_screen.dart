import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/emoji_picker_dialog.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parentName = TextEditingController();
  final _parentPin = TextEditingController();
  final _children = <_ChildEntry>[_ChildEntry()];
  bool _saving = false;

  @override
  void dispose() {
    _parentName.dispose();
    _parentPin.dispose();
    for (final c in _children) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '🎉',
                      style: const TextStyle(fontSize: 48),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome to Rewarding!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up your family to get started.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Parent section
                    Text('Parent', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _parentName,
                      decoration: const InputDecoration(labelText: 'Your name'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _parentPin,
                      decoration: const InputDecoration(labelText: '4-digit PIN'),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      validator: (v) {
                        if (v == null || v.length != 4) return 'Enter 4 digits';
                        if (int.tryParse(v) == null) return 'Digits only';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Children section
                    Row(
                      children: [
                        Text('Children', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => setState(() => _children.add(_ChildEntry())),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_children.length, (i) {
                      final c = _children[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _pickEmoji(i),
                              child: AvatarWidget(avatar: c.emoji, size: 48),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: c.nameCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Child ${i + 1} name',
                                ),
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                controller: c.pinCtrl,
                                decoration: const InputDecoration(labelText: 'PIN'),
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                maxLength: 4,
                                validator: (v) {
                                  if (v == null || v.length != 4) return '4 digits';
                                  return null;
                                },
                              ),
                            ),
                            if (_children.length > 1)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() {
                                  _children[i].dispose();
                                  _children.removeAt(i);
                                }),
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Get Started'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _pickEmoji(int index) async {
    final picked = await showAvatarPicker(
      context,
      selected: _children[index].emoji,
    );
    if (picked != null) {
      setState(() => _children[index].emoji = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final session = context.read<SessionProvider>();
    await session.seedFamily(
      parentName: _parentName.text.trim(),
      parentPin: _parentPin.text.trim(),
      children: _children
          .map((c) => {
                'name': c.nameCtrl.text.trim(),
                'pin': c.pinCtrl.text.trim(),
                'emoji': c.emoji,
              })
          .toList(),
    );

    if (mounted) setState(() => _saving = false);
  }
}

class _ChildEntry {
  final nameCtrl = TextEditingController();
  final pinCtrl = TextEditingController();
  String emoji = '😊';

  void dispose() {
    nameCtrl.dispose();
    pinCtrl.dispose();
  }
}
