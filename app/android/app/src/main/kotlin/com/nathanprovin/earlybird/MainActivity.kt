package com.nathanprovin.earlybird

import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var holdLockScreen = false

    // The alarm plugin hides the app from the lock screen as soon as the alarm stops;
    // keep it visible until the user has seen the pop-up and the reveal.
    override fun setShowWhenLocked(showWhenLocked: Boolean) {
        super.setShowWhenLocked(showWhenLocked || holdLockScreen)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "early_bird/lock_screen")
            .setMethodCallHandler { call, result ->
                holdLockScreen = call.arguments as Boolean
                setShowWhenLocked(holdLockScreen)
                result.success(null)
            }
        // The backup alarm's vibration: full strength, long-short-long, until stopped. Alarm
        // usage, so it buzzes in silent mode too (the alarm plugin's is weaker, fixed).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "early_bird/buzz")
            .setMethodCallHandler { call, result ->
                val vibrator = if (Build.VERSION.SDK_INT >= 31) {
                    getSystemService(VibratorManager::class.java).defaultVibrator
                } else {
                    @Suppress("DEPRECATION") getSystemService(Vibrator::class.java)
                }
                if (call.method == "start") {
                    val effect = VibrationEffect.createWaveform(
                        longArrayOf(0, 900, 200, 400, 200, 900, 500),
                        intArrayOf(0, 255, 0, 255, 0, 255, 0),
                        0, // repeat from the start
                    )
                    if (Build.VERSION.SDK_INT >= 33) {
                        vibrator.vibrate(
                            effect,
                            VibrationAttributes.createForUsage(VibrationAttributes.USAGE_ALARM),
                        )
                    } else {
                        @Suppress("DEPRECATION")
                        vibrator.vibrate(
                            effect,
                            AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build(),
                        )
                    }
                } else {
                    vibrator.cancel()
                }
                result.success(null)
            }
        // The app version for the Credits screen.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "early_bird/version")
            .setMethodCallHandler { _, result ->
                result.success(packageManager.getPackageInfo(packageName, 0).versionName)
            }
    }
}
