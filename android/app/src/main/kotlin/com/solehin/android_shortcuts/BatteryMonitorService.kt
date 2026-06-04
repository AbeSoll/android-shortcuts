package com.solehin.android_shortcuts

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONObject

/**
 * A ForegroundService that monitors the device battery state in real-time.
 *
 * This service is elevated to Foreground status to survive Doze mode and
 * aggressive OEM task killers (like ColorOS). It uses a WakeLock inside
 * the BroadcastReceiver to ensure the CPU is awake enough to process
 * battery events even when the screen is OFF.
 */
class BatteryMonitorService : Service() {

    companion object {
        const val EXTRA_CONFIG_JSON = "extra_config_json"

        private const val TAG = "BatteryMonitorService"
        private const val NOTIFICATION_CHANNEL_ID = "taskflow_battery_monitor"
        private const val ALARM_NOTIFICATION_CHANNEL_ID = "taskflow_alarm_channel"
        private const val NOTIFICATION_ID = 1001
        private const val ALARM_NOTIFICATION_ID = 1002
    }

    private var targetPercentage: Int = 90
    private var condition: String = "equals" // equals, risesAbove, fallsBelow
    private var requireCharging: Boolean = true
    private var timerSeconds: Int = 5
    
    // State machine to prevent spamming
    private var lastBatteryLevel: Int = -1

    /**
     * BroadcastReceiver that listens to battery state changes.
     */
    private val batteryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != Intent.ACTION_BATTERY_CHANGED) return

            // ── Acquire CPU WakeLock ──────────────────────────────────────
            // Crucial: Hold CPU for a few seconds to ensure we process the logic
            // while the device is in deep sleep/Doze mode.
            val powerManager = context?.getSystemService(Context.POWER_SERVICE) as PowerManager
            val cpuLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "TaskFlow::BatteryCheck")
            cpuLock.acquire(5000L) 

            val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            val plugged = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)

            if (level < 0 || scale <= 0) {
                if (cpuLock.isHeld) cpuLock.release()
                return
            }

            val batteryPercent = (level * 100) / scale
            val isCharging = plugged == BatteryManager.BATTERY_PLUGGED_AC ||
                    plugged == BatteryManager.BATTERY_PLUGGED_USB ||
                    plugged == BatteryManager.BATTERY_PLUGGED_WIRELESS

            Log.d(TAG, "Battery Received: $batteryPercent%, Prev: $lastBatteryLevel%, Condition: $condition, Target: $targetPercentage%")

            // ── Evaluation Logic ──────────────────────────────────────────
            
            val isFirstRun = lastBatteryLevel == -1
            val currentLevel = batteryPercent
            val target = targetPercentage
            
            val metCondition = when (condition) {
                "equals" -> (currentLevel == target) && (isFirstRun || lastBatteryLevel != target)
                "risesAbove" -> (currentLevel > target) && (!isFirstRun && lastBatteryLevel <= target)
                "fallsBelow" -> (currentLevel < target) && (!isFirstRun && lastBatteryLevel >= target)
                else -> false
            }

            // Apply charging constraint
            var shouldTrigger = metCondition
            if (shouldTrigger && requireCharging && !isCharging) {
                shouldTrigger = false
            }

            if (shouldTrigger) {
                Log.i(TAG, "Condition met! Triggering FullScreen Alert...")
                triggerFullScreenAlert()
            }

            // Always update state
            lastBatteryLevel = currentLevel
            
            // Release WakeLock if held (optional due to timeout)
            if (cpuLock.isHeld) cpuLock.release()
        }
    }

    // ── Service Lifecycle ──────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val configJson = intent?.getStringExtra(EXTRA_CONFIG_JSON)
        if (configJson != null) {
            parseTriggerConfig(configJson)
            // Reset state to allow fresh evaluation
            lastBatteryLevel = -1 
        }

        // ── Start Foreground ──────────────────────────────────────────────
        // Elevate service priority to prevent it being killed during CPU sleep.
        startForeground(NOTIFICATION_ID, buildForegroundNotification())

        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        registerReceiver(batteryReceiver, filter)

        Log.i(TAG, "BatteryMonitorService (Foreground) started.")

        return START_REDELIVER_INTENT
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(batteryReceiver)
        } catch (e: Exception) {
            Log.w(TAG, "Unregister receiver failed: ${e.message}")
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ── Configuration ──────────────────────────────────────────────────

    private fun parseTriggerConfig(json: String) {
        try {
            val config = JSONObject(json)
            targetPercentage = config.optInt("targetPercentage", 90)
            condition = config.optString("condition", "equals")
            requireCharging = config.optBoolean("isCharging", true)
            
            val actionObj = config.optJSONObject("action")
            timerSeconds = actionObj?.optInt("timerSeconds", 5) ?: 5
        } catch (e: Exception) {
            Log.e(TAG, "Parse error: ${e.message}")
        }
    }

    // ── Notification ───────────────────────────────────────────────────

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)

            val monitorChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Battery Monitor",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the battery monitoring service active in the background."
            }
            manager.createNotificationChannel(monitorChannel)

            val alarmChannel = NotificationChannel(
                ALARM_NOTIFICATION_CHANNEL_ID,
                "Alarm Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(alarmChannel)
        }
    }

    private fun buildForegroundNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("TaskFlow Active")
            .setContentText("Monitoring battery level securely in the background.")
            .setSmallIcon(android.R.drawable.ic_lock_idle_charging)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun triggerFullScreenAlert() {
        val fullScreenIntent = Intent(this, TimerAlertActivity::class.java).apply {
            putExtra("timerSeconds", timerSeconds)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            this,
            0,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notificationBuilder = NotificationCompat.Builder(this, ALARM_NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_charging)
            .setContentTitle("TaskFlow Alert!")
            .setContentText("Battery target reached: $targetPercentage%")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setOngoing(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setFullScreenIntent(fullScreenPendingIntent, true)

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(ALARM_NOTIFICATION_ID, notificationBuilder.build())
        
        try {
            startActivity(fullScreenIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Activity force-start failed: ${e.message}")
        }
    }
}
