import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../../core/constants.dart';

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  // ===== Login =====

  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    final response = await ApiService.instance.login(
      phone: phone,
      password: password,
    );

    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    await _saveUser(user);
    return user;
  }

  // ===== Signup =====

  Future<UserModel> signup({
    required String phone,
    required String name,
    required String password,
    required String licensePlate,
  }) async {
    final response = await ApiService.instance.signup(
      phone: phone,
      name: name,
      password: password,
      licensePlate: licensePlate,
    );

    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    await _saveUser(user);
    return user;
  }

  // ===== Logout =====

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyUserData);
  }

  // ===== Check Auth =====

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyAuthToken) != null;
  }

  Future<UserModel?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(AppConstants.keyUserData);
    if (userData == null) return null;
    try {
      return UserModel.fromJsonString(userData);
    } catch (_) {
      return null;
    }
  }

  // ===== Delete Account =====

  Future<void> deleteAccount() async {
    // TODO: Call API to delete account when backend ready
    await logout();
  }

  // ===== Private =====

  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAuthToken, user.token ?? '');
    await prefs.setString(AppConstants.keyUserData, user.toJsonString());
  }
}
