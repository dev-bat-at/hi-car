package com.hicar.ora.limited

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import java.io.File

/**
 * BootReceiver - Tự động kích hoạt khi thiết bị khởi động hoặc cập nhật gói ứng dụng.
 * Hỗ trợ tự động bật màn hình và phát âm thanh chào mừng cho các dòng Android Box xe hơi.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val validActions = listOf(
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_REBOOT,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON"
        )

        if (intent.action in validActions) {
            val prefs = getAvailablePrefs(context)
            
            // Đọc mode từ prefs (Flutter lưu với prefix flutter.)
            val connectionMode = prefs.getString("flutter.connection_mode", "android_screen_mode") ?: "android_screen_mode"

            // Mode Box mới được phép tự phát nhạc sau khi restart. Các mode còn lại đợi app/BT/AA trigger.
            if (connectionMode != "android_box_mode") return
            
            // 🟢 CHƯA ĐĂNG NHẬP THÌ KHÔNG PHÁT NHẠC
            if (!prefs.contains("flutter.auth_token")) return

            if (!hasGreetingAudio(context, prefs)) return

            android.util.Log.d("HiCarBoot", "Boot trigger OK – connectionMode=$connectionMode, action=${intent.action}")

            // Dùng DELAYED để service đợi audio system khởi tạo xong trước khi phát (tối thiểu 5 giây).
            val serviceIntent = Intent(context, AudioForegroundService::class.java).apply {
                action = AudioForegroundService.ACTION_PLAY_GREETING_DELAYED
                putExtra(AudioForegroundService.EXTRA_PREFER_BOOT_AUDIO, true)
            }

            // Mode Box: chỉ phát ngầm (Background), không được tự ý mở App (UI).
            // Nhạc sẽ vang lên ở dưới nền, màn hình xe vẫn giữ nguyên trạng thái cũ.
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun getAvailablePrefs(context: Context): SharedPreferences {
        val regularPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val protectedPrefs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            context.createDeviceProtectedStorageContext()
                .getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        } else {
            regularPrefs
        }

        return if (regularPrefs.all.isNotEmpty()) regularPrefs else protectedPrefs
    }

    private fun hasGreetingAudio(context: Context, prefs: SharedPreferences): Boolean {
        val configuredPath = prefs.getString("flutter.greeting_audio_path", "") ?: ""
        android.util.Log.d("HiCarBoot", "hasGreetingAudio: flutter.greeting_audio_path=$configuredPath")

        if (configuredPath.isNotEmpty()) {
            val exists = File(configuredPath).exists()
            android.util.Log.d("HiCarBoot", "hasGreetingAudio: regular path exists=$exists")
            if (exists) return true
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            android.util.Log.w("HiCarBoot", "hasGreetingAudio: API < N, no boot_greeting fallback → SKIP")
            return false
        }

        val protectedContext = context.createDeviceProtectedStorageContext()
        val bootFile = File(protectedContext.filesDir, "boot_greeting.mp3")
        android.util.Log.d("HiCarBoot", "hasGreetingAudio: boot_greeting.mp3 path=${bootFile.absolutePath}, exists=${bootFile.exists()}, size=${if (bootFile.exists()) bootFile.length() else 0}")
        return bootFile.exists()
    }
}