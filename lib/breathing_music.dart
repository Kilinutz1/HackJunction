/// The breathing exercise's explicit playlist excludes the upbeat rewind track.
enum BreathingMusic {
  lofty('Calm Loft', 'lofty.m4a'),
  noise('Deep Noise', 'blacknoise.m4a'),
  waves('Ocean Waves', 'waves.m4a'),
  forest('Forest Ambience', 'forest.m4a'),
  galaxy('Cosmic Calm', 'galaxy.m4a');

  const BreathingMusic(this.label, this.asset);
  final String label;
  final String asset;
}
