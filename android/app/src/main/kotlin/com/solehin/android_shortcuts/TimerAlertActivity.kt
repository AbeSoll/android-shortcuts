package com.solehin.android_shortcuts

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Custom Full-Screen Alert Activity that rings when the automation timer finishes.
 * Designed to bypass strict OEM background restrictions by acting as an Alarm.
 */
class TimerAlertActivity : Activity() {

    private var mediaPlayer: MediaPlayer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ── 1. Force Screen Wake & Lockscreen Bypass ───────────────────────
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        }

        // ── 2. UI Construction (Big Stop Button) ───────────────────────────
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = android.view.Gravity.CENTER
            setBackgroundColor(0xFF0A0A0A.toInt()) // Deep Dark background
            setPadding(32, 32, 32, 32)
        }

        val titleText = TextView(this).apply {
            text = "ALARM TUGASAN"
            textSize = 24f
            setTextColor(0xFF00E5FF.toInt()) // Electric Blue
            gravity = android.view.Gravity.CENTER
        }

        val msgText = TextView(this).apply {
            text = "Bateri Mencapai Sasaran!"
            textSize = 18f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 24, 0, 64)
        }

        val stopButton = Button(this).apply {
            text = "STOP ALARM"
            textSize = 28f
            setTextColor(0xFFFFFFFF.toInt())
            setBackgroundColor(0xFFFF5252.toInt()) // Red accent
            setPadding(64, 48, 64, 48)
            setOnClickListener {
                stopAlarmAndFinish()
            }
        }

        layout.addView(titleText)
        layout.addView(msgText)
        layout.addView(stopButton)

        setContentView(layout)

        // ── 3. Start Ringing ───────────────────────────────────────────────
        playAlarm()
    }

    private fun playAlarm() {
        try {
            val alertUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

            mediaPlayer = MediaPlayer().apply {
                setDataSource(this@TimerAlertActivity, alertUri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                prepare()
                start()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopAlarmAndFinish() {
        mediaPlayer?.apply {
            if (isPlaying) stop()
            release()
        }
        mediaPlayer = null
        finish()
    }

    override fun onDestroy() {
        mediaPlayer?.release()
        super.onDestroy()
    }

    override fun onBackPressed() {
        // Prevent accidental dismissal via back button
    }
}
