class VoiceTemplate {
  final String id;
  final String name;
  final String contentVi;
  final String contentEn;
  final String content;
  final String previewUrl;

  VoiceTemplate({
    required this.id,
    required this.name,
    required this.contentVi,
    required this.contentEn,
    required this.content,
    required this.previewUrl,
  });

  factory VoiceTemplate.fromJson(Map<String, dynamic> json) {
    return VoiceTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      contentVi: json['content_vi'] as String? ?? '',
      contentEn: json['content_en'] as String? ?? '',
      content: json['content'] as String? ?? '',
      previewUrl: json['preview_url'] as String? ?? '',
    );
  }
}

class VoiceSample {
  final int id;
  final String name;
  final String gender;
  final String? previewUrl;

  VoiceSample({
    required this.id,
    required this.name,
    required this.gender,
    this.previewUrl,
  });

  factory VoiceSample.fromJson(Map<String, dynamic> json) {
    return VoiceSample(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      gender: json['gender'] as String? ?? 'male',
      previewUrl: json['preview_url'] as String?,
    );
  }
}

class BackgroundMusic {
  final int id;
  final String name;
  final bool isDefault;
  final String previewUrl;

  BackgroundMusic({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.previewUrl,
  });

  factory BackgroundMusic.fromJson(Map<String, dynamic> json) {
    return BackgroundMusic(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      previewUrl: json['preview_url'] as String? ?? '',
    );
  }
}

class SignalSound {
  final int id;
  final String name;
  final bool isDefault;
  final String previewUrl;

  SignalSound({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.previewUrl,
  });

  factory SignalSound.fromJson(Map<String, dynamic> json) {
    return SignalSound(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      previewUrl: json['preview_url'] as String? ?? '',
    );
  }
}

class StudioData {
  final List<VoiceTemplate> templates;
  final List<VoiceSample> voiceSamples;
  final List<BackgroundMusic> backgroundMusics;
  final List<SignalSound> signalSounds;
  final Map<String, dynamic> currentVehicle;

  StudioData({
    required this.templates,
    required this.voiceSamples,
    required this.backgroundMusics,
    required this.signalSounds,
    required this.currentVehicle,
  });

  factory StudioData.fromJson(Map<String, dynamic> json) {
    return StudioData(
      templates: (json['templates'] as List? ?? [])
          .map((e) => VoiceTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
      voiceSamples: (json['voice_samples'] as List? ?? [])
          .map((e) => VoiceSample.fromJson(e as Map<String, dynamic>))
          .toList(),
      backgroundMusics: (json['background_musics'] as List? ?? [])
          .map((e) => BackgroundMusic.fromJson(e as Map<String, dynamic>))
          .toList(),
      signalSounds: (json['signal_sounds'] as List? ?? [])
          .map((e) => SignalSound.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentVehicle: json['current_vehicle'] as Map<String, dynamic>? ?? {},
    );
  }
}

class StudioPreviewResponse {
  final bool success;
  final String message;
  final String previewUrl;
  final String contentUsed;

  StudioPreviewResponse({
    required this.success,
    required this.message,
    required this.previewUrl,
    required this.contentUsed,
  });

  factory StudioPreviewResponse.fromJson(Map<String, dynamic> json) {
    return StudioPreviewResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      previewUrl: json['preview_url'] as String? ??
          '', // Adjusted for nesting if needed
      contentUsed: json['content_used'] as String? ?? '',
    );
  }
}

class StudioOrderResponse {
  final int orderId;
  final String orderCode;
  final String paymentQrUrl;

  StudioOrderResponse({
    required this.orderId,
    required this.orderCode,
    required this.paymentQrUrl,
  });

  factory StudioOrderResponse.fromJson(Map<String, dynamic> json) {
    return StudioOrderResponse(
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      orderCode: json['order_code'] as String? ?? '',
      paymentQrUrl: json['payment_qr_url'] as String? ?? '',
    );
  }
}
