import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyVisit();
    });
  }

  Future<void> _checkDailyVisit() async {
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
      // Wieder dein sauberes, originales Layout ohne das Refresh-Chaos
      body: Column(
        children: [
          RewindListWidget(),
          
          const SizedBox(height: 8),

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