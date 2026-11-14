import 'event.dart';
import 'project.dart';

DateTime reportWeekStart(DateTime date) =>
    DateTime(date.year, date.month, date.day - date.weekday + 1);

class WeeklyHighlight {
  WeeklyHighlight.event(this.event)
    : project = null,
      entries = const [],
      started = false;
  WeeklyHighlight.project(this.project, this.entries, this.started)
    : event = null;
  final Event? event;
  final Project? project;
  final List<ProjectLogEntry> entries;
  final bool started;
  String get kind => event?.type ?? 'Project';
  String get id =>
      event == null ? 'project:${project!.id}' : 'event:${event!.id}';
  DateTime get date =>
      event?.date ??
      (entries.isEmpty ? project!.createdAt : entries.first.date);
  int get weight => event != null
      ? (event!.isFavorite ? 40 : 0)
      : (project!.importance ?? 0) * 6;
  String get text =>
      event?.description ??
      (entries.isEmpty ? project!.description : entries.first.text);
}

class WeeklyReport {
  WeeklyReport({
    required Iterable<Event> events,
    required Iterable<Project> projects,
    required DateTime week,
    required DateTime now,
  }) : start = reportWeekStart(week) {
    end = DateTime(start.year, start.month, start.day + 7);
    bool included(DateTime date) =>
        !date.isBefore(start) && date.isBefore(end) && !date.isAfter(now);
    final eventItems = events
        .where(
          (e) =>
              included(e.date) &&
              (e.type == 'Memory' || e.type == 'Proud Moment'),
        )
        .toList();
    memories = eventItems.where((e) => e.type == 'Memory').length;
    proudMoments = eventItems.where((e) => e.type == 'Proud Moment').length;
    final projectItems = <WeeklyHighlight>[];
    for (final project in projects) {
      final entries =
          project.logbook.entries.where((e) => included(e.date)).toList()
            ..sort((a, b) {
              final order = b.date.compareTo(a.date);
              return order != 0 ? order : a.id.compareTo(b.id);
            });
      final started = included(project.createdAt);
      if (entries.isNotEmpty || started) {
        projectItems.add(WeeklyHighlight.project(project, entries, started));
      }
    }
    activeProjects = projectItems.length;
    all = [...eventItems.map(WeeklyHighlight.event), ...projectItems]
      ..sort((a, b) {
        final order = b.date.compareTo(a.date);
        return order != 0 ? order : a.id.compareTo(b.id);
      });
    entryCount =
        eventItems.length +
        projectItems.fold<int>(
          0,
          (sum, p) => sum + p.entries.length + (p.started ? 1 : 0),
        );
    highlights = _select(all);
  }
  final DateTime start;
  late final DateTime end;
  late final int memories, proudMoments, activeProjects, entryCount;
  late final List<WeeklyHighlight> all, highlights;

  static List<WeeklyHighlight> _select(List<WeeklyHighlight> candidates) {
    final remaining = [...candidates];
    final chosen = <WeeklyHighlight>[];
    final usedDays = <String>{};
    String day(WeeklyHighlight h) =>
        '${h.date.year}-${h.date.month}-${h.date.day}';
    void take(List<WeeklyHighlight> pool) {
      pool.sort((a, b) {
        int score(WeeklyHighlight h) =>
            h.weight + (usedDays.contains(day(h)) ? 0 : 8);
        final order = score(b).compareTo(score(a));
        return order != 0 ? order : a.id.compareTo(b.id);
      });
      final next = pool.first;
      chosen.add(next);
      remaining.remove(next);
      // Exact repeated notes should not crowd out distinct memories.
      String normalized(String text) =>
          text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      final note = normalized(next.text);
      if (next.event != null && note.isNotEmpty) {
        remaining.removeWhere(
          (h) => h.event != null && normalized(h.text) == note,
        );
      }
      usedDays.add(day(next));
    }

    // Reserve a place for each available category, then fill up to five.
    for (final kind in ['Memory', 'Proud Moment', 'Project']) {
      final pool = remaining.where((h) => h.kind == kind).toList();
      if (pool.isNotEmpty) take(pool);
    }
    while (chosen.length < 5 && remaining.isNotEmpty) {
      var pool = remaining
          .where((h) => chosen.where((c) => c.kind == h.kind).length < 2)
          .toList();
      // Give an unstarred moment space too, without increasing report length.
      if (!chosen.any((h) => h.event != null && !h.event!.isFavorite)) {
        final quiet = pool
            .where((h) => h.event != null && !h.event!.isFavorite)
            .toList();
        if (quiet.isNotEmpty) pool = quiet;
      }
      if (pool.isEmpty) {
        pool = remaining.where((h) => h.kind != 'Project').toList();
      }
      if (pool.isEmpty) break;
      take(pool);
    }
    return chosen;
  }
}
