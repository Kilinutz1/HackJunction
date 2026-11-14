import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_proud_space/event.dart';
import 'package:my_proud_space/project.dart';
import 'package:my_proud_space/localdb.dart';
import 'package:my_proud_space/app_theme.dart';
import 'package:my_proud_space/weekly_report.dart';
import 'package:my_proud_space/weekly_report_data.dart';

void main() {
  final now = DateTime(2026, 11, 15, 23);
  Event event(
    String id, {
    bool favorite = false,
    String type = 'Memory',
    DateTime? date,
  }) => Event(
    id: id,
    type: type,
    description: 'Moment $id',
    date: date ?? DateTime(2026, 11, 10),
    isFavorite: favorite,
  );
  WeeklyReport report(
    List<Event> events, [
    List<Project> projects = const [],
  ]) => WeeklyReport(events: events, projects: projects, week: now, now: now);

  test('Weekly bounds exclude adjacent weeks and future entries', () {
    final result = report([
      event('before', date: DateTime(2026, 11, 8, 23, 59)),
      event('start', date: DateTime(2026, 11, 9)),
      event('end', date: DateTime(2026, 11, 15, 22)),
      event('future', date: DateTime(2026, 11, 15, 23, 59)),
      event('next', date: DateTime(2026, 11, 16)),
    ]);
    expect(result.all.map((h) => h.event!.id), ['end', 'start']);
    expect(reportWeekStart(DateTime(2027, 1, 1)), DateTime(2026, 12, 28));
  });

  test(
    'Selection is capped, stable, varied and prefers favorites and priority',
    () {
      final projects = [
        for (var i = 1; i <= 5; i++)
          Project(
            id: 'p$i',
            name: 'Project $i',
            importance: i,
            createdAt: DateTime(2020),
            logbook: ProjectLogbook([
              for (var j = 0; j < 10; j++)
                ProjectLogEntry(
                  id: '$j',
                  date: DateTime(2026, 11, 11),
                  text: 'Step $j',
                ),
            ]),
          ),
      ];
      final events = [
        for (var i = 0; i < 30; i++) event('$i'),
        event('favorite', favorite: true),
        event('proud', type: 'Proud Moment', favorite: true),
      ];
      final result = report(events, projects);
      expect(result.highlights, hasLength(5));
      expect(result.highlights.map((h) => h.kind).toSet(), {
        'Memory',
        'Proud Moment',
        'Project',
      });
      expect(result.highlights.any((h) => h.event?.id == 'favorite'), isTrue);
      expect(result.highlights.any((h) => h.project?.id == 'p5'), isTrue);
      expect(
        result.highlights.any((h) => h.event != null && !h.event!.isFavorite),
        isTrue,
      );
      expect(
        result.highlights.map((h) => h.id),
        report(
          events.reversed.toList(),
          projects.reversed.toList(),
        ).highlights.map((h) => h.id),
      );
      expect(result.activeProjects, 5);
      expect(
        result.highlights.firstWhere((h) => h.project != null).entries,
        hasLength(10),
      );
    },
  );

  test('Repeated notes do not fill the highlights', () {
    final events = [
      for (var i = 0; i < 20; i++)
        Event(id: '$i', type: 'Memory', description: 'Same note', date: now),
    ];
    expect(report(events).highlights, hasLength(1));
    expect(report(events).all, hasLength(20));
  });

  test('Empty weeks and expired projects do not invent achievements', () {
    expect(report([]).highlights, isEmpty);
    final expired = Project(
      name: 'Old',
      createdAt: DateTime(2020),
      completed: true,
      period: DateTimeRange(
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 10),
      ),
    );
    expect(report([], [expired]).highlights, isEmpty);
    expect(report([event('only')]).highlights, hasLength(1));
  });

  testWidgets(
    'Small mobile report opens details, full week and previous week',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await LocalDatabase().addEvent(event('today', date: DateTime.now()));
      await tester.pumpWidget(
        MaterialApp(theme: buildAppTheme(), home: const WeeklyReportPage()),
      );
      await tester.pumpAndSettle();
      expect(find.text('One moment worth keeping.'), findsOneWidget);
      await tester.ensureVisible(find.text('Read more'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Read more'));
      await tester.pumpAndSettle();
      expect(find.text('Moment today'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('View the full week'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View the full week'));
      await tester.pumpAndSettle();
      expect(find.text('The full week'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byTooltip('Previous week'), -500);
      await tester.tap(find.byTooltip('Previous week'));
      await tester.pumpAndSettle();
      expect(find.text('Room for good things.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
