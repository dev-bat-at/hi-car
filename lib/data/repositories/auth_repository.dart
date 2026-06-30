import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/device_utils.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../../core/constants.dart';
import '../../native/service_channel.dart';

enum SessionValidation { noToken, valid, invalid, offline }

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
    // Auth & User
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyUserData);

    // Audio Metadata
    await prefs.remove(AppConstants.keyAudioList);
    await prefs.remove('cached_audio_list');

    // Audio Selection
    await prefs.remove(AppConstants.keyGreetingAudioId);
    await prefs.remove(AppConstants.keyGoodbyeAudioId);
    await prefs.remove('greeting_audio_path');
    await prefs.remove('goodbye_audio_path');

    // Others
    await prefs.remove(AppConstants.keyLastSyncTime);
  }

  /// Đăng xuất mềm khi token hết hạn: giữ danh sách nhạc + cấu hình lời chào/tạm biệt.
  Future<void> softLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyUserData);
  }

  /// Huỷ phiên: xoá token prefs + device-protected (Box boot không tự phát).
  Future<void> expireSession() async {
    await softLogout();
    try {
      await ServiceChannel.instance
          .clearAuthState()
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  /// Gọi GET /api/auth/me để xác minh token còn hợp lệ trên server.
  Future<SessionValidation> validateSession() async {
    if (!await isLoggedIn()) return SessionValidation.noToken;

    try {
      final me = await ApiService.instance.getMe();
      if (me.isEmpty) return SessionValidation.invalid;

      final isActive = me['is_active'];
      if (isActive == false) return SessionValidation.invalid;

      await _refreshUserFromMe(me);
      return SessionValidation.valid;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403 || code == 404) {
        return SessionValidation.invalid;
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        return SessionValidation.offline;
      }
      return SessionValidation.offline;
    } catch (_) {
      return SessionValidation.offline;
    }
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

  Future<void> _refreshUserFromMe(Map<String, dynamic> me) async {
    final stored = await getStoredUser();
    if (stored == null) return;

    final updated = stored.copyWith(
      id: (me['id'] ?? stored.id).toString(),
      name: me['name'] as String? ?? stored.name,
      phone: me['phone'] as String? ?? stored.phone,
      avatarUrl: me['avatar'] as String? ?? stored.avatarUrl,
    );
    await _saveUser(updated);
  }
}
