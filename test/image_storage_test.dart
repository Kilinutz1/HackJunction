import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_proud_space/stored_image.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('image-storage-test-');
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('Saved reference survives relocating the documents directory', () async {
    final oldDocs = await Directory(
      '${root.path}/old-container/Documents',
    ).create(recursive: true);
    final source = await File(
      '${root.path}/temporary.jpg',
    ).writeAsBytes([1, 2, 3]);
    final storage = ImageStorage(documents: () async => oldDocs);
    final reference = await storage.save(source.path);
    expect(reference.startsWith('documents:memory_'), isTrue);
    expect(reference.contains(root.path), isFalse);
    await source.delete();
    final newDocs = await oldDocs.rename('${root.path}/new-documents');
    final resolved = await ImageStorage(
      documents: () async => newDocs,
    ).resolve(reference);
    expect(await resolved.readAsBytes(), [1, 2, 3]);
  });

  test(
    'Recovers iOS and Android legacy paths without rewriting or deleting files',
    () async {
      final docs = await Directory('${root.path}/Documents').create();
      final image = await File(
        '${docs.path}/memory_123.jpg',
      ).writeAsBytes([4, 5, 6]);
      final storage = ImageStorage(documents: () async => docs);
      for (final oldPath in [
        '/var/mobile/Containers/Data/Application/OLD-ID/Documents/memory_123.jpg',
        '/data/user/0/old.app/app_flutter/memory_123.jpg',
      ]) {
        expect((await storage.resolve(oldPath)).path, image.path);
      }
      expect(await image.readAsBytes(), [4, 5, 6]);
      expect(
        (await storage.resolve('/old/Documents/memory_missing.jpg')).path,
        '/old/Documents/memory_missing.jpg',
      );
    },
  );

  test(
    'Missing source fails instead of returning a temporary path; base64 is preserved',
    () async {
      final storage = ImageStorage(documents: () async => root);
      await expectLater(
        storage.save('${root.path}/missing.jpg'),
        throwsA(isA<FileSystemException>()),
      );
      const encoded = 'base64:AQID';
      expect(await storage.save(encoded), encoded);
      await expectLater(
        storage.resolve('documents:../outside.jpg'),
        throwsFormatException,
      );
    },
  );

  testWidgets(
    'Base64 project pictures render on mobile and malformed data falls back',
    (tester) async {
      const png =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a0MsAAAAASUVORK5CYII=';
      await tester.pumpWidget(
        const MaterialApp(home: StoredImage(source: 'base64:$png')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          home: StoredImage(
            source: 'base64:!!!',
            errorBuilder: (_, _, _) => const Text('Missing'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Missing'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(base64Decode(png), isNotEmpty);
    },
  );
}
