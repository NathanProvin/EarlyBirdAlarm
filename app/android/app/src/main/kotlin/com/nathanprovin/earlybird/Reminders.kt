package com.nathanprovin.earlybird

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

/// Reminders to come back (reminders.dart): Dart sends [{at, title, body, channel}] each
/// time the app goes to the background; each is an inexact alarm (no exact-alarm
/// permission; Doze may delay it a little) that posts a notification. Kept in prefs so a
/// reboot can set them again.
object Reminders {
    private const val PREFS = "reminders"
    private const val MAX = 4

    fun schedule(context: Context, json: String) {
        cancel(context)
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString("list", json).apply()
        arm(context, json)
    }

    fun cancel(context: Context) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        for (i in 0 until MAX) alarms.cancel(pending(context, i, null))
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().remove("list").apply()
    }

    /// After a reboot: the reminders still ahead (alarms don't survive one).
    fun rearm(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString("list", null)
            ?.let { arm(context, it) }
    }

    private fun arm(context: Context, json: String) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        val list = JSONArray(json)
        for (i in 0 until minOf(list.length(), MAX)) {
            val r = list.getJSONObject(i)
            val at = r.getLong("at")
            if (at > System.currentTimeMillis()) {
                alarms.set(AlarmManager.RTC_WAKEUP, at, pending(context, i, r))
            }
        }
    }

    // Same request code and component: cancel() finds the alarm whatever the extras.
    private fun pending(context: Context, i: Int, r: JSONObject?): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java)
        for (k in listOf("title", "body", "channel")) intent.putExtra(k, r?.optString(k))
        return PendingIntent.getBroadcast(
            context, 7100 + i, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) return Reminders.rearm(context)
        val manager = context.getSystemService(NotificationManager::class.java)
        val builder = if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(
                NotificationChannel(
                    "reminders", intent.getStringExtra("channel") ?: "Reminders",
                    NotificationManager.IMPORTANCE_DEFAULT,
                )
            )
            Notification.Builder(context, "reminders")
        } else {
            @Suppress("DEPRECATION") Notification.Builder(context)
        }
        val open = PendingIntent.getActivity(
            context, 0,
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val body = intent.getStringExtra("body")
        manager.notify(
            7100,
            builder
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle(intent.getStringExtra("title"))
                .setContentText(body)
                .setStyle(Notification.BigTextStyle().bigText(body))
                .setContentIntent(open)
                .setAutoCancel(true)
                .build(),
        )
    }
}
