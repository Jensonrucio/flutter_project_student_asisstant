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

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: taskBloc,
          child: const StudentDashboardPage(
            accessToken: 'test-token',
            userName: 'Sam Student',
            onLogout: _doNothing,
          ),
        ),
      ),
    );

    expect(find.text("TODAY'S PROGRESS"), findsNothing);
    expect(find.text('Your plan is clear'), findsNothing);
    expect(find.text('Your tasks'), findsOneWidget);
    expect(find.text('No pending tasks in this view.'), findsOneWidget);
  });
}

void _doNothing() {}
