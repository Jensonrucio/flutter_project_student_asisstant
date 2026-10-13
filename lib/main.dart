import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/auth/data/auth_api.dart';
import 'features/auth/domain/auth_session.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'core/theme/glass_theme.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';

void main() {
  runApp(const StudentAssistantApp());
}

class StudentAssistantApp extends StatefulWidget {
  const StudentAssistantApp({super.key});

  @override
  State<StudentAssistantApp> createState() => _StudentAssistantAppState();
}

class _StudentAssistantAppState extends State<StudentAssistantApp> {
  final _authApi = AuthApi();
  AuthSession? _session;

  @override
  void dispose() {
    _authApi.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: GlassTheme.cyanAccent,
          brightness: Brightness.dark,
        ).copyWith(
          primary: GlassTheme.cyanAccent,
          secondary: GlassTheme.accentNeon,
          surface: const Color(0xFF142033),
        ),
        scaffoldBackgroundColor: GlassTheme.primaryDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: GlassTheme.primaryDark,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: session == null
          ? LoginPage(authApi: _authApi, onAuthenticated: _onAuthenticated)
          : MultiBlocProvider(
              providers: [
                BlocProvider<TaskBloc>(
                  create: (_) =>
                      TaskBloc(accessToken: session.accessToken)
                        ..add(FetchTasksEvent()),
                ),
              ],
              child: StudentDashboardPage(
                accessToken: session.accessToken,
                userName: session.user.name,
                onLogout: _signOut,
              ),
            ),
    );
  }

  void _onAuthenticated(AuthSession session) {
    setState(() => _session = session);
  }

  Future<void> _signOut() async {
    final session = _session;
    setState(() => _session = null);
    if (session != null) await _authApi.logout(session.accessToken);
  }
}
