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
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONObject

/**
 * A ForegroundService that monitors the device battery state in real-time.
 *
 * Updated Architecture: Countdown is handled internally while holding a WakeLock,
 * then a custom Full-Screen Intent is fired to bypass ColorOS restrictions.
 */
class BatteryMonitorService : Service() {

    companion object {
        const val EXTRA_CONFIG_JSON = "extra_config_json"

        private const val TAG = "BatteryMonitorService"
        private const val NOTIFICATION_CHANNEL_ID = "taskflow_battery_monitor"
        private const val ALARM_NOTIFICATION_CHANNEL_ID = "taskflow_alarm_channel_v2"
        private const val NOTIFICATION_ID = 1001
        private const val ALARM_NOTIFICATION_ID = 999
    }

    private var targetPercentage: Int = 90
    private var condition: String = "equals"
    private var requireCharging: Boolean = true
    private var timerSeconds: Int = 5
    
    private var lastBatteryLevel: Int = -1

    private val batteryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != Intent.ACTION_BATTERY_CHANGED) return

            // Acquire short WakeLock to process the battery change
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

            val currentLevel = (level * 100) / scale
            val isCharging = plugged == BatteryManager.BATTERY_PLUGGED_AC ||
                    plugged == BatteryManager.BATTERY_PLUGGED_USB ||
                    plugged == BatteryManager.BATTERY_PLUGGED_WIRELESS

            Log.d(TAG, "Battery Received: $currentLevel%, Target: $targetPercentage% ($condition)")

            // ── Evaluation Logic ──────────────────────────────────────────
            
            val isFirstRun = (lastBatteryLevel == -1)
            var shouldTrigger = false
            val safeCondition = condition.lowercase()

            if (safeCondition.contains("equal")) {
                shouldTrigger = (currentLevel == targetPercentage) && (isFirstRun || lastBatteryLevel != targetPercentage)
            } 
            else if (safeCondition.contains("rise") || safeCondition.contains("above")) {
                shouldTrigger = (currentLevel > targetPercentage) && (isFirstRun || lastBatteryLevel <= targetPercentage)
            } 
            else if (safeCondition.contains("fall") || safeCondition.contains("below")) {
                shouldTrigger = (currentLevel < targetPercentage) && (isFirstRun || lastBatteryLevel >= targetPercentage)
            }

            if (shouldTrigger && requireCharging && !isCharging) {
                shouldTrigger = false
            }

            if (shouldTrigger) {
                Log.i(TAG, "Condition met! Starting internal countdown...")
                startInternalTimer(context)
            }

            lastBatteryLevel = currentLevel
            if (cpuLock.isHeld) cpuLock.release()
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val configJson = intent?.getStringExtra(EXTRA_CONFIG_JSON)
        if (configJson != null) {
            parseTriggerConfig(configJson)
            lastBatteryLevel = -1 
        }

        startForeground(NOTIFICATION_ID, buildForegroundNotification())

        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        registerReceiver(batteryReceiver, filter)

        Log.i(TAG, "BatteryMonitorService (Foreground) active.")
        return START_REDELIVER_INTENT
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(batteryReceiver)
        } catch (e: Exception) {}
    }

    override fun onBind(intent: Intent?): IBinder? = null

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

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)

            val monitorChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Battery Monitor",
                NotificationManager.IMPORTANCE_LOW
            )
            manager.createNotificationChannel(monitorChannel)

            val alarmChannel = NotificationChannel(
                ALARM_NOTIFICATION_CHANNEL_ID,
                "Critical Alarm Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Forces screen wake up for battery alerts"
                setBypassDnd(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableLights(true)
                enableVibration(true)
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
            .setContentText("Monitoring battery securely in the background.")
            .setSmallIcon(android.R.drawable.ic_lock_idle_charging)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(pendingIntent)
            .build()
    }

    /**
     * Handles the timer countdown internally while holding a WakeLock.
     * When finished, it blasts a custom high-priority Full-Screen Activity alert.
     */
    private fun startInternalTimer(context: Context) {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        val countdownLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "TaskFlow::CountdownLock")
        
        // Acquire lock for the duration of the timer + buffer
        countdownLock.acquire((timerSeconds * 1000L) + 10000L)

        Handler(Looper.getMainLooper()).postDelayed({
            // 1. Prepare Intent to our custom Alert Activity
            val alertIntent = Intent(this, TimerAlertActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            
            val pendingIntent = PendingIntent.getActivity(
                this, 
                0, 
                alertIntent, 
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )

            // 2. Build the "Inescapable" Notification
            val notification = NotificationCompat.Builder(this, ALARM_NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle("Bateri Mencapai Sasaran!")
                .setContentText("Pengecasan tamat. Sila cabut palam.")
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setFullScreenIntent(pendingIntent, true) // CRITICAL for lock screen wake
                .setAutoCancel(true)
                .setOngoing(true)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .build()

            val notifManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notifManager.notify(ALARM_NOTIFICATION_ID, notification)

            // 3. Force start activity just in case screen is ON
            try {
                startActivity(alertIntent)
            } catch (e: Exception) {
                Log.e(TAG, "Force start activity failed: ${e.message}")
            }

            if (countdownLock.isHeld) countdownLock.release()
            Log.i(TAG, "Internal countdown finished. Alert triggered.")
            
        }, timerSeconds * 1000L)
    }
}
