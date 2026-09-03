import 'chess_game.dart';
import 'move.dart';

/// Contract for a computer opponent.
///
/// No implementation ships with the app: this build is local two-player only.
/// Adding an opponent later means writing one class that implements this
/// interface and handing it to the game controller together with a
/// `PlayerType.computer` side. Nothing in the UI needs to change, because the
/// controller already routes every move through `playMove` and already
/// exposes `isThinking` so the board can lock while the engine searches.
///
/// A search-based implementation has everything it needs on [ChessGame]:
/// `generateLegalMoves`, `makeMove`, `undoLastMove`, `result` and `perft`.
///
/// Sketch of a future implementation:
///
///     class RandomAi implements ChessAi {
///       @override
///       String get name => 'Computer';
///
///       @override
///       Future<Move?> chooseMove(ChessGame game) async {
///         final moves = game.generateLegalMoves();
///         if (moves.isEmpty) return null;
///         return moves[Random().nextInt(moves.length)];
///       }
///     }
abstract class ChessAi {
  /// Label shown in the player panel, for example "Computer (easy)".
  String get name;

  /// Chooses a move for the side to move, or null when there is none.
  ///
  /// Deep searches should stay off the UI isolate by using `compute()`.
  Future<Move?> chooseMove(ChessGame game);
}
