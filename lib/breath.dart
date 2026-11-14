import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class BreatheScreen extends StatefulWidget {
  final VoidCallback onComplete; // Triggered when the user is done
  final bool timedSession;
  final bool withMusic;
  final int durationInSeconds; // Time required before they can continue

  const BreatheScreen({
    super.key,
    required this.onComplete,
    this.durationInSeconds = 0,
    this.timedSession = false,
    this.withMusic = false,
  });

  @override
  State<BreatheScreen> createState() => _BreatheScreenState();
}

class _BreatheScreenState extends State<BreatheScreen>
    with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _progressController;
  late Animation<double> _scaleAnimation;
  String _instruction = "Breathe In...";
  AudioPlayer? _music;
  Future<void> _musicStart = Future.value();
  bool _musicStopped = false;

  Future<void> _startMusic(AudioPlayer player) async {
    try {
      await player.setReleaseMode(ReleaseMode.loop);
      if (_musicStopped || !mounted) return;
      await player.play(AssetSource('lofty.m4a'));
    } catch (error) {
      debugPrint('Could not play breathing music: $error');
      if (mounted && !_musicStopped) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Music could not be played. Your exercise will continue without it.',
            ),
          ),
        );
      }
    }
  }

  void _stopMusic() {
    if (_musicStopped) return;
    _musicStopped = true;
    final player = _music;
    if (player == null) return;
    // Wait for any pending start before disposal so a late load cannot restart audio.
    unawaited(
      _musicStart.then((_) => player.dispose()).catchError((Object error) {
        debugPrint('Could not release breathing music: $error');
      }),
    );
  }

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

    if (widget.timedSession) {
      _progressController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _breatheController.stop();
          _stopMusic();
          if (mounted) widget.onComplete();
        }
      });
    }

    if (widget.timedSession && widget.withMusic) {
      final player = AudioPlayer();
      _music = player;
      _musicStart = _startMusic(player);
    }

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
    _stopMusic();
    _breatheController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: widget.timedSession
          ? AppBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              title: const Text('Breathing exercise'),
            )
          : null,
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
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.3),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer.withOpacity(0.5),
                            blurRadius: 50,
                            spreadRadius: 20 * _scaleAnimation.value,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
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

            if (widget.timedSession)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, _) {
                    final remaining =
                        (widget.durationInSeconds *
                                (1 - _progressController.value))
                            .ceil();
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')} remaining',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          key: const ValueKey('breathing-progress'),
                          value: _progressController.value,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                          semanticsLabel: 'Session progress',
                        ),
                      ],
                    );
                  },
                ),
              )
            else
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
                        color:
                            Colors.white24, // Background of the unfilled button
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
                                child: Container(color: Colors.white),
                              ),
                              // Button Text
                              Center(
                                child: Text(
                                  "I'm present",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isReady
                                        ? Theme.of(context).colorScheme.primary
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
