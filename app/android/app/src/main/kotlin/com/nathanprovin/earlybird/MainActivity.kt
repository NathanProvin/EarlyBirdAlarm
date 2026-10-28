package com.nathanprovin.earlybird

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
    }
}
