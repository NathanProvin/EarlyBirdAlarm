package com.nathanprovin.earlybird

import android.app.NotificationManager
import android.content.Intent
import android.media.AudioAttributes
import android.net.ConnectivityManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
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
        // Alarm vibrations until stopped, with alarm usage so they buzz in silent mode too.
        // start(true): the backup's, full strength, long-short-long; start(false): after a
        // bird's fade-in, 500 ms on / 500 ms off like the alarm plugin's.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "early_bird/buzz")
            .setMethodCallHandler { call, result ->
                val vibrator = if (Build.VERSION.SDK_INT >= 31) {
                    getSystemService(VibratorManager::class.java).defaultVibrator
                } else {
                    @Suppress("DEPRECATION") getSystemService(Vibrator::class.java)
                }
                if (call.method == "start") {
                    val effect = if (call.arguments == false) {
                        VibrationEffect.createWaveform(longArrayOf(0, 500, 500), 0)
                    } else VibrationEffect.createWaveform(
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
        // Wake-up check: Android 14+ only shows the quiz over the lock screen with the
        // full-screen permission, which is off unless Play grants it or the user does.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "early_bird/wake")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "fullScreen" -> result.success(
                        Build.VERSION.SDK_INT < 34 ||
                            getSystemService(NotificationManager::class.java).canUseFullScreenIntent()
                    )
                    "fixFullScreen" -> {
                        val page = Uri.parse("package:$packageName")
                        try {
                            startActivity(Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, page))
                        } catch (e: Exception) {
                            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, page))
                        }
                        result.success(null)
                    }
                    // Alarm-clock alarms get through battery optimisation (the S22 passed 7
                    // nights optimised), except on brands that kill apps anyway: only there
                    // does "unrestricted" matter. Read directly: permission_handler would need
                    // the restricted REQUEST_IGNORE_BATTERY_OPTIMIZATIONS permission.
                    "battery" -> result.success(
                        Build.MANUFACTURER.lowercase() !in setOf(
                            "xiaomi", "huawei", "honor", "oppo", "vivo", "realme", "oneplus"
                        ) || getSystemService(PowerManager::class.java)
                            .isIgnoringBatteryOptimizations(packageName)
                    )
                    "fixBattery" -> {
                        // App info: Battery → Unrestricted (the wording varies by brand).
                        startActivity(
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        // The app version for the Credits screen.
        // Mobile data (a metered connection): the region's photos then come as they're shown,
        // not ~70-90 MB at once.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "early_bird/network")
            .setMethodCallHandler { _, result ->
                result.success(
                    getSystemService(ConnectivityManager::class.java).isActiveNetworkMetered
                )
            }
        // The Play referrer of this install (an invite link's `inviter=`), null if none.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "early_bird/referrer")
            .setMethodCallHandler { _, result ->
                val client = InstallReferrerClient.newBuilder(this).build()
                client.startConnection(object : InstallReferrerStateListener {
                    override fun onInstallReferrerSetupFinished(code: Int) {
                        val referrer = try {
                            if (code == InstallReferrerClient.InstallReferrerResponse.OK) {
                                client.installReferrer.installReferrer
                            } else null
                        } catch (e: Exception) {
                            null
                        }
                        client.endConnection()
                        result.success(referrer)
                    }

                    // Dart gives up after 10 s.
                    override fun onInstallReferrerServiceDisconnected() {}
                })
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "early_bird/version")
            .setMethodCallHandler { _, result ->
                result.success(packageManager.getPackageInfo(packageName, 0).versionName)
            }
    }
}
