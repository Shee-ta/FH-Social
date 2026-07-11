import 'package:flutter/foundation.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/environment/environment.dart';
import 'package:frontend/services/entity_services/user_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart' as jwt_decoder;

import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {

  final String baseUrl;

  final AuthService _authService;
  final UserService _userService;
  String? get accessToken => _authService.accessToken;

  AuthController()
  : baseUrl = Environment.getBaseUrl(), 
    _authService = AppDI.instance.authService,
    _userService = AppDI.instance.userService;

  bool _isLoggedIn = false;
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  String _userId = '';
  String get userId => _userId;

  String _username = '';
  String get username => _username;

  String _displayname = '';
  String get displayname => _displayname;

  void setUserInfo({
    required String userId,
    required String username,
    required String displayname,
  }) {
    _userId = userId;
    _username = username;
    _displayname = displayname;
    notifyListeners();
  }

  Future<bool> restoreSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _authService.restoreSession();

      if (!_isLoggedIn) {
        return false;
      }

      if (accessToken == null || accessToken!.isEmpty) {
        _isLoggedIn = false;
        return false;
      }

      final claims = jwt_decoder.JwtDecoder.decode(accessToken!);
      final restoredUserId = claims['sub']?.toString() ?? '';
      final restoredUsername = claims['username']?.toString() ?? '';

      if (restoredUserId.isEmpty) {
        _isLoggedIn = false;
        return false;
      }

      setUserInfo(
        userId: restoredUserId,
        username: restoredUsername,
        displayname: restoredUsername,
      );

      final user = await _userService.fetchUserById(restoredUserId);
      if (user != null) {
        setUserInfo(
          userId: user.id,
          username: user.username,
          displayname: user.displayname,
        );
      }

      return true;
    } catch (_) {
      _isLoggedIn = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AuthReply> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(
        username: username,
        password: password,
      );

      _isLoggedIn = result.reply == AuthReply.success;
      if (_isLoggedIn && result.userId.isNotEmpty) {
        setUserInfo(
          userId: result.userId,
          username: result.username,
          displayname: result.displayname,
        );
      }
      return result.reply;
    } catch (_) {
      _isLoggedIn = false;
      return AuthReply.connectionError;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (!_isLoggedIn || _isLoading) {
      return;
    }

    final wasLoggedIn = _isLoggedIn;

    _isLoading = true;
    _isLoggedIn = false;
    notifyListeners();

    try {
      final reply = await _authService.logout();
      if (reply != AuthReply.loggedOut) {
        _isLoggedIn = wasLoggedIn;
      }
      else if (reply == AuthReply.loggedOut) {
        _userId = '';
        _username = '';
        _displayname = '';
      }
    } catch (_) {
      _isLoggedIn = wasLoggedIn;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
