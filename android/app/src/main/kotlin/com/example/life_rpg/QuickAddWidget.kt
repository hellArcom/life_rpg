package com.example.life_rpg

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class QuickAddWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.widget_quick_add)

            val easyIntent = Intent(context, MainActivity::class.java).apply {
                action = "com.example.life_rpg.QUICK_ADD_EASY"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            views.setOnClickPendingIntent(R.id.widget_btn_easy, PendingIntent.getActivity(
                context, 0, easyIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            ))

            val mediumIntent = Intent(context, MainActivity::class.java).apply {
                action = "com.example.life_rpg.QUICK_ADD_MEDIUM"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            views.setOnClickPendingIntent(R.id.widget_btn_medium, PendingIntent.getActivity(
                context, 1, mediumIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            ))

            val hardIntent = Intent(context, MainActivity::class.java).apply {
                action = "com.example.life_rpg.QUICK_ADD_HARD"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            views.setOnClickPendingIntent(R.id.widget_btn_hard, PendingIntent.getActivity(
                context, 2, hardIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            ))

            val legendaryIntent = Intent(context, MainActivity::class.java).apply {
                action = "com.example.life_rpg.QUICK_ADD_LEGENDARY"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            views.setOnClickPendingIntent(R.id.widget_btn_legendary, PendingIntent.getActivity(
                context, 3, legendaryIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            ))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
