import 'package:flutter/material.dart';
import 'proudy.dart';
import 'mymemories.dart';
import 'project.dart';
import 'remind.dart';

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
      scaffoldBackgroundColor: Colors.grey[200], // Change to any color you want
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
    if (buttonName=="Add"){
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProudyPage(),
        ),
      );
    }
    if (buttonName=="My Memories"){
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyMemoriesPage(),
        ),
      );
    }
    if (buttonName=="favorites"){
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
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                // This stretches the buttons horizontally to fill the screen width
                crossAxisAlignment: CrossAxisAlignment.stretch, 
                children: [
                  // Top Row: 2 Thin Split Buttons
                  Row(
                    children: [
                      Expanded(
                        child: KahootButton(
                          height: 80, // Set specific height here
                          color: Colors.redAccent,
                          label: 'Favorites',
                          onTap: () => _handleTap(context, 'favorites'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: KahootButton(
                          height: 80, // Set specific height here
                          color: Colors.blueAccent,
                          label: 'Projects',
                          onTap: () => _handleTap(context, 'projects'),
                        ),
                      ),
                    ],
                  ),
                
                  const SizedBox(height: 12), 
                  
                  // Middle Button: Given a specific height
                  KahootButton(
                    height: 200, // You can specify any exact Y-direction size here
                    color: Colors.orangeAccent,
                    label: 'Add Memory',
                    onTap: () => _handleTap(context, 'Add'),
                  ),
                  
                  const SizedBox(height: 12), 
                  
                  // Last Button: Wrapped in Expanded to fill up all remaining vertical space
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
    return SizedBox(
      height: height, // Applies the exact height if provided, otherwise fills space
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
