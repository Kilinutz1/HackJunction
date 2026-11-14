import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'event.dart'; // Make sure this imports your Event class!
import 'project_model.dart';
import 'streak.dart';

class LocalDatabase {
  // The secret key where all your events will be stored on the device
  static const String _storageKey = 'hackathon_events';
  // Keep the existing key so previously saved projects remain available.
  static const String projectsStorageKey = 'hackathon_projects_v1';
  static Future<void>? _projectWrites;

  List<Project> _decodeProjects(String? saved) => saved == null
      ? []
      : (jsonDecode(saved) as List)
            .map(
              (item) =>
                  Project.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();

  Future<List<Project>> getAllProjects() async {
    await _projectWrites;
    final prefs = await SharedPreferences.getInstance();
    return _decodeProjects(prefs.getString(projectsStorageKey));
  }

  Future<void> saveProjects(List<Project> projects) {
    // Snapshot immediately, then serialize writes across page instances.
    final snapshot = jsonEncode(
      projects.map((project) => project.toJson()).toList(),
    );
    final write = (_projectWrites ?? Future<void>.value()).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final previous = _decodeProjects(prefs.getString(projectsStorageKey));
      final next = _decodeProjects(snapshot);
      final oldById = {for (final project in previous) project.id: project};
      final hasActivity = next.any((project) {
        final old = oldById[project.id];
        return old == null ||
            project.logbook.entries.length > old.logbook.entries.length;
      });
      if (!await prefs.setString(projectsStorageKey, snapshot)) {
        throw StateError('Project storage failed');
      }
      if (hasActivity) await StreakService().recordActivity();
    });
    // Failed writes must not block later saves or reads.
    final recovered = write.catchError((Object error) {});
    _projectWrites = recovered;
    unawaited(
      recovered.then((_) {
        if (identical(_projectWrites, recovered)) _projectWrites = null;
      }),
    );
    return write;
  }

  // 1. GET ALL EVENTS
  Future<List<Event>> getAllEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedData = prefs.getStringList(_storageKey);

    // If the database is completely empty, return an empty list
    if (savedData == null) {
      return [];
    }

    // Convert the saved JSON strings back into usable Event objects
    return savedData.map((item) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      return Event.fromJson(decoded);
    }).toList();
  }

  // 2. ADD AN EVENT
  Future<void> addEvent(Event newEvent) async {
    final prefs = await SharedPreferences.getInstance();

    // Fetch the current list first
    List<Event> currentEvents = await getAllEvents();

    // Insert the new event at the very top of the list
    currentEvents.insert(0, newEvent);

    // Convert the whole list back into JSON strings
    List<String> dataToSave = currentEvents
        .map((event) => jsonEncode(event.toJson()))
        .toList();

    // Overwrite the old database with the new updated list
    if (!await prefs.setStringList(_storageKey, dataToSave)) {
      throw StateError('Event storage failed');
    }
    if (newEvent.type == 'Memory' || newEvent.type == 'Proud Moment') {
      await StreakService().recordActivity();
    }
  }

  // 3. DELETE AN EVENT
  Future<void> deleteEvent(String eventId) async {
    final prefs = await SharedPreferences.getInstance();

    List<Event> currentEvents = await getAllEvents();

    // Find the event with the matching ID and remove it from the list
    currentEvents.removeWhere((event) => event.id == eventId);

    // Convert the remaining events back to JSON strings
    List<String> dataToSave = currentEvents
        .map((event) => jsonEncode(event.toJson()))
        .toList();

    // Save the updated list back to the device
    await prefs.setStringList(_storageKey, dataToSave);
  }

  Future<void> updateEvent(Event updatedEvent) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Fetch the current list
    List<Event> currentEvents = await getAllEvents();

    // 2. Find the exact position (index) of the event we want to change
    int index = currentEvents.indexWhere(
      (event) => event.id == updatedEvent.id,
    );

    // If we found it (index is not -1)
    if (index != -1) {
      // 3. Swap the old event with the newly updated one
      currentEvents[index] = updatedEvent;

      // 4. Convert and save the whole list back
      List<String> dataToSave = currentEvents
          .map((event) => jsonEncode(event.toJson()))
          .toList();

      await prefs.setStringList(_storageKey, dataToSave);
    }
  }
}
