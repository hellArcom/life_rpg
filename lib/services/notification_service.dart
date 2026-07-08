import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> init() async {
    if (kIsWeb) return; // Les notifications ne sont pas encore configurées pour le web

    await AwesomeNotifications().initialize(
      'resource://mipmap/launcher_icon', // Utilise l'icône de l'application
      [
        NotificationChannel(
          channelKey: 'quests',
          channelName: 'Quêtes',
          channelDescription: 'Notifications pour les quêtes',
          defaultColor: Colors.purple,
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
        ),
        NotificationChannel(
          channelKey: 'bets',
          channelName: 'Paris',
          channelDescription: 'Notifications pour les paris',
          defaultColor: Colors.amber,
          ledColor: Colors.amber,
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelKey: 'feedback',
          channelName: 'Feedback',
          channelDescription: 'Notifications d\'encouragement',
          defaultColor: Colors.green,
          ledColor: Colors.green,
          importance: NotificationImportance.Default,
        )
      ],
      debug: true,
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  static Future<void> scheduleQuestReminder(String id, String title, DateTime scheduledDate) async {
    if (kIsWeb) return;
    if (scheduledDate.isBefore(DateTime.now())) return;
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id.hashCode,
        channelKey: 'quests',
        title: 'Rappel de quête',
        body: title,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledDate),
    );
  }

  static Future<void> showFeedback(String title, String body) async {
    if (kIsWeb) return;
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecond,
        channelKey: 'feedback',
        title: title,
        body: body,
      ),
    );
  }

  static Future<void> cancelReminder(String id) async {
    if (kIsWeb) return;
    await AwesomeNotifications().cancel(id.hashCode);
  }

  static Future<void> scheduleDailyProactiveReminder() async {
    if (kIsWeb) return;
    final now = DateTime.now();
    final scheduledDate = DateTime(now.year, now.month, now.day, 19, 0);
    if (scheduledDate.isBefore(now)) return;
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 9999,
        channelKey: 'quests',
        title: 'Rappel du soir',
        body: 'Tu n\'as pas fini toutes tes quêtes aujourd\'hui ? Il est encore temps !',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledDate),
    );
  }

  static Future<void> scheduleEveningEntryReminder() async {
    if (kIsWeb) return;
    final now = DateTime.now();
    final scheduledDate = DateTime(now.year, now.month, now.day, 21, 0);
    if (scheduledDate.isBefore(now)) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 8888,
        channelKey: 'feedback',
        title: 'Bilan du soir 📝',
        body: 'Ta journée s\'est bien passée ? Note-la et gagne 10 pièces !',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledDate),
    );
  }
}
