# My Proud Space

**Das Gute wahrnehmen. Eigene Fortschritte erinnern. Kleinen Erfolgen Raum geben.**

My Proud Space ist eine Flutter-App, die positive Erlebnisse, persönliche Erfolge und bedeutungsvolle Ziele an einem Ort zusammenbringt. Unser Hackathon-Projekt entstand mit der Idee, Menschen beim Wiederaufbau ihres Alltags nach einer Depression zu unterstützen: Ein Spaziergang, ein Treffen mit Freunden oder ein kleiner Schritt Richtung Ziel soll nicht in Vergessenheit geraten.

Der Ablauf ist einfach: **Momente festhalten → Ziele verfolgen → Erinnerungen wiederentdecken → die Woche reflektieren.** Die App-Oberfläche ist auf Englisch.

## Demo-Video

Das [90-sekündige Demo-Video](video/out/demo.mp4) zeigt die Idee und die wichtigsten Funktionen anhand echter, mit Beispieldaten gerenderter Flutter-Oberflächen. Es führt vom ersten Eintrag über Projekte und Erinnerungen bis zum Wochenrückblick und zur Atemübung.

Das Video liegt lokal unter `video/out/demo.mp4` vor (Full HD, englischer Sprechertext). Der Ausgabeordner ist von Git ausgeschlossen und deshalb in einem frischen Checkout nicht enthalten. Hinweise zum Erstellen des Videos stehen in [video/README.md](video/README.md).

## Funktionen

| Bereich | Was die App bietet |
| --- | --- |
| **Erinnerungen und stolze Momente** | Erlebnisse mit Text, Datum und optionalem Foto speichern, bearbeiten und als Favoriten markieren. Die Sammlung lässt sich nach Kategorien und Favoriten filtern. |
| **Persönliche Projekte** | Ziele mit Beschreibung, Zeitraum, Kategorie und Priorität anlegen. Fortschritte im Logbuch mit Text und Bildern dokumentieren und Projekte als abgeschlossen markieren. |
| **Rückblick auf der Startseite** | Zufällig ausgewählte Erinnerungen und stolze Momente wiederentdecken. Ein „Project Spotlight“ zeigt Logbucheinträge eines ausgewählten Projekts. |
| **Wochenrückblick** | Erinnerungen, stolze Momente und Projektaktivitäten einer Woche gemeinsam betrachten und zwischen Wochen wechseln. |
| **Atemübungen** | Einer animierten Atemführung folgen, die Dauer zwischen 10 Sekunden und 30 Minuten wählen und bei Bedarf Hintergrundmusik einschalten. |
| **Routine und Gestaltung** | Aktivitätsserien verfolgen und die Akzentfarbe anpassen. Auf Android und iOS sind lokale Erinnerungen für die Serie und den Wochenrückblick vorgesehen. |

## Lokal starten

Voraussetzungen sind ein Flutter SDK mit Dart **3.12 oder kompatibler 3.x-Version** gemäß [pubspec.yaml](pubspec.yaml) sowie eine eingerichtete Zielplattform, beispielsweise ein Android-Emulator oder iOS-Simulator. Für iOS wird macOS mit Xcode benötigt.

Im Projektverzeichnis:

```sh
flutter pub get
flutter devices
flutter run
```

Bei mehreren verfügbaren Geräten lässt sich das Ziel mit `flutter run -d <device-id>` auswählen.

Beim ersten Öffnen an einem neuen Tag startet zunächst eine kurze Atemübung von 12 Sekunden. Nach deren Abschluss gelangt man zur Startseite.

## Demo-Version mit Beispieldaten aktivieren

**In [lib/demodata.dart](lib/demodata.dart) muss die Anweisung in Zeile 22 auskommentiert werden**, damit die App die vorbereiteten Beispieldaten lädt:

```dart
// Vorher (Zeile 22): Beispieldaten deaktiviert
isFirstLaunch = false;

// Nachher: Beispieldaten aktiviert
// isFirstLaunch = false;
```

Anschließend die App vollständig neu starten oder einen **Hot Restart** ausführen. Ein Hot Reload allein führt die Initialisierung nicht erneut aus.

Beim nächsten Laden der Startseite werden Beispielerinnerungen, stolze Momente und Fotos angelegt. Ist die Projektliste noch leer, kommen die Projekte **„Half-Marathon Training“** und **„Learning Guitar“** mit Logbucheinträgen hinzu.

Die Initialisierung erfolgt einmalig und wird über den lokal gespeicherten Schlüssel `firstLaunch_rewind` gesteuert. Wurden die Beispieldaten bereits geladen, werden sie beim Neustart nicht erneut angelegt. Für eine erneute Initialisierung kann dieser Schlüssel in einer Entwicklungsumgebung entfernt bzw. auf `true` gesetzt werden. Das Auskommentieren der Zeile löscht keine vorhandenen Einträge; bereits angelegte Demodaten bleiben auch nach dem erneuten Aktivieren der Anweisung erhalten.

## Technik und Speicherung

Die App verwendet **Flutter und Dart** mit Material-Komponenten. Ein separates Backend, Benutzerkonto oder API-Schlüssel ist für die App nicht erforderlich.

- **`shared_preferences`** speichert Einträge, Projekte, Einstellungen und Aktivitätsserien lokal.
- **`image_picker` und `path_provider`** unterstützen die Bildauswahl und lokale Bildablage. Je nach Eintrag werden Bilder als lokale Dateien oder Base64-Daten gespeichert.
- **`audioplayers`** spielt die mitgelieferten Audiotracks ab.
- **`flutter_local_notifications`, `timezone` und `flutter_timezone`** ermöglichen lokale Benachrichtigungen auf Android und iOS, sofern die erforderlichen Berechtigungen erteilt wurden.

Eine Synchronisierung zwischen Geräten ist derzeit nicht implementiert.

## Orientierung im Code

| Datei / Verzeichnis | Aufgabe |
| --- | --- |
| `lib/main.dart` | App-Einstieg, Startseite und tägliche Atemübung |
| `lib/proudy.dart`, `lib/mymemories.dart`, `lib/event.dart` | Einträge erfassen, verwalten und anzeigen |
| `lib/project.dart` | Projekte und Logbücher |
| `lib/remind.dart` | Zufällige Rückblicke und Project Spotlight |
| `lib/weekly_report.dart`, `lib/weekly_report_data.dart` | Wochenrückblick und Auswertung |
| `lib/breath.dart`, `lib/breathing_setup.dart`, `lib/breathing_music.dart` | Atemführung, Dauer und Musik |
| `lib/streak.dart`, `lib/streak_reminder.dart` | Aktivitätsserien und Benachrichtigungen |
| `lib/localdb.dart`, `lib/stored_image.dart` | Lokale Daten- und Bildspeicherung |
| `lib/demodata.dart` | Beispieldaten für die Demo-Version |
| `lib/app_theme.dart`, `lib/appearance.dart` | Gestaltung und Akzentfarben |
| `assets/` | Audio und Beispielbilder |
| `test/` | Tests für Layout, Speicherung, Rückblicke, Atemübungen und Serien |
| `video/` | Remotion-Projekt, Sprechertext und Demo-Video |

## Entwicklung

Die vorhandenen Flutter-Tests und die statische Analyse lassen sich im Projektverzeichnis ausführen:

```sh
flutter test
flutter analyze
```

Das Demo-Video wird separat mit Remotion erstellt. Die zugehörigen Befehle und Voraussetzungen sind in [video/README.md](video/README.md) dokumentiert.
