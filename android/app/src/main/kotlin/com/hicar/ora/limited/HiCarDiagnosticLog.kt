package com.hicar.ora.limited

import android.content.Context
import android.os.Build
import android.os.Process
import android.util.Log
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.CopyOnWriteArrayList

/**
 * In-app diagnostic log with adb/logcat-style lines (HiCar tags only).
 * Persists in device-protected storage so boot events survive before app UI opens.
 */
object HiCarDiagnosticLog {

    private val ALLOWED_TAGS = setOf(
        "HiCarBoot",
        "HiCarService",
        "HiCarAudio",
        "HiCarAA",
        "HiCarSync",
        "HiCarPlugin",
        "HiCar",
        "OverlayBridge"
    )

    private const val MAX_LINES = 200
    private const val FILE_NAME = "hicar_diagnostic.log"

    private val buffer = CopyOnWriteArrayList<String>()
    private val timeFormat = SimpleDateFormat("MM-dd HH:mm:ss.SSS", Locale.US)
    @Volatile private var storageContext: Context? = null

    fun init(context: Context) {
        if (storageContext != null) return
        val ctx = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            context.applicationContext.createDeviceProtectedStorageContext()
        } else {
            context.applicationContext
        }
        storageContext = ctx
        loadFromDisk(ctx)
    }

    fun markBootSession() {
        appendRaw("----- boot session ${timeFormat.format(Date())} -----")
    }

    fun d(tag: String, message: String) = write("D", tag, message)

    fun w(tag: String, message: String) = write("W", tag, message)

    fun e(tag: String, message: String) = write("E", tag, message)

    fun hasErrorLines(): Boolean = buffer.any { isErrorLine(it) }

    fun getFullLog(): String {
        if (buffer.isEmpty()) return ""
        return buffer.joinToString("\n")
    }

    /** E/W lines plus a few surrounding D lines for context. */
    fun getErrorLog(): String {
        if (buffer.isEmpty()) return ""
        val lines = buffer.toList()
        val include = BooleanArray(lines.size)
        for (i in lines.indices) {
            if (isErrorLine(lines[i])) {
                for (j in maxOf(0, i - 2)..minOf(lines.lastIndex, i + 2)) {
                    include[j] = true
                }
            }
        }
        return lines.indices.filter { include[it] }.joinToString("\n") { lines[it] }
    }

    fun clear() {
        buffer.clear()
        storageContext?.let { File(it.filesDir, FILE_NAME).delete() }
    }

    private fun write(level: String, tag: String, message: String) {
        if (tag !in ALLOWED_TAGS) return
        when (level) {
            "D" -> Log.d(tag, message)
            "W" -> Log.w(tag, message)
            "E" -> Log.e(tag, message)
        }
        appendRaw(formatLine(level, tag, message))
    }

    private fun appendRaw(line: String) {
        buffer.add(line)
        while (buffer.size > MAX_LINES) {
            buffer.removeAt(0)
        }
        persistLine(line)
    }

    private fun formatLine(level: String, tag: String, message: String): String {
        val ts = timeFormat.format(Date())
        val pid = Process.myPid()
        val tid = Process.myTid()
        return "$ts  $pid  $tid $level $tag: $message"
    }

    private fun isErrorLine(line: String): Boolean {
        return line.contains(" E HiCar") || line.contains(" W HiCar")
    }

    private fun loadFromDisk(context: Context) {
        try {
            val file = File(context.filesDir, FILE_NAME)
            if (!file.exists()) return
            buffer.clear()
            file.readLines().takeLast(MAX_LINES).forEach { buffer.add(it) }
        } catch (_: Exception) {
        }
    }

    private fun persistLine(line: String) {
        val ctx = storageContext ?: return
        try {
            File(ctx.filesDir, FILE_NAME).appendText("$line\n")
        } catch (_: Exception) {
        }
    }
}
