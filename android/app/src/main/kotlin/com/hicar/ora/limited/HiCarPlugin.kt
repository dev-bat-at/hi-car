package com.hicar.ora.limited

import android.content.Context
import android.content.Intent
import android.content.ComponentName
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * HiCarPlugin - Handle all native communications (Service & Bluetooth) 
 * across any Flutter Engine (Main App or Overlay).
 */
class HiCarPlugin : FlutterPlugin, MethodCallHandler {
    companion object {
        @Volatile
        var instance: HiCarPlugin? = null
    }

    private lateinit var serviceChannel: MethodChannel
    private lateinit var bluetoothChannel: MethodChannel
    private lateinit var context: Context
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        instance = this
        context = binding.applicationContext
        
        // Register Service Channel
        serviceChannel = MethodChannel(binding.binaryMessenger, "com.hicar.ora.limited/service")
        serviceChannel.setMethodCallHandler(this)
        
        // Register Bluetooth Channel
        bluetoothChannel = MethodChannel(binding.binaryMessenger, "com.hicar.ora.limited/bluetooth")
        bluetoothChannel.setMethodCallHandler { call, result ->
            handleBluetoothCall(call, result)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (instance == this) {
            instance = null
        }
        serviceChannel.setMethodCallHandler(null)
        bluetoothChannel.setMethodCallHandler(null)
    }

    /**
     * Helper to invoke methods on Service Channel from background threads
     */
    fun invokeServiceMethod(method: String, arguments: Any? = null) {
        mainHandler.post {
            try {
                serviceChannel.invokeMethod(method, arguments)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    /**
     * Helper to invoke methods on Bluetooth Channel from background threads
     */
    fun invokeBluetoothMethod(method: String, arguments: Any? = null) {
        mainHandler.post {
            try {
                bluetoothChannel.invokeMethod(method, arguments)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
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
            "minimizeApp" -> {
                minimizeApp()
                result.success(true)
            }
            "showAutostartSettings" -> {
                showAutostartSettings()
                result.success(true)
            }
            "syncPrefs" -> {
                syncPrefsToDeviceProtected()
                syncFilesToDeviceProtected() // 🟢 Đồng bộ cả file âm thanh
                result.success(true)
            }
            "openApp" -> {
                openApp(result)
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Đồng bộ SharedPreferences sang vùng nhớ an toàn để có thể đọc được ngay khi khởi động (Direct Boot)
     */
    private fun syncPrefsToDeviceProtected() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val deviceContext = context.createDeviceProtectedStorageContext()
            val sourcePrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val destPrefs = deviceContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            
            val allEntries = sourcePrefs.all
            val editor = destPrefs.edit()
            for ((key, value) in allEntries) {
                // Key trong Flutter SharedPreferences bắt đầu bằng "flutter."
                when (value) {
                    is String -> editor.putString(key, value)
                    is Boolean -> editor.putBoolean(key, value)
                    is Float -> editor.putFloat(key, value)
                    is Int -> editor.putInt(key, value)
                    is Long -> editor.putLong(key, value)
                }
            }
            editor.apply()
        }
    }

    /**
     * Sao chép các file âm thanh đang được chọn sang vùng nhớ an toàn (Device Protected Storage)
     * để có thể phát nhạc ngay khi máy khởi động (kể cả khi chưa mở khóa màn hình).
     */
    private fun syncFilesToDeviceProtected() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return

        val deviceContext = context.createDeviceProtectedStorageContext()
        val prefs = deviceContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        val greetingPath = prefs.getString("flutter.greeting_audio_path", "") ?: ""
        val goodbyePath = prefs.getString("flutter.goodbye_audio_path", "") ?: ""

        if (greetingPath.isNotEmpty()) {
            copyFileToProtected(greetingPath, "boot_greeting.mp3")
        }
        if (goodbyePath.isNotEmpty()) {
            copyFileToProtected(goodbyePath, "boot_goodbye.mp3")
        }
    }

    private fun copyFileToProtected(sourcePath: String, destName: String) {
        try {
            val sourceFile = java.io.File(sourcePath)
            if (!sourceFile.exists()) return

            val deviceContext = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                context.createDeviceProtectedStorageContext()
            } else {
                context
            }
            
            val destFile = java.io.File(deviceContext.filesDir, destName)
            sourceFile.inputStream().use { input ->
                destFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun showAutostartSettings() {
        val manufacturer = Build.MANUFACTURER.lowercase()
        val intent = Intent()
        try {
            when {
                manufacturer.contains("xiaomi") -> {
                    intent.component = ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")
                }
                manufacturer.contains("oppo") -> {
                    intent.component = ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")
                }
                manufacturer.contains("vivo") -> {
                    intent.component = ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")
                }
                else -> {
                    intent.action = android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                    intent.data = android.net.Uri.fromParts("package", context.packageName, null)
                }
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        } catch (e: Exception) {
            // Fallback to general settings
            val fallbackIntent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            fallbackIntent.data = android.net.Uri.fromParts("package", context.packageName, null)
            fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(fallbackIntent)
        }
    }

    private fun minimizeApp() {
        val intent = Intent(Intent.ACTION_MAIN)
        intent.addCategory(Intent.CATEGORY_HOME)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    private fun handleBluetoothCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPairedDevices" -> {
                val devices = BluetoothReceiver.getPairedDevices(context)
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
            "connectDevice" -> {
                val address = call.argument<String>("address") ?: ""
                BluetoothReceiver.connectDevice(context, address) { success ->
                   result.success(success)
                }
            }
            "disconnectDevice" -> {
                val address = call.argument<String>("address") ?: ""
                BluetoothReceiver.connectDevice(context, address) { success ->
                   result.success(success)
                }
            }
            "startDiscovery" -> {
                val success = BluetoothReceiver.startDiscovery(context)
                result.success(success)
            }
            "stopDiscovery" -> {
                val success = BluetoothReceiver.stopDiscovery(context)
                result.success(success)
            }
            "setConnectionMode" -> {
                val mode = call.argument<String>("mode") ?: "phone_bluetooth"
                AudioForegroundService.connectionMode = mode
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                prefs.edit().putString("flutter.connection_mode", mode).apply()
                result.success(true)
            }
            "openApp" -> {
                openApp(result)
            }
            else -> result.notImplemented()
        }
    }

    private fun openApp(result: Result) {
        try {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                // 🟢 ĐÂY LÀ CẤU HÌNH QUAN TRỌNG NHẤT ĐỂ MỞ APP ỔN ĐỊNH
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or 
                                    Intent.FLAG_ACTIVITY_SINGLE_TOP or 
                                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                
                // Đảm bảo intent nhắm đúng vào main activity của app
                launchIntent.action = Intent.ACTION_MAIN
                launchIntent.addCategory(Intent.CATEGORY_LAUNCHER)

                context.startActivity(launchIntent)
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            // Catch-all dự phòng: Cố gắng mở lại bằng package name nếu intent trên thất bại
            try {
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                result.success(true)
            } catch (e2: Exception) {
                result.success(false)
            }
        }
    }

    private fun startAudioService(action: String) {
        val intent = buildServiceIntent(action)
        startServiceSafe(intent)
    }

    private fun buildServiceIntent(action: String): Intent {
        return Intent(context, AudioForegroundService::class.java).apply {
            this.action = action
        }
    }

    private fun startServiceSafe(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }
}
