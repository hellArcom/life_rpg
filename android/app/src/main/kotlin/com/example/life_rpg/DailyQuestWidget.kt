package com.example.life_rpg

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray

class DailyQuestWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, null)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            questsJson: String?
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_daily_quests)

            if (questsJson.isNullOrEmpty() || questsJson == "[]") {
                views.setViewVisibility(R.id.widget_quests_container, View.GONE)
                views.setViewVisibility(R.id.widget_empty_text, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_quests_container, View.VISIBLE)
                views.setViewVisibility(R.id.widget_empty_text, View.GONE)

                try {
                    val questsArray = JSONArray(questsJson)
                    for (i in 0 until questsArray.length()) {
                        val quest = questsArray.getJSONObject(i)
                        val questId = quest.getString("id")
                        val title = quest.getString("title")
                        val status = quest.getString("status")
                        val difficulty = quest.getString("difficulty")

                        val isCompleted = status == "completed"
                        val checkText = if (isCompleted) "\u2705" else "\u26AA"

                        val questRow = RemoteViews(context.packageName, R.layout.widget_quest_row)
                        questRow.setTextViewText(R.id.quest_check, checkText)
                        questRow.setTextViewText(R.id.quest_title, title)
                        questRow.setTextViewText(R.id.quest_difficulty, difficulty.uppercase())

                        val toggleIntent = Intent(context, MainActivity::class.java).apply {
                            action = "com.example.life_rpg.TOGGLE_QUEST"
                            putExtra("quest_id", questId)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        }
                        val togglePendingIntent = PendingIntent.getActivity(
                            context, i, toggleIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        questRow.setOnClickPendingIntent(R.id.quest_row_container, togglePendingIntent)

                        views.addView(R.id.widget_quests_container, questRow)
                    }
                } catch (e: Exception) {
                    views.setViewVisibility(R.id.widget_quests_container, View.GONE)
                    views.setViewVisibility(R.id.widget_empty_text, View.VISIBLE)
                }
            }

            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openPendingIntent = PendingIntent.getActivity(
                context, 100, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, openPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
