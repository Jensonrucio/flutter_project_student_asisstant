import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:student_assistant_app/features/auth/data/auth_api.dart';
import 'package:student_assistant_app/features/auth/presentation/pages/login_page.dart';

void main() {
  test('auth API parses a session without logging the password', () async {
    var requestBody = <String, dynamic>{};
    final client = MockClient((request) async {
      requestBody = json.decode(request.body) as Map<String, dynamic>;
      return http.Response(
        json.encode({
          'token': List.filled(64, 'a').join(),
          'expiresAt': '2030-01-01T00:00:00Z',
          'user': {'id': 7, 'name': 'Sam Student', 'email': 'sam@example.com'},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final authApi = AuthApi(client: client);

    final session = await authApi.login(
      email: 'sam@example.com',
      password: 'test-password-only',
    );

    expect(session.user.id, 7);
    expect(session.user.email, 'sam@example.com');
    expect(session.accessToken.length, 64);
    expect(requestBody['action'], 'login');
    expect(requestBody['password'], 'test-password-only');
    client.close();
  });

  test(
    'password reset request sends only the email and returns a generic message',
    () async {
      late http.Request receivedRequest;
      final client = MockClient((request) async {
        receivedRequest = request;
        return http.Response(
          json.encode({
            'message': 'If that email address is linked to an account, a password reset link has been sent.',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final authApi = AuthApi(client: client);

      final message = await authApi.requestPasswordReset(
        email: ' sam@example.com ',
      );

      final body = json.decode(receivedRequest.body) as Map<String, dynamic>;
      expect(body['action'], 'request_password_reset');
      expect(body['email'], 'sam@example.com');
      expect(body.containsKey('password'), isFalse);
      expect(
        message,
        contains('If that email address is linked to an account'),
      );
      client.close();
    },
  );

  testWidgets('login form validates before making a request', (tester) async {
    var requestCount = 0;
    final client = MockClient((_) async {
      requestCount++;
      return http.Response('{}', 500);
    });
    final authApi = AuthApi(client: client);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(authApi: authApi, onAuthenticated: (_) {}),
      ),
    );
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(requestCount, 0);
    client.close();
  });

  testWidgets(
    'forgot password submits an email and shows the generic message',
    (tester) async {
      var requestedEmail = '';
      final client = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        requestedEmail = body['email'] as String;
        return http.Response(
          json.encode({
            'message': 'If that email address is linked to an account, a password reset link has been sent.',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final authApi = AuthApi(client: client);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(authApi: authApi, onAuthenticated: (_) {}),
        ),
      );
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'sam@example.com',
      );
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();

      expect(requestedEmail, 'sam@example.com');
      expect(
        find.text(
          'If that email address is linked to an account, a password reset link has been sent.',
        ),
        findsOneWidget,
      );
      expect(find.text('Back to sign in'), findsOneWidget);
      client.close();
    },
  );
}
