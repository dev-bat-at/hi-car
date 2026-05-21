import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_model.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';
import '../../core/constants.dart';

class AudioRepository {
  AudioRepository._();
  static final AudioRepository instance = AudioRepository._();

  // ===== Load Local =====

  /// Loads the saved audio list from SharedPreferences.
  Future<List<AudioModel>> loadLocalAudioList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(AppConstants.keyAudioList);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      return AudioModel.fromJsonList(jsonString);
    } catch (_) {
      return [];
    }
  }

  // ===== Sync =====

  /// Full sync: fetch from server → download files → save metadata locally.
  Future<List<AudioModel>> syncFromServer({
    void Function(String message, double progress)? onProgress,
  }) async {
    final audioList = await SyncService.instance.syncAudioFromServer(
      onProgress: onProgress,
    );

    // Restore active states from saved prefs
    final prefs = await SharedPreferences.getInstance();
    final greetingId = prefs.getString(AppConstants.keyGreetingAudioId) ?? '';
    final goodbyeId = prefs.getString(AppConstants.keyGoodbyeAudioId) ?? '';

    final updated = audioList.map((a) {
      return a.copyWith(
        isActiveGreeting: a.id == greetingId,
        isActiveGoodbye: a.id == goodbyeId,
      );
    }).toList();

    await saveLocalList(updated);
    return updated;
  }

  // ===== Set Active Audio =====

  Future<List<AudioModel>> setGreetingAudio(
    String audioId,
    List<AudioModel> currentList,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyGreetingAudioId, audioId);

    final updated = currentList.map((a) {
      return a.copyWith(isActiveGreeting: a.id == audioId);
    }).toList();

    await saveLocalList(updated);
    return updated;
  }

  Future<List<AudioModel>> setGoodbyeAudio(
    String audioId,
    List<AudioModel> currentList,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyGoodbyeAudioId, audioId);

    final updated = currentList.map((a) {
      return a.copyWith(isActiveGoodbye: a.id == audioId);
    }).toList();

    await saveLocalList(updated);
    return updated;
  }

  // ===== Generate Audio =====

  Future<AudioModel> generateAudio({
    required String ownerName,
    required String licensePlate,
    required String carBrand,
    required String type,
  }) async {
    final raw = await ApiService.instance.generateAudio(
      ownerName: ownerName,
      licensePlate: licensePlate,
      carBrand: carBrand,
      type: type,
    );
    return AudioModel.fromJson(raw);
  }

  // ===== Get Active Paths =====

  Future<String?> getGreetingAudioPath() async {
    final prefs = await SharedPreferences.getInstance();
    final greetingId = prefs.getString(AppConstants.keyGreetingAudioId) ?? '';
    if (greetingId.isEmpty) return null;
    final list = await loadLocalAudioList();
    final audio = list.where((a) => a.id == greetingId).firstOrNull;
    if (audio == null || !audio.hasLocalFile) return null;
    final exists = await SyncService.instance.fileExists(audio.localPath);
    return exists ? audio.localPath : null;
  }

  Future<String?> getGoodbyeAudioPath() async {
    final prefs = await SharedPreferences.getInstance();
    final goodbyeId = prefs.getString(AppConstants.keyGoodbyeAudioId) ?? '';
    if (goodbyeId.isEmpty) return null;
    final list = await loadLocalAudioList();
    final audio = list.where((a) => a.id == goodbyeId).firstOrNull;
    if (audio == null || !audio.hasLocalFile) return null;
    final exists = await SyncService.instance.fileExists(audio.localPath);
    return exists ? audio.localPath : null;
  }

  // ===== Delete =====

  Future<List<AudioModel>> deleteAudio(
    String audioId,
    List<AudioModel> currentList,
  ) async {
    final audio = currentList.where((a) => a.id == audioId).firstOrNull;
    if (audio?.localPath != null) {
      await SyncService.instance.deleteLocalFile(audio!.localPath!);
    }
    final updated = currentList
        .where((a) => a.id != audioId)
        .toList();
    await saveLocalList(updated);
    return updated;
  }

  // ===== Save Local List =====

  Future<void> saveLocalList(List<AudioModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAudioList, AudioModel.toJsonList(list));
  }
}
