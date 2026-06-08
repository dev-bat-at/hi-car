package com.hicar.ora.limited

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * BootReceiver - Tự động kích hoạt khi thiết bị khởi động hoặc cập nhật gói ứng dụng.
 * Hỗ trợ tự động bật màn hình và phát âm thanh chào mừng cho các dòng Android Box xe hơi.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val validActions = listOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON"
        )

        if (intent.action in validActions) {
            val storageContext = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                context.createDeviceProtectedStorageContext()
            } else {
                context
            }
            val prefs = storageContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val connectionMode = prefs.getString("flutter.connection_mode", "android_screen_mode") ?: "android_screen_mode"

            val serviceIntent = Intent(context, AudioForegroundService::class.java).apply {
                action = AudioForegroundService.ACTION_PLAY_GREETING
            }

            // 🟢 TẤT CẢ CÁC CHẾ ĐỘ: Chỉ phát ngầm (Background), không được tự ý mở App (UI)
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
}