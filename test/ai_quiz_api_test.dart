import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:student_assistant_app/features/ai_quiz/data/ai_quiz_api.dart';
import 'package:student_assistant_app/features/ai_quiz/presentation/pages/quiz_chat_page.dart';

void main() {
  final questions = List.generate(
    10,
    (index) => {
      'question': 'Question $index?',
      'options': ['A', 'B', 'C', 'D'],
      'correct_index': 1,
    },
  );

  test('AI quiz API uses the authenticated Gemini backend', () async {
    late http.Request receivedRequest;
    final client = MockClient((request) async {
      receivedRequest = request;
      return http.Response(
        json.encode({'provider': 'gemini', 'questions': questions}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = AiQuizApi(client: client);

    final result = await api.generateQuiz(
      notes: '  Biology notes  ',
      accessToken: 'session-token',
      questionCount: 10,
    );

    expect(receivedRequest.url.path, endsWith('/generate_quiz.php'));
    expect(receivedRequest.headers['authorization'], 'Bearer session-token');
    expect(json.decode(receivedRequest.body), {
      'notes': 'Biology notes',
      'question_count': 10,
    });
    expect(result, hasLength(10));
    expect(result.first['correct_index'], 1);
    client.close();
  });

  test('AI quiz API rejects malformed question data', () async {
    final client = MockClient(
      (_) async => http.Response(
        json.encode({
          'questions': [
            {
              'question': 'Question?',
              'options': ['Only one'],
              'correct_index': 0,
            },
          ],
        }),
        200,
      ),
    );
    final api = AiQuizApi(client: client);

    await expectLater(
      api.generateQuiz(
        notes: 'Biology notes',
        accessToken: 'session-token',
        questionCount: 5,
      ),
      throwsA(isA<AiQuizApiException>()),
    );
    client.close();
  });

  test('AI quiz API rejects responses from any non-Gemini provider', () async {
    final client = MockClient(
      (_) async => http.Response(
        json.encode({'provider': 'another-provider', 'questions': questions}),
        200,
      ),
    );
    final api = AiQuizApi(client: client);

    await expectLater(
      api.generateQuiz(
        notes: 'Biology notes',
        accessToken: 'session-token',
        questionCount: 10,
      ),
      throwsA(isA<AiQuizApiException>()),
    );
    client.close();
  });

  test(
    'AI quiz API rejects a response with a different question count',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          json.encode({'provider': 'gemini', 'questions': questions}),
          200,
        ),
      );
      final api = AiQuizApi(client: client);

      await expectLater(
        api.generateQuiz(
          notes: 'Biology notes',
          accessToken: 'session-token',
          questionCount: 5,
        ),
        throwsA(isA<AiQuizApiException>()),
      );
      client.close();
    },
  );

  test('AI quiz API rejects counts outside the supported range', () async {
    var requestSent = false;
    final client = MockClient((_) async {
      requestSent = true;
      return http.Response('{}', 200);
    });
    final api = AiQuizApi(client: client);

    await expectLater(
      api.generateQuiz(
        notes: 'Biology notes',
        accessToken: 'session-token',
        questionCount: 21,
      ),
      throwsA(isA<AiQuizApiException>()),
    );
    expect(requestSent, isFalse);
    client.close();
  });

  testWidgets('Study Buddy accepts uploaded notes and paste-in notes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: QuizChatPage(accessToken: 'session-token')),
    );

    expect(find.text('Study Buddy'), findsOneWidget);
    expect(find.text('Upload notes (PDF, TXT, DOCX)'), findsOneWidget);
    expect(find.text('Or paste your notes here...'), findsOneWidget);
    expect(find.text('Generate quiz from my notes'), findsOneWidget);
    expect(find.text('Number of questions'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10').last);
    await tester.pumpAndSettle();
    expect(find.text('10'), findsOneWidget);
    expect(
      find.text('Your notes are sent to Gemini only when you generate a quiz.'),
      findsOneWidget,
    );
  });
}
