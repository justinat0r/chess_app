import 'dart:math';

import 'chess_ai.dart';
import 'chess_game.dart';
import 'move.dart';
import 'piece.dart';

/// Plays a uniformly random legal move. Useful as a baseline / lowest rung.
class RandomAi implements ChessAi {
  @override
  String get name => 'Computer (Random)';

  final Random _random = Random();

  @override
  Future<Move?> chooseMove(ChessGame game) async {
    final moves = game.generateLegalMoves();
    if (moves.isEmpty) return null;
    return moves[_random.nextInt(moves.length)];
  }
}

/// Fixed-depth minimax with material scoring. [depth] and [randomness]
/// together define a difficulty level — see the presets at the bottom of
/// this file.
class MinimaxAi implements ChessAi {
  MinimaxAi({
    required this.depth,
    this.randomness = 0.0,
    String? name,
  }) : name = name ?? 'Computer';

  /// How many plies (half-moves) to search ahead. 1 is nearly instant,
  /// 3 is noticeably stronger but slower on a phone CPU.
  final int depth;

  /// Chance (0.0–1.0) of playing a random legal move instead of the
  /// best one found. This is what actually makes "easy" feel easy —
  /// depth 1 alone still punishes obvious blunders.
  final double randomness;

  @override
  final String name;

  final Random _random = Random();

  @override
  Future<Move?> chooseMove(ChessGame game) async {
    final moves = game.generateLegalMoves();
    if (moves.isEmpty) return null;

    if (_random.nextDouble() < randomness) {
      return moves[_random.nextInt(moves.length)];
    }

    final PieceColor rootColor = game.turn;
    Move? best;
    int bestScore = -1 << 30;

    for (final move in moves) {
      game.makeMove(move);
      final int score = -_search(game, depth - 1, rootColor);
      game.undoLastMove();
      if (score > bestScore) {
        bestScore = score;
        best = move;
      }
    }
    return best ?? moves[_random.nextInt(moves.length)];
  }

  /// Negamax: each level returns the score from the mover's own point of
  /// view, and the caller negates it — so [rootColor] is only needed to
  /// score checkmate/draw correctly, not to flip sign conventions.
  int _search(ChessGame game, int depth, PieceColor rootColor) {
    final result = game.result;
    if (result.isOver) {
      if (result.isDraw) return 0;
      return result.winner == rootColor ? 100000 : -100000;
    }
    if (depth == 0) {
      return _evaluate(game, rootColor);
    }
    final moves = game.generateLegalMoves();
    int best = -1 << 30;
    for (final move in moves) {
      game.makeMove(move);
      final int score = -_search(game, depth - 1, rootColor);
      game.undoLastMove();
      if (score > best) best = score;
    }
    return best;
  }

  int _evaluate(ChessGame game, PieceColor rootColor) {
    int score = 0;
    for (int i = 0; i < 64; i++) {
      final piece = game.pieceAt(i);
      if (piece == null) continue;
      score += piece.color == rootColor ? piece.type.value : -piece.type.value;
    }
    return score;
  }
}

/// Ready-to-use difficulty presets. Import these directly, or build your
/// own MinimaxAi with different numbers.
final MinimaxAi easyAi =
    MinimaxAi(depth: 1, randomness: 0.5, name: 'Computer (Easy)');
final MinimaxAi mediumAi =
    MinimaxAi(depth: 2, randomness: 0.1, name: 'Computer (Medium)');
final MinimaxAi hardAi =
    MinimaxAi(depth: 3, randomness: 0.0, name: 'Computer (Hard)');