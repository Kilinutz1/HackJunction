import 'package:flutter/material.dart';

class BreatheScreen extends StatefulWidget {
  final VoidCallback onComplete; // Triggered when the user is done
  final int durationInSeconds; // Time required before they can continue

  const BreatheScreen({
    super.key,
    required this.onComplete,
    this.durationInSeconds = 0,
  });

  @override
  State<BreatheScreen> createState() => _BreatheScreenState();
}

class _BreatheScreenState extends State<BreatheScreen> with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _progressController;
  late Animation<double> _scaleAnimation;
  String _instruction = "Breathe In...";

  @override
  void initState() {
    super.initState();

    // 6 seconds to breathe in, 6 seconds to breathe out
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    // Progress timer for the button
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationInSeconds),
    );

    // Smooth ease in and out curve for natural breathing
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    // Listen to the animation changing directions to update the text
    _breatheController.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        if (mounted) setState(() => _instruction = "Breathe In...");
      } else if (status == AnimationStatus.reverse) {
        if (mounted) setState(() => _instruction = "Breathe Out...");
      }
    });

    // Start the endless breathing loop
    _breatheController.repeat(reverse: true);

    // Start the progress timer (if > 0)
    if (widget.durationInSeconds > 0) {
      _progressController.forward();
    } else {
      _progressController.value = 1.0; // Instantly complete if 0
    }
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade900,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text(
              "Let's center ourselves",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            // The Breathing Circle
            Center(
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.tealAccent.withOpacity(0.3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.tealAccent.withOpacity(0.5),
                            blurRadius: 50,
                            spreadRadius: 20 * _scaleAnimation.value,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.tealAccent,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // The Instruction Text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _instruction,
                key: ValueKey<String>(_instruction),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),

            // Continue Button (Fills up based on progress)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  final isReady = _progressController.isCompleted;
                  final progress = _progressController.value;

                  return Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white24, // Background of the unfilled button
                      borderRadius: BorderRadius.circular(28),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isReady ? widget.onComplete : null,
                        child: Stack(
                          children: [
                            // The filling color
                            FractionallySizedBox(
                              widthFactor: progress,
                              heightFactor: 1.0,
                              child: Container(
                                color: Colors.white,
                              ),
                            ),
                            // Button Text
                            Center(
                              child: Text(
                                "I'm present",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isReady 
                                      ? Colors.teal.shade900 
                                      : Colors.white54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}