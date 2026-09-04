# Chess App

Flutte chess app with basic move implementation (check/checkmate, legal move, difficulty levels, etc.).

## Features

- Implements all chess rules
- Draw detection
- Player modes
- Match difficulty
- win/tie results in rematch

## Build requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Android Studio or VS Code with the Flutter extension
- An Android emulator, iOS simulator, or a physical device

## Running the app

'''bash
git clone http://github.com/justinat0r/chess_app.git
cd chess_app
flutter pub get
flutter run
'''

## Structure

- `lib/game/` — the rules
  `GameController`, move/piece models, and the computer opponent
- `lib/screens/` — app screens 
- `lib/widgets/` — board view, players, etc.
- `android/` — Android files
- `test/` — unit tests
