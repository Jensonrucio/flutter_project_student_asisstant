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
  ThemeMode _themeMode = ThemeMode.dark;

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
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
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
                isDarkTheme: _themeMode == ThemeMode.dark,
                onThemeChanged: _setTheme,
              ),
            ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: GlassTheme.cyanAccent,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? GlassTheme.cyanAccent : const Color(0xFF087F73),
      secondary: GlassTheme.accentNeon,
      surface: isDark ? GlassTheme.surfaceDark : Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? GlassTheme.primaryDark
          : const Color(0xFFF4F7FB),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? GlassTheme.primaryDark : Colors.white,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  void _setTheme(bool isDark) {
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
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
