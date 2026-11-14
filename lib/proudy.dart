import 'package:flutter/material.dart';
import 'localdb.dart';
import 'event.dart';

class ProudyPage extends StatefulWidget {
  const ProudyPage({super.key});

  @override
  State<ProudyPage> createState() => _ProudyPageState();
}

class _ProudyPageState extends State<ProudyPage> {
  // --- STATE VARIABLES ---
  bool _isFavorite = false; 
  String _selectedType = 'Proud Moment'; 
  DateTime _selectedDate = DateTime.now(); 
  
  final TextEditingController _textController = TextEditingController();
  final List<String> _eventTypes = ['Proud Moment','Memory', 'Other'];

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

  Future<void> _saveEvent() async {
    // 1. Check if the text is empty
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a description first!')),
      );
      return;
    }

    // 2. Create the Event object
    final newEvent = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
      type: _selectedType,
      description: _textController.text.trim(),
      date: _selectedDate,
      isFavorite: _isFavorite,
      // pictureUrl: null // We will add this when we wire up the camera
    );

    // 3. Save to database
    final db = LocalDatabase();
    await db.addEvent(newEvent);

    // 4. Return to the Main Screen
    if (mounted) {
      Navigator.pop(context);
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
        title: const Text('Add Event'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top Row: Type Selector (Left) and Heart Button (Right)
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
                
                // The Heart Button is now securely in the Row
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
            
            // Text Input Area
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
            
            const SizedBox(height: 5),
            
            // Bottom Row: Picture (Left) and Date (Right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Picture'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Picture picker coming soon!')),
                    );
                  },
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
                child: const Text(
                  'Save Event',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ),
          ],
        ),
      ),
    );
  }
}