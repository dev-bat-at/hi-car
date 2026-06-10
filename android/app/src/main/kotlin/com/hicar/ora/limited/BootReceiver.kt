package com.hicar.ora.limited

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.UserManager
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
        // ⚠️ Direct Boot: trước khi user unlock lần đầu, vùng credential-encrypted KHÔNG truy cập
        //    được — chỉ cần GỌI getSharedPreferences trên context thường cũng ném
        //    IllegalStateException và làm CRASH receiver. Vì vậy phải kiểm tra trạng thái unlock
        //    và ưu tiên vùng device-protected khi chưa unlock.
        val deviceContext = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            context.createDeviceProtectedStorageContext()
        } else {
            context
        }
        val protectedPrefs = deviceContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        val userUnlocked = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            (context.getSystemService(Context.USER_SERVICE) as? UserManager)?.isUserUnlocked ?: false
        } else {
            true
        }

        // Chỉ chạm vào credential storage khi đã unlock (để lấy dữ liệu mới nhất từ UI).
        if (userUnlocked) {
            try {
                val regularPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                if (regularPrefs.all.isNotEmpty()) return regularPrefs
            } catch (e: Exception) {
                android.util.Log.w("HiCarBoot", "getAvailablePrefs: credential storage không đọc được – ${e.message}")
            }
        }

        return protectedPrefs
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