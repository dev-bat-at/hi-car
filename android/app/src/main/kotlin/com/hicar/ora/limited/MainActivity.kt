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
        super.configureFlutterEngine(flutterEngine)
        instance = this
        
        // 🟢 ĐĂNG KÝ HICAR PLUGIN Ở ĐÂY
        // Điều này giúp Debug và Release hoạt động ổn định như nhau
        flutterEngine.plugins.add(HiCarPlugin())

        // Cache engine để tái sử dụng nếu cần
        FlutterEngineCache.getInstance().put("hicar_engine_id", flutterEngine)
    }

    // Giữ Engine sống ngay cả khi Activity bị hệ thống tạm hủy
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