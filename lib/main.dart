import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/session_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/setup_screen.dart';
import 'screens/parent/parent_home.dart';
import 'screens/child/child_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.signInAnonymously();
  runApp(const RewardingApp());
}

class RewardingApp extends StatelessWidget {
  const RewardingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionProvider()..loadUsers(),
      child: MaterialApp(
        title: 'Rewarding',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const _AppShell(),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  bool? _hasFamily;

  @override
  void initState() {
    super.initState();
    _checkFamily();
  }

  Future<void> _checkFamily() async {
    final session = context.read<SessionProvider>();
    final has = await session.hasFamilyData();
    if (mounted) setState(() => _hasFamily = has);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    // Still checking
    if (_hasFamily == null || session.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // No family set up yet — show setup wizard
    if (!_hasFamily! && session.allUsers.isEmpty) {
      return const SetupScreen();
    }

    // Reload after setup
    if (_hasFamily == false && session.allUsers.isNotEmpty) {
      _hasFamily = true;
    }

    // Not logged in
    if (!session.isLoggedIn) {
      return const LoginScreen();
    }

    // Logged in — route by role
    if (session.isParent) {
      return const ParentHome();
    }
    return const ChildHome();
  }
}
