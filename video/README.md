# My Proud Space — hackathon demo

A 90-second English demo using the existing Remotion project and genuine Flutter-rendered screenshots. Export: `out/demo.mp4` (1920 × 1080, 30 fps, H.264 with English audio).

## Run

```sh
cd video
npm ci                         # only needed on a fresh checkout
cp .env.example .env            # fill in your ElevenLabs credentials
npm run voiceover              # sends only NARRATION text to ElevenLabs
npm run studio                 # preview/edit the Demo composition
npm run render                 # writes out/demo.mp4
npm run verify                 # metadata validation + scene frame samples
```

The current export uses the supplied ElevenLabs narration at its original speed. To generate an alternative local voice on macOS:

```sh
npm run voiceover -- --local
```

The local speech service must be accessible; restrictive sandboxes may generate empty audio. The script checks duration and fails rather than rendering a silent substitute. For a different installed voice, set `LOCAL_VOICE` in `.env`. On other systems use ElevenLabs.

Remotion downloads its browser if needed. To use an installed Chrome:

```sh
REMOTION_BROWSER_EXECUTABLE="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" npm run render
```

## Edit the story

- `scripts/scenes.mjs`: narration, titles and screen choices.
- `scripts/align.mjs`: detects actual pauses in the original audio, builds the frame timeline and pads only silence.
- `src/scene-timing.json`: measured pauses, speech bounds and frame-exact scene timing.
- `STORYBOARD.md`: English scene plan and narration with time ranges.
- `NARRATION.txt`: standalone English speaker script.
- `src/Composition.tsx`: animated phone frames, titles, progress line and phrase captions.
- `src/audio-timing.json`: measured original speech durations. Captions use approximate word-group timing and stop advancing during detected pauses; they are not forced-aligned word subtitles.

Run `npm run voiceover` again after changing narration, then render. To adjust timing for existing recordings without regenerating or sending anything to ElevenLabs, run `npm run align`. Rendering also runs alignment automatically.

Alignment analyzes the original MP3s (or local source WAVs) with FFmpeg silence detection at -38 dB for pauses of at least 180 ms. The supplied ElevenLabs clips total approximately 81.53 seconds. Every original sample and internal pause is retained at speed 1.0. Each scene has a 9-frame visual lead-in, a pause after narration, and a fade-out that starts after the final spoken segment. The remaining frames are distributed as silent holds, with a longer closing hold. The project screenshot change also lands within a detected internal pause. The script fails if the recordings cannot fit safely; it never accelerates or truncates speech.

Nine scenes sum to exactly 2700 frames / 90 seconds. After rendering, `scripts/finalize.mjs` preserves the video frames and re-encodes the audio with an exact 90-second duration to remove AAC container padding. `npm run lint` checks ESLint and TypeScript. `npm run verify` validates both the frame timeline and the final MP4.

## Real app screenshots

`public/screens/` contains actual rendered Flutter widgets with fictional fixture data, not recreated UI mockups. Captured at 390 × 844 logical pixels and 2× resolution using `capture_test.dart`, adapted from the repository's `test/layout_test.dart`. This is a screenshot-based demo, not a screen recording. The outer device frame and surrounding titles are Remotion graphics.

To recapture on this Mac, with the repository's Flutter SDK and dependencies ready:

```sh
npm run capture
```

The capture loads system fonts and Flutter's Material Icons. It exercises the home screen, memory entry, memory collection, weekly report, project editing, completion toggling and logbook. Notification scheduling is unavailable in the widget-test environment and logs a harmless warning; no notifications or user data are involved. Fixture storage uses mocked SharedPreferences. Screenshot dates reflect the capture date.

## Repository grounding

Read before writing the script:

| Demo feature | App code |
| --- | --- |
| Dashboard and entry points | `../lib/main.dart` |
| Positive memories, proud moments, photos, favourites | `../lib/proudy.dart`, `../lib/mymemories.dart`, `../lib/event.dart` |
| Random resurfacing of memories and proud moments | `../lib/remind.dart` |
| Projects, periods, importance, progress logbook, completion | `../lib/project.dart` |
| Weekly highlights across memories, proud moments and projects | `../lib/weekly_report.dart`, `../lib/weekly_report_data.dart` |
| Breathing setup and guided exercise | `../lib/breathing_setup.dart`, `../lib/breath.dart` |
| Local persistence and visual style | `../lib/localdb.dart`, `../lib/app_theme.dart` |

The story describes the intended support for life after depression and a practice of noticing positive experiences. It does not claim proven treatment effects. Breathing occupies only six seconds; the central story is capture → goals → remembering → weekly reflection.

## Secrets and generated files

`.env` and all `.env.*` files except `.env.example`, `public/audio/`, `out/`, and all MP4s are ignored by Git. No key is read by browser-side React code. Voiceover runs in Node and sends the script to the [ElevenLabs speech API](https://elevenlabs.io/docs/api-reference/text-to-speech/convert). Generated audio must be recreated after a fresh checkout. Screenshots, scripts and the scene plan are intended to be committed.

Rendering follows the [Remotion render workflow](https://www.remotion.dev/docs/render).
