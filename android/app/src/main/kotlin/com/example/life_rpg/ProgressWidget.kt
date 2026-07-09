package com.example.life_rpg

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class ProgressWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, null, null, null, null, null, null, null)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            level: String?,
            xp: String?,
            xpForCurrent: String?,
            xpForNext: String?,
            streak: String?,
            coins: String?,
            title: String?
        ) {
            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openPendingIntent = PendingIntent.getActivity(
                context, 1, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val views = RemoteViews(context.packageName, R.layout.widget_progress)

            val currentXp = (xp ?: "0").toIntOrNull() ?: 0
            val currentXpForCurrent = (xpForCurrent ?: "0").toIntOrNull() ?: 0
            val currentXpForNext = (xpForNext ?: "100").toIntOrNull() ?: 100
            val xpRange = currentXpForNext - currentXpForCurrent
            val xpProgress = if (xpRange > 0) ((currentXp - currentXpForCurrent) * 100 / xpRange).coerceIn(0, 100) else 0

            views.setTextViewText(R.id.widget_level, level ?: "1")
            views.setTextViewText(R.id.widget_streak, "${streak ?: "0"}j")
            views.setTextViewText(R.id.widget_coins, coins ?: "0")
            views.setTextViewText(R.id.widget_rank, title ?: "Novice")
            views.setProgressBar(R.id.widget_xp_bar, 100, xpProgress, false)
            views.setTextViewText(R.id.widget_xp_text, "$currentXp / $currentXpForNext XP")
            views.setOnClickPendingIntent(R.id.widget_container, openPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
