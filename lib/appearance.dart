import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

abstract final class Appearance {
  static final accent = ValueNotifier<Color>(AppPalette.forest);
  static const choices = <String, Color>{
    'Forest': AppPalette.forest,
    'Ocean': Color(0xFF345D79),
    'Plum': Color(0xFF71516F),
    'Clay': Color(0xFF96513A),
  };
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    accent.value = choices[prefs.getString('app_accent')] ?? AppPalette.forest;
  }

  static Future<void> select(String name) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString('app_accent', name)) {
      throw StateError('Could not save appearance');
    }
    accent.value = choices[name]!;
  }
}

class AppearanceMenu extends StatelessWidget {
  const AppearanceMenu({super.key});
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'App color',
    icon: const Icon(Icons.palette_outlined, size: 20),
    onSelected: (name) async {
      try {
        await Appearance.select(name);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not save app color. Please try again.'),
            ),
          );
        }
      }
    },
    itemBuilder: (_) => [
      for (final entry in Appearance.choices.entries)
        CheckedPopupMenuItem(
          value: entry.key,
          checked: Appearance.accent.value == entry.value,
          child: Row(
            children: [
              Icon(Icons.circle, color: entry.value, size: 16),
              const SizedBox(width: 12),
              Text(entry.key),
            ],
          ),
        ),
    ],
  );
}
