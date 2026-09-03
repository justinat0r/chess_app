# Chess

A local two-player chess app for Android, built with Flutter. Two people share
one phone: White moves, then Black, on the same board.

## Playing

1. **Start screen** shows the title, `NEW GAME`, and an optional
   "rotate board each turn" setting for hot-seat play.
2. **Board screen** is the game itself. Tap a piece to see its legal moves,
   tap a highlighted square to move. Dots mark quiet moves, rings mark
   captures. The last move stays tinted, and a king in check glows red.
   The panel for each player shows captured pieces and material lead.
3. **Win screen** appears on checkmate or resignation, naming the winner.
4. **Tie screen** appears on stalemate, insufficient material, the fifty-move
   rule, or threefold repetition, naming the rule that ended the game.

Both result screens offer `PLAY AGAIN`, `MAIN MENU`, and a link back to the
final position.

## Rules covered

Full legal-move generation: castling (including all the ways it is forbidden),
en passant, promotion to any of four pieces, pins, and check evasion. Game
endings: checkmate, stalemate, insufficient material, the fifty-move rule,
threefold repetition, and resignation.

## Layout of the code

| Path | Role |
| --- | --- |
| `lib/game/chess_game.dart` | The rules engine. No Flutter imports. |
| `lib/game/piece.dart`, `move.dart`, `game_result.dart` | Value types. |
| `lib/game/game_controller.dart` | `ChangeNotifier` holding board, selection, notation and result. |
| `lib/game/chess_ai.dart` | Interface for a future computer opponent. |
| `lib/screens/` | Start, game, win and tie screens. |
| `lib/widgets/` | Board, vector pieces, player panels, promotion dialog. |

The pieces are drawn as vector paths in `chess_piece_view.dart`, so there are
no image assets and no licence questions, and they stay sharp at any size.

## Adding a computer opponent later

Nothing needs restructuring. The seam is already in place:

1. Write a class implementing `ChessAi` (`lib/game/chess_ai.dart`). Its
   `chooseMove` receives the live `ChessGame`, which already exposes
   `generateLegalMoves`, `makeMove`, `undoLastMove`, `result` and `perft`.
   Run a deep search through `compute()` to stay off the UI isolate.
2. Construct the controller with that engine and the side it plays:

   ```dart
   GameController(
     blackPlayer: PlayerType.computer,
     ai: MyEngine(),
   )
   ```

3. Enable the `PLAY THE COMPUTER` button on the start screen and pass the
   choice into `GameScreen`.

The controller already calls the engine after every human move, already locks
the board while `isThinking` is true, already takes back both plies on undo,
and already labels the panel with the engine's `name`.

## Tests

```
flutter test
```

- `test/chess_engine_test.dart` verifies move generation with perft counts on
  five standard positions (start position to depth 4, Kiwipete to depth 3),
  plus every game-ending condition.
- `test/chess_rules_test.dart` covers castling, en passant, promotion, pins,
  undo and algebraic notation.
- `test/app_test.dart` drives the UI: start screen to board, a full checkmate
  played by tapping squares, illegal moves being ignored, undo, resignation,
  and the tie screen.

## Building

```
flutter build apk --release
```

The APK lands in `build/app/outputs/flutter-apk/app-release.apk`.
