import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_proud_space/event.dart';
import 'package:my_proud_space/localdb.dart';
import 'package:my_proud_space/main.dart';
import 'package:my_proud_space/project.dart';
import 'package:my_proud_space/streak.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Streak handles duplicate days, gaps, and the chance to continue today',
    () {
      final days = ['2026-11-10', '2026-11-11', '2026-11-12', '2026-11-12'];
      final today = StreakStats.fromDays(days, DateTime(2026, 11, 12));
      expect(today.current, 3);
      expect(today.longest, 3);
      expect(today.totalActiveDays, 3);
      expect(today.currentStart, DateTime.utc(2026, 11, 10));
      expect(today.activeToday, isTrue);
      final tomorrow = StreakStats.fromDays(days, DateTime(2026, 11, 13));
      expect(tomorrow.current, 3);
      expect(tomorrow.activeToday, isFalse);
      final missed = StreakStats.fromDays(days, DateTime(2026, 11, 14));
      expect(missed.current, 0);
      expect(missed.currentStart, isNull);
      expect(missed.longest, 3);
      final restarted = StreakStats.fromDays([
        ...days,
        '2026-11-14',
      ], DateTime(2026, 11, 14));
      expect(restarted.current, 1);
      expect(restarted.longest, 3);
    },
  );

  test(
    'Calendar arithmetic works across year and daylight-saving boundaries',
    () {
      expect(
        StreakStats.fromDays([
          '2025-12-31',
          '2026-01-01',
        ], DateTime(2026, 1, 1)).current,
        2,
      );
      expect(
        StreakStats.fromDays([
          '2026-03-28',
          '2026-03-29',
          '2026-03-30',
        ], DateTime(2026, 3, 30)).current,
        3,
      );
      final empty = StreakStats.fromDays([
        'invalid',
        '2026-11-99',
        '2099-01-01',
      ], DateTime(2026, 11, 14));
      expect(empty.totalActiveDays, 0);
      expect(empty.current, 0);
      expect(empty.longest, 0);
    },
  );

  test(
    'Concurrent activities count once per local day and survive reloading',
    () async {
      final service = StreakService();
      await Future.wait([
        service.recordActivity(DateTime(2026, 11, 13, 23, 59)),
        service.recordActivity(DateTime(2026, 11, 14, 0, 1)),
        service.recordActivity(DateTime(2026, 11, 14, 12)),
      ]);
      expect(await StreakService().getActiveDays(), [
        '2026-11-13',
        '2026-11-14',
      ]);
    },
  );

  for (final type in ['Memory', 'Proud Moment', 'Other']) {
    test('$type records the action date only when newly created', () async {
      final db = LocalDatabase();
      final event = Event(
        id: 'test',
        type: type,
        description: 'Backdated entry',
        date: DateTime(2000, 1, 1),
      );
      await db.addEvent(event);
      expect(
        await StreakService().getActiveDays(),
        type == 'Other' ? isEmpty : [StreakService.dayKey(DateTime.now())],
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StreakService.storageKey);
      await db.updateEvent(event);
      await db.deleteEvent(event.id);
      expect(await StreakService().getActiveDays(), isEmpty);
    });
  }

  test(
    'LocalDatabase keeps the existing project format without counting old data',
    () async {
      final oldProject = Project(name: 'Existing', description: 'Keep this');
      SharedPreferences.setMockInitialValues({
        'hackathon_projects_v1': jsonEncode([oldProject.toJson()]),
      });
      final store = ProjectStore();
      await store.load();
      expect(store.value.single.description, 'Keep this');
      expect(await StreakService().getActiveDays(), isEmpty);
      store.update(store.value.single.withCompleted(true));
      await store.persist();
      expect(await StreakService().getActiveDays(), isEmpty);
      expect(
        (await LocalDatabase().getAllProjects()).single.isCompleted,
        isTrue,
      );
      store.dispose();
    },
  );

  test(
    'Projects and new logbook entries count, edits and deletion do not',
    () async {
      final db = LocalDatabase();
      final project = Project(name: 'New project');
      await db.saveProjects([project]);
      expect(await StreakService().getActiveDays(), [
        StreakService.dayKey(DateTime.now()),
      ]);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StreakService.storageKey);
      project.logbook.entries.add(
        ProjectLogEntry(date: DateTime(2000, 1, 1), text: 'Progress'),
      );
      await db.saveProjects([project]);
      expect(await StreakService().getActiveDays(), [
        StreakService.dayKey(DateTime.now()),
      ]);
      await prefs.remove(StreakService.storageKey);
      await db.saveProjects([project.withCompleted(true)]);
      await db.saveProjects([]);
      expect(await StreakService().getActiveDays(), isEmpty);
    },
  );

  testWidgets(
    'Dashboard badge refreshes after an activity and opens streak details',
    (tester) async {
      await tester.pumpWidget(const HackathonApp());
      await tester.pumpAndSettle();
      expect(find.text('0 day streak'), findsOneWidget);
      await LocalDatabase().addEvent(
        Event(
          id: 'today',
          type: 'Memory',
          description: 'Today',
          date: DateTime(2000, 1, 1),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 day streak'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('streak-badge')));
      await tester.pumpAndSettle();
      expect(find.text('Your streak'), findsOneWidget);
      expect(find.text('Longest streak:'), findsOneWidget);
      expect(find.text('Current streak started:'), findsOneWidget);
      expect(find.text('1 day'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
}
