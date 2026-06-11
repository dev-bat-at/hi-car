class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String loginCode = '/api/auth/login/';
  static const String loginPhone = '/api/auth/login/phone/';
  static const String register = '/api/auth/register/';

  // Vehicles
  static const String vehicles = '/api/vehicles/';
  static const String selectVehicle = '/api/vehicles/select/';

  // Audio & Sync
  static const String audioList = '/api/audio/list/';
  static String downloadAudio(String id) => '/api/audio/download/$id/';

  // Studio (Voice Studio)
  static const String studioTemplates = '/api/v1/voice/templates/';
  static const String studioPreview = '/api/v1/voice/preview/';
  static const String studioOrders = '/api/v1/orders/';
  static String studioRecreate(String orderId) =>
      '/api/v1/orders/$orderId/recreate/';

  // Logs
  static const String errorLog = '/api/logs/error/';
}
