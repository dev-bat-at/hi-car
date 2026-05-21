import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/audio_model.dart';
import '../services/api_service.dart';

/// SyncService - Downloads audio files from server and saves to local storage.
/// On sync: fetches metadata → downloads each file → returns updated models.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  /// Returns the app's audio storage directory, creating it if needed.
  Future<Directory> getAudioDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${docs.path}/hicar_audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }

  /// Main sync: fetches list from server, downloads all files, returns models.
  Future<List<AudioModel>> syncAudioFromServer({
    void Function(String message, double progress)? onProgress,
  }) async {
    onProgress?.call('Đang kết nối server...', 0.05);

    // 1. Fetch metadata list from API
    final rawList = await ApiService.instance.getAudioList();
    final List<AudioModel> result = [];

    onProgress?.call('Đã nhận ${rawList.length} file audio...', 0.2);

    final audioDir = await getAudioDir();
    final total = rawList.length;

    for (int i = 0; i < total; i++) {
      final raw = rawList[i];
      final audioModel = AudioModel.fromJson(raw);
      final progressBase = 0.2 + (i / total) * 0.75;

      onProgress?.call(
        'Đang tải "${audioModel.title}"... (${i + 1}/$total)',
        progressBase,
      );

      // 2. Download file to local storage
      final localPath = await _downloadAudioFile(
        audioDir: audioDir,
        audioId: audioModel.id,
        remoteUrl: audioModel.remoteUrl,
      );

      result.add(audioModel.copyWith(
        localPath: localPath,
        isDownloaded: localPath != null,
        downloadedAt: localPath != null ? DateTime.now() : null,
      ));
    }

    onProgress?.call('Đồng bộ hoàn tất!', 1.0);
    return result;
  }

  /// Downloads and caches a single audio file to local storage.
  Future<String?> downloadSingleFile({
    required String audioId,
    required String remoteUrl,
  }) async {
    final audioDir = await getAudioDir();
    return _downloadAudioFile(
      audioDir: audioDir,
      audioId: audioId,
      remoteUrl: remoteUrl,
    );
  }

  /// Downloads a single audio file.
  /// For mock URLs: copies the bundled default audio asset.
  /// For real URLs: use Dio to download from HTTP.
  Future<String?> _downloadAudioFile({
    required Directory audioDir,
    required String audioId,
    required String remoteUrl,
  }) async {
    final localFilePath = '${audioDir.path}/$audioId.mp3';

    try {
      if (remoteUrl.startsWith('mock://')) {
        // Demo: copy bundled asset to local storage
        await _copyAssetToLocal(
          assetPath: 'assets/audio/audio_default.MP3',
          destPath: localFilePath,
        );
      } else {
        // TODO: Replace with real Dio download when backend ready
        // final dio = Dio();
        // await dio.download(remoteUrl, localFilePath);
        await _copyAssetToLocal(
          assetPath: 'assets/audio/audio_default.MP3',
          destPath: localFilePath,
        );
      }
      return localFilePath;
    } catch (e) {
      return null;
    }
  }

  /// Copies a Flutter asset to a local file path.
  Future<void> _copyAssetToLocal({
    required String assetPath,
    required String destPath,
  }) async {
    final byteData = await rootBundle.load(assetPath);
    final file = File(destPath);
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
  }

  /// Checks if a downloaded file still exists on disk.
  Future<bool> fileExists(String? localPath) async {
    if (localPath == null || localPath.isEmpty) return false;
    return File(localPath).exists();
  }

  /// Deletes a locally downloaded audio file.
  Future<void> deleteLocalFile(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Clears all downloaded audio files.
  Future<void> clearAllDownloads() async {
    try {
      final audioDir = await getAudioDir();
      if (await audioDir.exists()) {
        await audioDir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
