import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:student_assistant_app/main.dart';
import 'package:student_assistant_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:student_assistant_app/features/tasks/presentation/bloc/task_bloc.dart';

void main() {
  testWidgets('student assistant app starts at login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StudentAssistantApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('dashboard prioritizes tasks without the progress banner', (
    WidgetTester tester,
  ) async {
    final taskBloc = TaskBloc();
    addTearDown(taskBloc.close);
    var selectedDarkTheme = false;
    var didLogOut = false;

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: taskBloc,
          child: StudentDashboardPage(
            accessToken: 'test-token',
            userName: 'Sam Student',
            onLogout: () => didLogOut = true,
            isDarkTheme: false,
            onThemeChanged: (isDark) => selectedDarkTheme = isDark,
          ),
        ),
      ),
    );

    expect(find.text("TODAY'S PROGRESS"), findsNothing);
    expect(find.text('Your plan is clear'), findsNothing);
    expect(find.text('Your tasks'), findsOneWidget);
    expect(find.text('No pending tasks in this view.'), findsOneWidget);

    await tester.tap(find.byTooltip('Main menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark theme'));
    await tester.pumpAndSettle();

    expect(selectedDarkTheme, isTrue);

    await tester.tap(find.byTooltip('Main menu'));
    await tester.pumpAndSettle();
    expect(find.text('Light theme'), findsOneWidget);
    expect(find.text('Dark theme'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(didLogOut, isTrue);
  });
}
