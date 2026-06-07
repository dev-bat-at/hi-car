package com.hicar.ora.limited

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val validActions = listOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON"
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

            // Launch UI if in Box mode (requires SYSTEM_ALERT_WINDOW on newer Android)
            if (connectionMode == "android_screen_box") {
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(launchIntent)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }
    }
}
