package id.activid.satset

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** The channel and engine outlive the Activity; no Activity is captured here. */
internal object ServerHost {
    var engine: FlutterEngine? = null
    var hosting = false
        private set
    var service: SatSetServerService? = null
    private var pendingStart: MethodChannel.Result? = null
    private val handler = Handler(Looper.getMainLooper())

    fun attach(context: Context, flutterEngine: FlutterEngine) {
        if (engine === flutterEngine) return
        engine = flutterEngine
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "satset/host")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "start" -> {
                            check(!hosting) { "Server host already started" }
                            hosting = true
                            pendingStart = result
                            // Bounds both service dispatch and a stalled Dart boot.
                            handler.postDelayed({ stop(context, "Server startup timed out") }, 30_000)
                            val intent = Intent(context, SatSetServerService::class.java)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                context.startForegroundService(intent)
                            } else {
                                context.startService(intent)
                            }
                        }
                        "ready" -> {
                            check(hosting && service != null) { "Server service is unavailable" }
                            service!!.showNotification(ready = true)
                            handler.removeCallbacksAndMessages(null)
                            result.success(null)
                        }
                        "stop" -> {
                            stop(context, "Server stopped")
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    if (call.method == "start" && pendingStart === result) {
                        stop(context, e.message ?: "Server service failed")
                    } else {
                        result.error("server_service", e.message, null)
                    }
                }
            }
    }

    fun started() {
        pendingStart?.success(null)
        pendingStart = null
    }

    fun stop(context: Context, reason: String) {
        hosting = false
        handler.removeCallbacksAndMessages(null)
        pendingStart?.error("server_service", reason, null)
        pendingStart = null
        service?.releaseWakeLock()
        context.stopService(Intent(context, SatSetServerService::class.java))
    }
}
