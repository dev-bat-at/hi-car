import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../data/models/audio_model.dart';
import '../data/repositories/audio_repository.dart';
import '../data/services/sync_service.dart';
import '../native/service_channel.dart';

enum SyncStatus { idle, syncing, success, error }

class AudioProvider extends ChangeNotifier {
  final _player = AudioPlayer();

  List<AudioModel> _audioList = [];
  AudioModel? _currentlyPlaying;
  bool _isPlaying = false;
  SyncStatus _syncStatus = SyncStatus.idle;
  String _syncMessage = '';
  double _syncProgress = 0;
  String? _syncError;
  DateTime? _lastSyncTime;

  List<AudioModel> get audioList => _audioList;
  AudioModel? get currentlyPlaying => _currentlyPlaying;
  bool get isPlaying => _isPlaying;
  SyncStatus get syncStatus => _syncStatus;
  String get syncMessage => _syncMessage;
  double get syncProgress => _syncProgress;
  String? get syncError => _syncError;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isSyncing => _syncStatus == SyncStatus.syncing;

  AudioModel? get activeGreeting =>
      _audioList.where((a) => a.isActiveGreeting).firstOrNull;
  AudioModel? get activeGoodbye =>
      _audioList.where((a) => a.isActiveGoodbye).firstOrNull;

  // ===== Init =====

  Future<void> init() async {
    _audioList = await AudioRepository.instance.loadLocalAudioList();
    notifyListeners();
  }

  // ===== Sync =====

  Future<void> syncFromServer() async {
    if (_syncStatus == SyncStatus.syncing) return;

    _syncStatus = SyncStatus.syncing;
    _syncError = null;
    _syncProgress = 0;
    notifyListeners();

    try {
      final updated = await AudioRepository.instance.syncFromServer(
        onProgress: (msg, progress) {
          _syncMessage = msg;
          _syncProgress = progress;
          notifyListeners();
        },
      );

      _audioList = updated;
      _lastSyncTime = DateTime.now();
      _syncStatus = SyncStatus.success;
      _syncMessage = 'Đồng bộ thành công ${updated.length} file';

      // Update native service with new audio paths
      await _syncNativePaths();
    } catch (e) {
      _syncStatus = SyncStatus.error;
      _syncError = e.toString().replaceFirst('Exception: ', '');
      _syncMessage = 'Đồng bộ thất bại';
    }

    notifyListeners();

    // Reset to idle after 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    if (_syncStatus != SyncStatus.syncing) {
      _syncStatus = SyncStatus.idle;
      notifyListeners();
    }
  }

  // ===== Set Active =====

  Future<void> setAsGreeting(String audioId) async {
    _audioList = await AudioRepository.instance.setGreetingAudio(
      audioId,
      _audioList,
    );
    await _syncNativePaths();
    notifyListeners();
  }

  Future<void> setAsGoodbye(String audioId) async {
    _audioList = await AudioRepository.instance.setGoodbyeAudio(
      audioId,
      _audioList,
    );
    await _syncNativePaths();
    notifyListeners();
  }

  // ===== In-App Playback =====

  Future<void> playAudio(AudioModel audio) async {
    try {
      await _player.stop();
      
      // Fallback: If local file is missing, stream from remote URL directly for previewing
      if (audio.hasLocalFile && audio.localPath != null && await File(audio.localPath!).exists()) {
        await _player.setFilePath(audio.localPath!);
      } else {
        String url = audio.remoteUrl;
        if (url.startsWith('mock://')) {
          await _player.setAsset('assets/audio/audio_default.MP3');
        } else {
          await _player.setUrl(url);
        }
      }
      
      await _player.play();
      _currentlyPlaying = audio;
      _isPlaying = true;
      notifyListeners();

      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _currentlyPlaying = null;
          notifyListeners();
        }
      });
    } catch (_) {
      _isPlaying = false;
      _currentlyPlaying = null;
      notifyListeners();
    }
  }

  Future<void> stopAudio() async {
    await _player.stop();
    _isPlaying = false;
    _currentlyPlaying = null;
    notifyListeners();
  }

  // ===== Native Service Playback =====

  Future<void> playGreetingViaNative() async {
    final path = await AudioRepository.instance.getGreetingAudioPath();
    if (path != null) {
      await ServiceChannel.instance.playGreeting(audioPath: path);
    }
  }

  Future<void> playGoodbyeViaNative() async {
    final path = await AudioRepository.instance.getGoodbyeAudioPath();
    if (path != null) {
      await ServiceChannel.instance.playGoodbye(audioPath: path);
    }
  }

  Future<void> stopNativeAudio() async {
    await _player.stop();
    _isPlaying = false;
    _currentlyPlaying = null;
    await ServiceChannel.instance.stopAudio();
    notifyListeners();
  }

  // ===== Add & Cache Generated Audio =====

  Future<AudioModel> addAndDownloadGeneratedAudio(AudioModel audio) async {
    final localPath = await SyncService.instance.downloadSingleFile(
      audioId: audio.id,
      remoteUrl: audio.remoteUrl,
    );

    final updatedAudio = audio.copyWith(
      localPath: localPath,
      isDownloaded: localPath != null,
      downloadedAt: localPath != null ? DateTime.now() : null,
    );

    _audioList = [updatedAudio, ..._audioList];
    await AudioRepository.instance.saveLocalList(_audioList);
    notifyListeners();
    return updatedAudio;
  }

  // ===== Delete =====

  Future<void> deleteAudio(String audioId) async {
    _audioList = await AudioRepository.instance.deleteAudio(audioId, _audioList);
    notifyListeners();
  }

  // ===== Private =====

  Future<void> _syncNativePaths() async {
    final greetingPath = await AudioRepository.instance.getGreetingAudioPath();
    final goodbyePath = await AudioRepository.instance.getGoodbyeAudioPath();

    if (greetingPath != null) {
      await ServiceChannel.instance.playGreeting(audioPath: greetingPath);
      await ServiceChannel.instance.stopAudio();
    }
    if (goodbyePath != null) {
      // Store paths in native service companion
      // Just start/stop to register paths
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
