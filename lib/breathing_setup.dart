import 'package:flutter/material.dart';
import 'breath.dart';

class BreathingSetupPage extends StatefulWidget {
  const BreathingSetupPage({super.key});
  @override
  State<BreathingSetupPage> createState() => _BreathingSetupPageState();
}

class _BreathingSetupPageState extends State<BreathingSetupPage> {
  int _minutes = 1;
  int _seconds = 0;
  bool _withMusic = false;

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
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Music'),
            subtitle: const Text('Play calming music during your exercise'),
            value: _withMusic,
            onChanged: (value) => setState(() => _withMusic = value),
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
                  withMusic: _withMusic,
                  onComplete: () => Navigator.of(sessionContext).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
