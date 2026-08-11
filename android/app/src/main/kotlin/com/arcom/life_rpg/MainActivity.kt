package com.arcom.life_rpg

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.arcom.life_rpg/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialAction" -> {
                    val action = intent?.action
                    val questId = intent?.getStringExtra("quest_id")
                    if (action == "com.arcom.life_rpg.TOGGLE_QUEST" && questId != null) {
                        result.success("TOGGLE_QUEST:$questId")
                    } else {
                        result.success(action)
                    }
                }
                "updateWidget" -> {
                    val level = call.argument<String>("level")
                    val streak = call.argument<String>("streak")
                    val coins = call.argument<String>("coins")
                    updateWidget(QuestWidget::class.java) { context, manager, id ->
                        QuestWidget.updateAppWidget(context, manager, id, level, streak, coins)
                    }
                    result.success(true)
                }
                "updateProgressWidget" -> {
                    val level = call.argument<String>("level")
                    val xp = call.argument<String>("xp")
                    val xpForCurrent = call.argument<String>("xpForCurrent")
                    val xpForNext = call.argument<String>("xpForNext")
                    val streak = call.argument<String>("streak")
                    val coins = call.argument<String>("coins")
                    val title = call.argument<String>("title")
                    updateWidget(ProgressWidget::class.java) { context, manager, id ->
                        ProgressWidget.updateAppWidget(context, manager, id, level, xp, xpForCurrent, xpForNext, streak, coins, title)
                    }
                    result.success(true)
                }
                "updateDailyQuestsWidget" -> {
                    val quests = call.argument<String>("quests")
                    updateWidget(DailyQuestWidget::class.java) { context, manager, id ->
                        DailyQuestWidget.updateAppWidget(context, manager, id, quests)
                    }
                    result.success(true)
                }
                "updateCalendarWidget" -> {
                    val year = call.argument<String>("year")
                    val month = call.argument<String>("month")
                    val todayDay = call.argument<String>("todayDay")
                    val quests = call.argument<String>("quests")
                    updateWidget(CalendarWidget::class.java) { context, manager, id ->
                        CalendarWidget.updateAppWidget(context, manager, id, year, month, todayDay, quests)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun <T> updateWidget(widgetClass: Class<T>, updater: (android.content.Context, AppWidgetManager, Int) -> Unit) {
        val appWidgetManager = AppWidgetManager.getInstance(this)
        val componentName = ComponentName(this, widgetClass)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
        for (appWidgetId in appWidgetIds) {
            updater(this, appWidgetManager, appWidgetId)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = intent.action
        val questId = intent.getStringExtra("quest_id")

        when {
            action == "com.arcom.life_rpg.ADD_QUEST" -> {
                flutterEngine?.dartExecutor?.binaryMessenger?.let {
                    MethodChannel(it, CHANNEL).invokeMethod("triggerAction", "com.arcom.life_rpg.ADD_QUEST")
                }
            }
            action == "com.arcom.life_rpg.TOGGLE_QUEST" && questId != null -> {
                flutterEngine?.dartExecutor?.binaryMessenger?.let {
                    MethodChannel(it, CHANNEL).invokeMethod("triggerAction", "TOGGLE_QUEST:$questId")
                }
            }
            action == "com.arcom.life_rpg.QUICK_ADD_EASY" -> {
                flutterEngine?.dartExecutor?.binaryMessenger?.let {
                    MethodChannel(it, CHANNEL).invokeMethod("triggerAction", "com.arcom.life_rpg.QUICK_ADD_EASY")
                }
            }
            action == "com.arcom.life_rpg.QUICK_ADD_MEDIUM" -> {
                flutterEngine?.dartExecutor?.binaryMessenger?.let {
                    MethodChannel(it, CHANNEL).invokeMethod("triggerAction", "com.arcom.life_rpg.QUICK_ADD_MEDIUM")
                }
            }
            action == "com.arcom.life_rpg.QUICK_ADD_HARD" -> {
                flutterEngine?.dartExecutor?.binaryMessenger?.let {
                    MethodChannel(it, CHANNEL).invokeMethod("triggerAction", "com.arcom.life_rpg.QUICK_ADD_HARD")
                }
            }
            action == "com.arcom.life_rpg.QUICK_ADD_LEGENDARY" -> {
                flutterEngine?.dartExecutor?.binaryMessenger?.let {
                    MethodChannel(it, CHANNEL).invokeMethod("triggerAction", "com.arcom.life_rpg.QUICK_ADD_LEGENDARY")
                }
            }
        }
    }
}
