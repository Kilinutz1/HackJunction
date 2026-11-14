import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'event.dart'; // Make sure this imports your Event class!

class LocalDatabase {
  // The secret key where all your events will be stored on the device
  static const String _storageKey = 'hackathon_events';

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
    await prefs.setStringList(_storageKey, dataToSave);
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
    int index = currentEvents.indexWhere((event) => event.id == updatedEvent.id);
    
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