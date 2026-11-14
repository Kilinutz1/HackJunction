import 'package:flutter/material.dart';
import 'breath.dart';
import 'breathing_music.dart';
import 'streak.dart';

class BreathingSetupPage extends StatefulWidget {
  const BreathingSetupPage({super.key});
  @override
  State<BreathingSetupPage> createState() => _BreathingSetupPageState();
}

class _BreathingSetupPageState extends State<BreathingSetupPage> {
  int _minutes = 1;
  int _seconds = 0;
  BreathingMusic? _music;

  void _chooseMusic() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Choose music',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final track in <BreathingMusic?>[
                null,
                ...BreathingMusic.values,
              ])
                ListTile(
                  title: Text(track?.label ?? 'No music'),
                  leading: Icon(
                    _music == track
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  selected: _music == track,
                  onTap: () {
                    setState(() => _music = track);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Breathing exercise')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            Icons.air,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'A little time for yourself',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Choose how long you would like to breathe. Follow the circle as it gently expands and contracts.',
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _minutes,
                  decoration: const InputDecoration(labelText: 'Minutes'),
                  items: [
                    for (var n = 0; n <= 30; n++)
                      DropdownMenuItem(value: n, child: Text('$n')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _minutes = value;
                      if (_minutes == 30) _seconds = 0;
                      if (_minutes == 0 && _seconds < 10) _seconds = 10;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey('seconds-$_minutes'),
                  initialValue: _seconds,
                  decoration: const InputDecoration(labelText: 'Seconds'),
                  items: [
                    for (
                      var n = _minutes == 0 ? 10 : 0;
                      n <= (_minutes == 30 ? 0 : 59);
                      n++
                    )
                      DropdownMenuItem(value: n, child: Text('$n')),
                  ],
                  onChanged: _minutes == 30
                      ? null
                      : (value) {
                          if (value != null) setState(() => _seconds = value);
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('10 seconds to 30 minutes'),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Music'),
            subtitle: Text(_music?.label ?? 'No music'),
            leading: const Icon(Icons.music_note_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: _chooseMusic,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start exercise'),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (sessionContext) => BreatheScreen(
                  durationInSeconds: _minutes * 60 + _seconds,
                  timedSession: true,
                  withMusic: _music != null,
                  music: _music ?? BreathingMusic.lofty,
                  onComplete: () async {
                    Navigator.of(sessionContext).pop();
                    try {
                      await StreakService().recordActivity();
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not save your streak activity. Please try again.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
