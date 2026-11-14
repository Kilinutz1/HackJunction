import 'app_theme.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localdb.dart';

const _categories = ['Hobbies', 'Sports', 'Everyday life', 'Work', 'Other'];

enum _ProjectStatusFilter {
  all('All'),
  completed('Completed'),
  incomplete('Incomplete');

  const _ProjectStatusFilter(this.label);
  final String label;
}

enum _ProjectSort {
  priority('Priority – highest first'),
  duration('Duration – longest first'),
  oldest('Oldest first'),
  newest('Newest first');

  const _ProjectSort(this.label);
  final String label;
}

class ProjectLogEntry {
  ProjectLogEntry({
    required this.date,
    required this.text,
    this.image,
    String? id,
  }) : id =
           id ??
           '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(0x7fffffff)}';

  final String id;
  final DateTime date;
  final String text;
  final Uint8List? image;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'text': text,
    if (image != null) 'image': base64Encode(image!),
  };

  factory ProjectLogEntry.fromJson(Map<String, dynamic> json) =>
      ProjectLogEntry(
        id: json['id'] as String?,
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

class _ProjectLogbookPage extends StatefulWidget {
  const _ProjectLogbookPage({required this.projectName, required this.logbook});

  final String projectName;
  final ProjectLogbook logbook;

  @override
  State<_ProjectLogbookPage> createState() => _ProjectLogbookPageState();
}

class _ProjectLogbookPageState extends State<_ProjectLogbookPage> {
  final _textController = TextEditingController();
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  String? _textError;

  String? _editingEntryId;
  Uint8List? _entryImage;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select entry date',
    );
    if (!mounted || date == null) return;
    setState(() => _date = date);
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (mounted) setState(() => _entryImage = bytes);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not load image.')));
      }
    }
  }

  void _saveEntry() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _textError = 'Please describe your progress.');
      return;
    }

    setState(() {
      if (_editingEntryId != null) {
        final index = widget.logbook.entries.indexWhere(
          (e) => e.id == _editingEntryId,
        );
        if (index != -1) {
          widget.logbook.entries[index] = ProjectLogEntry(
            id: _editingEntryId,
            date: _date,
            text: text,
            image: _entryImage,
          );
        }
      } else {
        widget.logbook.entries.insert(
          0,
          ProjectLogEntry(date: _date, text: text, image: _entryImage),
        );
      }

      _textController.clear();
      _textError = null;
      _date = DateUtils.dateOnly(DateTime.now());
      _entryImage = null;
      _editingEntryId = null;
    });
    FocusScope.of(context).unfocus();
    widget.logbook.onChanged?.call();
  }

  void _editEntry(ProjectLogEntry entry) {
    setState(() {
      _editingEntryId = entry.id;
      _textController.text = entry.text;
      _date = entry.date;
      _entryImage = entry.image;
    });
  }

  void _deleteEntry(ProjectLogEntry entry) {
    setState(() {
      widget.logbook.entries.removeWhere((e) => e.id == entry.id);
      if (_editingEntryId == entry.id) {
        _textController.clear();
        _date = DateUtils.dateOnly(DateTime.now());
        _entryImage = null;
        _editingEntryId = null;
      }
    });
    widget.logbook.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final entries = [...widget.logbook.entries];
    entries.sort((a, b) {
      final dateOrder = b.date.compareTo(a.date);
      return dateOrder != 0
          ? dateOrder
          : widget.logbook.entries
                .indexOf(a)
                .compareTo(widget.logbook.entries.indexOf(b));
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Logbook',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.projectName.isEmpty ? 'New project' : widget.projectName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            Card(
              elevation: _editingEntryId != null ? 4 : 1,
              color: _editingEntryId != null
                  ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.05)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingEntryId != null ? 'Edit Entry' : 'New Entry',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _editingEntryId != null
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text('Date: ${_formatDate(_date)}'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textController,
                      minLines: 3,
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: 'Progress',
                        hintText: 'What progress have you made?',
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                        errorText: _textError,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_entryImage != null)
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _entryImage!,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            ),
                          ),
                          IconButton.filled(
                            onPressed: () => setState(() => _entryImage = null),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    if (_entryImage != null) const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: Icon(
                            _entryImage == null
                                ? Icons.add_photo_alternate
                                : Icons.photo,
                          ),
                          label: Text(
                            _entryImage == null ? 'Add photo' : 'Change photo',
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_editingEntryId != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _editingEntryId = null;
                                    _textController.clear();
                                    _entryImage = null;
                                    _date = DateUtils.dateOnly(DateTime.now());
                                  });
                                },
                                child: const Text('Cancel'),
                              ),
                            FilledButton.icon(
                              onPressed: _saveEntry,
                              icon: Icon(
                                _editingEntryId != null
                                    ? Icons.save
                                    : Icons.add,
                              ),
                              label: Text(
                                _editingEntryId != null
                                    ? 'Update'
                                    : 'Add entry',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text('Entries', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const Text(
                'No entries yet. Record your first progress update above.',
              ),

            for (final entry in entries)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(entry.date),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _editEntry(entry),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Entry?'),
                                      content: const Text(
                                        'Are you sure you want to delete this log entry?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _deleteEntry(entry);
                                          },
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(entry.text),
                      if (entry.image != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            entry.image!,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (_, error, stackTrace) =>
                                const Text('Image unavailable'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Project {
  Project({
    required this.name,
    this.description = '',
    this.period,
    this.importance,
    this.category,
    DateTime? createdAt,
    ProjectLogbook? logbook,
    String? id,
    this.completed = false,
  }) : id =
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
    'completed': completed, // Reversible!
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
    logbook: ProjectLogbook(
      (json['entries'] as List? ?? []).map(
        (entry) =>
            ProjectLogEntry.fromJson(Map<String, dynamic>.from(entry as Map)),
      ),
    ),
  );

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

class ProjectStore extends ValueNotifier<List<Project>> {
  ProjectStore({this.onSaveError}) : super([]);

  static const storageKey = 'hackathon_projects_v1';
  final VoidCallback? onSaveError;
  static Future<void>? _pendingWrite;
  bool _disposed = false;

  Future<void> load() async {
    await _pendingWrite;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(storageKey);
    final decoded = saved == null ? <dynamic>[] : jsonDecode(saved) as List;
    if (_disposed) return;
    value = decoded
        .map((item) => Project.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    _bindLogbooks();
  }

  void _bindLogbooks() {
    for (final project in value) {
      project.logbook.onChanged = () {
        if (_disposed) return;
        notifyListeners();
        unawaited(persist());
      };
    }
  }

  void add(Project project) {
    value = [...value, project];
    _bindLogbooks();
    unawaited(persist());
  }

  void update(Project project) {
    value = [
      for (final item in value)
        if (item.id == project.id) project else item,
    ];
    _bindLogbooks();
    unawaited(persist());
  }

  void remove(Project project) {
    project.logbook.onChanged = null;
    value = value.where((item) => item.id != project.id).toList();
    unawaited(persist());
  }

  Future<void> persist() {
    final snapshot = jsonEncode(
      value.map((project) => project.toJson()).toList(),
    );
    final write = (_pendingWrite ?? Future<void>.value())
        .then((_) async {
          final prefs = await SharedPreferences.getInstance();
          if (!await prefs.setString(storageKey, snapshot)) {
            throw StateError('Project storage failed');
          }
        })
        .catchError((Object error) {
          if (!_disposed) onSaveError?.call();
        });
    _pendingWrite = write;
    return write.whenComplete(() {
      if (identical(_pendingWrite, write)) _pendingWrite = null;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    for (final project in value) {
      project.logbook.onChanged = null;
    }
    super.dispose();
  }
}

Future<bool> _confirmDelete(BuildContext context, Project project) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text(
          'Delete "${project.name}" and its logbook? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
    false;

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.'
    '${date.month.toString().padLeft(2, '0')}.${date.year}';

String _periodLabel(Project project) {
  final range = project.period;
  if (range == null) return 'No date range selected';
  return '${_formatDate(range.start)} – ${_formatDate(range.end)}'
      ' · ${project.durationDays} days';
}

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage>
    with WidgetsBindingObserver {
  late final ProjectStore _projects;
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _projects = ProjectStore(
      onSaveError: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not save projects on this device.'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => unawaited(_projects.persist()),
            ),
          ),
        );
      },
    );
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      await _projects.load();
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _projects.dispose();
    super.dispose();
  }

  Future<void> _addProject() async {
    final project = await Navigator.of(context).push<Project>(
      MaterialPageRoute(builder: (_) => const _ProjectDetailsPage()),
    );
    if (!mounted || project == null) return;
    _projects.add(project);
  }

  Future<void> _editProject(Project project) async {
    final updated = await Navigator.of(context).push<Project>(
      MaterialPageRoute(
        builder: (_) => _ProjectDetailsPage(
          project: project,
          onDelete: () => _projects.remove(project),
        ),
      ),
    );
    if (!mounted || updated == null) return;
    _projects.update(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Projects',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Could not load projects. Your saved data has not been changed.',
                  ),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.view_list_outlined),
                          label: const Text('All projects'),
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => _AllProjectsPage(
                                projects: _projects,
                                onProjectTap: _editProject,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _addProject,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _ProjectsList(
                      projects: _projects,
                      onProjectTap: _editProject,
                      preview: true,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AllProjectsPage extends StatelessWidget {
  const _AllProjectsPage({required this.projects, required this.onProjectTap});

  final ProjectStore projects;
  final ValueChanged<Project> onProjectTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'All Projects',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _ProjectsList(
                projects: projects,
                onProjectTap: onProjectTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectsList extends StatefulWidget {
  const _ProjectsList({
    required this.projects,
    required this.onProjectTap,
    this.preview = false,
  });

  final ProjectStore projects;
  final ValueChanged<Project> onProjectTap;
  final bool preview;

  @override
  State<_ProjectsList> createState() => _ProjectsListState();
}

class _ProjectsListState extends State<_ProjectsList> {
  _ProjectSort _sort = _ProjectSort.duration;
  _ProjectStatusFilter _status = _ProjectStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<_ProjectSort>(
            initialValue: _sort,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Sort by',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.sort),
            ),
            items: [
              for (final sort in _ProjectSort.values)
                DropdownMenuItem(value: sort, child: Text(sort.label)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _sort = value);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: DropdownButtonFormField<_ProjectStatusFilter>(
            key: const ValueKey('project-status-filter'),
            initialValue: _status,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.filter_list),
            ),
            items: [
              for (final status in _ProjectStatusFilter.values)
                DropdownMenuItem(value: status, child: Text(status.label)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _status = value);
            },
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<List<Project>>(
            valueListenable: widget.projects,
            builder: (context, projects, _) {
              if (projects.isEmpty) {
                return const Center(child: Text('No projects added yet.'));
              }
              final items = projects
                  .where(
                    (project) => switch (_status) {
                      _ProjectStatusFilter.all => true,
                      _ProjectStatusFilter.completed => project.isCompleted,
                      _ProjectStatusFilter.incomplete => !project.isCompleted,
                    },
                  )
                  .toList();
              if (items.isEmpty) {
                return const Center(
                  child: Text('No projects match this status.'),
                );
              }
              items.sort((a, b) {
                final order = switch (_sort) {
                  _ProjectSort.priority => (b.importance ?? 0).compareTo(
                    a.importance ?? 0,
                  ),
                  _ProjectSort.duration => b.durationDays.compareTo(
                    a.durationDays,
                  ),
                  _ProjectSort.oldest => a.createdAt.compareTo(b.createdAt),
                  _ProjectSort.newest => b.createdAt.compareTo(a.createdAt),
                };
                return order != 0
                    ? order
                    : projects.indexOf(a).compareTo(projects.indexOf(b));
              });
              return LayoutBuilder(
                builder: (context, constraints) {
                  // --- FIX: Syntax error from copy-paste fixed here! ---
                  final cardExtent =
                      168.0 * MediaQuery.textScalerOf(context).scale(16) / 16;

                  final visibleCount = widget.preview
                      ? min(
                          items.length,
                          (constraints.maxHeight / cardExtent).floor(),
                        )
                      : items.length;
                  if (visibleCount == 0) {
                    return const Center(
                      child: Text('Open All projects to view your projects.'),
                    );
                  }
                  return ListView.builder(
                    key: ValueKey(
                      widget.preview ? 'project-preview' : 'all-projects-list',
                    ),
                    physics: widget.preview
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    itemExtent: widget.preview ? cardExtent : null,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      widget.preview ? 0 : 16,
                    ),
                    itemCount: visibleCount,
                    itemBuilder: (context, index) {
                      final project = items[index];

                      final images = project.logbook.entries.where(
                        (e) => e.image != null,
                      );
                      final firstLogImage = images.isNotEmpty
                          ? images.first.image
                          : null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        color: AppPalette.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => widget.onProjectTap(project),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (firstLogImage != null) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.memory(
                                          firstLogImage,
                                          width: 28,
                                          height: 28,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, error, stack) =>
                                              const Icon(Icons.image_outlined),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        project.name,
                                        maxLines: widget.preview ? 1 : null,
                                        overflow: widget.preview
                                            ? TextOverflow.ellipsis
                                            : null,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (project.isCompleted)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Text(
                                          'Completed',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${project.category ?? 'No category'} · '
                                  '${project.importance == null ? 'No priority' : 'Priority ${project.importance}/5'}\n'
                                  '${_periodLabel(project)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: widget.preview ? 2 : null,
                                  overflow: widget.preview
                                      ? TextOverflow.ellipsis
                                      : null,
                                ),
                                if (widget.preview)
                                  const Spacer()
                                else
                                  const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      tooltip: 'Logbook',
                                      icon: const Icon(
                                        Icons.menu_book_outlined,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).push<void>(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  _ProjectLogbookPage(
                                                    projectName: project.name,
                                                    logbook: project.logbook,
                                                  ),
                                            ),
                                          ),
                                    ),
                                    IconButton(
                                      tooltip: 'Project overview',
                                      icon: const Icon(Icons.info_outline),
                                      onPressed: () =>
                                          Navigator.of(context).push<void>(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  _ProjectOverviewPage(
                                                    project: project,
                                                  ),
                                            ),
                                          ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'Project actions',
                                      onSelected: (action) async {
                                        if (action == 'toggle_complete') {
                                          widget.projects.update(
                                            project.withCompleted(
                                              !project.completed,
                                            ),
                                          );
                                        } else if (action == 'delete') {
                                          if (await _confirmDelete(
                                                context,
                                                project,
                                              ) &&
                                              mounted) {
                                            widget.projects.remove(project);
                                          }
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: 'toggle_complete',
                                          child: Text(
                                            project.isCompleted
                                                ? 'Mark as incomplete'
                                                : 'Mark as completed',
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete project'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProjectOverviewPage extends StatelessWidget {
  const _ProjectOverviewPage({required this.project});

  final Project project;

  Widget _info(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(value),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final entries = [...project.logbook.entries];
    entries.sort((a, b) {
      final order = b.date.compareTo(a.date);
      return order != 0
          ? order
          : project.logbook.entries
                .indexOf(a)
                .compareTo(project.logbook.entries.indexOf(b));
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Project Overview',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              project.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            _info(
              context,
              'Description',
              project.description.isEmpty
                  ? 'No description added.'
                  : project.description,
            ),
            _info(
              context,
              'Status',
              project.isCompleted ? 'Completed' : 'Incomplete',
            ),
            _info(context, 'Date range', _periodLabel(project)),
            _info(
              context,
              'Priority',
              project.importance == null
                  ? 'No priority selected'
                  : '${project.importance} out of 5',
            ),
            _info(
              context,
              'Category',
              project.category ?? 'No category selected',
            ),
            _info(context, 'Created', _formatDate(project.createdAt)),

            const SizedBox(height: 24),
            Text(
              'Recent logbook entries',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty) const Text('No logbook entries yet.'),
            for (final entry in entries.take(3))
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(entry.date),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(entry.text),
                      if (entry.image != null) ...[
                        const SizedBox(height: 8),
                        Image.memory(
                          entry.image!,
                          height: 160,
                          fit: BoxFit.contain,
                          errorBuilder: (_, error, stackTrace) =>
                              const Text('Image unavailable'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectDetailsPage extends StatefulWidget {
  const _ProjectDetailsPage({this.project, this.onDelete});

  final Project? project;
  final VoidCallback? onDelete;

  @override
  State<_ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<_ProjectDetailsPage> {
  late DateTimeRange? _period;
  late int? _importance;
  late String? _category;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String? _nameError;
  late final ProjectLogbook _logbook;
  late bool _completed;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.project?.description ?? '',
    );
    _period = widget.project?.period;
    _importance = widget.project?.importance;
    _category = widget.project?.category;
    _logbook = widget.project?.logbook ?? ProjectLogbook();
    _completed = widget.project?.completed ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter a project name.');
      return;
    }
    Navigator.of(context).pop(
      Project(
        name: name,
        id: widget.project?.id,
        description: _descriptionController.text.trim(),
        period: _period,
        importance: _importance,
        category: _category,
        createdAt: widget.project?.createdAt,
        logbook: _logbook,
        completed: _completed, // Reversible status is saved here!
      ),
    );
  }

  Future<void> _selectPeriod() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 100, 12, 31),
      initialDateRange: _period,
      helpText: 'Select project date range',
      saveText: 'Apply',
      confirmText: 'Apply',
    );
    if (!mounted || selected == null) return;
    setState(() => _period = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.project == null ? 'New project' : 'Edit project',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
        actions: [
          if (widget.project != null)
            IconButton(
              tooltip: 'Delete project',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (!await _confirmDelete(context, widget.project!) ||
                    !mounted) {
                  return;
                }
                widget.onDelete?.call();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Builder(
              builder: (context) {
                // --- FIX: The button now acts purely as a toggle that says "Mark as incomplete" if it's currently true ---
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    icon: Icon(
                      _completed
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                    ),
                    label: Text(
                      _completed ? 'Mark as incomplete' : 'Mark as completed',
                    ),
                    onPressed: () {
                      setState(() => _completed = !_completed);
                    },
                  ),
                );
              },
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Project name',
                hintText: 'What would you like to work on?',
                border: const OutlineInputBorder(),
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your project …',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Select date range'),
                subtitle: Text(
                  _periodLabel(Project(name: '', period: _period)),
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _selectPeriod,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _importance == null
                  ? 'Select priority'
                  : 'Priority: $_importance out of 5',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                for (var value = 1; value <= 5; value++)
                  ChoiceChip(
                    label: Text('$value'),
                    selected: _importance == value,
                    onSelected: (selected) =>
                        setState(() => _importance = selected ? value : null),
                  ),
              ],
            ),
            const Text('1 = less important · 5 = very important'),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _category,
              hint: const Text('Select category'),
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final category in _categories)
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Logbook'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => _ProjectLogbookPage(
                    projectName: _nameController.text.trim(),
                    logbook: _logbook,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Save'),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
