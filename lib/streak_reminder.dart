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

DateTime nextWeeklyReportTime(DateTime now) {
  final days = (DateTime.monday - now.weekday + 7) % 7;
  final candidate = DateTime(now.year, now.month, now.day + days, 8);
  return candidate.isAfter(now)
      ? candidate
      : DateTime(candidate.year, candidate.month, candidate.day + 7, 8);
}

class StreakReminder with WidgetsBindingObserver {
  StreakReminder({this.onWeeklyReport});
  final VoidCallback? onWeeklyReport;
  static const weeklyPayload = 'weekly_report';
  void _onResponse(NotificationResponse response) {
    if (!_disposed && response.payload == weeklyPayload) onWeeklyReport?.call();
  }

  final _notifications = FlutterLocalNotificationsPlugin();
  Future<void> _queue = Future.value();
  bool _disposed = false;
  bool _ready = false;
  static const _id = 22001;
  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  Future<void> start() {
    if (!_supported) return Future.value();
    WidgetsBinding.instance.addObserver(this);
    StreakService.changes.addListener(refresh);
    refresh();
    return _queue;
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
              onDidReceiveNotificationResponse: _onResponse,
            );
            final launch = await _notifications
                .getNotificationAppLaunchDetails();
            if (launch?.didNotificationLaunchApp == true &&
                launch?.notificationResponse != null) {
              _onResponse(launch!.notificationResponse!);
            }
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

          final android = _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
          final exact = await android?.canScheduleExactNotifications() ?? false;
          final weekly = nextWeeklyReportTime(DateTime.now());
          await _notifications.zonedSchedule(
            22002,
            "Here’s last week’s report",
            'Take a moment to remember the good things from your week.',
            tz.TZDateTime(tz.local, weekly.year, weekly.month, weekly.day, 8),
            const NotificationDetails(
              iOS: DarwinNotificationDetails(),
              android: AndroidNotificationDetails(
                'weekly_reports',
                'Weekly reports',
                channelDescription: 'Your weekly report on Monday at 08:00',
              ),
            ),
            payload: weeklyPayload,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            androidScheduleMode: exact
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
          );
          if (date == null) return;
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
