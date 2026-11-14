import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beautiful Comments',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurpleAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.tealAccent,
          surface: Colors.grey.shade900,
        ),
        cardTheme: CardThemeData( // Updated for newer Flutter versions
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.deepPurpleAccent,
          foregroundColor: Colors.white,
        ),
      ),
      home: const CommentScreen(),
    );
  }
}

class CommentScreen extends StatefulWidget {
  const CommentScreen({super.key});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  List _comments = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // LOAD DATA: Safely decodes JSON into strict Dart maps
  Future<void> _loadComments() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedData = prefs.getStringList('my_comments_v2');
    
    if (savedData != null) {
      setState(() {
        _comments = savedData.map((item) {
          final decoded = jsonDecode(item) as Map;
          return Map<String, dynamic>.from(decoded); // Prevents list casting errors
        }).toList();
      });
    }
  }

  // SAVE DATA
  Future<void> _saveComments() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> dataToSave = 
        _comments.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('my_comments_v2', dataToSave);
  }

  // DELETE DATA
  void _deleteComment(int index) {
    setState(() {
      _comments.removeAt(index);
    });
    _saveComments();
  }

  // TIMESTAMP GENERATOR
  String _getCurrentTimestamp() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  // DIALOG POPUP
  void _showAddCommentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Comment', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _textController,
            autofocus: true,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'What\'s on your mind?',
              filled: true,
              fillColor: Colors.black12,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _textController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (_textController.text.trim().isNotEmpty) {
                  setState(() {
                    _comments.insert(0, {
                      'text': _textController.text.trim(),
                      'date': _getCurrentTimestamp(),
                    });
                  });
                  _saveComments();
                  
                  _textController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Thoughts', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _comments.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return _buildCommentCard(comment, index);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCommentDialog,
        icon: const Icon(Icons.edit),
        label: const Text('Write'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.speaker_notes_off, size: 80, color: Colors.grey.shade800),
          const SizedBox(height: 16),
          Text(
            "It's quiet in here.",
            style: TextStyle(fontSize: 20, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap 'Write' to add your first thought.",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    comment['text'] ?? '',
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _deleteComment(index),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              comment['date'] ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}