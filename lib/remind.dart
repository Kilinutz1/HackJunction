import 'app_theme.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'localdb.dart';
import 'event.dart';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'project.dart';

// ---------------------------------------------------------
// 1. THE LIST WIDGET (The Horizontal Dashboard Cards)
// ---------------------------------------------------------
class RewindListWidget extends StatefulWidget {
  const RewindListWidget({super.key});

  @override
  State<RewindListWidget> createState() => RewindListWidgetState();
}

class RewindListWidgetState extends State<RewindListWidget> {
  Map<String, List<Event>> _groupedEvents = {};
  bool _isLoading = true;
  Future<void>? _pendingLoad;

  Future<void> refresh() =>
      _pendingLoad ??= _loadEvents().whenComplete(() => _pendingLoad = null);

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> _loadEvents() async {
    final db = LocalDatabase();
    final allEvents = await db.getAllEvents();

    // 1. Separate all normal events into our two main categories
    final memoryEvents = allEvents.where((e) => e.type == 'Memory').toList();
    final proudEvents = allEvents
        .where((e) => e.type == 'Proud Moment')
        .toList();

    // 2. Run our custom algorithm on both normal buckets
    final Map<String, List<Event>> finalGroups = {};

    final finalMemories = _generateRandomBucket(memoryEvents);
    if (finalMemories.isNotEmpty) {
      finalGroups['Memory'] = finalMemories;
    }

    final finalProud = _generateRandomBucket(proudEvents);
    if (finalProud.isNotEmpty) {
      finalGroups['Proud Moment'] = finalProud;
    }

    // --- NEW: 3rd BUCKET (PROJECT SPOTLIGHT) ---
    final projectStore = ProjectStore();
    await projectStore.load(); // Fetch from SharedPreferences

    final random = Random();

    // 1. Filter: Finde alle Projekte, die mindestens einen Logbuch-Eintrag haben
    final eligibleProjects = projectStore.value
        .where((p) => p.logbook.entries.isNotEmpty)
        .toList();

    if (eligibleProjects.isNotEmpty) {
      // 2. Wähle EIN zufälliges Projekt aus
      final selectedProject = eligibleProjects[random.nextInt(eligibleProjects.length)];

      List<Event> projectEvents = [];

      // 3. Sortiere die Einträge dieses Projekts chronologisch (alt nach neu),
      // damit die Story einen echten Fortschritt zeigt!
      final sortedEntries = selectedProject.logbook.entries.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // 4. Wandle sie in Events um
      for (var entry in sortedEntries) {
        projectEvents.add(
          Event(
            id: entry.id, 
            type: 'Project Spotlight',
            // Zeigt den Projektnamen + den Text des Eintrags an
            description: '${selectedProject.name}:\n${entry.text}',
            date: entry.date,
            isFavorite: true,
            pictureUrl: entry.image != null
                ? 'base64:${base64Encode(entry.image!)}'
                : null,
          ),
        );
      }

      // Nimm maximal 10 Einträge (damit die Story nicht endlos wird) und füge sie hinzu
      if (projectEvents.isNotEmpty) {
        finalGroups['Project Spotlight'] = projectEvents.take(10).toList();
      }
    }
    
    projectStore.dispose();
    // ------------------------------------------
    
    if (!mounted) return;

    setState(() {
      _groupedEvents = finalGroups;
      _isLoading = false;
    });
  }

  // --- THE CUSTOM RANDOMIZER ALGORITHM ---
  List<Event> _generateRandomBucket(List<Event> categoryEvents) {
    if (categoryEvents.isEmpty) return [];

    final random = Random();

    final sizeOptions = [1, 1, 1, 2, 2, 3, 4, 5];
    int targetSize = sizeOptions[random.nextInt(sizeOptions.length)];

    List<Event> likedEvents = categoryEvents
        .where((e) => e.isFavorite)
        .toList();
    List<Event> unlikedEvents = categoryEvents
        .where((e) => !e.isFavorite)
        .toList();

    likedEvents.shuffle(random);
    unlikedEvents.shuffle(random);

    List<Event> bucket = [];

    int targetLiked = (targetSize / 2).ceil();
    int targetUnliked = targetSize - targetLiked;

    int takenLiked = min(targetLiked, likedEvents.length);
    bucket.addAll(likedEvents.take(takenLiked));

    int takenUnliked = min(targetSize - takenLiked, unlikedEvents.length);
    bucket.addAll(unlikedEvents.take(takenUnliked));

    if (bucket.length < targetSize && likedEvents.length > takenLiked) {
      int extraNeeded = targetSize - bucket.length;
      bucket.addAll(likedEvents.skip(takenLiked).take(extraNeeded));
    }

    bucket.shuffle(random);
    return bucket;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 132,
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (_groupedEvents.isEmpty) {
      return SizedBox(
        height: 132,
        child: Center(
          child: Text(
            "Add some events to see your Rewind!",
            style: TextStyle(fontFamily: 'Roboto', color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 132,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        itemCount: _groupedEvents.keys.length,
        itemBuilder: (context, index) {
          final type = _groupedEvents.keys.elementAt(index);
          final eventsList = _groupedEvents[type]!;

          final musicTrack = type == 'Proud Moment' ? 'funky.m4a' : 'lofty.m4a';

          return SingleRewindWidget(
            title: type,
            events: eventsList,
            musicTrack: musicTrack,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------
// 2. THE SINGLE WIDGET (The Card on the Dashboard)
// ---------------------------------------------------------
class SingleRewindWidget extends StatelessWidget {
  final String title;
  final List<Event> events;
  final String musicTrack;

  const SingleRewindWidget({
    super.key,
    required this.title,
    required this.events,
    required this.musicTrack,
  });

  @override
  Widget build(BuildContext context) {
    final coverEvent = events.firstWhere(
      (e) => e.pictureUrl != null && e.pictureUrl!.isNotEmpty,
      orElse: () => events.first,
    );
    final hasPicture =
        coverEvent.pictureUrl != null && coverEvent.pictureUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryViewerScreen(
              title: title,
              events: events,
              musicTrack: musicTrack,
            ),
          ),
        );
      },
      child: Container(
        width: 148,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.primary,
          boxShadow: const [
            BoxShadow(
              color: Colors.transparent,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPicture)
              // --- FIX: ZUERST prüfen, ob es Base64 ist, EGAL ob Web oder Handy ---
              coverEvent.pictureUrl!.startsWith('base64:')
                  ? Image.memory(
                      base64Decode(coverEvent.pictureUrl!.substring(7)),
                      fit: BoxFit.cover,
                    )
                  : (kIsWeb
                      ? Image.network(
                          coverEvent.pictureUrl!,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(coverEvent.pictureUrl!),
                          fit: BoxFit.cover,
                        ))
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      AppPalette.ink,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

            Container(color: Colors.black45),

            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 3. THE FULL SCREEN STORY VIEWER (Instagram Style)
// ---------------------------------------------------------
class StoryViewerScreen extends StatefulWidget {
  final String title;
  final List<Event> events;
  final String musicTrack;

  const StoryViewerScreen({
    super.key,
    required this.title,
    required this.events,
    required this.musicTrack,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  int _currentIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startMusic();
  }

  Future<void> _startMusic() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource(widget.musicTrack));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onTap(TapUpDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;

    if (dx < screenWidth / 3) {
      setState(() {
        if (_currentIndex > 0) {
          _currentIndex--;
        }
      });
    } else {
      setState(() {
        if (_currentIndex < widget.events.length - 1) {
          _currentIndex++;
        } else {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEvent = widget.events[_currentIndex];
    final hasPicture =
        currentEvent.pictureUrl != null && currentEvent.pictureUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: _onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: SizedBox(
                key: ValueKey<String>(currentEvent.id),
                width: double.infinity,
                height: double.infinity,
                child: hasPicture
                    // --- FIX: Auch hier die Reihenfolge der Überprüfung angepasst ---
                    ? (currentEvent.pictureUrl!.startsWith('base64:')
                        ? Image.memory(
                            base64Decode(currentEvent.pictureUrl!.substring(7)),
                            fit: BoxFit.contain,
                          )
                        : (kIsWeb
                            ? Image.network(
                                currentEvent.pictureUrl!,
                                fit: BoxFit.contain,
                              )
                            : Image.file(
                                File(currentEvent.pictureUrl!),
                                fit: BoxFit.contain,
                              )))
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              AppPalette.ink,
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                        ),
                      ),
              ),
            ),

            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent, Colors.black87],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            Positioned(
              top: 40,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(
                  widget.events.length,
                  (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentIndex
                            ? Colors.white
                            : Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 55,
              left: 16,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Column(
                  key: ValueKey<String>("text_${currentEvent.id}"),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentEvent.description,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currentEvent.date.day}/${currentEvent.date.month}/${currentEvent.date.year}',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
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