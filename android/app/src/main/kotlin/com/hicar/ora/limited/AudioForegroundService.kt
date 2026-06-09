package com.hicar.ora.limited

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.*
import android.os.*
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.media.MediaBrowserServiceCompat
import android.util.Log
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngine
import java.io.File

/**
 * AudioForegroundService - Extends MediaBrowserServiceCompat for Android Auto support.
 *
 * Responsibilities:
 * - Foreground service to keep app alive
 * - WakeLock to prevent CPU sleep
 * - MediaSession for Android Auto / lock screen integration
 * - Audio focus management (grabs & releases properly)
 * - Delayed auto-play on Bluetooth connection
 * - Restarts itself if killed (START_STICKY)
 * - Nạp tĩnh MethodChannel để tránh lỗi MissingPluginException ở bản Release
 */
class AudioForegroundService : MediaBrowserServiceCompat() {

    companion object {
        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
        const val ACTION_PLAY_GREETING = "ACTION_PLAY_GREETING"
        const val ACTION_PLAY_GOODBYE = "ACTION_PLAY_GOODBYE"
        const val ACTION_PLAY_GREETING_DELAYED = "ACTION_PLAY_GREETING_DELAYED"
        const val ACTION_STOP_AUDIO = "ACTION_STOP_AUDIO"
        const val ACTION_BLUETOOTH_DISCONNECTED = "ACTION_BLUETOOTH_DISCONNECTED"

        const val NOTIFICATION_CHANNEL_ID = "hicar_service_channel"
        const val NOTIFICATION_ID = 1001

        @Volatile var connectionMode: String = "phone_bluetooth"
        @Volatile var targetDeviceAddress: String = ""
        @Volatile var delaySeconds: Int = 5
        @Volatile var autoPlayEnabled: Boolean = true
        @Volatile var greetingAudioPath: String = ""
        @Volatile var goodbyeAudioPath: String = ""
    }

    private var mediaPlayer: MediaPlayer? = null
    private var mediaSession: MediaSessionCompat? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var audioManager: AudioManager? = null
    private val handler = Handler(Looper.getMainLooper())
    private var delayedRunnable: Runnable? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    // ==============================
    // Lifecycle
    // ==============================

    override fun onCreate() {
        super.onCreate()
        Log.d("HiCarService", "Service onCreate started")
        
        try {
            // 1. Initialize core managers safely
            audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            
            // 2. Setup Notification & MediaSession FIRST
            setupNotificationChannel()
            setupMediaSession()
            
            // 3. Load preferences (this will trigger updateMediaSessionState if session exists)
            loadPrefs()
            
            acquireWakeLock()
            buildAudioFocusRequest()
            
            Log.d("HiCarService", "Service onCreate finished successfully")
        } catch (e: Exception) {
            Log.e("HiCarService", "CRITICAL ERROR in onCreate: ${e.message}")
            e.printStackTrace()
        }
    }


    private fun loadPrefs() {
        val regularPrefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val storageContext = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            applicationContext.createDeviceProtectedStorageContext()
        } else {
            applicationContext
        }
        val protectedPrefs = storageContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        // Priority: Regular prefs (latest from UI) -> Protected prefs (boot sequence)
        val prefs = if (regularPrefs.all.isNotEmpty()) regularPrefs else protectedPrefs
        
        connectionMode = prefs.getString("flutter.connection_mode", "phone_bluetooth") ?: "phone_bluetooth"
        targetDeviceAddress = prefs.getString("flutter.target_device_address", "") ?: ""
        
        val allPrefs = prefs.all
        val delayVal = allPrefs["flutter.delay_seconds"]
        delaySeconds = when (delayVal) {
            is Long -> delayVal.toInt()
            is Int -> delayVal
            is Number -> delayVal.toInt()
            is String -> delayVal.toIntOrNull() ?: 5
            else -> 5
        }
        
        autoPlayEnabled = prefs.getBoolean("flutter.auto_play_enabled", true)
        
        greetingAudioPath = prefs.getString("flutter.greeting_audio_path", "") ?: ""
        goodbyeAudioPath = prefs.getString("flutter.goodbye_audio_path", "") ?: ""

        // 🟢 ƯU TIÊN: Chỉ dùng file Boot nếu chưa có thiết lập nhạc chính thức
        if (greetingAudioPath.isEmpty()) {
            val bootGreeting = File(storageContext.filesDir, "boot_greeting.mp3")
            if (bootGreeting.exists()) {
                greetingAudioPath = bootGreeting.absolutePath
            }
        }
        
        if (goodbyeAudioPath.isEmpty()) {
            val bootGoodbye = File(storageContext.filesDir, "boot_goodbye.mp3")
            if (bootGoodbye.exists()) {
                goodbyeAudioPath = bootGoodbye.absolutePath
            }
        }

        // 🟢 CẬP NHẬT TRẠNG THÁI MEDIA SESSION: Nếu không phải mode AA, ngắt kết nối với màn hình xe
        updateMediaSessionState()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: "NONE"
        Log.d("HiCarService", "onStartCommand: action=$action")
        
        try {
            loadPrefs()
            startForeground(NOTIFICATION_ID, buildNotification())
        } catch (e: Exception) {
            Log.e("HiCarService", "Error in onStartCommand: ${e.message}")
            // Even if it fails, we must call startForeground on Android 8+ to avoid ANR/Crash
            try {
                startForeground(NOTIFICATION_ID, buildNotification())
            } catch (e2: Exception) {}
        }

        when (intent?.action) {
            ACTION_START -> { /* Keep alive */ }
            ACTION_STOP -> stopSelf()

            ACTION_PLAY_GREETING -> {
                val path = intent.getStringExtra("audioPath") ?: greetingAudioPath
                playAudio(path, "greeting")
            }
            ACTION_PLAY_GOODBYE -> {
                val path = intent.getStringExtra("audioPath") ?: goodbyeAudioPath
                playAudio(path, "goodbye")
            }
            ACTION_PLAY_GREETING_DELAYED -> scheduleDelayedGreeting()
            ACTION_STOP_AUDIO -> stopPlayback()
            ACTION_BLUETOOTH_DISCONNECTED -> {
                cancelDelayedPlay()
                stopPlayback()
            }
        }

        return START_STICKY
    }

    override fun onDestroy() {
        stopPlayback()
        mediaSession?.release()
        wakeLock?.let { if (it.isHeld) it.release() }
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        // Auto-restart when app is swiped away
        val restartIntent = Intent(applicationContext, AudioForegroundService::class.java).apply {
            action = ACTION_START
        }
        val pending = PendingIntent.getService(
            applicationContext, 1, restartIntent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )
        (getSystemService(Context.ALARM_SERVICE) as AlarmManager).set(
            AlarmManager.ELAPSED_REALTIME,
            SystemClock.elapsedRealtime() + 1000,
            pending
        )
    }

    // ==============================
    // MediaBrowserService (Android Auto)
    // ==============================

    override fun onGetRoot(
        clientPackageName: String,
        clientUid: Int,
        rootHints: Bundle?
    ): BrowserRoot? {
        loadPrefs()
        Log.d("HiCarAA", "onGetRoot called by: $clientPackageName")
        
        // 🟢 ẨN APP KHỎI MÀN HÌNH XE NẾU KHÔNG PHẢI MODE ANDROID AUTO
        if (connectionMode != "phone_android_auto") {
            Log.d("HiCarAA", "Not in AA mode, returning null")
            return null
        }

        // Nếu là Android Auto (gearhead), tự động kích hoạt phát nhạc mà ko cần check Bluetooth Target
        if (clientPackageName.contains("gearhead") || clientPackageName.contains("com.google.android.projection.gearhead")) {
            Log.d("HiCarAA", "Android Auto detected, scheduling audio (5s delay for stability)...")
            handler.postDelayed({
                if (greetingAudioPath.isNotEmpty()) {
                    Log.d("HiCarAA", "Playing greeting: $greetingAudioPath")
                    playAudio(greetingAudioPath, "greeting")
                }
            }, 5000) // 🟢 Tăng lên 5 giây để đợi hệ thống xe ổn định hoàn toàn
        }
        return BrowserRoot("hicar_root", null)
    }

    override fun onLoadChildren(
        parentId: String,
        result: Result<List<MediaBrowserCompat.MediaItem>>
    ) {
        result.sendResult(emptyList())
    }

    // ==============================
    // Audio Playback
    // ==============================

    private fun scheduleDelayedGreeting() {
        cancelDelayedPlay()
        delayedRunnable = Runnable {
            if (greetingAudioPath.isNotEmpty()) {
                playAudio(greetingAudioPath, "greeting")
            }
        }
        handler.postDelayed(delayedRunnable!!, (delaySeconds * 1000).toLong())
    }

    private fun cancelDelayedPlay() {
        delayedRunnable?.let { handler.removeCallbacks(it) }
        delayedRunnable = null
    }

    private fun playAudio(path: String, type: String) {
        if (path.isEmpty()) return

        val granted = requestAudioFocus()
        if (!granted) return

        try {
            // Re-use or reset MediaPlayer to avoid rapid recreation stuttering
            if (mediaPlayer == null) {
                mediaPlayer = MediaPlayer()
            } else {
                mediaPlayer?.reset()
            }
            
            mediaPlayer?.apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC) 
                        .build()
                )
                setDataSource(path)
                setVolume(1.0f, 1.0f)
                prepare()
                start()
                
                // 🟢 SYNCED STATE: Update playback state only after successful start
                if (type == "greeting") {
                    updatePlaybackState(PlaybackStateCompat.STATE_PLAYING)
                } else if (type == "goodbye") {
                    updatePlaybackState(PlaybackStateCompat.STATE_SKIPPING_TO_NEXT) 
                }

                // Notify Flutter to pulse UI
                HiCarPlugin.instance?.invokeServiceMethod("onPlaybackStarted", type)

                setOnCompletionListener {
                    updatePlaybackState(PlaybackStateCompat.STATE_STOPPED)
                    releaseAudioFocus()
                    mediaPlayer?.release()
                    mediaPlayer = null
                }
                
                setOnErrorListener { _, _, _ ->
                    releaseAudioFocus()
                    updatePlaybackState(PlaybackStateCompat.STATE_ERROR)
                    true
                }
            }
        } catch (e: Exception) {
            Log.e("HiCarAudio", "Error playing audio: ${e.message}")
            releaseAudioFocus()
            updatePlaybackState(PlaybackStateCompat.STATE_ERROR)
        }
    }

    private fun stopPlayback(releaseOnly: Boolean = false) {
        cancelDelayedPlay()
        mediaPlayer?.let {
            try {
                if (it.isPlaying) it.stop()
                it.reset()
                it.release()
            } catch (_: Exception) {}
        }
        mediaPlayer = null
        if (!releaseOnly) {
            releaseAudioFocus()
            updatePlaybackState(PlaybackStateCompat.STATE_STOPPED)
        }
    }

    // ==============================
    // Audio Focus
    // ==============================

    private fun buildAudioFocusRequest() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // 🟢 DÙNG AUDIOFOCUS_GAIN_TRANSIENT: Để tạm dừng nhạc khác hoàn toàn thay vì chỉ giảm âm lượng (ducking)
            // Giúp âm thanh Bluetooth ổn định hơn trên một số đầu giải trí xe hơi
            audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                .setOnAudioFocusChangeListener { change ->
                    when (change) {
                        AudioManager.AUDIOFOCUS_LOSS -> {
                            Log.d("HiCarAudio", "Focus Loss (-1)")
                            if (connectionMode == "phone_android_auto" && mediaPlayer?.isPlaying == true) {
                                // 🟢 Nếu là AA và đang phát mà bị mất focus -> Thử phát lại sau 2.5s (cho ổn định)
                                Log.d("HiCarAudio", "AA Focus Loss: Will retry in 2.5s...")
                                handler.postDelayed({
                                    if (greetingAudioPath.isNotEmpty()) playAudio(greetingAudioPath, "greeting")
                                }, 2500)
                            } else {
                                stopPlayback()
                            }
                        }
                        AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                            Log.d("HiCarAudio", "Focus Loss Transient (-2)")
                            mediaPlayer?.pause()
                        }
                        AudioManager.AUDIOFOCUS_GAIN -> {
                            Log.d("HiCarAudio", "Focus Gain (1)")
                            mediaPlayer?.start()
                        }
                    }
                }
                .build()
        }
    }

    private fun requestAudioFocus(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let {
                audioManager?.requestAudioFocus(it) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            } ?: false
        } else {
            @Suppress("DEPRECATION")
            audioManager?.requestAudioFocus(
                null,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
            ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
    }

    private fun releaseAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            audioManager?.abandonAudioFocus(null)
        }
    }

    // ==============================
    // MediaSession
    // ==============================

    private fun setupMediaSession() {
        mediaSession = MediaSessionCompat(this, "HiCarSession").apply {
            setCallback(object : MediaSessionCompat.Callback() {
                override fun onPlay() { /* handled externally */ }
                override fun onPause() { stopPlayback() }
                override fun onStop() { stopPlayback() }
            })
        }
        // 🟢 QUAN TRỌNG: Chỉ set sessionToken 1 lần duy nhất trong vòng đời Service
        sessionToken = mediaSession?.sessionToken
        updateMediaSessionState()
    }

    private fun updateMediaSessionState() {
        mediaSession?.let { session ->
            // Chỉ chỉnh trạng thái Active thay vì thay đổi Token (tránh lỗi crash)
            session.isActive = (connectionMode == "phone_android_auto")
        }
    }

    private fun updatePlaybackState(state: Int) {
        val playbackState = PlaybackStateCompat.Builder()
            .setState(state, PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN, 1f)
            .setActions(
                PlaybackStateCompat.ACTION_PLAY_PAUSE or
                        PlaybackStateCompat.ACTION_STOP
            )
            .build()
        mediaSession?.setPlaybackState(playbackState)

        // Notify Flutter when playback completes via Plugin
        if (state == PlaybackStateCompat.STATE_STOPPED) {
            // Loại bỏ độ trễ 1s để UI cập nhật tức thì, tránh bị nháy khi phát bản tiếp theo
            HiCarPlugin.instance?.invokeServiceMethod("onPlaybackComplete")
        }
    }

    // ==============================
    // Notification
    // ==============================

    private fun setupNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Giọng Thương Gia",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Automotive background audio service"
                setSound(null, null)
                enableVibration(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val launchIntent = packageManager?.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Giọng Thương Gia")
            .setContentText("Hệ thống trợ lý xe đang hoạt động")
            .setSmallIcon(R.drawable.ic_car)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    // ==============================
    // WakeLock
    // ==============================

    private fun acquireWakeLock() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "HiCar::AudioServiceWakeLock"
        ).apply {
            acquire(10 * 60 * 60 * 1000L) // Max 10 hours
        }
    }
}