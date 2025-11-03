import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationsService {
  final _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Thêm handler cho notification taps
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        print('Notification tapped: ${details.payload}');
      },
    );

    // Request permissions
    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  Future<void> showWeightReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = _nextInstanceOf8AM();
    
    // Kiểm tra nếu thời gian đã qua
    if (scheduledDate.isBefore(now)) {
      print('Scheduled time has passed');
      return;
    }

    try {
      await _notifications.zonedSchedule(
        1,
        'Nhắc nhở cân nặng',
        'Hãy cập nhật cân nặng hôm nay của bạn!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weight_channel',
            'Weight Reminders',
            channelDescription: 'Daily weight measurement reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print('Weight reminder scheduled for ${scheduledDate.toString()}');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> scheduleWaterReminders() async {
    // Nhắc nhở uống nước mỗi 2 tiếng từ 8h-20h
    const times = [8, 10, 12, 14, 16, 18, 20];
    
    for (var i = 0; i < times.length; i++) {
      const androidDetails = AndroidNotificationDetails(
        'water_channel',
        'Water Reminders',
        channelDescription: 'Water drinking reminders',
        importance: Importance.high,
        priority: Priority.high,
      );

      const details = NotificationDetails(android: androidDetails);

      await _notifications.zonedSchedule(
        10 + i, // Unique ID for each notification
        'Nhắc nhở uống nước',
        'Đã đến giờ uống nước rồi! 💧',
        _nextInstanceOfHour(times[i]),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> scheduleExerciseReminder() async {
    // Nhắc nhở tập thể dục lúc 17h
    const androidDetails = AndroidNotificationDetails(
      'exercise_channel',
      'Exercise Reminders',
      channelDescription: 'Daily exercise reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      20,
      'Đến giờ tập thể dục!',
      'Dành 30 phút để vận động nào 💪',
      _nextInstanceOfHour(17),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf8AM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      8,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfHour(int hour) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}