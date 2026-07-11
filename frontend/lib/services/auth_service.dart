import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/services/connection_services/http_retry.dart';
import 'package:frontend/services/ui_feedback_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart' as jwt_decoder;
import 'package:http/http.dart' as http;

import 'token_storage_service.dart';

enum AuthReply {
  success,
  invalidCredentials,
  loggedOut,
  connectionError,
}

class AuthLoginResult {
  const AuthLoginResult({
    required this.reply,
    this._userId = '',
    this._username = '',
    this._displayname = '',
  });

  final AuthReply reply;

  final String _userId;
  String get userId => _userId;

  final String _username;
  String get username => _username;

  final String _displayname;
  String get displayname => _displayname;
}

class AuthService {

  final String _baseUrl;
  final TokenStorageService _tokenStorage;
  String? _accessToken;

  String? get accessToken => _accessToken;

  AuthService(
    this._baseUrl
  )
  : _tokenStorage = TokenStorageService();

  Future<void> _onTokenExpired() async {
    await _tokenStorage.removeAccessToken();
    _accessToken = null;
    UIfeedbackService.notification(
      message: 'Session expired. Please log in again.',
      type: NotificationType.error
    );

  }

  Future<String?> getAccessToken() async {
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      return _accessToken;
    }

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      if (jwt_decoder.JwtDecoder.isExpired(token)) {
        await _onTokenExpired();
        return null;
      }
      _accessToken = token;
      return token;
    } catch (_) {
      await _tokenStorage.removeAccessToken();
      _accessToken = null;
      return null;
    }
  }

  Future<bool> restoreSession() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
       _accessToken = null;
      return false;
    }

    try {
      if (jwt_decoder.JwtDecoder.isExpired(token)) {
        await _onTokenExpired();
        return false;
      }
      _accessToken = token;
      return true;
    } catch (_) {
      await _tokenStorage.removeAccessToken();
      _accessToken = null;
      return false;
    }
  }

  String? _extractToken(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['accessToken'] as String?;
    } catch (_) {
      return null;
    }
  }

  ({String userId, String username, String displayname})? _extractUser(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final user = json['user'] as Map<String, dynamic>?;
      if (user != null) {
        return (
          userId: user['id'] as String? ?? '',
          username: user['username'] as String? ?? '',
          displayname: user['displayname'] as String? ?? '',
        );
      }
    } catch (e) {
      debugPrint('Error extracting user: $e');
    }
    return null;
  }

  Future<AuthLoginResult> login({
    required String username,
    required String password,
  }) async {

    final uri = Uri.parse('$_baseUrl/auth/login');

    final response = await retryHttpRequest(() => http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      })));

    if (response.statusCode >= 500) {
      return const AuthLoginResult(reply: AuthReply.connectionError);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const AuthLoginResult(reply: AuthReply.invalidCredentials);
    }

    final token = _extractToken(response.body);
    final user = _extractUser(response.body);

    if (token == null) {
      return const AuthLoginResult(reply: AuthReply.invalidCredentials);
    }

    try {
      if (jwt_decoder.JwtDecoder.isExpired(token)) {
        await _onTokenExpired();
        return const AuthLoginResult(reply: AuthReply.connectionError);
      }

      jwt_decoder.JwtDecoder.decode(token);
      await _tokenStorage.saveAccessToken(token);
      _accessToken = token;
      return AuthLoginResult(
        reply: AuthReply.success,
        userId: user?.userId ?? '',
        username: user?.username ?? '',
        displayname: user?.displayname ?? '',
      );
    } catch (_) {
      return const AuthLoginResult(reply: AuthReply.connectionError);
    }
  }

  Future<AuthReply> logout() async {
    await _tokenStorage.removeAccessToken();
    _accessToken = null;
    return AuthReply.loggedOut;
  }
}
