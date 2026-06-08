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
            "android.intent.action.QUICKBOOT_POWERON" // Hỗ trợ khởi động nhanh trên một số dòng đầu DVD ô tô chuyên dụng
        )

        if (intent.action in validActions) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val connectionMode = prefs.getString("flutter.connection_mode", "phone_bluetooth") ?: "phone_bluetooth"

            val serviceIntent = Intent(context, AudioForegroundService::class.java).apply {
                action = if (connectionMode == "android_screen_box") {
                    AudioForegroundService.ACTION_PLAY_GREETING
                } else {
                    AudioForegroundService.ACTION_START
                }
            }

            // Launch UI nếu ở chế độ Android Box lắp trực tiếp vào xe
            if (connectionMode == "android_screen_box") {
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                launchIntent?.addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or 
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or 
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
                try {
                    context.startActivity(launchIntent)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            // Kích hoạt dịch vụ chạy ngầm an toàn theo phiên bản hệ điều hành
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