package com.example.life_rpg

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.util.Calendar

class CalendarWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, null, null, null, null)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            yearStr: String?,
            monthStr: String?,
            todayDayStr: String?,
            questsJson: String?
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_calendar)

            val cal = Calendar.getInstance()
            val year = yearStr?.toIntOrNull() ?: cal.get(Calendar.YEAR)
            val month = monthStr?.toIntOrNull() ?: (cal.get(Calendar.MONTH) + 1)
            val todayDay = todayDayStr?.toIntOrNull() ?: cal.get(Calendar.DAY_OF_MONTH)

            val monthNames = arrayOf(
                "JANVIER", "F\u00C9VRIER", "MARS", "AVRIL", "MAI", "JUIN",
                "JUILLET", "AO\u00DBT", "SEPTEMBRE", "OCTOBRE", "NOVEMBRE", "D\u00C9CEMBRE"
            )
            val monthName = if (month in 1..12) monthNames[month - 1] else "MOIS"
            views.setTextViewText(R.id.widget_month_year, "$monthName $year")

            val dayHeaders = arrayOf("L", "M", "M", "J", "V", "S", "D")
            val headerContainer = RemoteViews(context.packageName, R.layout.widget_calendar_row)
            for (day in dayHeaders) {
                val headerCell = RemoteViews(context.packageName, R.layout.widget_calendar_header_cell)
                headerCell.setTextViewText(R.id.header_cell_text, day)
                headerContainer.addView(R.id.row_container, headerCell)
            }
            views.addView(R.id.widget_day_headers, headerContainer)

            val tempCal = Calendar.getInstance()
            tempCal.set(year, month - 1, 1)
            val firstDayOfWeek = (tempCal.get(Calendar.DAY_OF_WEEK) + 5) % 7
            val daysInMonth = tempCal.getActualMaximum(Calendar.DAY_OF_MONTH)

            var dayCounter = 1
            val totalCells = firstDayOfWeek + daysInMonth
            val totalRows = (totalCells + 6) / 7

            for (row in 0 until totalRows) {
                val weekRow = RemoteViews(context.packageName, R.layout.widget_calendar_row)
                for (col in 0..6) {
                    val cellIndex = row * 7 + col
                    val cell = RemoteViews(context.packageName, R.layout.widget_calendar_cell)
                    if (cellIndex < firstDayOfWeek || dayCounter > daysInMonth) {
                        cell.setTextViewText(R.id.cell_text, "")
                    } else {
                        val dayNum = dayCounter
                        cell.setTextViewText(R.id.cell_text, dayNum.toString())
                        if (dayNum == todayDay) {
                            cell.setInt(R.id.cell_text, "setBackgroundColor", Color.parseColor("#FFC107"))
                            cell.setTextColor(R.id.cell_text, Color.parseColor("#000000"))
                        }
                        dayCounter++
                    }
                    weekRow.addView(R.id.row_container, cell)
                }
                views.addView(R.id.widget_calendar_grid, weekRow)
            }

            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openPendingIntent = PendingIntent.getActivity(
                context, 200, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, openPendingIntent)

            if (!questsJson.isNullOrEmpty() && questsJson != "[]") {
                views.setViewVisibility(R.id.widget_today_quests, View.VISIBLE)
                views.setViewVisibility(R.id.widget_no_quests, View.GONE)

                try {
                    val questsArray = JSONArray(questsJson)
                    for (i in 0 until questsArray.length().coerceAtMost(3)) {
                        val quest = questsArray.getJSONObject(i)
                        val title = quest.getString("title")
                        val status = quest.getString("status")
                        val difficulty = quest.getString("difficulty")

                        val isCompleted = status == "completed"
                        val checkText = if (isCompleted) "\u2705" else "\u26AA"
                        val diffStars = when (difficulty.lowercase()) {
                            "easy" -> "\u2605"
                            "medium" -> "\u2605\u2605"
                            "hard" -> "\u2605\u2605\u2605"
                            "legendary" -> "\u2605\u2605\u2605\u2605"
                            else -> ""
                        }

                        val questRow = RemoteViews(context.packageName, R.layout.widget_quest_row)
                        questRow.setTextViewText(R.id.quest_check, checkText)
                        questRow.setTextViewText(R.id.quest_title, title)
                        questRow.setTextViewText(R.id.quest_difficulty, diffStars)

                        val questId = quest.getString("id")
                        val toggleIntent = Intent(context, MainActivity::class.java).apply {
                            action = "com.example.life_rpg.TOGGLE_QUEST"
                            putExtra("quest_id", questId)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        }
                        val togglePendingIntent = PendingIntent.getActivity(
                            context, 300 + i, toggleIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        questRow.setOnClickPendingIntent(R.id.quest_row_container, togglePendingIntent)

                        views.addView(R.id.widget_today_quests, questRow)
                    }
                } catch (e: Exception) {
                    views.setViewVisibility(R.id.widget_today_quests, View.GONE)
                    views.setViewVisibility(R.id.widget_no_quests, View.VISIBLE)
                }
            } else {
                views.setViewVisibility(R.id.widget_today_quests, View.GONE)
                views.setViewVisibility(R.id.widget_no_quests, View.VISIBLE)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
