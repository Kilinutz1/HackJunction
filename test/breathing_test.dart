import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_proud_space/breath.dart';
import 'package:my_proud_space/streak.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_proud_space/breathing_setup.dart';

void main() {
  testWidgets('Duration limits and timed completion', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: BreathingSetupPage()));
    final pickers = find.byType(DropdownButtonFormField<int>);
    tester.widget<DropdownButtonFormField<int>>(pickers.first).onChanged!(30);
    await tester.pump();
    expect(
      tester.widget<DropdownButtonFormField<int>>(pickers.last).onChanged,
      isNull,
    );
    await tester.tap(find.text('Start exercise'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester
          .widget<BreatheScreen>(find.byType(BreatheScreen))
          .durationInSeconds,
      1800,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(await StreakService().getActiveDays(), isEmpty);
    tester.widget<DropdownButtonFormField<int>>(pickers.first).onChanged!(0);
    await tester.pump();
    expect(
      tester.widget<DropdownButtonFormField<int>>(pickers.last).initialValue,
      10,
    );
    await tester.tap(find.text('Start exercise'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    final progress = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('breathing-progress')),
    );
    expect(progress.value, closeTo(0.5, 0.01));
    expect(find.byType(BreatheScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(BreatheScreen), findsNothing);
    expect(find.byType(BreathingSetupPage), findsOneWidget);
    expect(await StreakService().getActiveDays(), [
      StreakService.dayKey(DateTime.now()),
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Startup exercise keeps its original completion button', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: BreatheScreen(
          durationInSeconds: 12,
          onComplete: () => completed = true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 12));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text("I'm present"), findsOneWidget);
    await tester.tap(find.text("I'm present"));
    await tester.pump(const Duration(milliseconds: 100));
    expect(completed, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
