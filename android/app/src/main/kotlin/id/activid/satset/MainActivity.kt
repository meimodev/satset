package id.activid.satset

import android.content.Intent
import android.content.pm.ActivityInfo
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "satset/server"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Service floor: the screen never sleeps while SatSet is foreground. A
        // KDS on the line is read for a whole service without ever being
        // touched, and a waiter must never lose an order screen mid-tap. The
        // flag is scoped to this window, so Android drops it the moment the app
        // backgrounds. Deliberate trade: a foregrounded phone left in an apron
        // pocket burns battery. See ADR-0049.
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Hardware decides presentation. `smallestScreenWidthDp` is the sw600dp
        // qualifier — invariant under rotation, unlike a width read, so it can
        // pin orientation here (before the first Flutter frame, hence no
        // visible flip) without the chicken-and-egg of classifying a device by
        // a dimension the lock itself changes.
        //
        // SENSOR_LANDSCAPE lets a wall-mounted tablet be remounted either way
        // up; a phone gets portrait-up only. Orientation is not reachable from
        // Dart by design — an opt-out screen would need a method channel.
        requestedOrientation =
            if (resources.configuration.smallestScreenWidthDp >= 600) {
                ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
            } else {
                ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
            }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startServerService" -> {
                        val intent = Intent(this, SatSetServerService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }
                    "stopServerService" -> {
                        stopService(Intent(this, SatSetServerService::class.java))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
