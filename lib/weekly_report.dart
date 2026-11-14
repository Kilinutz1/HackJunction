import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'event.dart';
import 'localdb.dart';
import 'project.dart';
import 'weekly_report_data.dart';

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

class WeeklyReportPage extends StatefulWidget {
  const WeeklyReportPage({super.key, this.initialWeek});
  final DateTime? initialWeek;
  @override
  State<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends State<WeeklyReportPage> {
  late DateTime _week;
  List<Event> _events = [];
  List<Project> _projects = [];
  bool _loading = true;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _week = reportWeekStart(widget.initialWeek ?? DateTime.now());
    _load();
  }

  Future<void> _load() async {
    final store = ProjectStore();
    try {
      final events = await LocalDatabase().getAllEvents();
      await store.load();
      if (!mounted) return;
      setState(() {
        _events = events;
        _projects = [...store.value];
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    } finally {
      store.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final report = WeeklyReport(
      events: _events,
      projects: _projects,
      week: _week,
      now: now,
    );
    final current = _week == reportWeekStart(now);
    return Scaffold(
      appBar: AppBar(title: const Text('Your week')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed
          ? Center(
              child: TextButton(
                onPressed: _load,
                child: const Text('Could not load your week. Retry'),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous week',
                        onPressed: () => setState(
                          () => _week = DateTime(
                            _week.year,
                            _week.month,
                            _week.day - 7,
                          ),
                        ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          '${_date(report.start)} – ${_date(DateTime(report.end.year, report.end.month, report.end.day - 1))}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next week',
                        onPressed: current
                            ? null
                            : () => setState(
                                () => _week = DateTime(
                                  _week.year,
                                  _week.month,
                                  _week.day + 7,
                                ),
                              ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    report.highlights.isEmpty
                        ? 'Room for good things.'
                        : report.all.length == 1
                        ? 'One moment worth keeping.'
                        : 'A week worth remembering.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    current
                        ? 'Your week so far. A few things to take with you.'
                        : 'Small moments. Real steps forward.',
                  ),
                  const SizedBox(height: 24),
                  if (report.highlights.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No moments saved for this week yet. Your memories, proud moments and project updates will appear here.',
                      ),
                    )
                  else ...[
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _Count('${report.memories}', 'memories'),
                        _Count('${report.proudMoments}', 'proud moments'),
                        _Count(
                          '${report.activeProjects}',
                          'projects with activity',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    for (final highlight in report.highlights) ...[
                      _HighlightCard(highlight: highlight),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      '${report.highlights.length} highlights from ${report.entryCount} saved moments and project activities',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.view_list_outlined),
                      label: const Text('View the full week'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _FullWeek(report: report),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: Theme.of(context).textTheme.headlineSmall),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.highlight, this.expanded = false});
  final WeeklyHighlight highlight;
  final bool expanded;
  @override
  Widget build(BuildContext context) {
    final event = highlight.event;
    final project = highlight.project;
    final heading =
        project?.name ??
        (event!.type == 'Proud Moment'
            ? 'Something to be proud of'
            : event.isFavorite
            ? 'A favorite moment'
            : 'A moment to keep');
    final photo = event?.pictureUrl;
    final images = highlight.entries.where((e) => e.image != null);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: expanded
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(project?.name ?? event!.type)),
                    body: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _HighlightCard(highlight: highlight, expanded: true),
                      ],
                    ),
                  ),
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photo != null && photo.isNotEmpty) ...[
                _ReportPhoto(source: photo),
                const SizedBox(height: 16),
              ] else if (images.isNotEmpty) ...[
                _ReportPhoto(bytes: images.first.image),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    project != null
                        ? Icons.flag_outlined
                        : event!.isFavorite
                        ? Icons.favorite_border
                        : Icons.auto_stories_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Text(
                    highlight.kind,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    _date(highlight.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(heading, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              if (project != null) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (project.importance != null)
                      Chip(label: Text('Priority ${project.importance}/5')),
                    if (highlight.started)
                      const Chip(label: Text('Started this week')),
                    Chip(
                      label: Text(
                        '${highlight.entries.length} logbook updates',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if ((!expanded || project == null) &&
                  highlight.text.trim().isNotEmpty)
                Text(
                  highlight.text,
                  maxLines: expanded ? null : 4,
                  overflow: expanded ? null : TextOverflow.ellipsis,
                ),
              if (project != null && expanded) ...[
                if (project.description.isNotEmpty) ...[
                  const Divider(height: 32),
                  Text(project.description),
                ],
                if (project.category != null)
                  Text('Category: ${project.category}'),
                if (project.period != null)
                  Text(
                    '${_date(project.period!.start)} – ${_date(project.period!.end)}',
                  ),
                const SizedBox(height: 20),
                Text(
                  'This week’s logbook',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final entry in highlight.entries) ...[
                  const Divider(height: 24),
                  Text(
                    _date(entry.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (entry.text.isNotEmpty) Text(entry.text),
                  if (entry.image != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _ReportPhoto(bytes: entry.image),
                    ),
                ],
              ],
              if (!expanded)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Read more'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportPhoto extends StatelessWidget {
  const _ReportPhoto({this.source, this.bytes});
  final String? source;
  final Uint8List? bytes;
  @override
  Widget build(BuildContext context) {
    Widget fallback() => Container(
      height: 160,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Center(child: Icon(Icons.image_not_supported_outlined)),
    );
    Widget image;
    try {
      if (bytes != null) {
        image = Image.memory(
          bytes!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback(),
        );
      } else if (source!.startsWith('base64:')) {
        image = Image.memory(
          base64Decode(source!.substring(7)),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback(),
        );
      } else if (kIsWeb ||
          source!.startsWith('https://') ||
          source!.startsWith('http://')) {
        image = Image.network(
          source!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback(),
        );
      } else {
        image = Image.file(
          File(source!),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback(),
        );
      }
    } catch (_) {
      image = fallback();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(height: 180, width: double.infinity, child: image),
    );
  }
}

class _FullWeek extends StatelessWidget {
  const _FullWeek({required this.report});
  final WeeklyReport report;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('The full week')),
    body: ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: report.all.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, index) => _HighlightCard(highlight: report.all[index]),
    ),
  );
}
