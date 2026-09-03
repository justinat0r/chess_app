import 'package:chess_app/game/chess_game.dart';
import 'package:chess_app/game/game_result.dart';
import 'package:chess_app/game/move.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scripted games that are also tapped out on a device during manual testing.
/// Keeping them here means a regression shows up in CI, not just by hand.
void main() {
  test('ten move stalemate ends in a draw', () {
    final ChessGame game = ChessGame();
    const List<String> line = <String>[
      'e2e3', 'a7a5',
      'd1h5', 'a8a6',
      'h5a5', 'h7h5',
      'a5c7', 'a6h6',
      'h2h4', 'f7f6',
      'c7d7', 'e8f7',
      'd7b7', 'd8d3',
      'b7b8', 'd3h7',
      'b8c8', 'f7g6',
      'c8e6',
    ];
    for (final String uci in line) {
      final Move? move = game.findMove(
        Move.squareFromName(uci.substring(0, 2))!,
        Move.squareFromName(uci.substring(2, 4))!,
      );
      expect(move, isNotNull, reason: '$uci should be legal');
      game.makeMove(move!);
    }
    expect(game.isInCheck, isFalse);
    expect(game.generateLegalMoves(), isEmpty);
    expect(game.result.outcome, GameOutcome.stalemate);
    expect(game.result.isDraw, isTrue);
  });

  test('five move promotion line reaches a promotion choice', () {
    final ChessGame game = ChessGame();
    const List<String> line = <String>[
      'e2e4', 'd7d5',
      'e4d5', 'c7c6',
      'd5c6', 'g8f6',
      'c6b7', 'e7e6',
    ];
    for (final String uci in line) {
      final Move? move = game.findMove(
        Move.squareFromName(uci.substring(0, 2))!,
        Move.squareFromName(uci.substring(2, 4))!,
      );
      expect(move, isNotNull, reason: '$uci should be legal');
      game.makeMove(move!);
    }
    final List<Move> promotions = game
        .generateLegalMoves()
        .where((Move m) =>
            m.from == Move.squareFromName('b7') &&
            m.to == Move.squareFromName('a8'))
        .toList();
    expect(promotions.length, 4, reason: 'bxa8 should offer four promotions');
    expect(promotions.every((Move m) => m.isCapture), isTrue);
  });
}
