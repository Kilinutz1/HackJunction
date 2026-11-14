import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// References are relative to Documents, whose absolute path may change on iOS.
class ImageStorage {
  ImageStorage({Future<Directory> Function()? documents})
    : _documents = documents ?? getApplicationDocumentsDirectory;
  final Future<Directory> Function() _documents;
  static const prefix = 'documents:';

  Future<String> save(String source) async {
    if (source.startsWith(prefix) || source.startsWith('base64:'))
      return source;
    if (kIsWeb)
      return 'base64:${base64Encode(await XFile(source).readAsBytes())}';
    final directory = await _documents();
    await directory.create(recursive: true);
    final file = await resolve(source);
    final name =
        'memory_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(0x7fffffff)}.jpg';
    await file.copy('${directory.path}/$name');
    return '$prefix$name';
  }

  Future<File> resolve(String source) async {
    final directory = await _documents();
    if (source.startsWith(prefix)) {
      final name = source.substring(prefix.length);
      if (name.isEmpty ||
          name.contains('/') ||
          name.contains('\\') ||
          name == '..') {
        throw const FormatException('Invalid stored image name');
      }
      return File('${directory.path}/$name');
    }
    // Older versions copied images to Documents but persisted absolute paths.
    // Recover these by filename; never change or delete the original reference.
    final name = source.replaceAll('\\', '/').split('/').last;
    final relocated = File('${directory.path}/$name');
    if (name.startsWith('memory_') && await relocated.exists())
      return relocated;
    return File(source);
  }
}

class StoredImage extends StatefulWidget {
  const StoredImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });
  final String source;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;
  @override
  State<StoredImage> createState() => _StoredImageState();
}

class _StoredImageState extends State<StoredImage> {
  Future<File>? _file;
  bool get _network =>
      widget.source.startsWith('http:') ||
      widget.source.startsWith('https:') ||
      widget.source.startsWith('blob:');
  void _resolve() {
    _file = !_network && !widget.source.startsWith('base64:')
        ? ImageStorage().resolve(widget.source)
        : null;
  }

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(StoredImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) _resolve();
  }

  Widget _error(BuildContext context, Object error, StackTrace? stack) =>
      widget.errorBuilder?.call(context, error, stack) ??
      const Center(child: Icon(Icons.broken_image_outlined));
  @override
  Widget build(BuildContext context) {
    if (_network)
      return Image.network(
        widget.source,
        fit: widget.fit,
        errorBuilder: _error,
      );
    if (widget.source.startsWith('base64:')) {
      try {
        return Image.memory(
          base64Decode(widget.source.substring(7)),
          fit: widget.fit,
          errorBuilder: _error,
        );
      } catch (error, stack) {
        return _error(context, error, stack);
      }
    }
    return FutureBuilder<File>(
      future: _file,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return _error(context, snapshot.error!, snapshot.stackTrace);
        if (!snapshot.hasData) return const SizedBox.shrink();
        return Image.file(
          snapshot.data!,
          fit: widget.fit,
          errorBuilder: _error,
        );
      },
    );
  }
}
