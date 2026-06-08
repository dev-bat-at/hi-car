package com.hicar.ora.limited

import android.content.Context
import android.content.Intent
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
            "openApp" -> {
                openApp(result)
            }
            else -> result.notImplemented()
        }
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
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (launchIntent != null) {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or 
                                Intent.FLAG_ACTIVITY_CLEAR_TOP or 
                                Intent.FLAG_ACTIVITY_SINGLE_TOP)
            try {
                context.startActivity(launchIntent)
                result.success(true)
            } catch (e: Exception) {
                result.success(false)
            }
        } else {
            result.success(false)
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
