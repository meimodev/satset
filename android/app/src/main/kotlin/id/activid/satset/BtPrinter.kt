package id.activid.satset

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Bluetooth Classic (SPP) transport for thermal printers (ADR-0022).
 *
 * Every socket call blocks — a printer out of paper or walking out of range
 * holds a write for as long as it likes — so none of it runs on the main
 * thread, which is also the Dart UI thread and, on the host, the embedded
 * server's. One call is one whole session (connect, write, close), so a probe
 * and a print can never share or close each other's socket.
 */
internal object BtPrinter {
    private val spp = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val io = Executors.newCachedThreadPool()
    private val watchdog = Executors.newSingleThreadScheduledExecutor()
    private val main = Handler(Looper.getMainLooper())

    // An SPP printer takes one connection at a time.
    private val locks = ConcurrentHashMap<String, Any>()

    fun attach(context: Context, engine: FlutterEngine) {
        val app = context.applicationContext
        MethodChannel(engine.dartExecutor.binaryMessenger, "satset/bt")
            .setMethodCallHandler { call, result ->
                io.execute {
                    val reply: () -> Unit = try {
                        val value: Any? = when (call.method) {
                            "enabled" -> adapter(app)?.isEnabled == true
                            "paired" -> adapter(app)?.bondedDevices.orEmpty().map {
                                mapOf("name" to (it.name ?: ""), "mac" to it.address)
                            }
                            "probe" -> {
                                session(app, call.argument<String>("mac")!!, 10_000) {}
                                true
                            }
                            "send" -> {
                                val bytes = call.argument<ByteArray>("bytes")!!
                                session(app, call.argument<String>("mac")!!, 30_000) {
                                    it.outputStream.write(bytes)
                                    it.outputStream.flush()
                                }
                                null
                            }
                            else -> {
                                main.post { result.notImplemented() }
                                return@execute
                            }
                        }
                        { result.success(value) }
                    } catch (e: Exception) {
                        { result.error("bt_failed", e.message ?: e.javaClass.simpleName, null) }
                    }
                    main.post(reply)
                }
            }
    }

    private fun adapter(context: Context): BluetoothAdapter? =
        context.getSystemService(BluetoothManager::class.java)?.adapter

    private fun session(
        context: Context,
        mac: String,
        timeoutMs: Long,
        use: (BluetoothSocket) -> Unit,
    ) {
        synchronized(locks.getOrPut(mac) { Any() }) {
            val adapter = adapter(context) ?: error("no_adapter")
            val socket = adapter.getRemoteDevice(mac).createRfcommSocketToServiceRecord(spp)
            // Closing the socket is the only way to abort a blocked connect or write.
            val abort = watchdog.schedule(
                { runCatching { socket.close() } },
                timeoutMs,
                TimeUnit.MILLISECONDS,
            )
            try {
                socket.connect()
                use(socket)
            } finally {
                abort.cancel(false)
                runCatching { socket.close() }
            }
        }
    }
}
