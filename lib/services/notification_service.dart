import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb) return;

    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );

    final DarwinInitializationSettings darwinInitializationSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onNotificationResponse,
    );

    await _createChannels();

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    final bool? granted = await androidImplementation?.areNotificationsEnabled();

    if (granted == false) {
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  @pragma('vm:entry-point')
  static void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap if needed
  }

  static Future<void> _createChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation == null) return;

    await androidImplementation.createNotificationChannel(const AndroidNotificationChannel(
      'quests',
      'Quêtes',
      description: 'Notifications pour les quêtes',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    ));

    await androidImplementation.createNotificationChannel(const AndroidNotificationChannel(
      'bets',
      'Paris',
      description: 'Notifications pour les paris',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));

    await androidImplementation.createNotificationChannel(const AndroidNotificationChannel(
      'feedback',
      'Feedback',
      description: 'Notifications d\'encouragement',
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
    ));

    await androidImplementation.createNotificationChannel(const AndroidNotificationChannel(
      'guild_chat',
      'Chat Guilde',
      description: 'Notifications pour les messages de guilde',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));
  }

  static NotificationDetails _getNotificationDetails(String channelKey) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelKey,
        channelKey,
        channelDescription: _getChannelDescription(channelKey),
        importance: _getImportance(channelKey),
        priority: _getPriority(channelKey),
        playSound: _shouldPlaySound(channelKey),
        enableVibration: _shouldVibrate(channelKey),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: _shouldPlaySound(channelKey),
      ),
    );
  }

  static String _getChannelDescription(String channelKey) {
    switch (channelKey) {
      case 'quests':
        return 'Notifications pour les quêtes';
      case 'bets':
        return 'Notifications pour les paris';
      case 'feedback':
        return 'Notifications d\'encouragement';
      case 'guild_chat':
        return 'Notifications pour les messages de guilde';
      default:
        return '';
    }
  }

  static Importance _getImportance(String channelKey) {
    switch (channelKey) {
      case 'quests':
        return Importance.max;
      case 'bets':
        return Importance.high;
      case 'feedback':
        return Importance.defaultImportance;
      case 'guild_chat':
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }

  static Priority _getPriority(String channelKey) {
    switch (channelKey) {
      case 'quests':
        return Priority.max;
      case 'bets':
        return Priority.high;
      case 'feedback':
        return Priority.defaultPriority;
      case 'guild_chat':
        return Priority.high;
      default:
        return Priority.defaultPriority;
    }
  }

  static bool _shouldPlaySound(String channelKey) {
    return channelKey != 'feedback';
  }

  static bool _shouldVibrate(String channelKey) {
    return channelKey != 'feedback';
  }

  static Future<void> scheduleQuestReminder(String id, String title, DateTime scheduledDate) async {
    if (kIsWeb) return;
    if (scheduledDate.isBefore(DateTime.now())) return;

    final int notificationId = id.hashCode & 0x7FFFFFFF;
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      id: notificationId,
      title: 'Rappel de quête',
      body: title,
      scheduledDate: tzScheduledDate,
      notificationDetails: _getNotificationDetails('quests'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'type=quest_reminder',
    );
  }

  static Future<void> showFeedback(String title, String body) async {
    if (kIsWeb) return;
    final int notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;

    await _plugin.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: _getNotificationDetails('feedback'),
    );
  }

  static Future<void> showGuildMessageNotification({
    required String guildName,
    required String senderName,
    required String message,
    required String guildId,
  }) async {
    if (kIsWeb) return;
    final int notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;

    await _plugin.show(
      id: notificationId,
      title: '$guildName • $senderName',
      body: message,
      notificationDetails: _getNotificationDetails('guild_chat'),
      payload: 'guild_id=$guildId&type=guild_message',
    );
  }

  static Future<void> cancelReminder(String id) async {
    if (kIsWeb) return;
    final int notificationId = id.hashCode & 0x7FFFFFFF;
    await _plugin.cancel(id: notificationId);
  }

  static Future<void> scheduleDailyProactiveReminder() async {
    if (kIsWeb) return;
    final now = DateTime.now();
    final scheduledDate = DateTime(now.year, now.month, now.day, 19, 0);
    if (scheduledDate.isBefore(now)) return;

    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      id: 9999,
      title: 'Rappel du soir',
      body: 'Tu n\'as pas fini toutes tes quêtes aujourd\'hui ? Il est encore temps !',
      scheduledDate: tzScheduledDate,
      notificationDetails: _getNotificationDetails('quests'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'type=daily_proactive',
    );
  }

  static Future<void> scheduleEveningEntryReminder() async {
    if (kIsWeb) return;
    final now = DateTime.now();
    final scheduledDate = DateTime(now.year, now.month, now.day, 21, 0);
    if (scheduledDate.isBefore(now)) return;

    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      id: 8888,
      title: 'Bilan du soir 📝',
      body: 'Ta journée s\'est bien passée ? Note-la et gagne 10 pièces !',
      scheduledDate: tzScheduledDate,
      notificationDetails: _getNotificationDetails('feedback'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'type=evening_entry',
    );
  }
}