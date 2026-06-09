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
        loadPrefs()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        setupNotificationChannel()
        setupMediaSession()
        acquireWakeLock()
        buildAudioFocusRequest()
    }


    private fun loadPrefs() {
        val storageContext = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            applicationContext.createDeviceProtectedStorageContext()
        } else {
            applicationContext
        }
        
        val prefs = storageContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        connectionMode = prefs.getString("flutter.connection_mode", "phone_bluetooth") ?: "phone_bluetooth"
        targetDeviceAddress = prefs.getString("flutter.target_device_address", "") ?: ""
        
        val delayVal = prefs.all["flutter.delay_seconds"]
        delaySeconds = when (delayVal) {
            is Long -> delayVal.toInt()
            is Int -> delayVal
            is Number -> delayVal.toInt()
            is String -> delayVal.toIntOrNull() ?: 5
            else -> 5
        }
        
        greetingAudioPath = prefs.getString("flutter.greeting_audio_path", "") ?: ""
        goodbyeAudioPath = prefs.getString("flutter.goodbye_audio_path", "") ?: ""

        // 🟢 ƯU TIÊN: Nếu đang trong trạng thái khóa (Boot), dùng file trong vùng an toàn
        val bootGreeting = File(storageContext.filesDir, "boot_greeting.mp3")
        if (bootGreeting.exists()) {
            greetingAudioPath = bootGreeting.absolutePath
        }
        
        val bootGoodbye = File(storageContext.filesDir, "boot_goodbye.mp3")
        if (bootGoodbye.exists()) {
            goodbyeAudioPath = bootGoodbye.absolutePath
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        loadPrefs()
        startForeground(NOTIFICATION_ID, buildNotification())

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
    ): BrowserRoot {
        loadPrefs()
        if (connectionMode == "phone_android_auto" && clientPackageName.contains("gearhead")) {
            // 🟢 THÊM ĐỘ TRỄ: Android Auto cần thời gian để thiết lập kênh âm thanh Bluetooth (A2DP)
            // Nếu phát ngay lập tức, âm thanh có thể bị mất hoặc phát ra loa điện thoại
            handler.postDelayed({
                if (greetingAudioPath.isNotEmpty()) {
                    playAudio(greetingAudioPath, "greeting")
                }
            }, 3000) 
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

        stopPlayback(releaseOnly = true)

        try {
            mediaPlayer = MediaPlayer().apply {
                // 🟢 ĐỔI SANG CONTENT_TYPE_MUSIC: Để tránh DSP của xe xử lý lọc nhiễu nhầm (gây rè)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC) 
                        .build()
                )
                setDataSource(path)
                setVolume(1.0f, 1.0f) // Đảm bảo âm lượng nguồn tối đa
                prepare()
                start()
                setOnCompletionListener {
                    // Update state FIRST so Flutter knows we are done before resources are gone
                    updatePlaybackState(PlaybackStateCompat.STATE_STOPPED)
                    releaseAudioFocus()
                    reset()
                    release()
                    mediaPlayer = null
                }
                setOnErrorListener { _, _, _ ->
                    releaseAudioFocus()
                    false
                }
            }
            updatePlaybackState(PlaybackStateCompat.STATE_PLAYING)
            
            // 🟢 THÔNG BÁO FLUTTER: Để UI cập nhật trạng thái đang phát (Pulsing animation)
            HiCarPlugin.instance?.invokeServiceMethod("onPlaybackStarted", type)
        } catch (e: Exception) {
            releaseAudioFocus()
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
                    if (change == AudioManager.AUDIOFOCUS_LOSS ||
                        change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT
                    ) {
                        stopPlayback()
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
            isActive = true
        }
        sessionToken = mediaSession?.sessionToken
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
            // Tăng độ trễ lên 1000ms (1 giây) để đảm bảo đồng bộ tuyệt đối
            handler.postDelayed({
                HiCarPlugin.instance?.invokeServiceMethod("onPlaybackComplete")
            }, 1000)
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
            getSystemService(NotificationManager::class.java)
                ?.createNotificationChannel(channel)
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