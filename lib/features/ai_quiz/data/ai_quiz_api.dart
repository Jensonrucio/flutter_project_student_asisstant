import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';

class AiQuizApiException implements Exception {
  const AiQuizApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AiQuizApi {
  AiQuizApi({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<List<Map<String, dynamic>>> generateQuiz({
    required String notes,
    required String accessToken,
    required int questionCount,
  }) async {
    if (questionCount < 1 || questionCount > 20) {
      throw const AiQuizApiException(
        'Choose between 1 and 20 questions for your quiz.',
      );
    }
    late final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(ApiConstants.aiQuizEndpoint),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: json.encode({
              'notes': notes.trim(),
              'question_count': questionCount,
            }),
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw const AiQuizApiException(
        'Gemini took too long to generate the quiz. Please try again.',
      );
    } on http.ClientException {
      throw const AiQuizApiException(
        'Could not connect to the AI quiz service. Check your connection.',
      );
    }

    Map<String, dynamic> body;
    try {
      body = Map<String, dynamic>.from(json.decode(response.body) as Map);
    } on Object {
      throw const AiQuizApiException(
        'The AI quiz service returned an invalid response.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body['error'];
      throw AiQuizApiException(
        message is String ? message : 'Gemini could not generate this quiz.',
      );
    }

    if (body['provider'] != 'gemini') {
      throw const AiQuizApiException(
        'Study Buddy is configured to use Gemini only.',
      );
    }

    final rawQuestions = body['questions'];
    if (rawQuestions is! List || rawQuestions.length != questionCount) {
      throw const AiQuizApiException(
        'Gemini returned an invalid quiz. Please try again.',
      );
    }

    final questions = <Map<String, dynamic>>[];
    for (final rawQuestion in rawQuestions) {
      if (rawQuestion is! Map) {
        throw const AiQuizApiException(
          'Gemini returned an invalid quiz. Please try again.',
        );
      }
      final question = Map<String, dynamic>.from(rawQuestion);
      final questionText = question['question'];
      final options = question['options'];
      final correctIndex = question['correct_index'];
      if (questionText is! String ||
          questionText.trim().isEmpty ||
          options is! List ||
          options.length != 4 ||
          options.any((option) => option is! String || option.trim().isEmpty) ||
          correctIndex is! int ||
          correctIndex < 0 ||
          correctIndex >= options.length) {
        throw const AiQuizApiException(
          'Gemini returned an invalid quiz. Please try again.',
        );
      }
      questions.add({
        'question': questionText,
        'options': List<String>.from(options),
        'correct_index': correctIndex,
      });
    }
    return questions;
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
