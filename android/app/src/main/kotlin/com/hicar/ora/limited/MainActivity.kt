package com.hicar.ora.limited

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity : FlutterActivity() {

    companion object {
        @Volatile
        var instance: MainActivity? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // 1. Đăng ký pub plugins qua GeneratedPluginRegistrant (tự sinh bởi Flutter tools)
        super.configureFlutterEngine(flutterEngine)
        instance = this

        // 2. Đăng ký HiCarPlugin TRỰC TIẾP trên dartExecutor của engine HIỂN THỊ này.
        //    Đây là messenger mà Dart code (ServiceChannel/_channel) dùng → cả 2 chiều khớp.
        //    KHÔNG phụ thuộc GeneratedPluginRegistrant (file tự sinh, bị regenerate mỗi build)
        //    và KHÔNG bị engine phụ (overlay/audio_service) ghi đè.
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        HiCarPlugin.registerWith(messenger, applicationContext)
        android.util.Log.e(
            "HiCarMain",
            "registerWith on dartExecutor messenger#${System.identityHashCode(messenger)}"
        )

        // Cache engine để service có thể tham chiếu khi cần
        FlutterEngineCache.getInstance().put("hicar_engine_id", flutterEngine)
        android.util.Log.e("HiCarMain", "configureFlutterEngine DONE")
    }

    override fun shouldDestroyEngineWithHost() = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        instance = this
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }
}
