package id.activid.satset

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Holds SatSet's process in the foreground while the system camera or photo
 * picker is open. Those run as another app, and on a low-RAM phone Android
 * kills the backgrounded app to make room: the cashier comes back from the
 * proof photo to a cold start, with the half-settled bill gone. A foreground
 * service is what moves the process out of the kill order. `shortService`
 * because a capture is short; Android stops it after three minutes.
 */
class CaptureGuardService : Service() {
    companion object {
        private const val channelId = "satset.capture"
        private const val notifId = 1002
        private var instance: CaptureGuardService? = null

        // Stop can arrive before the service has started; it must still
        // promote itself first, or Android kills the app for a late promotion.
        private var wanted = false

        fun attach(context: Context, engine: FlutterEngine) {
            val app = context.applicationContext
            MethodChannel(engine.dartExecutor.binaryMessenger, "satset/capture")
                .setMethodCallHandler { call, result ->
                    try {
                        when (call.method) {
                            "hold" -> {
                                wanted = true
                                val intent = Intent(app, CaptureGuardService::class.java)
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                    app.startForegroundService(intent)
                                } else {
                                    app.startService(intent)
                                }
                            }
                            "release" -> {
                                wanted = false
                                instance?.stopSelf()
                            }
                            else -> return@setMethodCallHandler result.notImplemented()
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("capture_guard", e.message, null)
                    }
                }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(channelId, getString(R.string.capture_channel), NotificationManager.IMPORTANCE_LOW)
            )
        }
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle(getString(R.string.capture_title))
            .setSmallIcon(R.drawable.ic_server_notification)
            .setOngoing(true)
            .setSilent(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(notifId, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SHORT_SERVICE)
        } else {
            startForeground(notifId, notification)
        }
        instance = this
        if (!wanted) stopSelf()
        return START_NOT_STICKY
    }

    // Past the three-minute short-service limit an unstopped service is an ANR.
    override fun onTimeout(startId: Int) {
        stopSelf()
    }

    override fun onDestroy() {
        if (instance === this) instance = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }
}
