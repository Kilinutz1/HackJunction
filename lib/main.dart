import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Make sure this is imported

import 'proudy.dart';
import 'mymemories.dart';
import 'project.dart';
import 'remind.dart';
import 'streak.dart';
import 'breath.dart';

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
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.grey[200], 
      ),      
      home: const MainScreen(),
    );
  }
}

// 1. Changed to StatefulWidget to handle lifecycle and startup checks
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  @override
  void initState() {
    super.initState();
    // 2. Run the check right after the first frame builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyVisit();
    });
  }

  // 3. The logic to check if they visited today
  Future<void> _checkDailyVisit() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    // Using your existing dayKey format from StreakService
    final todayStr = StreakService.dayKey(now); 
    final lastVisit = prefs.getString('last_visit_date');

    if (lastVisit != todayStr) {
      // It's a new day! Save today's date so it doesn't trigger again today
      await prefs.setString('last_visit_date', todayStr);
      
      if (!mounted) return;

      // Force navigation to the breathe screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BreatheScreen(
            durationInSeconds: 12, // Set to however long you want them to breathe
            onComplete: () {
              // 4. Increase the streak when they finish breathing!
              StreakService().recordActivity(); 
              Navigator.pop(context);
            },
          ),
        ),
      );
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
        MaterialPageRoute(
          builder: (context) => ProudyPage(),
        ),
      );
    }
    if (buttonName == "My Memories") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyMemoriesPage(),
        ),
      );
    }
    if (buttonName == "breath") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BreatheScreen(
            durationInSeconds: 0, 
            onComplete: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: StreakBadge(),
          ),
        ],
        centerTitle: true,
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
        elevation: 0,
        title: const Text('My Proud Space', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // 1. The Scrollable Row of RemindWidgets
          RewindListWidget(),
          
          const SizedBox(height: 8),

          // 2. The Button Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, 
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: KahootButton(
                          height: 80, 
                          color: Colors.redAccent,
                          label: 'Breathing exercise',
                          onTap: () => _handleTap(context, 'breath'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: KahootButton(
                          height: 80,
                          color: Colors.blueAccent,
                          label: 'Projects',
                          onTap: () => _handleTap(context, 'projects'),
                        ),
                      ),
                    ],
                  ),
                
                  const SizedBox(height: 12), 
                  
                  KahootButton(
                    height: 200, 
                    color: Colors.orangeAccent,
                    label: 'Add Memory',
                    onTap: () => _handleTap(context, 'Add'),
                  ),
                  
                  const SizedBox(height: 12), 
                  
                  Expanded(
                    child: KahootButton(
                      color: Colors.greenAccent,
                      label: 'My Memories',
                      onTap: () => _handleTap(context, 'My Memories'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    return SizedBox(
      height: height, 
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}