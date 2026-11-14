import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProjectLogEntry {
  const ProjectLogEntry({required this.date, required this.text, this.image});

  final DateTime date;
  final String text;
  final Uint8List? image;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'text': text,
    if (image != null) 'image': base64Encode(image!),
  };

  factory ProjectLogEntry.fromJson(Map<String, dynamic> json) =>
      ProjectLogEntry(
        date: DateTime.parse(json['date'] as String),
        text: json['text'] as String,
        image: json['image'] == null
            ? null
            : base64Decode(json['image'] as String),
      );
}

class ProjectLogbook {
  ProjectLogbook([Iterable<ProjectLogEntry> entries = const []])
    : entries = [...entries];
  final List<ProjectLogEntry> entries;
  VoidCallback? onChanged;
}

class Project {
  Project({
    required this.name,
    this.description = '',
    this.period,
    this.importance,
    this.category,
    List<Uint8List> images = const [],
    DateTime? createdAt,
    ProjectLogbook? logbook,
    String? id,
    this.completed = false,
  }) : images = List.unmodifiable(images),
       id =
           id ??
           '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(0x7fffffff)}',
       logbook = logbook ?? ProjectLogbook(),
       createdAt = createdAt ?? DateTime.now();

  final String name;
  final String description;
  final DateTimeRange? period;
  final int? importance;
  final String? category;
  final DateTime createdAt;
  final List<Uint8List> images;
  final ProjectLogbook logbook;
  final String id;
  final bool completed;

  bool hasExpired(DateTime now) {
    final end = period?.end;
    if (end == null) return false;
    return !now.isBefore(DateTime(end.year, end.month, end.day + 1));
  }

  bool get isCompleted => completed || hasExpired(DateTime.now());

  Project withCompleted(bool completed) => Project(
    id: id,
    name: name,
    description: description,
    period: period,
    importance: importance,
    category: category,
    images: images,
    createdAt: createdAt,
    logbook: logbook,
    completed: completed,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'start': period?.start.toIso8601String(),
    'end': period?.end.toIso8601String(),
    'importance': importance,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'completed': isCompleted,
    'images': images.map(base64Encode).toList(),
    'entries': logbook.entries.map((entry) => entry.toJson()).toList(),
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    period: json['start'] == null || json['end'] == null
        ? null
        : DateTimeRange(
            start: DateTime.parse(json['start'] as String),
            end: DateTime.parse(json['end'] as String),
          ),
    importance: json['importance'] as int?,
    category: json['category'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    completed: json['completed'] as bool? ?? false,
    images: (json['images'] as List? ?? [])
        .map((image) => base64Decode(image as String))
        .toList(),
    logbook: ProjectLogbook(
      (json['entries'] as List? ?? []).map(
        (entry) =>
            ProjectLogEntry.fromJson(Map<String, dynamic>.from(entry as Map)),
      ),
    ),
  );

  // UTC calendar dates avoid daylight-saving changes affecting the order.
  int get durationDays {
    final range = period;
    if (range == null) return 0;
    final start = DateTime.utc(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime.utc(range.end.year, range.end.month, range.end.day);
    return end.difference(start).inDays + 1;
  }
}
