package id.activid.satset

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class SatSetServerService : Service() {
    private val channelId = "satset.server"
    private val notifId = 1001
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            // Promotion precedes all backend work, even a cancelled start.
            showNotification(ready = false)
            if (!ServerHost.hosting || ServerHost.engine == null) {
                stopSelf()
                return START_NOT_STICKY
            }
            ServerHost.service = this
            if (wakeLock == null) {
                wakeLock = getSystemService(PowerManager::class.java)
                    .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "SatSet:server")
                    .apply {
                        setReferenceCounted(false)
                        // Held for the hosting session; stop/error/destroy release it.
                        acquire()
                    }
            }
            ServerHost.started()
        } catch (e: Exception) {
            ServerHost.stop(this, e.message ?: "Server service failed")
            stopSelf()
        }
        // ponytail: retain the live Dart host only. Process-death recovery needs
        // headless auth/eligibility restoration before it can safely be sticky.
        return START_NOT_STICKY
    }

    fun showNotification(ready: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(channelId, getString(R.string.server_channel), NotificationManager.IMPORTANCE_LOW)
            )
        }
        val openApp = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle(getString(if (ready) R.string.server_running else R.string.server_starting))
            .setContentText(getString(R.string.server_notification_body))
            .setSmallIcon(R.drawable.ic_server_notification)
            .setContentIntent(openApp)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(notifId, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
        } else {
            startForeground(notifId, notification)
        }
    }

    fun releaseWakeLock() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }

    override fun onDestroy() {
        releaseWakeLock()
        if (ServerHost.service === this) ServerHost.service = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }
}
