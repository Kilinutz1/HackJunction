import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'streak.dart';

/// Only the next endangered day is scheduled. A repeating daily notification
/// would incorrectly remind users after their streak has already expired.
DateTime? nextStreakReminder(Iterable<String> days, DateTime now) {
  final stats = StreakStats.fromDays(days, now);
  if (stats.current == 0) return null;
  final next = DateTime(
    now.year,
    now.month,
    now.day + (stats.activeToday ? 1 : 0),
    22,
  );
  return next.isAfter(now) ? next : null;
}

class StreakReminder with WidgetsBindingObserver {
  final _notifications = FlutterLocalNotificationsPlugin();
  Future<void> _queue = Future.value();
  bool _disposed = false;
  bool _ready = false;
  static const _id = 22001;
  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  void start() {
    if (!_supported) return;
    WidgetsBinding.instance.addObserver(this);
    StreakService.changes.addListener(refresh);
    refresh();
  }

  void refresh() {
    _queue = _queue
        .then((_) async {
          if (_disposed) return;
          if (!_ready) {
            tzdata.initializeTimeZones();
            await _notifications.initialize(
              const InitializationSettings(
                android: AndroidInitializationSettings(
                  'ic_streak_notification',
                ),
                iOS: DarwinInitializationSettings(),
              ),
            );
            await _notifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission();
            await _notifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestExactAlarmsPermission();
            _ready = true;
          }
          final zone = await FlutterTimezone.getLocalTimezone();
          tz.setLocalLocation(tz.getLocation(zone.identifier));
          final days = await StreakService().getActiveDays();
          if (_disposed) return;
          final date = nextStreakReminder(days, DateTime.now());
          await _notifications.cancel(_id);
          if (date == null) return;
          final android = _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
          final exact = await android?.canScheduleExactNotifications() ?? false;
          await _notifications.zonedSchedule(
            _id,
            'Keep your streak going',
            'There is still time to save a moment or add a project update today.',
            tz.TZDateTime(tz.local, date.year, date.month, date.day, 22),
            const NotificationDetails(
              iOS: DarwinNotificationDetails(),
              android: AndroidNotificationDetails(
                'streak_reminders',
                'Streak reminders',
                channelDescription:
                    'A reminder at 22:00 when your streak is at risk',
              ),
            ),
            androidScheduleMode: exact
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
          );
        })
        .catchError((Object error, StackTrace stack) {
          // Notification failures must never interrupt recording an activity.
          debugPrint('Could not schedule streak reminder: $error');
        });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    StreakService.changes.removeListener(refresh);
  }
}
