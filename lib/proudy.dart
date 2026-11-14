import 'dart:io'; // Needed for File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // NEW: Image Picker
import 'localdb.dart';
import 'event.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProudyPage extends StatefulWidget {
  final Event? existingEvent; 

  const ProudyPage({super.key, this.existingEvent});

  @override
  State<ProudyPage> createState() => _ProudyPageState();
}

class _ProudyPageState extends State<ProudyPage> {
  // --- STATE VARIABLES ---
  bool _isFavorite = false; 
  String _selectedType = 'Proud Moment'; 
  DateTime _selectedDate = DateTime.now(); 
  String? _selectedImagePath; // NEW: Holds the path to our selected image
  
  final TextEditingController _textController = TextEditingController();
  final List<String> _eventTypes = ['Proud Moment','Memory', 'Other'];

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing
    if (widget.existingEvent != null) {
      _isFavorite = widget.existingEvent!.isFavorite;
      _selectedType = widget.existingEvent!.type;
      _selectedDate = widget.existingEvent!.date;
      _textController.text = widget.existingEvent!.description;
      _selectedImagePath = widget.existingEvent!.pictureUrl; // Load existing image
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000), 
      lastDate: DateTime.now(), 
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- NEW: IMAGE PICKER LOGIC ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Force gallery selection only
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path; // Save the local path
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a description first!')),
      );
      return;
    }

    final db = LocalDatabase();

    if (widget.existingEvent == null) {
      final newEvent = Event(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedType,
        description: _textController.text.trim(),
        date: _selectedDate,
        isFavorite: _isFavorite,
        pictureUrl: _selectedImagePath, // Save the image path
      );
      await db.addEvent(newEvent);
    } else {
      final updatedEvent = Event(
        id: widget.existingEvent!.id, 
        type: _selectedType,
        description: _textController.text.trim(),
        date: _selectedDate,
        isFavorite: _isFavorite,
        pictureUrl: _selectedImagePath, // Save the updated/kept image path
      );
      await db.updateEvent(updatedEvent);
    }

    if (mounted) {
      Navigator.pop(context, true); 
    }
  }

  Future<void> _deleteEvent() async {
    if (widget.existingEvent != null) {
      final db = LocalDatabase();
      await db.deleteEvent(widget.existingEvent!.id);
      if (mounted) {
        Navigator.pop(context, true); 
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEvent == null ? 'Add Event' : 'Edit Event'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (widget.existingEvent != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Memory?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context), 
                        child: const Text('Cancel')
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); 
                          _deleteEvent(); 
                        }, 
                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: const ExpansionTile(
                leading: Icon(Icons.lightbulb_outline),
                title: Text(
                  'Recommendations',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Click to expand'),
                children: [
                  ListTile(title: Text('Example 1')),
                  ListTile(title: Text('Example 2')),
                  ListTile(title: Text('Example 3')),
                  ListTile(title: Text('Example 4')),
                  ListTile(title: Text('Example 5')),
                ],
              ),
            ),
            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedType,
                      dropdownColor: Colors.grey.shade800,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: _eventTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedType = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.redAccent : Colors.grey,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFavorite = !_isFavorite;
                    });
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 5),
            
            TextField(
              controller: _textController,
              minLines: 5,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe this moment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
            
            const SizedBox(height: 15),

            if (_selectedImagePath != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 200, // Keeps the preview a reasonable size
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb 
                            ? Image.network(
                                _selectedImagePath!,
                                fit: BoxFit.contain, // Shows full image
                              )
                            : Image.file(
                                File(_selectedImagePath!),
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                  ),
                  // Button to remove the selected image
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _selectedImagePath = null;
                      });
                    },
                  )
                ],
              ),
            
            if (_selectedImagePath != null) const SizedBox(height: 15),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  // Change button icon/text depending on if an image is picked
                  icon: Icon(_selectedImagePath == null ? Icons.add_photo_alternate_outlined : Icons.photo_library),
                  label: Text(_selectedImagePath == null ? 'Picture' : 'Change Pic'),
                  onPressed: _pickImage, // Calls our new gallery function
                ),
                
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                  onPressed: _pickDate,
                ),
              ],
            ),
            const SizedBox(height: 15),

            SizedBox(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveEvent,
                child: Text(
                  widget.existingEvent == null ? 'Save Event' : 'Update Event',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}