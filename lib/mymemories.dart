import 'dart:io';
import 'package:flutter/material.dart';
import 'localdb.dart'; 
import 'event.dart'; 
import 'proudy.dart'; // Make sure this matches your file name!
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';


class MyMemoriesPage extends StatefulWidget {
  final bool initialShowFavoritesOnly;
  const MyMemoriesPage({super.key,this.initialShowFavoritesOnly = false});

  @override
  State<MyMemoriesPage> createState() => _MyMemoriesPageState();
}

class _MyMemoriesPageState extends State<MyMemoriesPage> {
  List<Event> _events = [];
  bool _isLoading = true;

  // --- NEW: Filter State Variables ---
  bool _showFavoritesOnly = false;
  String _selectedCategory = 'All'; // 'All', 'Proud Moment', 'Memory', 'Other'
  final List<String> _categories = ['All', 'Proud Moment', 'Memory', 'Other'];

  @override
  void initState() {
    super.initState();
    _showFavoritesOnly = widget.initialShowFavoritesOnly;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final db = LocalDatabase();
    final events = await db.getAllEvents();
    
    setState(() {
      _events = events;
      _isLoading = false;
    });
  }

  // --- NEW: Dynamic Filter Logic ---
  // This computes the filtered list on the fly without deleting the original data
  List<Event> get _filteredEvents {
    return _events.where((event) {
      final matchesFavorite = _showFavoritesOnly ? event.isFavorite : true;
      final matchesCategory = _selectedCategory == 'All' ? true : event.type == _selectedCategory;
      
      return matchesFavorite && matchesCategory;
    }).toList();
  }
Widget _buildImageError() {
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
  }
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
    // Grab the filtered list to use in our UI
    final displayEvents = _filteredEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Memories', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : Column(
              children: [
                // 1. The Filter Bar
                _buildFilterBar(),
                
                // 2. The List (or Empty States)
                Expanded(
                  child: _events.isEmpty
                      ? _buildEmptyState() // Overall database is empty
                      : displayEvents.isEmpty
                          ? _buildNoResultsState() // Filters hid everything
                          : ListView.builder(
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40, top: 8),
                              itemCount: displayEvents.length,
                              itemBuilder: (context, index) {
                                return _buildEventCard(displayEvents[index]);
                              },
                            ),
                ),
              ],
            ),
    );
  }

  // --- NEW UI: The horizontal scrollable filter chips ---
  Widget _buildFilterBar() {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Favorites Toggle Chip
          FilterChip(
            label: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite, size: 16, color: Colors.redAccent),
                SizedBox(width: 4),
                Text('Favorites'),
              ],
            ),
            selected: _showFavoritesOnly,
            selectedColor: Colors.redAccent.withOpacity(0.2),
            checkmarkColor: Colors.redAccent,
            onSelected: (bool selected) {
              setState(() {
                _showFavoritesOnly = selected;
              });
            },
          ),
          const SizedBox(width: 12),
          
          // Vertical Divider
          Container(width: 1, height: 30, color: Colors.grey.shade700),
          const SizedBox(width: 12),

          // Category Chips
          ..._categories.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(category),
                selected: isSelected,
                selectedColor: category == 'All' 
                    ? Colors.grey.shade700 
                    : _getTypeColor(category).withOpacity(0.3),
                onSelected: (bool selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

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

  // --- NEW UI: State when filters hide everything ---
  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text(
            "No matching memories.",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 8),
          Text(
            "Try changing your filters.",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade900, 
      clipBehavior: Clip.antiAlias, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // 1. The Image (Only shows if a pictureUrl exists)
          if (event.pictureUrl != null && event.pictureUrl!.isNotEmpty)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 250, // Prevents tall photos from taking over the screen
                ),
                child: kIsWeb
                    ? (event.pictureUrl!.startsWith('base64:')
                        ? Image.memory(
                            base64Decode(event.pictureUrl!.substring(7)),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => _buildImageError(),
                          )
                        : Image.network(
                            event.pictureUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => _buildImageError(),
                          ))
                    : Image.file(
                        File(event.pictureUrl!),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => _buildImageError(),
                      ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
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
                        Text(
                          '${event.date.day}/${event.date.month}/${event.date.year}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                    
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (event.isFavorite)
                          const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                        
                        if (event.isFavorite)
                          const SizedBox(width: 8),

                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            final dataChanged = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProudyPage(existingEvent: event),
                              ),
                            );
                            
                            if (dataChanged == true) {
                              _loadEvents();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
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