import 'package:flutter/material.dart';
import 'add.dart';

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
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TexttInput(),
      ),
    );
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
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: 10,
              itemBuilder: (context, index) {
                return RemindWidget(index: index);
              },
            ),
          ),
          
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
// COMPONENT: Stateless RemindWidget
// ---------------------------------------------------------
class RemindWidget extends StatelessWidget {
  final int index;
  
  const RemindWidget({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 117, 113, 113),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'Task\n${index + 1}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w500),
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