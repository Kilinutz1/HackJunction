import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_proud_space/breathing_music.dart';
import 'package:my_proud_space/breathing_setup.dart';

void main() {
  test('Playlist includes every audio asset except funky', () {
    final available = Directory('assets')
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .where((name) => name.endsWith('.m4a') && !name.contains('funky'))
        .toSet();
    expect(
      BreathingMusic.values.map((track) => track.asset).toSet(),
      available,
    );
  });

  testWidgets('Music menu selects exactly one track or silence', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BreathingSetupPage()));
    for (final track in BreathingMusic.values) {
      await tester.tap(find.text('Music'));
      await tester.pumpAndSettle();
      expect(find.text('funky'), findsNothing);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      await tester.ensureVisible(find.text(track.label).last);
      await tester.tap(find.text(track.label).last);
      await tester.pumpAndSettle();
      expect(find.text('Choose music'), findsNothing);
      expect(find.text(track.label), findsOneWidget);
    }
    await tester.tap(find.text('Music'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No music'));
    await tester.pumpAndSettle();
    expect(find.text('No music'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
