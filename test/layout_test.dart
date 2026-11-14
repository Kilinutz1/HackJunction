@TestOn('vm')
library;

import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_proud_space/main.dart';
import 'package:my_proud_space/app_theme.dart';
import 'package:my_proud_space/proudy.dart';
import 'package:my_proud_space/mymemories.dart';
import 'package:my_proud_space/project.dart';
import 'package:my_proud_space/event.dart';
import 'package:my_proud_space/localdb.dart';

void main() {
  testWidgets('Mobile design review across the main screens', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const capture = bool.fromEnvironment('CAPTURE_DESIGN');
    if (capture) {
      for (final family in ['Roboto', 'Georgia', 'Ahem', 'MaterialIcons']) {
        final path = family == 'MaterialIcons'
            ? '${Directory.fromUri(Uri.parse(jsonDecode(File(".dart_tool/package_config.json").readAsStringSync())["flutterRoot"] as String)).path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'
            : '/System/Library/Fonts/Supplemental/${family == 'Georgia' ? 'Georgia' : 'Arial'}.ttf';
        final loader = FontLoader(family)
          ..addFont(
            Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
          );
        await tester.runAsync(() => loader.load());
      }
    }
    final db = LocalDatabase();
    await db.addEvent(
      Event(
        id: '1',
        type: 'Proud Moment',
        description:
            'A little further than yesterday. Finished my first 5 km run by the water.',
        date: DateTime.now(),
        isFavorite: true,
      ),
    );
    await db.addEvent(
      Event(
        id: '2',
        type: 'Memory',
        description: 'Coffee, a long walk, and no particular place to be.',
        date: DateTime.now(),
      ),
    );
    final project = Project(
      name: 'A stronger kind of everyday',
      description: 'Build a habit of moving, one small step at a time.',
      importance: 4,
      category: 'Sports',
      period: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 30)),
      ),
    );
    project.logbook.entries.add(
      ProjectLogEntry(
        date: DateTime.now(),
        text: 'First morning run. It felt good just to show up.',
      ),
    );
    await db.saveProjects([project]);
    Future<void> photo(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (!capture) return;
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('capture')),
        );
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/design-review/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    Future<void> page(Widget child) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            home: child,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(
      const RepaintBoundary(key: ValueKey('capture'), child: HackathonApp()),
    );
    await photo('home');
    await tester.tap(find.byKey(const ValueKey('streak-badge')));
    await photo('streak');
    await page(const ProudyPage());
    await photo('add-memory');
    await page(const MyMemoriesPage());
    await photo('memories');
    await page(const ProjectsPage());
    await photo('projects');
    await tester.tap(find.byTooltip('Project overview'));
    await photo('project-overview');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Logbook'));
    await photo('logbook');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text(project.name));
    await photo('project-edit');
    await page(const MainScreen());
    tester.view.physicalSize = const Size(320, 640);
    await photo('home-small');
    await page(const MyMemoriesPage());
    await photo('memories-small');
  });
}
