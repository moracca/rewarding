import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../services/session_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _selectedUserId;
  final _pinCtrl = TextEditingController();
  String? _error;
  bool _loggingIn = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final users = session.allUsers;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo area
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.balanceGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text('D', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rewarding',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Who\'s logging in?',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // User avatars
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: users.map((u) {
                      final selected = _selectedUserId == u.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedUserId = u.id;
                            _error = null;
                            _pinCtrl.clear();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: selected
                                ? Border.all(color: cs.primary, width: 2)
                                : Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            children: [
                              AvatarWidget(
                                avatar: u.avatarEmoji ?? (u.role == UserRole.parent ? '👨' : '😊'),
                                size: 48,
                                fontSize: 36,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                u.name,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                    ),
                              ),
                              Text(
                                u.role == UserRole.parent ? 'Parent' : 'Kid',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  if (_selectedUserId != null) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 160,
                      child: TextFormField(
                        controller: _pinCtrl,
                        decoration: const InputDecoration(
                          labelText: 'PIN',
                          counterText: '',
                        ),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        autofocus: true,
                        onFieldSubmitted: (_) => _login(),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: cs.error)),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loggingIn ? null : _login,
                      child: _loggingIn
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Log In'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_selectedUserId == null || _pinCtrl.text.length != 4) return;
    setState(() {
      _loggingIn = true;
      _error = null;
    });

    final ok = await context.read<SessionProvider>().login(
          _selectedUserId!,
          _pinCtrl.text,
        );

    if (!ok && mounted) {
      setState(() {
        _error = 'Wrong PIN. Try again.';
        _loggingIn = false;
        _pinCtrl.clear();
      });
    } else {
      setState(() => _loggingIn = false);
    }
  }
}
