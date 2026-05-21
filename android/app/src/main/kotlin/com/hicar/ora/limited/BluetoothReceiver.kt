package com.hicar.ora.limited

import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BluetoothReceiver : BroadcastReceiver() {

    companion object {
        /**
         * Returns list of paired Bluetooth devices as maps for Flutter MethodChannel.
         */
        fun getPairedDevices(context: Context): List<Map<String, String>> {
            return try {
                val bluetoothManager =
                    context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                val adapter = bluetoothManager?.adapter ?: return emptyList()
                adapter.bondedDevices?.map { device ->
                    mapOf(
                        "name" to (device.name ?: "Unknown Device"),
                        "address" to device.address
                    )
                } ?: emptyList()
            } catch (e: SecurityException) {
                emptyList()
            }
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

        when (intent.action) {
            BluetoothDevice.ACTION_ACL_CONNECTED -> {
                // Only trigger if user selected this device
                if (targetAddress.isNotEmpty() && deviceAddress == targetAddress) {
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
                context.startService(serviceIntent)
            }
        }
    }
}
