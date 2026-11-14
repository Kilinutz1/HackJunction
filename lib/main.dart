import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'proudy.dart';
import 'mymemories.dart';
import 'project.dart';
import 'remind.dart';
import 'weekly_report.dart';
import 'weekly_report_data.dart';
import 'streak.dart';
import 'breath.dart';
import 'breathing_setup.dart';
import 'app_theme.dart';
import 'appearance.dart';
import 'streak_reminder.dart';

void main() {
  runApp(const HackathonApp());
}

class HackathonApp extends StatefulWidget {
  const HackathonApp({super.key});

  @override
  State<HackathonApp> createState() => _HackathonAppState();
}

class _HackathonAppState extends State<HackathonApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final reminder = StreakReminder(onWeeklyReport: _openWeeklyReport);
  late Future<void> _notificationStartup;
  Future<void>? _reportRoute;

  void _openWeeklyReport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _reportRoute != null) return;
      final start = reportWeekStart(DateTime.now());
      _reportRoute = _navigatorKey.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => WeeklyReportPage(
            initialWeek: DateTime(start.year, start.month, start.day - 7),
          ),
        ),
      );
      _reportRoute!.whenComplete(() => _reportRoute = null);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _waitForNotification() async {
    await _notificationStartup;
    // Let a cold-start notification route open before the daily exercise.
    await WidgetsBinding.instance.endOfFrame;
    await _reportRoute;
  }

  @override
  void initState() {
    super.initState();
    Appearance.load();
    _notificationStartup = reminder.start();
  }

  @override
  void dispose() {
    reminder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Color>(
    valueListenable: Appearance.accent,
    builder: (context, accent, _) => MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Hackathon App',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(accent: accent),
      builder: (context, child) => ColoredBox(
        color: AppPalette.paper,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: child,
          ),
        ),
      ),
      home: MainScreen(beforeDailyExercise: _waitForNotification),
    ),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.beforeDailyExercise});
  final Future<void> Function()? beforeDailyExercise;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _rewindKey = GlobalKey<RewindListWidgetState>();

  Future<void> _refreshDashboard() async {
    try {
      await _rewindKey.currentState?.refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not refresh your memories. Please try again.'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyVisit();
    });
  }

  Future<void> _checkDailyVisit() async {
    await widget.beforeDailyExercise?.call();
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = StreakService.dayKey(now);
    final lastVisit = prefs.getString('last_visit_date');

    if (lastVisit != todayStr) {
      if (!mounted) return;

      bool completedBreathe = false;

      // Die Endlos-Schleife gegen Schummler!
      // Wenn der Nutzer die Seite über "Zurück" verlässt, wird completedBreathe
      // nicht auf true gesetzt und die Seite öffnet sich sofort wieder.
      while (!completedBreathe && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BreatheScreen(
              durationInSeconds: 12, // Zeit absitzen!
              onComplete: () {
                completedBreathe = true; // Übung bestanden!
                StreakService().recordActivity();
                Navigator.pop(context);
              },
            ),
          ),
        );
      }

      // Erst speichern, wenn die Schleife besiegt wurde (Button geklickt).
      // Wer die App vorher killt, muss beim Neustart ran.
      await prefs.setString('last_visit_date', todayStr);
    }
  }

  void _handleTap(BuildContext context, String buttonName) {
    if (buttonName == 'projects') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProjectsPage()),
      );
    }
    if (buttonName == "Add") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProudyPage()),
      );
    }
    if (buttonName == "My Memories") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyMemoriesPage()),
      );
    }
    if (buttonName == "breath") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BreathingSetupPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MY PROUD SPACE',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [
          AppearanceMenu(),
          Padding(padding: EdgeInsets.only(right: 8), child: StreakBadge()),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const Row(
                children: [
                  Text(
                    'A LOOK BACK',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.muted,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 8),
              RewindListWidget(key: _rewindKey),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.auto_stories_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Your week, remembered'),
                  subtitle: const Text('A few good things to take with you'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WeeklyReportPage()),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              KahootButton(
                color: Theme.of(context).colorScheme.primary,
                label: 'Add Memory',
                height: 132,
                onTap: () => _handleTap(context, 'Add'),
              ),
              const SizedBox(height: 24),
              const Text(
                'YOUR COLLECTION',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.muted,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: KahootButton(
                      color: AppPalette.blush,
                      label: 'Breathing exercise',
                      height: 112,
                      onTap: () => _handleTap(context, 'breath'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KahootButton(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      label: 'Projects',
                      height: 112,
                      onTap: () => _handleTap(context, 'projects'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              KahootButton(
                color: AppPalette.surface,
                label: 'My Memories',
                height: 88,
                onTap: () => _handleTap(context, 'My Memories'),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// COMPONENT: Kahoot-style Action Button
// ---------------------------------------------------------
class KahootButton extends StatelessWidget {
  final Color color;
  final String label;
  final VoidCallback onTap;
  final double? height;

  const KahootButton({
    super.key,
    required this.color,
    required this.label,
    required this.onTap,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final prominent = label == 'Add Memory';
    final foreground = prominent ? AppPalette.surface : AppPalette.ink;
    final icon = switch (label) {
      'Breathing exercise' => Icons.air,
      'Projects' => Icons.flag_outlined,
      'My Memories' => Icons.auto_stories_outlined,
      _ => Icons.add,
    };
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height ?? 0),
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: prominent
                ? Theme.of(context).colorScheme.primary
                : AppPalette.line,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != 'My Memories')
                  Icon(icon, color: foreground, size: 24),
                Row(
                  children: [
                    if (label == 'My Memories') ...[
                      Icon(icon, color: foreground),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: prominent ? 24 : 17,
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_outward, size: 18, color: foreground),
                  ],
                ),
                if (prominent)
                  const Text(
                    'Keep a moment from today.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: Color(0xFFD9E4D8),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
