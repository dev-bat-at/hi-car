import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/audio_model.dart';
import '../data/repositories/audio_repository.dart';
import '../data/services/sync_service.dart';
import '../native/service_channel.dart';
import '../core/constants.dart';

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
  bool _isBetaMode = false;
  String? _activeGreetingId;
  String? _activeGoodbyeId;
  bool _isNativeGreetingPlaying = false;
  bool _isNativeGoodbyePlaying = false;
  VoidCallback? onNativePlaybackComplete; // Callback for UI to react
  Timer? _playbackWatchdog;

  List<AudioModel> get audioList {
    final mappedList = _audioList.map((a) {
      return a.copyWith(
        isActiveGreeting: _activeGreetingId == a.id,
        isActiveGoodbye: _activeGoodbyeId == a.id,
      );
    }).toList();

    if (!_isBetaMode) return mappedList;

    final demoAudio = AudioModel(
      id: 'demo_default',
      title: 'Giọng Mặc Định (Demo)',
      type: AudioType.custom,
      remoteUrl: '',
      assetPath: AppConstants.defaultAudioAsset,
      description: 'Lấy từ bộ nhớ máy (Không cần mạng)',
      isActiveGreeting: _activeGreetingId == 'demo_default',
      isActiveGoodbye: _activeGoodbyeId == 'demo_default',
    );

    return [demoAudio, ...mappedList];
  }

  AudioModel? get currentlyPlaying => _currentlyPlaying;
  bool get isPlaying => _isPlaying;
  SyncStatus get syncStatus => _syncStatus;
  String get syncMessage => _syncMessage;
  double get syncProgress => _syncProgress;
  String? get syncError => _syncError;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isSyncing => _syncStatus == SyncStatus.syncing;
  bool get isNativeGreetingPlaying => _isNativeGreetingPlaying;
  bool get isNativeGoodbyePlaying => _isNativeGoodbyePlaying;

  AudioModel? get activeGreeting =>
      audioList.where((a) => a.isActiveGreeting).firstOrNull;
  AudioModel? get activeGoodbye =>
      audioList.where((a) => a.isActiveGoodbye).firstOrNull;

  // ===== Init =====

  Future<void> init() async {
    _audioList = await AudioRepository.instance.loadLocalAudioList();

    final prefs = await SharedPreferences.getInstance();
    _isBetaMode = prefs.getBool('is_beta_mode') ?? false;
    _activeGreetingId = prefs.getString(AppConstants.keyGreetingAudioId);
    _activeGoodbyeId = prefs.getString(AppConstants.keyGoodbyeAudioId);

    notifyListeners();

    // Initialize ServiceChannel listener
    ServiceChannel.instance.init();
    ServiceChannel.instance.onPlaybackComplete = () {
      debugPrint('🔔 [AudioProvider] NHẬN TÍN HIỆU: PHÁT XONG TỪ NATIVE');
      _stopNativePlaybackState();
    };

    // Auto-sync on startup if logged in
    if (prefs.containsKey('auth_token')) {
      syncFromServer();
    }
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
      _syncMessage = 'Đồng bộ hoàn tất (${updated.length} file)';

      // Update native service
      await _syncNativePaths();
    } catch (e) {
      _syncStatus = SyncStatus.error;
      _syncError = e.toString();
      _syncMessage = 'Lỗi đồng bộ';
    }

    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      if (_syncStatus != SyncStatus.syncing) {
        _syncStatus = SyncStatus.idle;
        notifyListeners();
      }
    });
  }

  // ===== Actions =====

  Future<void> setAsGreeting(String audioId) async {
    _activeGreetingId = audioId;
    _audioList =
        await AudioRepository.instance.setGreetingAudio(audioId, _audioList);
    await _syncNativePaths();
    notifyListeners();
  }

  Future<void> setAsGoodbye(String audioId) async {
    _activeGoodbyeId = audioId;
    _audioList =
        await AudioRepository.instance.setGoodbyeAudio(audioId, _audioList);
    await _syncNativePaths();
    notifyListeners();
  }

  // ===== Playback =====

  Future<void> playAudio(AudioModel audio) async {
    try {
      await _player.stop();

      if (audio.assetPath != null && audio.assetPath!.isNotEmpty) {
        await _player.setAsset(audio.assetPath!);
      } else if (audio.hasLocalFile &&
          audio.localPath != null &&
          await File(audio.localPath!).exists()) {
        await _player.setFilePath(audio.localPath!);
      } else {
        await _player.setUrl(audio.remoteUrl);
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

  Future<bool> playGreetingViaNative() async {
    final audio = activeGreeting;
    String? path;

    if (audio != null) {
      path = await AudioRepository.instance.getGreetingAudioPath(audio);
    } else {
      // Fallback: audioList may not be loaded yet, read persisted path
      final prefs = await SharedPreferences.getInstance();
      path = prefs.getString('greeting_audio_path');
      debugPrint(
          'AudioProvider: No active greeting in list, fallback path=$path');
    }

    if (path == null || path.isEmpty) {
      debugPrint('AudioProvider: No active greeting found');
      return false;
    }

    try {
      _isNativeGreetingPlaying = true;
      _isNativeGoodbyePlaying = false;
      notifyListeners();

      await ServiceChannel.instance.playGreeting(audioPath: path);
      _startWatchdog(audio?.durationSeconds ?? 15);
      return true;
    } catch (e) {
      debugPrint('AudioProvider: playGreetingViaNative error: $e');
      _stopNativePlaybackState();
      return false;
    }
  }

  Future<bool> playGoodbyeViaNative() async {
    final audio = activeGoodbye;
    String? path;

    if (audio != null) {
      path = await AudioRepository.instance.getGoodbyeAudioPath(audio);
    } else {
      // Fallback: audioList may not be loaded yet, read persisted path
      final prefs = await SharedPreferences.getInstance();
      path = prefs.getString('goodbye_audio_path');
      debugPrint(
          'AudioProvider: No active goodbye in list, fallback path=$path');
    }

    if (path == null || path.isEmpty) {
      debugPrint('AudioProvider: No active goodbye found');
      return false;
    }

    try {
      _isNativeGoodbyePlaying = true;
      _isNativeGreetingPlaying = false;
      notifyListeners();

      await ServiceChannel.instance.playGoodbye(audioPath: path);
      _startWatchdog(audio?.durationSeconds ?? 15);
      return true;
    } catch (e) {
      debugPrint('AudioProvider: playGoodbyeViaNative error: $e');
      _stopNativePlaybackState();
      return false;
    }
  }

  Future<void> stopNativeAudio() async {
    try {
      debugPrint('AudioProvider: stopNativeAudio');
      _stopNativePlaybackState();
      await ServiceChannel.instance.stopAudio();
    } catch (e) {
      debugPrint('Native stopAudio error: $e');
    }
  }

  void _startWatchdog(int durationSeconds) {
    _playbackWatchdog?.cancel();
    // Use duration + 5s buffer, or default 60s if duration is unknown/zero
    final timeout = (durationSeconds > 0) ? durationSeconds + 5 : 60;
    _playbackWatchdog = Timer(Duration(seconds: timeout), () {
      if (_isNativeGreetingPlaying || _isNativeGoodbyePlaying) {
        debugPrint(
            '⚠️ [AudioProvider] Watchdog triggered: Force stopping animation');
        _stopNativePlaybackState();
      }
    });
  }

  void _stopNativePlaybackState() {
    _playbackWatchdog?.cancel();
    _player.stop();
    _isPlaying = false;
    _currentlyPlaying = null;
    _isNativeGreetingPlaying = false;
    _isNativeGoodbyePlaying = false;
    notifyListeners();
    onNativePlaybackComplete?.call(); // 🟢 Trigger callback
  }

  // ===== Action Methods =====

  Future<void> deleteAudio(String audioId) async {
    _audioList =
        await AudioRepository.instance.deleteAudio(audioId, _audioList);
    notifyListeners();
  }

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

  // ===== Lifecycle =====

  Future<void> _syncNativePaths() async {
    final greetingPath =
        await AudioRepository.instance.getGreetingAudioPath(activeGreeting);
    final goodbyePath =
        await AudioRepository.instance.getGoodbyeAudioPath(activeGoodbye);
    final prefs = await SharedPreferences.getInstance();

    if (greetingPath != null)
      await prefs.setString('greeting_audio_path', greetingPath);
    if (goodbyePath != null)
      await prefs.setString('goodbye_audio_path', goodbyePath);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void setBetaMode(bool value) {
    _isBetaMode = value;
    notifyListeners();
  }
}
