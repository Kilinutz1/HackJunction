import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'localdb.dart';
import 'project_model.dart';

export 'project_model.dart';

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

  void _addEntry() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _textError = 'Please describe your progress.');
      return;
    }
    setState(() {
      widget.logbook.entries.insert(
        0,
        ProjectLogEntry(date: _date, text: text),
      );
      _textController.clear();
      _textError = null;
      _date = DateUtils.dateOnly(DateTime.now());
    });
    FocusScope.of(context).unfocus();
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
      appBar: AppBar(title: const Text('Logbook')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.projectName.isEmpty ? 'New project' : widget.projectName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
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
            FilledButton.icon(
              onPressed: _addEntry,
              icon: const Icon(Icons.add),
              label: const Text('Add entry'),
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
                      Text(
                        _formatDate(entry.date),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(entry.text),
                      if (entry.image != null) ...[
                        const SizedBox(height: 12),
                        Image.memory(
                          entry.image!,
                          height: 200,
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

class ProjectStore extends ValueNotifier<List<Project>> {
  ProjectStore({this.onSaveError}) : super([]);

  final VoidCallback? onSaveError;
  final LocalDatabase _db = LocalDatabase();
  bool _disposed = false;

  Future<void> load() async {
    final projects = await _db.getAllProjects();
    if (_disposed) return;
    value = projects;
    _bindLogbooks();
    completeExpired();
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
    completeExpired();
    unawaited(persist());
  }

  void update(Project project) {
    value = [
      for (final item in value)
        if (item.id == project.id) project else item,
    ];
    _bindLogbooks();
    completeExpired();
    unawaited(persist());
  }

  void remove(Project project) {
    project.logbook.onChanged = null;
    value = value.where((item) => item.id != project.id).toList();
    unawaited(persist());
  }

  void completeExpired([DateTime? now]) {
    final time = now ?? DateTime.now();
    if (!value.any(
      (project) => !project.completed && project.hasExpired(time),
    )) {
      return;
    }
    value = [
      for (final project in value)
        if (!project.completed && project.hasExpired(time))
          project.withCompleted(true)
        else
          project,
    ];
    _bindLogbooks();
    unawaited(persist());
  }

  Future<void> persist() => _db.saveProjects(value).catchError((Object error) {
    if (!_disposed) onSaveError?.call();
  });

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
          'Delete "${project.name}" and its images and logbook? This cannot be undone.',
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
  Timer? _expirationTimer;
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
    _scheduleExpirationCheck();
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

  void _scheduleExpirationCheck() {
    _expirationTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _expirationTimer = Timer(tomorrow.difference(now), () {
      _projects.completeExpired();
      _scheduleExpirationCheck();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _projects.completeExpired();
      _scheduleExpirationCheck();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _expirationTimer?.cancel();
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
          onCompleted: () => _projects.update(project.withCompleted(true)),
        ),
      ),
    );
    if (!mounted || updated == null) return;
    _projects.update(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
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
      appBar: AppBar(title: const Text('All projects')),
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: project.images.isEmpty
                              ? const Icon(Icons.folder_outlined)
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    project.images.first,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, error, stackTrace) =>
                                        const Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                          title: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name,
                                maxLines: widget.preview ? 1 : null,
                                overflow: widget.preview
                                    ? TextOverflow.ellipsis
                                    : null,
                              ),
                              if (project.isCompleted)
                                Text(
                                  'Completed',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${project.category ?? 'No category'} · '
                            '${project.importance == null ? 'No priority' : 'Priority ${project.importance}/5'}\n'
                            '${_periodLabel(project)}',
                            maxLines: widget.preview ? 2 : null,
                            overflow: widget.preview
                                ? TextOverflow.ellipsis
                                : null,
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Logbook',
                                icon: const Icon(Icons.menu_book_outlined),
                                onPressed: () =>
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute(
                                        builder: (_) => _ProjectLogbookPage(
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
                                        builder: (_) => _ProjectOverviewPage(
                                          project: project,
                                        ),
                                      ),
                                    ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Project actions',
                                onSelected: (action) async {
                                  if (action == 'complete') {
                                    widget.projects.update(
                                      project.withCompleted(true),
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
                                  if (!project.isCompleted)
                                    const PopupMenuItem(
                                      value: 'complete',
                                      child: Text('Mark as completed'),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete project'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => widget.onProjectTap(project),
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
      appBar: AppBar(title: const Text('Project overview')),
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
            Text('Images', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (project.images.isEmpty) const Text('No images added.'),
            for (final image in project.images)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Image.memory(
                  image,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stackTrace) =>
                      const Text('Image unavailable'),
                ),
              ),
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
  const _ProjectDetailsPage({this.project, this.onDelete, this.onCompleted});

  final Project? project;
  final VoidCallback? onDelete;
  final VoidCallback? onCompleted;

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
  late final List<Uint8List> _images;
  bool _isPickingImages = false;
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
    _images = [...?widget.project?.images];
    _logbook = widget.project?.logbook ?? ProjectLogbook();
    _completed = widget.project?.isCompleted ?? false;
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
        images: _images,
        logbook: _logbook,
        completed: _completed,
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

  Future<void> _pickImages() async {
    setState(() => _isPickingImages = true);
    try {
      final selected = await ImagePicker().pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      final images = await Future.wait(
        selected.map((image) => image.readAsBytes()),
      );
      if (!mounted) return;
      setState(() {
        _images.addAll(images);
        final addedAt = DateTime.now();
        for (final image in images) {
          _logbook.entries.insert(
            0,
            ProjectLogEntry(date: addedAt, text: 'Image added', image: image),
          );
        }
      });
      if (images.isNotEmpty) _logbook.onChanged?.call();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load images. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPickingImages = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project == null ? 'New project' : 'Edit project'),
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
                final expired =
                    _period != null &&
                    !DateTime.now().isBefore(
                      DateTime(
                        _period!.end.year,
                        _period!.end.month,
                        _period!.end.day + 1,
                      ),
                    );
                final completed = _completed || expired;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    icon: Icon(
                      completed
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                    ),
                    label: Text(completed ? 'Completed' : 'Mark as completed'),
                    onPressed: completed
                        ? null
                        : () {
                            setState(() => _completed = true);
                            widget.onCompleted?.call();
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
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isPickingImages ? null : _pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(_isPickingImages ? 'Loading images …' : 'Add images'),
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var index = 0; index < _images.length; index++)
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _images[index],
                              fit: BoxFit.contain,
                              errorBuilder: (_, error, stackTrace) =>
                                  const Center(
                                    child: Text('Image unavailable'),
                                  ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton.filled(
                              tooltip: 'Remove image',
                              onPressed: _isPickingImages
                                  ? null
                                  : () =>
                                        setState(() => _images.removeAt(index)),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
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
              onPressed: _isPickingImages ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
