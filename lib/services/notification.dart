import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'medication.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Cancels all existing medication notifications and reschedules one
  /// notification per (medication × weekday) pair that has a time set.
  Future<void> scheduleDailyMedicationReminder() async {
    await _plugin.cancelAll();

    final medications = await MedicationService.instance.getAllMedications();

    for (final medication in medications) {
      final id = medication.id;
      final timeStr = medication.notificationTime;
      if (id == null || timeStr == null || timeStr.isEmpty) continue;

      final parts = timeStr.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final details = _buildDetails(medication.name);

      for (final weekday in medication.daysOfWeek) {
        final notifId = id * 7 + (weekday - 1);
        try {
          await _plugin.zonedSchedule(
            notifId,
            'Med Control',
            'Hora de tomar: ${medication.name}.',
            _nextInstanceOfWeekdayTime(weekday, hour, minute),
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        } catch (_) {
          // Exact alarm permission may not be granted on Android 12+; skip.
        }
      }
    }
  }

  NotificationDetails _buildDetails(String medicationName) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_reminder',
        'Lembretes de medicamentos',
        channelDescription: 'Notificações no horário de tomar cada medicamento',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (candidate.weekday != weekday || !candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
