package com.hicar.ora.limited

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val SERVICE_CHANNEL = "com.hicar.ora.limited/service"
        const val BLUETOOTH_CHANNEL = "com.hicar.ora.limited/bluetooth"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ===== SERVICE CHANNEL =====
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        startAudioService(AudioForegroundService.ACTION_START)
                        result.success(true)
                    }
                    "stopService" -> {
                        startAudioService(AudioForegroundService.ACTION_STOP)
                        result.success(true)
                    }
                    "playGreeting" -> {
                        val audioPath = call.argument<String>("audioPath") ?: ""
                        val intent = buildServiceIntent(AudioForegroundService.ACTION_PLAY_GREETING)
                        intent.putExtra("audioPath", audioPath)
                        startServiceSafe(intent)
                        result.success(true)
                    }
                    "playGoodbye" -> {
                        val audioPath = call.argument<String>("audioPath") ?: ""
                        val intent = buildServiceIntent(AudioForegroundService.ACTION_PLAY_GOODBYE)
                        intent.putExtra("audioPath", audioPath)
                        startServiceSafe(intent)
                        result.success(true)
                    }
                    "stopAudio" -> {
                        startAudioService(AudioForegroundService.ACTION_STOP_AUDIO)
                        result.success(true)
                    }
                    "openApp" -> {
                        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                        if (launchIntent != null) {
                            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(launchIntent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ===== BLUETOOTH CHANNEL =====
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BLUETOOTH_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPairedDevices" -> {
                        val devices = BluetoothReceiver.getPairedDevices(this)
                        result.success(devices)
                    }
                    "setTargetDevice" -> {
                        val address = call.argument<String>("address") ?: ""
                        val delay = call.argument<Int>("delay") ?: 5
                        AudioForegroundService.targetDeviceAddress = address
                        AudioForegroundService.delaySeconds = delay
                        result.success(true)
                    }
                    "clearTargetDevice" -> {
                        AudioForegroundService.targetDeviceAddress = ""
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startAudioService(action: String) {
        val intent = buildServiceIntent(action)
        startServiceSafe(intent)
    }

    private fun buildServiceIntent(action: String): Intent {
        return Intent(this, AudioForegroundService::class.java).apply {
            this.action = action
        }
    }

    private fun startServiceSafe(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}
