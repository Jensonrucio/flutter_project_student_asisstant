import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../domain/auth_session.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthApi {
  AuthApi({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<AuthSession> login({required String email, required String password}) {
    return _authenticate({
      'action': 'login',
      'email': email.trim(),
      'password': password,
    });
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _authenticate({
      'action': 'register',
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
    });
  }

  Future<String> requestPasswordReset({required String email}) async {
    late final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(ApiConstants.authEndpoint),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'action': 'request_password_reset',
              'email': email.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const AuthApiException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'Could not connect to the password reset service.',
      );
    }

    Map<String, dynamic> body;
    try {
      body = Map<String, dynamic>.from(json.decode(response.body) as Map);
    } on Object {
      throw const AuthApiException(
        'The password reset service returned an invalid response.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final message = body['message'];
      if (message is String && message.isNotEmpty) return message;
      throw const AuthApiException(
        'The password reset service returned an incomplete response.',
      );
    }

    final error = body['error'];
    throw AuthApiException(
      error is String && error.isNotEmpty
          ? error
          : 'Could not request a password reset. Please try again.',
    );
  }

  Future<AuthSession> _authenticate(Map<String, String> payload) async {
    late final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(ApiConstants.authEndpoint),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const AuthApiException(
        'The server took too long to respond. Check that Apache and MySQL are running.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'Could not connect to XAMPP. Check the server address and make sure Apache and MySQL are running.',
      );
    }

    Map<String, dynamic> body;
    try {
      body = Map<String, dynamic>.from(json.decode(response.body) as Map);
    } on Object {
      throw const AuthApiException(
        'The authentication server returned an invalid response.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return AuthSession.fromJson(body);
      } on Object {
        throw const AuthApiException(
          'The authentication server returned an incomplete session.',
        );
      }
    }

    final message = body['error'];
    if (message is String && message.isNotEmpty) {
      throw AuthApiException(message);
    }
    throw AuthApiException(
      response.statusCode >= 500
          ? 'Authentication service is temporarily unavailable.'
          : 'Sign in failed. Check your details and try again.',
    );
  }

  Future<void> logout(String accessToken) async {
    try {
      await _client
          .post(
            Uri.parse(ApiConstants.authEndpoint),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: json.encode({'action': 'logout'}),
          )
          .timeout(const Duration(seconds: 8));
    } on Object {
      // The client still clears its in-memory session when the server is offline.
    }
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
