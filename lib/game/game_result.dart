import 'piece.dart';

/// How a game ended (or that it has not).
enum GameOutcome {
  ongoing,
  checkmate,
  resignation,
  stalemate,
  insufficientMaterial,
  fiftyMoveRule,
  threefoldRepetition,
}

class GameResult {
  const GameResult(this.outcome, {this.winner});

  final GameOutcome outcome;

  /// Winning side, or null for a draw / unfinished game.
  final PieceColor? winner;

  static const GameResult ongoing = GameResult(GameOutcome.ongoing);

  bool get isOver => outcome != GameOutcome.ongoing;
  bool get isDraw => isOver && winner == null;
  bool get isWin => winner != null;

  /// Short headline for the result screens.
  String get headline {
    if (!isOver) return 'Game in progress';
    if (isDraw) return 'Draw';
    return '${winner!.label} wins';
  }

  /// Explanation of how the game ended.
  String get reason {
    switch (outcome) {
      case GameOutcome.ongoing:
        return '';
      case GameOutcome.checkmate:
        return 'by checkmate';
      case GameOutcome.resignation:
        return 'by resignation';
      case GameOutcome.stalemate:
        return 'Stalemate: the side to move has no legal move and is not in check.';
      case GameOutcome.insufficientMaterial:
        return 'Neither side has enough material to deliver checkmate.';
      case GameOutcome.fiftyMoveRule:
        return 'Fifty-move rule: 50 moves each with no capture and no pawn move.';
      case GameOutcome.threefoldRepetition:
        return 'Threefold repetition: the same position occurred three times.';
    }
  }
}
