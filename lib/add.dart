import 'package:flutter/material.dart';

class TexttInput extends StatefulWidget {
  const TexttInput({super.key});

  @override
  State<TexttInput> createState() => _TexttInputState();
}

class _TexttInputState extends State<TexttInput> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a proud moment of today'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
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

              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Schreib etwas...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
