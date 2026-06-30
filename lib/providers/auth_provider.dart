import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/api_client.dart';
import '../data/services/api_service.dart';

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
  bool get sessionExpired => _sessionExpired;

  bool _sessionExpired = false;

  // ===== Init =====

  Future<void> checkAuth() async {
    _setStatus(AuthStatus.loading);
    _sessionExpired = false;
    try {
      if (!await AuthRepository.instance.isLoggedIn()) {
        _user = null;
        _setStatus(AuthStatus.unauthenticated);
        return;
      }

      final validation = await AuthRepository.instance.validateSession();
      switch (validation) {
        case SessionValidation.valid:
        case SessionValidation.offline:
          _user = await AuthRepository.instance.getStoredUser();
          _setStatus(AuthStatus.authenticated);
        case SessionValidation.invalid:
          await AuthRepository.instance.expireSession();
          _user = null;
          _sessionExpired = true;
          _setStatus(AuthStatus.unauthenticated);
        case SessionValidation.noToken:
          _user = null;
          _setStatus(AuthStatus.unauthenticated);
      }
    } catch (_) {
      _user = null;
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
    // 🟢 Gọi API huỷ token phía server (best-effort). BỌC timeout để KHÔNG BAO GIỜ
    //    làm treo nút đăng xuất nếu mạng chậm / server không phản hồi.
    try {
      await ApiService.instance.logout().timeout(const Duration(seconds: 3));
    } catch (_) {
      // Mạng lỗi / quá hạn → vẫn tiếp tục đăng xuất cục bộ.
    }

    await AuthRepository.instance.expireSession();

    _user = null;
    _sessionExpired = false;
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
