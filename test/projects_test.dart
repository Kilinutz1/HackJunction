import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// The picker platform is replaced to test selection without a native dialog.
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:my_proud_space/project.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestImageFile extends XFile {
  _TestImageFile(this.bytes, String name)
    : super.fromData(bytes, name: name, mimeType: 'image/png');

  final Uint8List bytes;

  @override
  Future<Uint8List> readAsBytes() async => bytes;
}

class _TestImagePicker extends ImagePickerPlatform {
  List<XFile> selection = [];
  bool fail = false;

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    if (fail) throw Exception('Picker unavailable');
    return selection;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final overview in ['start', 'all']) {
    testWidgets(
      'Status filtering combines with sorting in $overview overview',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final seed = ProjectStore();
        await seed.load();
        seed.add(Project(name: 'Low priority', importance: 1));
        seed.add(Project(name: 'High priority', importance: 5));
        seed.add(Project(name: 'Finished', completed: true));
        seed.add(
          Project(
            name: 'Expired',
            period: DateTimeRange(
              start: DateTime(2000, 1, 1),
              end: DateTime(2000, 1, 2),
            ),
          ),
        );
        await seed.persist();
        seed.dispose();
        await tester.pumpWidget(const MaterialApp(home: ProjectsPage()));
        await tester.pumpAndSettle();
        if (overview == 'all') {
          await tester.tap(find.text('All projects'));
          await tester.pumpAndSettle();
        }

        Future<void> filter(String label) async {
          await tester.tap(find.byKey(const ValueKey('project-status-filter')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(label).last);
          await tester.pumpAndSettle();
        }

        await filter('Completed');
        expect(find.text('Finished'), findsOneWidget);
        expect(find.text('Expired'), findsOneWidget);
        expect(find.text('Low priority'), findsNothing);
        await filter('Incomplete');
        expect(find.text('Finished'), findsNothing);
        expect(find.text('Expired'), findsNothing);
        await tester.tap(find.text('Duration – longest first'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Priority – highest first').last);
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(find.text('High priority')).dy,
          lessThan(tester.getTopLeft(find.text('Low priority')).dy),
        );
        await tester.tap(find.byTooltip('Project actions').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mark as completed'));
        await tester.pumpAndSettle();
        expect(find.text('High priority'), findsNothing);
        await tester.tap(find.byTooltip('Project actions'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mark as completed'));
        await tester.pumpAndSettle();
        expect(find.text('No projects match this status.'), findsOneWidget);
        await filter('All');
        expect(find.text('High priority'), findsOneWidget);
        expect(find.text('Low priority'), findsOneWidget);
        expect(find.text('Finished'), findsOneWidget);
        expect(find.text('Expired'), findsOneWidget);
        expect(find.text('Priority – highest first'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final view in ['start', 'all', 'details']) {
    testWidgets('Complete, reopen and delete a project from $view', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final seed = ProjectStore();
      await seed.load();
      seed.add(Project(name: 'Keep me'));
      await seed.persist();
      seed.dispose();
      await tester.pumpWidget(const MaterialApp(home: ProjectsPage()));
      await tester.pumpAndSettle();
      if (view == 'all') {
        await tester.tap(find.text('All projects'));
        await tester.pumpAndSettle();
      }
      if (view == 'details') {
        await tester.tap(find.text('Keep me'));
        await tester.pumpAndSettle();
      } else {
        await tester.tap(find.byTooltip('Project actions'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Mark as completed'));
      await tester.pumpAndSettle();
      expect(find.text('Completed'), findsOneWidget);

      // Recreate the entire project page, like returning from the dashboard.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const MaterialApp(home: ProjectsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Keep me'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      if (view == 'all') {
        await tester.tap(find.text('All projects'));
        await tester.pumpAndSettle();
      }
      if (view == 'details') {
        await tester.tap(find.text('Keep me'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Delete project'));
      } else {
        await tester.tap(find.byTooltip('Project actions'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete project'));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      if (view == 'details') {
        await tester.tap(find.byTooltip('Delete project'));
      } else {
        await tester.tap(find.byTooltip('Project actions'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete project'));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('No projects added yet.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const MaterialApp(home: ProjectsPage()));
      await tester.pumpAndSettle();
      expect(find.text('No projects added yet.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('Projects, images, logs and completion survive reloading', () async {
    final store = ProjectStore();
    await store.load();
    final image = base64Decode('AQID');
    final project = Project(name: 'Persistent', images: [image]);
    store.add(project);
    project.logbook.entries.add(
      ProjectLogEntry(
        date: DateTime(2026, 1, 1),
        text: 'Image added',
        image: image,
      ),
    );
    project.logbook.onChanged?.call();
    store.update(project.withCompleted(true));
    await store.persist();
    store.dispose();
    final restored = ProjectStore();
    await restored.load();
    expect(restored.value.single.name, 'Persistent');
    expect(restored.value.single.id, project.id);
    expect(restored.value.single.isCompleted, isTrue);
    expect(restored.value.single.images.single, image);
    expect(restored.value.single.logbook.entries.single.image, image);
    restored.remove(restored.value.single);
    await restored.persist();
    restored.dispose();
    final empty = ProjectStore();
    await empty.load();
    expect(empty.value, isEmpty);
    empty.dispose();
  });

  test('Projects expire after the end date, not during the last day', () async {
    final store = ProjectStore();
    await store.load();
    final project = Project(
      name: 'Deadline',
      period: DateTimeRange(
        start: DateTime(2090, 1, 1),
        end: DateTime(2090, 1, 5),
      ),
    );
    store.add(project);
    expect(project.hasExpired(DateTime(2090, 1, 5, 23, 59)), isFalse);
    store.completeExpired(DateTime(2090, 1, 6));
    expect(store.value.single.completed, isTrue);
    await store.persist();
    store.dispose();
  });

  testWidgets('Logbook is shared across project details and both overviews', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: ProjectsPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Training');
    await tester.ensureVisible(find.text('Logbook'));
    await tester.tap(find.text('Logbook'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add entry'));
    await tester.pumpAndSettle();
    expect(find.text('Please describe your progress.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.byType(TextField),
      ),
      '01/01/2026',
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'First training session');
    await tester.tap(find.text('Add entry'));
    await tester.pumpAndSettle();
    expect(find.text('01.01.2026'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Logbook'));
    await tester.pumpAndSettle();
    expect(find.text('First training session'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Second training session');
    await tester.tap(find.text('Add entry'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Second training session')).dy,
      lessThan(tester.getTopLeft(find.text('First training session')).dy),
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('All projects'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Logbook'));
    await tester.pumpAndSettle();
    expect(find.text('Second training session'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Training'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'Updated description');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Logbook'));
    await tester.pumpAndSettle();
    expect(find.text('First training session'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Other project');
    await tester.ensureVisible(find.text('Logbook'));
    await tester.tap(find.text('Logbook'));
    await tester.pumpAndSettle();
    expect(find.text('First training session'), findsNothing);
    expect(
      find.text('No entries yet. Record your first progress update above.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Project images can be selected, kept and removed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final original = ImagePickerPlatform.instance;
    final picker = _TestImagePicker();
    ImagePickerPlatform.instance = picker;
    addTearDown(() => ImagePickerPlatform.instance = original);
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
    );
    picker.selection = [
      _TestImageFile(bytes, 'one.png'),
      _TestImageFile(bytes, 'two.png'),
    ];
    await tester.pumpWidget(const MaterialApp(home: ProjectsPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Photo project');
    await tester.tap(find.text('Add images'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove image'), findsNWidgets(2));
    picker.selection = [];
    await tester.tap(find.text('Add images'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove image'), findsNWidgets(2));
    picker.fail = true;
    await tester.tap(find.text('Add images'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not load images'), findsOneWidget);
    expect(find.byTooltip('Remove image'), findsNWidgets(2));
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    await tester.tap(find.byTooltip('Logbook'));
    await tester.pumpAndSettle();
    expect(find.text('Image added'), findsNWidgets(2));
    expect(find.byType(Image), findsNWidgets(2));
    final today = DateTime.now();
    final addedDate =
        '${today.day.toString().padLeft(2, '0')}.'
        '${today.month.toString().padLeft(2, '0')}.${today.year}';
    expect(find.text(addedDate), findsNWidgets(2));
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photo project'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove image'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Remove image').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove image'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove image'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('Project duration counts calendar days inclusively', () {
    expect(Project(name: 'Unset').durationDays, 0);
    final project = Project(
      name: 'Across daylight saving',
      period: DateTimeRange(
        start: DateTime(2026, 3, 28),
        end: DateTime(2026, 3, 30),
      ),
    );
    expect(project.durationDays, 3);
  });

  testWidgets('Add, configure and sort projects by duration', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: ProjectsPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
    expect(find.text('No date range selected'), findsOneWidget);
    expect(find.text('Select category'), findsOneWidget);
    expect(
      tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .every((chip) => !chip.selected),
      isTrue,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a project name.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('No projects added yet.'), findsOneWidget);

    Future<void> addProject(String name) async {
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, name);
    }

    Future<void> setPeriod(String start, String end) async {
      await tester.tap(find.text('Select date range'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Switch to input'));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(DateRangePickerDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), start);
      await tester.enterText(fields.at(1), end);
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
    }

    await addProject('Short project');
    await setPeriod('01/01/2026', '01/02/2026');
    await tester.tap(find.text('2'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await addProject('Long project');
    await tester.enterText(
      find.byType(TextField).at(1),
      'Mein langfristiges Ziel',
    );
    await setPeriod('01/01/2026', '02/01/2026');
    await tester.tap(find.text('5'));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sports').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sports · Priority 5/5'), findsOneWidget);

    await addProject('Without dates');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No category · No priority'), findsWidgets);

    var currentSort = 'Duration – longest first';
    Future<void> selectSort(String label) async {
      await tester.tap(find.text(currentSort));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      currentSort = label;
    }

    void expectOrder(List<String> names) {
      for (var i = 0; i < names.length - 1; i++) {
        expect(
          tester.getTopLeft(find.text(names[i])).dy,
          lessThan(tester.getTopLeft(find.text(names[i + 1])).dy),
        );
      }
    }

    Future<void> checkSortOptions() async {
      await selectSort('Priority – highest first');
      expectOrder(['Long project', 'Short project', 'Without dates']);
      await selectSort('Oldest first');
      expectOrder(['Short project', 'Long project', 'Without dates']);
      await selectSort('Newest first');
      expectOrder(['Without dates', 'Long project', 'Short project']);
      await selectSort('Duration – longest first');
      expectOrder(['Long project', 'Short project', 'Without dates']);
    }

    await checkSortOptions();
    await tester.tap(find.text('All projects'));
    await tester.pumpAndSettle();
    await checkSortOptions();
    expect(
      tester.getTopLeft(find.text('Long project')).dy,
      lessThan(tester.getTopLeft(find.text('Short project')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Short project')).dy,
      lessThan(tester.getTopLeft(find.text('Without dates')).dy),
    );

    // Edits from the overview also update the underlying project list.
    await tester.tap(find.text('Long project'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
      'Mein langfristiges Ziel',
    );
    await tester.tap(find.text('1'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sports · Priority 1/5'), findsOneWidget);
    await selectSort('Priority – highest first');
    expectOrder(['Short project', 'Long project', 'Without dates']);
    await selectSort('Oldest first');
    expectOrder(['Short project', 'Long project', 'Without dates']);
    await selectSort('Newest first');
    expectOrder(['Without dates', 'Long project', 'Short project']);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('Sports · Priority 1/5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
