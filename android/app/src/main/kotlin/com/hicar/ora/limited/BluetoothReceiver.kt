package com.hicar.ora.limited

import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BluetoothReceiver : BroadcastReceiver() {

    companion object {
        /**
         * Returns list of paired Bluetooth devices as maps for Flutter MethodChannel.
         */
        fun getPairedDevices(context: Context): List<Map<String, Any>> {
            return try {
                val bluetoothManager =
                    context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                val adapter = bluetoothManager?.adapter ?: return emptyList()
                adapter.bondedDevices?.map { device ->
                    mapOf(
                        "name" to (device.name ?: "Unknown Device"),
                        "address" to device.address,
                        "isConnected" to isDeviceConnected(device)
                    )
                } ?: emptyList()
            } catch (e: SecurityException) {
                emptyList()
            }
        }

        /**
         * Check if a classic Bluetooth device is connected using reflection.
         */
        private fun isDeviceConnected(device: BluetoothDevice): Boolean {
            return try {
                val method = device.javaClass.getMethod("isConnected")
                method.invoke(device) as? Boolean ?: false
            } catch (e: Exception) {
                false
            }
        }

        fun startDiscovery(context: Context): Boolean {
            val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            val adapter = bluetoothManager?.adapter ?: return false
            return try {
                if (adapter.isDiscovering) {
                    adapter.cancelDiscovery()
                }
                adapter.startDiscovery()
            } catch (e: SecurityException) {
                false
            }
        }

        fun stopDiscovery(context: Context): Boolean {
            val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            val adapter = bluetoothManager?.adapter ?: return false
            return try {
                if (adapter.isDiscovering) {
                    adapter.cancelDiscovery()
                } else {
                    true
                }
            } catch (e: SecurityException) {
                false
            }
        }

        /**
         * Connect to A2DP and Headset profiles of a device using reflection.
         */
        fun connectDevice(context: Context, address: String, callback: (Boolean) -> Unit) {
            val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            val adapter = bluetoothManager?.adapter ?: run {
                callback(false)
                return
            }
            val device = try {
                adapter.getRemoteDevice(address)
            } catch (e: Exception) {
                null
            }
            if (device == null) {
                callback(false)
                return
            }

            // Connect A2DP (Music)
            adapter.getProfileProxy(context, object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                    try {
                        val connectMethod = proxy.javaClass.getMethod("connect", BluetoothDevice::class.java)
                        connectMethod.invoke(proxy, device)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    } finally {
                        adapter.closeProfileProxy(BluetoothProfile.A2DP, proxy)
                    }
                }
                override fun onServiceDisconnected(profile: Int) {}
            }, BluetoothProfile.A2DP)

            // Connect HEADSET (Calls)
            adapter.getProfileProxy(context, object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                    try {
                        val connectMethod = proxy.javaClass.getMethod("connect", BluetoothDevice::class.java)
                        connectMethod.invoke(proxy, device)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    } finally {
                        adapter.closeProfileProxy(BluetoothProfile.HEADSET, proxy)
                    }
                }
                override fun onServiceDisconnected(profile: Int) {}
            }, BluetoothProfile.HEADSET)

            callback(true)
        }

        /**
         * Disconnect from A2DP and Headset profiles using reflection.
         */
        fun disconnectDevice(context: Context, address: String, callback: (Boolean) -> Unit) {
            val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            val adapter = bluetoothManager?.adapter ?: run {
                callback(false)
                return
            }
            val device = try {
                adapter.getRemoteDevice(address)
            } catch (e: Exception) {
                null
            }
            if (device == null) {
                callback(false)
                return
            }

            // Disconnect A2DP
            adapter.getProfileProxy(context, object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                    try {
                        val disconnectMethod = proxy.javaClass.getMethod("disconnect", BluetoothDevice::class.java)
                        disconnectMethod.invoke(proxy, device)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    } finally {
                        adapter.closeProfileProxy(BluetoothProfile.A2DP, proxy)
                    }
                }
                override fun onServiceDisconnected(profile: Int) {}
            }, BluetoothProfile.A2DP)

            // Disconnect HEADSET
            adapter.getProfileProxy(context, object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                    try {
                        val disconnectMethod = proxy.javaClass.getMethod("disconnect", BluetoothDevice::class.java)
                        disconnectMethod.invoke(proxy, device)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    } finally {
                        adapter.closeProfileProxy(BluetoothProfile.HEADSET, proxy)
                    }
                }
                override fun onServiceDisconnected(profile: Int) {}
            }, BluetoothProfile.HEADSET)

            callback(true)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
        }

        val deviceAddress = device?.address ?: return
        val targetAddress = AudioForegroundService.targetDeviceAddress

        // Read connectionMode from SharedPreferences to know if we are in phone_bluetooth mode
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val connectionMode = prefs.getString("flutter.connection_mode", "phone_bluetooth") ?: "phone_bluetooth"

        // 🟢 SỬA ĐỔI CHÍNH: Thay đổi từ gọi instance sang biến tĩnh tĩnh toàn cục để tránh lỗi Unresolved reference
        // Send Bluetooth events to Flutter via Plugin
        when (intent.action) {
            BluetoothDevice.ACTION_FOUND -> {
                HiCarPlugin.instance?.invokeBluetoothMethod("onDeviceFound", mapOf(
                    "name" to (device.name ?: "Unknown Device"),
                    "address" to deviceAddress,
                    "isConnected" to false
                ))
            }
            BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                HiCarPlugin.instance?.invokeBluetoothMethod("onDiscoveryFinished", null)
            }
            else -> {
                // Connection state changes
                HiCarPlugin.instance?.invokeBluetoothMethod("onDeviceConnectionChanged", mapOf(
                    "address" to deviceAddress,
                    "action" to intent.action
                ))
            }
        }

        when (intent.action) {
            BluetoothDevice.ACTION_ACL_CONNECTED -> {
                // Only trigger auto-play if we are in Phone + Bluetooth mode and device matches target address
                if (connectionMode == "phone_bluetooth" && targetAddress.isNotEmpty() && deviceAddress == targetAddress) {
                    val serviceIntent = Intent(context, AudioForegroundService::class.java).apply {
                        action = AudioForegroundService.ACTION_PLAY_GREETING_DELAYED
                        putExtra("deviceAddress", deviceAddress)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                }
            }
            BluetoothDevice.ACTION_ACL_DISCONNECTED -> {
                // Cancel any pending delayed playback
                val serviceIntent = Intent(context, AudioForegroundService::class.java).apply {
                    action = AudioForegroundService.ACTION_BLUETOOTH_DISCONNECTED
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        }
    }
}