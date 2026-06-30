package com.hicar.ora.limited

import android.content.Context
import android.content.SharedPreferences
import android.os.Build

/**
 * Boot session tracking persisted in device-protected storage.
 * Survives process lifetime so a long-lived FGS does not block the next real boot.
 */
object BootSessionManager {

    private const val PREFS_NAME = "HiCarBootSession"
    private const val KEY_SESSION = "boot_session_id"
    private const val KEY_COMPLETED = "last_completed_boot_session_id"
    private const val KEY_MISS_REPORTED = "boot_miss_reported_session_id"
    private const val KEY_LAST_INCREMENT_MS = "last_boot_increment_at_ms"
    private const val BOOT_INCREMENT_DEBOUNCE_MS = 60_000L

    private fun prefs(context: Context): SharedPreferences {
        val app = context.applicationContext
        val storage = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            app.createDeviceProtectedStorageContext()
        } else {
            app
        }
        return storage.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun incrementSessionOnBoot(context: Context): Long {
        val p = prefs(context)
        val now = System.currentTimeMillis()
        val lastIncrement = p.getLong(KEY_LAST_INCREMENT_MS, 0L)
        if (lastIncrement > 0L && now - lastIncrement < BOOT_INCREMENT_DEBOUNCE_MS) {
            val existing = p.getLong(KEY_SESSION, 0L)
            HiCarDiagnosticLog.d("HiCarBoot", "Boot session debounce → reuse id=$existing")
            return existing
        }
        val next = p.getLong(KEY_SESSION, 0L) + 1L
        p.edit()
            .putLong(KEY_SESSION, next)
            .putLong(KEY_LAST_INCREMENT_MS, now)
            .apply()
        HiCarDiagnosticLog.d("HiCarBoot", "New boot session id=$next")
        return next
    }

    fun getCurrentSession(context: Context): Long =
        prefs(context).getLong(KEY_SESSION, 0L)

    fun isSessionCompleted(context: Context, sessionId: Long): Boolean {
        if (sessionId <= 0L) return false
        return prefs(context).getLong(KEY_COMPLETED, -1L) >= sessionId
    }

    fun markSessionCompleted(context: Context, sessionId: Long) {
        if (sessionId <= 0L) return
        val p = prefs(context)
        val prev = p.getLong(KEY_COMPLETED, -1L)
        if (sessionId > prev) {
            p.edit().putLong(KEY_COMPLETED, sessionId).apply()
            HiCarDiagnosticLog.d("HiCarBoot", "Boot session $sessionId completed (onCompletion)")
        }
    }

    fun reportMissIfNeeded(context: Context, sessionId: Long, reason: String) {
        if (sessionId <= 0L) return
        if (isSessionCompleted(context, sessionId)) return
        val p = prefs(context)
        if (p.getLong(KEY_MISS_REPORTED, -1L) == sessionId) return
        HiCarDiagnosticLog.e("HiCarBoot", "BOOT_PLAYBACK_MISSED: $reason (session=$sessionId)")
        p.edit().putLong(KEY_MISS_REPORTED, sessionId).apply()
    }
}
