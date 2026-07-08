package com.example.life_rpg

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.life_rpg/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialAction" -> {
                    result.success(intent?.action)
                }
                "updateWidget" -> {
                    val level = call.argument<String>("level")
                    val streak = call.argument<String>("streak")
                    val coins = call.argument<String>("coins")
                    
                    val appWidgetManager = AppWidgetManager.getInstance(this)
                    val componentName = ComponentName(this, QuestWidget::class.java)
                    val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
                    
                    for (appWidgetId in appWidgetIds) {
                        QuestWidget.updateAppWidget(this, appWidgetManager, appWidgetId, level, streak, coins)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == "com.example.life_rpg.ADD_QUEST") {
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                MethodChannel(it, CHANNEL).invokeMethod("triggerAction", intent.action)
            }
        }
    }
}
