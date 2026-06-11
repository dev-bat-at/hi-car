import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/api_client.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _status == AuthStatus.authenticated && _user != null;
  bool get isLoading => _status == AuthStatus.loading;

  // ===== Init =====

  Future<void> checkAuth() async {
    _setStatus(AuthStatus.loading);
    try {
      final loggedIn = await AuthRepository.instance.isLoggedIn();
      if (loggedIn) {
        _user = await AuthRepository.instance.getStoredUser();
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (_) {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  // ===== Login =====

  Future<bool> login({
    String? code,
    String? phone,
    String? password,
  }) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;
    try {
      _user = await AuthRepository.instance.login(
        code: code,
        phone: phone,
        password: password,
      );
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _errorMessage = ApiClient.formatError(e);
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ===== Logout =====

  Future<void> logout() async {
    await AuthRepository.instance.logout();
    _user = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  // ===== Delete Account =====

  Future<void> deleteAccount() async {
    await AuthRepository.instance.deleteAccount();
    _user = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  // ===== Private =====

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
