import 'app_theme.dart';
import 'dart:io';
import 'dart:math'; // NEW: Required for our randomizer logic
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'localdb.dart';
import 'event.dart';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

// ---------------------------------------------------------
// 1. THE LIST WIDGET (The Horizontal Dashboard Cards)
// ---------------------------------------------------------
class RewindListWidget extends StatefulWidget {
  const RewindListWidget({super.key});

  @override
  State<RewindListWidget> createState() => _RewindListWidgetState();
}

class _RewindListWidgetState extends State<RewindListWidget> {
  Map<String, List<Event>> _groupedEvents = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final db = LocalDatabase();
    final allEvents = await db.getAllEvents();

    // 1. Separate all events into our two main categories
    final memoryEvents = allEvents.where((e) => e.type == 'Memory').toList();
    final proudEvents = allEvents
        .where((e) => e.type == 'Proud Moment')
        .toList();

    // 2. Run our custom algorithm on both buckets
    final Map<String, List<Event>> finalGroups = {};

    final finalMemories = _generateRandomBucket(memoryEvents);
    if (finalMemories.isNotEmpty) {
      finalGroups['Memory'] = finalMemories;
    }

    final finalProud = _generateRandomBucket(proudEvents);
    if (finalProud.isNotEmpty) {
      finalGroups['Proud Moment'] = finalProud;
    }

    setState(() {
      _groupedEvents = finalGroups;
      _isLoading = false;
    });
  }

  // --- THE CUSTOM RANDOMIZER ALGORITHM ---
  List<Event> _generateRandomBucket(List<Event> categoryEvents) {
    if (categoryEvents.isEmpty) return [];

    final random = Random();

    // The specific random sizes you requested
    final sizeOptions = [1, 1, 1, 2, 2, 3, 4, 5];
    int targetSize = sizeOptions[random.nextInt(sizeOptions.length)];

    // Separate into liked and unliked buckets
    List<Event> likedEvents = categoryEvents
        .where((e) => e.isFavorite)
        .toList();
    List<Event> unlikedEvents = categoryEvents
        .where((e) => !e.isFavorite)
        .toList();

    // Shuffle both pools so we get different pictures on every refresh
    likedEvents.shuffle(random);
    unlikedEvents.shuffle(random);

    List<Event> bucket = [];

    // Calculate how many of each we need (Roughly 50/50)
    int targetLiked = (targetSize / 2).ceil();
    int targetUnliked = targetSize - targetLiked;

    // 1. Try to take the liked events
    int takenLiked = min(targetLiked, likedEvents.length);
    bucket.addAll(likedEvents.take(takenLiked));

    // 2. Try to take the unliked events
    int takenUnliked = min(targetSize - takenLiked, unlikedEvents.length);
    bucket.addAll(unlikedEvents.take(takenUnliked));

    // 3. Fallback: If we didn't have enough unliked events to reach the target size,
    // fill the remaining slots with extra liked events (if we have any left)
    if (bucket.length < targetSize && likedEvents.length > takenLiked) {
      int extraNeeded = targetSize - bucket.length;
      bucket.addAll(likedEvents.skip(takenLiked).take(extraNeeded));
    }

    // Finally, shuffle the resulting bucket so the liked/unliked events are in a random order!
    bucket.shuffle(random);

    return bucket;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 132,
        child: Center(
          child: CircularProgressIndicator(color: AppPalette.forest),
        ),
      );
    }

    if (_groupedEvents.isEmpty) {
      return const SizedBox(
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

          // Assign simulated music track
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

// ... The rest of the file (SingleRewindWidget and StoryViewerScreen) stays exactly the same!

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
    // Try to find an event with a picture to use as the cover image
    final coverEvent = events.firstWhere(
      (e) => e.pictureUrl != null && e.pictureUrl!.isNotEmpty,
      orElse: () => events.first,
    );
    final hasPicture =
        coverEvent.pictureUrl != null && coverEvent.pictureUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        // Open the full-screen story viewer!
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
          color: AppPalette.forest,
          boxShadow: [
            BoxShadow(
              color: Colors.transparent,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background: Picture or Gradient
            if (hasPicture)
              kIsWeb
                  ? (coverEvent.pictureUrl!.startsWith('base64:')
                        ? Image.memory(
                            base64Decode(coverEvent.pictureUrl!.substring(7)),
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            coverEvent.pictureUrl!,
                            fit: BoxFit.cover,
                          ))
                  : Image.file(File(coverEvent.pictureUrl!), fit: BoxFit.cover)
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppPalette.forest, AppPalette.ink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

            // Dark overlay for text readability
            Container(color: Colors.black45),

            // Title Text
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

  // 1. Create the Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startMusic();
  }

  // 2. Play the music!
  Future<void> _startMusic() async {
    // Tell the player to loop the song seamlessly
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);

    // Play the specific track passed in from the RewindListWidget
    // Note: AssetSource automatically looks inside the 'assets' folder!
    await _audioPlayer.play(AssetSource(widget.musicTrack));
  }

  // 3. Stop the music when the user closes the story
  @override
  void dispose() {
    _audioPlayer.dispose(); // Kills the audio instantly
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
          Navigator.pop(
            context,
          ); // Closes story (which triggers dispose() and stops music)
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
            // 1. The Background
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: SizedBox(
                key: ValueKey<String>(currentEvent.id),
                width: double.infinity,
                height: double.infinity,
                child: hasPicture
                    ? (kIsWeb
                          ? (currentEvent.pictureUrl!.startsWith('base64:')
                                ? Image.memory(
                                    base64Decode(
                                      currentEvent.pictureUrl!.substring(7),
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    currentEvent.pictureUrl!,
                                    fit: BoxFit.cover,
                                  ))
                          : Image.file(
                              File(currentEvent.pictureUrl!),
                              fit: BoxFit.cover,
                            ))
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppPalette.forest, AppPalette.ink],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                        ),
                      ),
              ),
            ),

            // 2. Dark Overlay
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

            // 3. Story Bars
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

            // 4. Header
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

            // 5. Text
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
