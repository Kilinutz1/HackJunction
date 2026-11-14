import 'package:flutter/material.dart';
import 'proudy.dart';
import 'mymemories.dart';
import 'project.dart';
import 'remind.dart';
import 'streak.dart';
import 'app_theme.dart';

void main() {
  runApp(const HackathonApp());
}

class HackathonApp extends StatelessWidget {
  const HackathonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hackathon App',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) => ColoredBox(
        color: AppPalette.paper,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: child,
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

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
    if (buttonName == "favorites") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyMemoriesPage(initialShowFavoritesOnly: true),
        ),
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
          Padding(padding: EdgeInsets.only(right: 8), child: StreakBadge()),
        ],
      ),
      body: SafeArea(
        child: ListView(
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
            const RewindListWidget(),
            const SizedBox(height: 24),
            KahootButton(
              color: AppPalette.forest,
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
                    label: 'Favorites',
                    height: 112,
                    onTap: () => _handleTap(context, 'favorites'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KahootButton(
                    color: AppPalette.sage,
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
  final double? height; // Added height property

  const KahootButton({
    super.key,
    required this.color,
    required this.label,
    required this.onTap,
    this.height, // Allow it to be passed in
  });

  @override
  Widget build(BuildContext context) {
    final prominent = label == 'Add Memory';
    final foreground = prominent ? AppPalette.surface : AppPalette.ink;
    final icon = switch (label) {
      'Favorites' => Icons.favorite_border,
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
            color: prominent ? AppPalette.forest : AppPalette.line,
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
