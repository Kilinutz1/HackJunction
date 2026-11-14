import 'dart:io';
import 'package:flutter/material.dart';
import 'localdb.dart'; // Make sure this matches your file name
import 'event.dart'; // Make sure this matches your file name

class MyMemoriesPage extends StatefulWidget {
  const MyMemoriesPage({super.key});

  @override
  State<MyMemoriesPage> createState() => _MyMemoriesPageState();
}

class _MyMemoriesPageState extends State<MyMemoriesPage> {
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // Fetches events from your LocalDatabase
  Future<void> _loadEvents() async {
    final db = LocalDatabase();
    final events = await db.getAllEvents();
    
    setState(() {
      _events = events;
      _isLoading = false;
    });
  }

  // Helper to color-code the event types
  Color _getTypeColor(String type) {
    switch (type) {
      case 'Proud Moment':
        return Colors.orangeAccent;
      case 'Memory':
        return Colors.blueAccent;
      default:
        return Colors.tealAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Memories', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : _events.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40, top: 8),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return _buildEventCard(event);
                  },
                ),
    );
  }

  // --- UI: What shows up when there are no events yet ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text(
            "No memories yet.",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 8),
          Text(
            "Go back and add your first event!",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // --- UI: The beautiful card design for each event ---
  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade900, // Sleek dark card background
      clipBehavior: Clip.antiAlias, // Ensures the image respects the rounded corners
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. The Image (Only shows if a pictureUrl exists)
          if (event.pictureUrl != null && event.pictureUrl!.isNotEmpty)
            Image.file(
              File(event.pictureUrl!),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 120,
                  color: Colors.grey.shade800,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.grey, size: 40),
                      SizedBox(height: 8),
                      Text('Image missing', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Top Header (Category Chip, Date, and Heart)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Colorful Type Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getTypeColor(event.type).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _getTypeColor(event.type).withOpacity(0.5)),
                          ),
                          child: Text(
                            event.type,
                            style: TextStyle(
                              color: _getTypeColor(event.type),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Date Text
                        Text(
                          '${event.date.day}/${event.date.month}/${event.date.year}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                    // Favorite Heart
                    if (event.isFavorite)
                      const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 3. The Main Description
                Text(
                  event.description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}