import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/device_utils.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../../core/constants.dart';

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

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

    final user =
        UserModel.fromJson(response['driver'] ?? response['user'] ?? response);
    await _saveUser(user);
    return user;
  }

  Future<UserModel> login({
    String? code,
    String? phone,
    String? password,
  }) async {
    // Collect real device info using utility
    final deviceContext = await DeviceUtils.GetDeviceContext();

    final response = await ApiService.instance.login(
      code: code,
      phone: phone,
      password: password,
      deviceContext: deviceContext,
    );

    final user = UserModel.fromJson(response);
    await _saveUser(user);
    return user;
  }

  // ===== Logout =====

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyUserData);
    await prefs.remove('cached_audio_list');
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

  Future<void> deleteAccount() async {
    // Note: Implementation usually calls an API to delete data then log out.
    await logout();
  }

  // ===== Private =====

  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user.token != null) {
      await prefs.setString(AppConstants.keyAuthToken, user.token!);
    }
    await prefs.setString(AppConstants.keyUserData, user.toJsonString());
  }
}
