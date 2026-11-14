import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const storageKey = 'hackathon_active_days_v1';
  static final changes = ValueNotifier<int>(0);
  static Future<void>? _pendingWrite;

  static String dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<List<String>> getActiveDays() async {
    await _pendingWrite;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(storageKey) ?? [];
  }

  Future<void> recordActivity([DateTime? performedAt]) {
    // Use the actual local action date, independently of an entry's chosen date.
    final day = dayKey(performedAt ?? DateTime.now());
    final write = (_pendingWrite ?? Future<void>.value()).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final days = (prefs.getStringList(storageKey) ?? []).toSet();
      if (!days.add(day)) return;
      if (!await prefs.setStringList(storageKey, days.toList()..sort())) {
        throw StateError('Streak storage failed');
      }
      changes.value++;
    });
    final recovered = write.catchError((Object error) {});
    _pendingWrite = recovered;
    unawaited(
      recovered.then((_) {
        if (identical(_pendingWrite, recovered)) _pendingWrite = null;
      }),
    );
    return write;
  }
}

class StreakStats {
  StreakStats.fromDays(Iterable<String> days, DateTime now) {
    final today = DateTime.utc(now.year, now.month, now.day);
    // UTC is used only for calendar arithmetic, avoiding DST-related 23h days.
    final dates = <DateTime>{};
    for (final key in days) {
      final parsed = DateTime.tryParse(key);
      if (parsed == null || StreakService.dayKey(parsed) != key) continue;
      final day = DateTime.utc(parsed.year, parsed.month, parsed.day);
      if (!day.isAfter(today)) dates.add(day);
    }
    final ordered = dates.toList()..sort();
    activeDays = ordered.map(StreakService.dayKey).toSet();
    totalActiveDays = ordered.length;
    activeToday = dates.contains(today);
    firstActivity = ordered.isEmpty ? null : ordered.first;
    lastActivity = ordered.isEmpty ? null : ordered.last;

    var run = 0;
    var longestRun = 0;
    DateTime? previous;
    for (final day in ordered) {
      run = previous != null && day.difference(previous).inDays == 1
          ? run + 1
          : 1;
      if (run > longestRun) longestRun = run;
      previous = day;
    }

    longest = longestRun;
    var currentRun = 0;
    DateTime? start;
    if (ordered.isNotEmpty && today.difference(ordered.last).inDays <= 1) {
      var expected = ordered.last;
      for (final day in ordered.reversed) {
        if (day != expected) break;
        currentRun++;
        start = day;
        expected = expected.subtract(const Duration(days: 1));
      }
    }
    current = currentRun;
    currentStart = start;
  }

  late final Set<String> activeDays;
  late final int totalActiveDays;
  late final bool activeToday;
  late final DateTime? firstActivity;
  late final DateTime? lastActivity;
  late final int current;
  late final int longest;
  late final DateTime? currentStart;
}

String _displayDate(DateTime? date) => date == null
    ? '—'
    : '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.${date.year}';

class StreakBadge extends StatefulWidget {
  const StreakBadge({super.key});

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge> with WidgetsBindingObserver {
  final _stats = ValueNotifier<StreakStats?>(null);
  Timer? _midnightTimer;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    StreakService.changes.addListener(_refresh);
    _refresh();
    _scheduleRefresh();
  }

  Future<void> _refresh() async {
    try {
      final days = await StreakService().getActiveDays();
      if (!mounted) return;
      _stats.value = StreakStats.fromDays(days, DateTime.now());
      if (_failed) setState(() => _failed = false);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _scheduleRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    _midnightTimer = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        _refresh();
        _scheduleRefresh();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _scheduleRefresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    StreakService.changes.removeListener(_refresh);
    _midnightTimer?.cancel();
    _stats.dispose();
    super.dispose();
  }

  void _showOverview() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.8,
          child: ValueListenableBuilder<StreakStats?>(
            valueListenable: _stats,
            builder: (context, stats, _) {
              if (stats == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Your streak',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _detail(
                    'Current streak',
                    '${stats.current} ${stats.current == 1 ? 'day' : 'days'}',
                  ),
                  _detail(
                    'Longest streak',
                    '${stats.longest} ${stats.longest == 1 ? 'day' : 'days'}',
                  ),
                  _detail(
                    'Current streak started',
                    _displayDate(stats.currentStart),
                  ),
                  _detail('Last active', _displayDate(stats.lastActivity)),
                  _detail('First active', _displayDate(stats.firstActivity)),
                  _detail('Total active days', '${stats.totalActiveDays}'),
                  const SizedBox(height: 16),
                  Text(
                    stats.activeToday
                        ? 'You have already kept your streak going today!'
                        : stats.current > 0
                        ? 'Record an activity today to keep your streak going.'
                        : 'Record an activity today to start a new streak.',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Create a Memory or Proud Moment, start a new project, or add a project logbook entry. Each calendar day counts once. Editing existing content does not count.',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Wrap(
      spacing: 12,
      children: [
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(value),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return TextButton(onPressed: _refresh, child: const Text('Retry streak'));
    }
    return ValueListenableBuilder<StreakStats?>(
      valueListenable: _stats,
      builder: (context, stats, _) => TextButton.icon(
        key: const ValueKey('streak-badge'),
        onPressed: stats == null ? null : _showOverview,
        icon: const Icon(
          Icons.local_fire_department,
          size: 20,
          color: Colors.deepOrange,
        ),
        label: Text(
          stats == null ? '…' : '${stats.current} day streak',
          maxLines: 1,
        ),
      ),
    );
  }
}
