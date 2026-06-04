package com.solehin.android_shortcuts

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.CountDownTimer
import android.os.PowerManager
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import java.util.Locale

class TimerAlertActivity : Activity() {

    private var countDownTimer: CountDownTimer? = null
    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private lateinit var timerText: TextView
    private var timerSeconds: Int = 5

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ── 1. Force Screen & Lockscreen Bypass ───────────────────────
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

        // ── 2. Acquire CPU WakeLock (Prevent Doze Sleep) ──────────────
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "TaskFlow::TimerTickLock")
        wakeLock?.acquire(10 * 60 * 1000L) // Max 10 mins protection

        // ── 3. UI Construction ────────────────────────────────────────
        timerSeconds = intent.getIntExtra("timerSeconds", 5)
        
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = android.view.Gravity.CENTER
            setBackgroundColor(0xFF0A0A0A.toInt()) 
            setPadding(32, 32, 32, 32)
        }

        val titleText = TextView(this).apply {
            text = "TASKFLOW TIMER"
            textSize = 18f
            setTextColor(0xFF00E5FF.toInt()) 
            gravity = android.view.Gravity.CENTER
        }

        timerText = TextView(this).apply {
            text = formatTime(timerSeconds)
            textSize = 80f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 48, 0, 48)
        }

        val stopButton = Button(this).apply {
            text = "STOP ALARM"
            textSize = 24f
            setTextColor(0xFFFFFFFF.toInt())
            setBackgroundColor(0xFFFF5252.toInt()) 
            setPadding(64, 32, 64, 32)
            setOnClickListener {
                stopAlarmAndFinish()
            }
        }

        layout.addView(titleText)
        layout.addView(timerText)
        layout.addView(stopButton)

        setContentView(layout)

        startTimer()
    }

    private fun startTimer() {
        countDownTimer = object : CountDownTimer(timerSeconds * 1000L, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val secondsRemaining = (millisUntilFinished / 1000).toInt()
                timerText.text = formatTime(secondsRemaining)
            }

            override fun onFinish() {
                timerText.text = "00:00"
                
                // ── 4. Wake Screen AGAIN for Ringing ───────────────────
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                val ringLock = powerManager.newWakeLock(
                    PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                    "TaskFlow::RingLock"
                )
                ringLock.acquire(3 * 60 * 1000L) 

                playAlarmSound()
            }
        }.start()
    }

    private fun playAlarmSound() {
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
        cleanup()
        finish()
    }

    private fun cleanup() {
        countDownTimer?.cancel()
        countDownTimer = null
        
        mediaPlayer?.apply {
            if (isPlaying) stop()
            release()
        }
        mediaPlayer = null

        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
        wakeLock = null
    }

    private fun formatTime(seconds: Int): String {
        val minutes = seconds / 60
        val remainingSeconds = seconds % 60
        return String.format(Locale.getDefault(), "%02d:%02d", minutes, remainingSeconds)
    }

    override fun onDestroy() {
        cleanup()
        super.onDestroy()
    }

    override fun onBackPressed() {
        stopAlarmAndFinish()
    }
}
