<<<<<<< HEAD
# Kids Number Tracing

An offline Flutter Android app that helps toddlers and preschool children (ages 2–5) learn and trace numbers from 1 to 20.

## Features

- Splash screen with auto-navigation
- Number learning screen with illustration, dotted number, and tracing canvas
- Touch-based tracing with progress tracking and 70% success validation
- Success sound, confetti, and auto-advance to the next number
- Previous / Next navigation
- Completion celebration screen with restart option
- Fully offline — no backend, database, login, or internet required

## Tech Stack

- Flutter (Material 3)
- Dart with null safety
- Provider for state management
- audioplayers, confetti, google_fonts, flutter_svg

## Project Structure

```
lib/
├── main.dart
├── constants/app_constants.dart
├── models/number_item.dart
├── data/number_data.dart
├── providers/learning_provider.dart
├── screens/
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   └── completion_screen.dart
├── widgets/
│   ├── tracing_canvas.dart
│   ├── number_card.dart
│   ├── success_dialog.dart
│   └── progress_indicator_widget.dart
└── services/
    ├── audio_service.dart
    └── tracing_service.dart

assets/
├── images/number_1.png … number_20.png
└── sounds/success.mp3
```

## Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio or VS Code with Flutter extensions
- Android device or emulator

### Install dependencies

```bash
flutter pub get
```

### Run on Android

```bash
flutter run
```

### Build release APK

```bash
flutter build apk --release
```

The APK will be generated at:

`build/app/outputs/flutter-apk/app-release.apk`

## How Tracing Works

1. The app renders a dotted number guide in the tracing area.
2. The child draws over the guide using finger strokes.
3. Sample points are generated from the number outline.
4. When at least **70%** of guide points are covered, tracing is marked successful.
5. A success sound plays, confetti appears, and the app advances after 2 seconds.

## Replacing Placeholder Assets

Replace files in `assets/images/` with your own illustrations:

- `number_1.png` through `number_20.png`

Replace the success sound:

- `assets/sounds/success.mp3`

After replacing assets, run:

```bash
flutter pub get
flutter run
```

## App Flow

1. **Splash** → waits 2 seconds
2. **Learning Screen** → numbers 1–20
3. **Completion Screen** → shown after number 20

## License

Private project — not published to pub.dev.
=======
# Number-tracing-app
>>>>>>> 389c8c8fec2718481030691c0328bbcaf6a217a9
