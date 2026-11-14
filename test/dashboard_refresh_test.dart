import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_proud_space/app_theme.dart';
import 'package:my_proud_space/main.dart';
import 'package:my_proud_space/event.dart';
import 'package:my_proud_space/localdb.dart';
import 'package:my_proud_space/project.dart';
import 'package:my_proud_space/remind.dart';
import 'package:my_proud_space/streak.dart';
import 'package:my_proud_space/breath.dart';

void main() {
  testWidgets(
    'Pull to refresh loads first entries without restarting dashboard',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'last_visit_date': StreakService.dayKey(DateTime.now()),
      });
      // The gesture must work even when the dashboard fits without scrolling.
      tester.view.physicalSize = const Size(390, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(theme: buildAppTheme(), home: const MainScreen()),
      );
      await tester.pumpAndSettle();
      final dashboardState = tester.state(find.byType(MainScreen));
      expect(find.byType(SingleRewindWidget), findsNothing);

      Future<void> pull() async {
        final dashboardList = find
            .descendant(
              of: find.byType(RefreshIndicator),
              matching: find.byType(ListView),
            )
            .first;
        await tester.drag(dashboardList, const Offset(0, 350));
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(MainScreen)), same(dashboardState));
        expect(find.byType(BreatheScreen), findsNothing);
        expect(tester.takeException(), isNull);
      }

      final db = LocalDatabase();
      for (final type in ['Memory', 'Proud Moment']) {
        await db.addEvent(
          Event(
            id: type,
            type: type,
            description: 'First $type',
            date: DateTime.now(),
          ),
        );
        await pull();
        final cards = tester.widgetList<SingleRewindWidget>(
          find.byType(SingleRewindWidget),
        );
        expect(cards.any((card) => card.title == type), isTrue);
      }

      final store = ProjectStore();
      await store.load();
      store.add(
        Project(
          name: 'First project',
          logbook: ProjectLogbook([
            ProjectLogEntry(date: DateTime.now(), text: 'First progress'),
          ]),
        ),
      );
      await store.persist();
      store.dispose();
      final daysBefore = await StreakService().getActiveDays();
      await pull();
      final horizontalList = find.descendant(
        of: find.byType(RewindListWidget),
        matching: find.byType(ListView),
      );
      await tester.drag(horizontalList, const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('Project Spotlight'), findsOneWidget);
      expect(await StreakService().getActiveDays(), daysBefore);
      expect(await db.getAllEvents(), hasLength(2));
    },
  );
}
