import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';
import 'localdb.dart';
import 'event.dart';
import 'project.dart';
import 'package:flutter/material.dart'; // Needed for DateTimeRange
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

Future<void> seedDemoDataIfNeeded() async {
  Future<Uint8List?> loadAssetBytes(String path) async {
  try {
    final byteData = await rootBundle.load(path);
    return byteData.buffer.asUint8List();
  } catch (e) {
    return null; // Fails safely if the image is missing
  }
}
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('firstLaunch_rewind') ?? true;
  isFirstLaunch = false;
  if (isFirstLaunch) {
    final db = LocalDatabase();
    int z = 0;
    // --- INJECT DEMO MEMORIES ---
    // (Note: adjust 'addEvent' if your LocalDatabase uses a different 
    // method name like 'insertEvent' or 'saveEvent')
    final memoryDescriptions = [
      "Watching the sunset at the lake with friends and a campfire.",
      "Hiking up to the viewpoint and seeing the whole valley from above.",
      "A spontaneous road trip to the coast just to see the ocean.",
      "Having a massive picnic in the park under the old oak tree.",
      // "Biking through the forest trails on a crisp autumn morning.",
      // "Skipping rocks at the river while eating ice cream.",
      // "Catching the golden hour light during our walk through the botanical gardens.",
      // "Finding that hidden waterfall after a two-hour hike.",
      // "Laying on the grass and stargazing on a perfectly clear, warm night.",
      // "Getting caught in a sudden summer rainstorm and laughing the whole way home.",
      // "Early morning coffee outside on the porch, just listening to the birds.",
      // "Picking fresh apples at the orchard with the whole group.",
      // "Taking a small boat out on the water and just drifting for hours.",
      // "Watching the city lights slowly turn on from the hill outside of town.",
      // "A perfect beach day, reading a book while hearing the waves crash.",
      // "Exploring a new trail and finding a beautiful meadow full of wildflowers.",
      // "Grilling outside with friends while the sun slowly went down.",
      // "Walking along the misty forest path early on a Sunday morning.",
      // "Driving with the windows down and the music up on a scenic country road.",
      // "Sitting on the wooden pier, dangling our feet over the water and talking for hours."
    ];
      List<Event> allDemoEvents = [];

    for (int i = 0; i< memoryDescriptions.length; i++){
      final bytes = await loadAssetBytes('assets/junction_bilder/junction${z++}.png');
      final base64Image = bytes != null ? 'base64:${base64Encode(bytes)}' : null;
      allDemoEvents.add(Event(
      id: 'demo_mem_$i',
      type: 'Memory',
      description: memoryDescriptions[i],
      date: DateTime.now().subtract(Duration(days: i)),
      isFavorite: i%3==1,
      pictureUrl: base64Image

    ));
    }
    z = 20;

    final proudDescriptions = [
     "Finally managed to run a full 5K without stopping once.",
     "Cooked a complex three-course dinner over the campfire.",
      "Fixed my broken bike chain all by myself on the trail.",
      // "Woke up at 5 AM just to hike up and catch the sunrise.",
      // "Successfully navigated the backcountry trail using only a map.",
      // "Pushed past my fear and jumped off the high cliff into the lake.",
      // "Identified 5 different types of wild mushrooms on our walk.",
      // "Carried the heaviest backpack for the last two miles to help a friend.",
      // "Pitched the tent completely perfectly in under 5 minutes.",
      // "Climbed the steepest part of the hill without needing to take a break."
    ];
  final now = DateTime.now();
    for (int i = 0; i < proudDescriptions.length; i++) {
      final bytes = await loadAssetBytes('assets/junction_bilder/junction${z++}.png');
      final base64Image = bytes != null ? 'base64:${base64Encode(bytes)}' : null;
       allDemoEvents.add(Event(
        id: 'demo_proud_$i',
        type: 'Proud Moment',
        description: proudDescriptions[i],
        // Spaced out every 2 days: 0, 2, 4, 6... up to 18 days ago
        date: now.subtract(Duration(days: i * 2)),
        // Make every other proud moment a favorite
        isFavorite: i % 2 == 0, 
        pictureUrl: base64Image
      ));
    }
    z=30;
    final otherDescriptions = [
      "Bought a new pair of hiking boots for the upcoming season.",
      //"It rained heavily all afternoon, so we just played cards inside."
    ];

    for (int i = 0; i < otherDescriptions.length; i++) {
      final bytes = await loadAssetBytes('assets/junction_bilder/junction${z++}.png');
      final base64Image = bytes != null ? 'base64:${base64Encode(bytes)}' : null;
      allDemoEvents.add(Event(
        id: 'demo_other_$i',
        type: 'Other', // Matches your "Other" category in the filter
        description: otherDescriptions[i],
        // Spaces them out: 3 days ago and 10 days ago
        date: now.subtract(Duration(days: (i * 7) + 3)),
        isFavorite: false, 
          pictureUrl: base64Image

      ));
    }
    
  await db.addEventsBulk(allDemoEvents);
    // --- 5. GENERATE PROJECTS ---
  final projectStore = ProjectStore();
  await projectStore.load();

  // Only inject if the project store is completely empty
  if (projectStore.value.isEmpty) {
    // Helper function to load asset images into bytes for the logbook
  
    // Project 1: Sports (Marathon Training) - 4 Entries
    final sportsProject = Project(
    id: 'demo_proj_sports',
    name: 'Half-Marathon Training',
    description: 'Training program for the upcoming city half-marathon.',
    category: 'Sports',
    importance: 4,
    createdAt: now.subtract(const Duration(days: 30)),
    period: DateTimeRange(
      start: now.subtract(const Duration(days: 20)),
      end: now.add(const Duration(days: 40)),
    ),
    logbook: ProjectLogbook([
      ProjectLogEntry(
        id: 'entry_s1',
        text: 'Bought new running shoes and registered for the race!',
        date: now.subtract(const Duration(days: 15)),
      image: await loadAssetBytes('assets/junction_bilder/s3junction.png'),
      ),
      ProjectLogEntry(
        id: 'entry_s2',
        text: 'First 5K run completed! Legs are sore but feels amazing.',
        date: now.subtract(const Duration(days: 10)),
        image: await loadAssetBytes('assets/junction_bilder/s2junction.png'),
      ),
      // ProjectLogEntry(
      //   id: 'entry_s3',
      //   text: '10K milestone reached. Breathing technique is getting much better.',
      //   date: now.subtract(const Duration(days: 5)),
      //   image: await loadAssetBytes('assets/junction_bilder/s1junction.png'),
      // ),
      // ProjectLogEntry(
      //   id: 'entry_s4',
      //   text: 'Ran 15K today! The race is actually starting to look possible.',
      //   date: now.subtract(const Duration(days: 1)),
      //   image: await loadAssetBytes('assets/junction_bilder/g4junction.png'),
      // ),
    ]),
  );

  // Project 2: Music (Learning Guitar) - 3 Entries
  final musicProject = Project(
    id: 'demo_proj_music',
    name: 'Learning Guitar',
    description: 'Goal: Be able to play 3 songs around the campfire.',
    category: 'Hobbies',
    importance: 3,
    createdAt: now.subtract(const Duration(days: 45)),
    period: DateTimeRange(
      start: now.subtract(const Duration(days: 15)),
      end: now.add(const Duration(days: 90)),
    ),
    logbook: ProjectLogbook([
      ProjectLogEntry(
        id: 'entry_m1',
        text: 'Bought a beautiful acoustic guitar. My fingertips hurt so much already.',
        date: now.subtract(const Duration(days: 12)),
        image: await loadAssetBytes('assets/junction_bilder/g3junction.png'),
      ),
      ProjectLogEntry(
        id: 'entry_m2',
        text: 'Learned the basic chords: G, C, D, and Em. Transitioning is so slow.',
        date: now.subtract(const Duration(days: 7)),
        image: await loadAssetBytes('assets/junction_bilder/g2junction.png'),
      ),
      ProjectLogEntry(
        id: 'entry_m3',
        text: 'Finally played my first full song without stopping! Sounds decent.',
        date: now.subtract(const Duration(days: 2)),
        image: await loadAssetBytes('assets/junction_bilder/g1junction.png'),
      ),
    ]),
  );

  // Add to store and trigger the save
  projectStore.add(sportsProject);
  projectStore.add(musicProject);
  
  // Wait for it to write to SharedPreferences
  await projectStore.persist();
}
    // Mark that this user has received the demo data
    await prefs.setBool('firstLaunch_rewind', false);
  }
  
}