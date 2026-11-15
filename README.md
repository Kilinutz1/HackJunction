# My Proud Space

**Notice the good. Remember your growth. Make room for small wins.**

My Proud Space is a Flutter app that brings positive experiences, personal achievements, and meaningful goals together in one place. Our hackathon project was conceived to support people rebuilding everyday life after depression: a walk, a coffee with a friend, or a small step toward a goal deserves to be remembered.

The journey is simple: **Capture moments → Pursue goals → Rediscover memories → Reflect on your week.** The app interface is in English.

## Features

| Area | What the app offers |
| --- | --- |
| **Memories and proud moments** | Save and edit experiences with text, a date, and an optional photo. Mark favorites and filter your collection by category or favorites. |
| **Personal projects** | Create goals with a description, time frame, category, and priority. Document progress in a logbook with text and photos, and mark projects as completed. |
| **Home screen rewind** | Rediscover randomly selected memories and proud moments. A Project Spotlight presents logbook entries from a selected project. |
| **Weekly review** | Look back at memories, proud moments, and project activity together, and browse previous weeks. |
| **Breathing exercises** | Follow an animated breathing guide, choose a duration from 10 seconds to 30 minutes, and optionally add background music. |
| **Routine and appearance** | Track activity streaks and customize the accent color. Android and iOS support local streak and weekly review reminders. |

## Run locally

You need a Flutter SDK with Dart **3.12 or a compatible later 3.x version**, as specified in [pubspec.yaml](pubspec.yaml), and a configured target platform, such as an Android emulator or iOS simulator. Building for iOS requires macOS and Xcode.

From the project directory:

```sh
flutter pub get
flutter devices
flutter run
```

If multiple devices are available, select one with `flutter run -d <device-id>`.

The first time you open the app each day, it starts with a short, 12-second breathing exercise. Complete it to reach the home screen.

## Enable the demo version with sample data

**Comment out the statement on line 22 of [lib/demodata.dart](lib/demodata.dart)** to enable the prepared sample data:

```dart
// Before (line 22): sample data disabled
isFirstLaunch = false;

// After: sample data enabled
// isFirstLaunch = false;
```

Then restart the app completely or perform a **Hot Restart**. Hot Reload alone does not run the initialization again.

The next time the home screen loads, the app adds sample memories, proud moments, and photos. If the project list is empty, it also adds **“Half-Marathon Training”** and **“Learning Guitar”**, including logbook entries.

This initialization runs once and is controlled by the locally stored `firstLaunch_rewind` key. Once sample data has been loaded, restarting the app does not add it again. To run initialization again in a development environment, remove this key or set it to `true`. Commenting out the line does not delete existing entries; previously created demo data also remains if you later restore the statement.

## Technology and storage

The app uses **Flutter and Dart** with Material components. No separate backend, user account, or API key is required to run the app.

- **`shared_preferences`** stores entries, projects, settings, and activity streaks locally.
- **`image_picker` and `path_provider`** handle image selection and local image storage. Depending on the entry, images are stored as local files or Base64 data.
- **`audioplayers`** plays the bundled audio tracks.
- **`flutter_local_notifications`, `timezone`, and `flutter_timezone`** provide local notifications on Android and iOS when the required permissions are granted.

Cross-device synchronization is not currently implemented.

## Code overview

| File / directory | Purpose |
| --- | --- |
| `lib/main.dart` | App entry point, home screen, and daily breathing exercise |
| `lib/proudy.dart`, `lib/mymemories.dart`, `lib/event.dart` | Create, manage, and display entries |
| `lib/project.dart` | Projects and logbooks |
| `lib/remind.dart` | Random memory rewind and Project Spotlight |
| `lib/weekly_report.dart`, `lib/weekly_report_data.dart` | Weekly review and activity summaries |
| `lib/breath.dart`, `lib/breathing_setup.dart`, `lib/breathing_music.dart` | Breathing guidance, duration, and music |
| `lib/streak.dart`, `lib/streak_reminder.dart` | Activity streaks and notifications |
| `lib/localdb.dart`, `lib/stored_image.dart` | Local data and image storage |
| `lib/demodata.dart` | Sample data for the demo version |
| `lib/app_theme.dart`, `lib/appearance.dart` | Visual design and accent colors |
| `assets/` | Audio tracks and sample images |
| `test/` | Tests for layouts, storage, reviews, breathing exercises, and streaks |

## Development

Run the existing Flutter tests and static analysis from the project directory:

```sh
flutter test
flutter analyze
```
