import 'dart:async';
import '../../core/constants.dart';

/// Mock API service - simulates server responses.
/// Replace with real Dio HTTP calls when backend is ready.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // Simulate network delay
  Future<void> _delay([int ms = 800]) =>
      Future.delayed(Duration(milliseconds: ms));

  // ===== AUTH =====

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    await _delay(1200);
    if (phone.isEmpty || password.length < 6) {
      throw Exception('Số điện thoại hoặc mật khẩu không đúng');
    }
    return {
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'id': 'user_001',
        'phone': phone,
        'name': 'Nguyễn Văn A',
        'license_plate': '51A-12345',
        'generate_credits': 3,
        'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      },
    };
  }

  Future<Map<String, dynamic>> signup({
    required String phone,
    required String name,
    required String password,
    required String licensePlate,
  }) async {
    await _delay(1500);
    return {
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'phone': phone,
        'name': name,
        'license_plate': licensePlate,
        'generate_credits': AppConstants.defaultGenerateCredits,
        'token': 'mock_token_new',
      },
    };
  }

  // ===== AUDIO LIST =====

  /// Returns list of audio metadata from server.
  /// In production: GET /v1/audio
  Future<List<Map<String, dynamic>>> getAudioList() async {
    await _delay(1000);
    return [
      {
        'id': 'audio_greeting_default',
        'title': 'Lời chào - Mặc định',
        'type': 'greeting',
        'remote_url': 'mock://audio/greeting_default.mp3',
        'description': 'Lời chào tự động khi xe khởi động',
        'duration_seconds': 8,
      },
      {
        'id': 'audio_goodbye_default',
        'title': 'Lời tạm biệt - Mặc định',
        'type': 'goodbye',
        'remote_url': 'mock://audio/goodbye_default.mp3',
        'description': 'Lời tạm biệt khi tắt xe',
        'duration_seconds': 6,
      },
      {
        'id': 'audio_greeting_premium',
        'title': 'Lời chào - Premium',
        'type': 'greeting',
        'remote_url': 'mock://audio/greeting_premium.mp3',
        'description': 'Phiên bản lời chào cao cấp',
        'duration_seconds': 10,
      },
    ];
  }

  // ===== GENERATE AUDIO =====

  Future<Map<String, dynamic>> generateAudio({
    required String ownerName,
    required String licensePlate,
    required String carBrand,
    required String type,
  }) async {
    await _delay(3000);
    return {
      'id': 'audio_gen_${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Lời chào - $ownerName',
      'type': type,
      'remote_url': 'mock://audio/generated_${DateTime.now().millisecondsSinceEpoch}.mp3',
      'description': 'Đã tạo cho $ownerName · $licensePlate · $carBrand',
      'duration_seconds': 8,
    };
  }
}

