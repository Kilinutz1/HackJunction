import 'dart:io'; 
import 'dart:convert'; // NEW: Required for Base64 encoding
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart'; // NEW: For permanent storage
import 'localdb.dart';
import 'event.dart';

class ProudyPage extends StatefulWidget {
  final Event? existingEvent; 

  const ProudyPage({super.key, this.existingEvent});

  @override
  State<ProudyPage> createState() => _ProudyPageState();
}

class _ProudyPageState extends State<ProudyPage> {
  bool _isFavorite = false; 
  String _selectedType = 'Proud Moment'; 
  DateTime _selectedDate = DateTime.now(); 
  String? _selectedImagePath; 
  
  final TextEditingController _textController = TextEditingController();
  final List<String> _eventTypes = ['Proud Moment','Memory', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.existingEvent != null) {
      _isFavorite = widget.existingEvent!.isFavorite;
      _selectedType = widget.existingEvent!.type;
      _selectedDate = widget.existingEvent!.date;
      _textController.text = widget.existingEvent!.description;
      _selectedImagePath = widget.existingEvent!.pictureUrl; 
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path; 
      });
    }
  }

  Future<String?> _saveImageToPermanentStorage(String? tempPath) async {
    if (tempPath == null || tempPath.isEmpty) return null;

    // --- NEW: WEB HYBRID STORAGE (Base64) ---
    if (kIsWeb) {
      try {
        // Read the temporary browser file and convert it to a permanent text string
        final bytes = await XFile(tempPath).readAsBytes();
        final base64String = base64Encode(bytes);
        return 'base64:$base64String'; // We add 'base64:' so the app knows how to read it later
      } catch (e) {
        debugPrint("Error encoding web image: $e");
        return tempPath;
      }
    }

    // --- MOBILE PERMANENT STORAGE (Unchanged) ---
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'memory_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentPath = '${directory.path}/$fileName';
      final newFile = await File(tempPath).copy(permanentPath);
      return newFile.path;
    } catch (e) {
      debugPrint("Error saving mobile image: $e");
      return tempPath;
    }
  }

  Future<void> _saveEvent() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a description first!')),
      );
      return;
    }

    String? finalImagePath = _selectedImagePath;

    // If we picked a NEW image (or this is a brand new event), copy it to permanent storage
    if (widget.existingEvent == null || widget.existingEvent!.pictureUrl != _selectedImagePath) {
      finalImagePath = await _saveImageToPermanentStorage(_selectedImagePath);
    }

    final db = LocalDatabase();

    if (widget.existingEvent == null) {
      final newEvent = Event(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedType,
        description: _textController.text.trim(),
        date: _selectedDate,
        isFavorite: _isFavorite,
        pictureUrl: finalImagePath, // Save the permanent path
      );
      await db.addEvent(newEvent);
    } else {
      final updatedEvent = Event(
        id: widget.existingEvent!.id, 
        type: _selectedType,
        description: _textController.text.trim(),
        date: _selectedDate,
        isFavorite: _isFavorite,
        pictureUrl: finalImagePath, // Save the permanent path
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
      
      // Optional: You could also delete the physical file here using File(widget.existingEvent!.pictureUrl!).delete() 
      // to save storage space, but we'll keep it simple for now.

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
        title: Text(widget.existingEvent == null ? 'Add Event' : 'Edit Event',style: TextStyle(fontWeight: FontWeight.bold)),
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
              child: ExpansionTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: const Text(
                  'Recommendations',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Click to expand'),
                children: _selectedType == 'Memory'
                    ? const [
                        ListTile(title: Text('Did you meet some friends/family today?')),
                        ListTile(title: Text('A nice trip/vacation you don\'t want to forget?')),
                        ListTile(title: Text('Did you go to a nice event recently?')),
                        ListTile(title: Text('Did some funny little thing happen today?')),
                      ]
                    : const [
                  ListTile(title: Text('Did you do any sports/outdoor activity?')),
                  ListTile(title: Text('Were you able to help someone?')),
                  ListTile(title: Text('Maybe you got a nice compliment?')),
                  ListTile(title: Text('Did you achieve a goal or make progress towards one?')),
                  ListTile(title: Text('Did you try something new?')),
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
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb 
                            ? (_selectedImagePath!.startsWith('base64:')
                                ? Image.memory(base64Decode(_selectedImagePath!.substring(7)), fit: BoxFit.contain)
                                : Image.network(_selectedImagePath!, fit: BoxFit.contain))
                            : Image.file(File(_selectedImagePath!), fit: BoxFit.contain),
                      ),
                    ),
                  ),
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
                  icon: Icon(_selectedImagePath == null ? Icons.add_photo_alternate_outlined : Icons.photo_library),
                  label: Text(_selectedImagePath == null ? 'Picture' : 'Change Pic'),
                  onPressed: _pickImage, 
                ),
                
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
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
