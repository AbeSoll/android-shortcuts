package com.solehin.android_shortcuts

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Main entry point for the Android side of TaskFlow.
 *
 * Sets up the MethodChannel handler for `com.solehin.taskflow/automation`
 * to receive battery monitoring configurations from Flutter and start/stop
 * the [BatteryMonitorService] ForegroundService accordingly.
 *
 * Also overrides [onActivityResult] to handle the result from the native
 * [RingtoneManager.ACTION_RINGTONE_PICKER] intent, returning the selected
 * ringtone URI and name back to Flutter.
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.solehin.taskflow/automation"
        private const val RINGTONE_PICKER_REQUEST_CODE = 5001
    }

    /**
     * Holds the pending [MethodChannel.Result] while waiting for the
     * ringtone picker activity to return. Set to `null` after delivery
     * to prevent stale callbacks.
     */
    private var pendingRingtoneResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)


        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startMonitoring" -> {
                    val configJson = call.argument<String>("configJson")
                    if (configJson == null) {
                        result.error(
                            "INVALID_ARGUMENT",
                            "configJson is required",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    val serviceIntent = Intent(this, BatteryMonitorService::class.java).apply {
                        putExtra(BatteryMonitorService.EXTRA_CONFIG_JSON, configJson)
                    }

                    // ForegroundService requires startForegroundService on API 26+
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }

                    result.success(true)
                }

                "stopMonitoring" -> {
                    val serviceIntent = Intent(this, BatteryMonitorService::class.java)
                    stopService(serviceIntent)
                    result.success(true)
                }

                "pickSystemRingtone" -> {
                    pendingRingtoneResult = result
                    launchRingtonePicker()
                }

                else -> result.notImplemented()
            }
        }
    }

    // ── Ringtone Picker ────────────────────────────────────────────────

    /**
     * Launches the native Android ringtone picker intent.
     *
     * Shows all alarm and ringtone sounds available on the device.
     * The user's selection is returned via [onActivityResult].
     */
    private fun launchRingtonePicker() {
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALL)
            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Select Alarm Ringtone")
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
        }
        startActivityForResult(intent, RINGTONE_PICKER_REQUEST_CODE)
    }

    /**
     * Handles the result from the ringtone picker activity.
     *
     * Extracts the selected ringtone's [Uri] and resolves its display
     * name via [RingtoneManager.getRingtone]. Returns both values to
     * Flutter as a `Map<String, String>` with keys `uri` and `name`.
     *
     * Returns `null` to Flutter if the user cancelled the picker.
     */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != RINGTONE_PICKER_REQUEST_CODE) {
            return
        }

        val result = pendingRingtoneResult
        pendingRingtoneResult = null

        if (result == null) {
            return
        }

        if (resultCode != Activity.RESULT_OK || data == null) {
            // User cancelled the picker
            result.success(null)
            return
        }

        val ringtoneUri: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            data.getParcelableExtra(
                RingtoneManager.EXTRA_RINGTONE_PICKED_URI,
                Uri::class.java
            )
        } else {
            @Suppress("DEPRECATION")
            data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        }

        if (ringtoneUri == null) {
            result.success(null)
            return
        }

        // Resolve the human-readable ringtone title
        val ringtone = RingtoneManager.getRingtone(this, ringtoneUri)
        val ringtoneName = ringtone?.getTitle(this) ?: "Unknown Ringtone"

        result.success(
            mapOf(
                "uri" to ringtoneUri.toString(),
                "name" to ringtoneName
            )
        )
    }
}
