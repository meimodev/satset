package id.activid.satset

import android.app.Activity
import android.content.Intent
import android.content.pm.ActivityInfo
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val channel = "satset/server"
    private val csvRequest = 1042
    private var csvResult: MethodChannel.Result? = null

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
                    "pickCsv" -> {
                        if (csvResult != null) {
                            result.error("picker_busy", "CSV picker already open", null)
                        } else {
                            csvResult = result
                            startActivityForResult(
                                Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                                    addCategory(Intent.CATEGORY_OPENABLE)
                                    type = "text/*"
                                    putExtra(
                                        Intent.EXTRA_MIME_TYPES,
                                        arrayOf("text/csv", "text/comma-separated-values", "text/plain")
                                    )
                                },
                                csvRequest
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != csvRequest) return
        val result = csvResult ?: return
        csvResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        try {
            val output = ByteArrayOutputStream()
            contentResolver.openInputStream(uri)!!.use { input ->
                val buffer = ByteArray(8192)
                while (true) {
                    val read = input.read(buffer)
                    if (read < 0) break
                    output.write(buffer, 0, read)
                    if (output.size() > 5 * 1024 * 1024) {
                        throw IllegalArgumentException("file_too_large")
                    }
                }
            }
            result.success(output.toByteArray())
        } catch (e: Exception) {
            result.error(
                if (e.message == "file_too_large") "file_too_large" else "file_read_failed",
                e.message,
                null
            )
        }
    }
}
