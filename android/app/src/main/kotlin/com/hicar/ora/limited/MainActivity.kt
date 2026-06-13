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

    override fun onResume() {
        super.onResume()
        instance = this
        ensureOverlayBridge()
    }

    override fun onPause() {
        super.onPause()
        // Đăng ký TRƯỚC khi app xuống nền (nút nổi hiện ở trạng thái paused),
        // đảm bảo overlay luôn gọi thẳng được xuống native dù isolate chính có bị treo.
        ensureOverlayBridge()
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    /**
     * Gắn OverlayBridge lên engine của nút nổi (flutter_overlay_window cache nó dưới
     * tag "myCachedEngine"). Engine này được tạo khi plugin attach vào Activity và tồn tại
     * suốt vòng đời process, nên chỉ cần đăng ký 1 lần là đủ (register() đã idempotent).
     */
    private fun ensureOverlayBridge() {
        try {
            val overlayEngine = FlutterEngineCache.getInstance().get(OverlayBridge.OVERLAY_ENGINE_TAG)
            if (overlayEngine != null) {
                OverlayBridge.register(overlayEngine, applicationContext)
            }
        } catch (e: Exception) {
            android.util.Log.e("HiCarMain", "ensureOverlayBridge error: ${e.message}")
        }
    }
}
