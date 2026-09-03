import 'package:chess_app/game/chess_game.dart';
import 'package:chess_app/game/game_result.dart';
import 'package:chess_app/game/move.dart';
import 'package:chess_app/game/piece.dart';
import 'package:flutter_test/flutter_test.dart';

int sq(String name) => Move.squareFromName(name)!;

void play(ChessGame game, String from, String to, {PieceType? promotion}) {
  final Move? move = game.findMove(sq(from), sq(to), promotion: promotion);
  expect(move, isNotNull, reason: 'expected $from$to to be legal');
  game.makeMove(move!);
}

void main() {
  group('perft move generation', () {
    test('starting position', () {
      final ChessGame game = ChessGame();
      expect(game.perft(1), 20);
      expect(game.perft(2), 400);
      expect(game.perft(3), 8902);
      expect(game.perft(4), 197281);
    });

    test('kiwipete', () {
      final ChessGame game = ChessGame.fromFen(
          'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1');
      expect(game.perft(1), 48);
      expect(game.perft(2), 2039);
      expect(game.perft(3), 97862);
    });

    test('endgame with en passant and promotion edges', () {
      final ChessGame game =
          ChessGame.fromFen('8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1');
      expect(game.perft(1), 14);
      expect(game.perft(2), 191);
      expect(game.perft(3), 2812);
      expect(game.perft(4), 43238);
    });

    test('promotion heavy position', () {
      final ChessGame game = ChessGame.fromFen(
          'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1');
      expect(game.perft(1), 6);
      expect(game.perft(2), 264);
      expect(game.perft(3), 9467);
    });

    test('tactical middlegame position', () {
      final ChessGame game = ChessGame.fromFen(
          'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8');
      expect(game.perft(1), 44);
      expect(game.perft(2), 1486);
      expect(game.perft(3), 62379);
    });
  });

  group('game endings', () {
    test('fool mate is checkmate for black', () {
      final ChessGame game = ChessGame();
      play(game, 'f2', 'f3');
      play(game, 'e7', 'e5');
      play(game, 'g2', 'g4');
      play(game, 'd8', 'h4');
      final GameResult result = game.result;
      expect(result.outcome, GameOutcome.checkmate);
      expect(result.winner, PieceColor.black);
      expect(game.generateLegalMoves(), isEmpty);
      expect(game.isInCheck, isTrue);
    });

    test('scholar mate is checkmate for white', () {
      final ChessGame game = ChessGame();
      play(game, 'e2', 'e4');
      play(game, 'e7', 'e5');
      play(game, 'f1', 'c4');
      play(game, 'b8', 'c6');
      play(game, 'd1', 'h5');
      play(game, 'g8', 'f6');
      play(game, 'h5', 'f7');
      expect(game.result.outcome, GameOutcome.checkmate);
      expect(game.result.winner, PieceColor.white);
    });

    test('stalemate is detected as a draw', () {
      final ChessGame game = ChessGame.fromFen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1');
      expect(game.generateLegalMoves(), isEmpty);
      expect(game.isInCheck, isFalse);
      expect(game.result.outcome, GameOutcome.stalemate);
      expect(game.result.isDraw, isTrue);
    });

    test('bare kings are insufficient material', () {
      final ChessGame game = ChessGame.fromFen('8/8/4k3/8/8/3K4/8/8 w - - 0 1');
      expect(game.hasInsufficientMaterial, isTrue);
      expect(game.result.outcome, GameOutcome.insufficientMaterial);
    });

    test('king and bishop each is a draw, king and rook is not', () {
      expect(
        ChessGame.fromFen('8/8/4k3/5b2/8/3K4/2B5/8 w - - 0 1').result.outcome,
        GameOutcome.insufficientMaterial,
      );
      expect(
        ChessGame.fromFen('8/8/4k3/8/8/3K4/2R5/8 w - - 0 1').result.outcome,
        GameOutcome.ongoing,
      );
    });

    test('fifty move rule ends the game', () {
      final ChessGame game =
          ChessGame.fromFen('8/8/4k3/8/8/3K4/2R5/8 w - - 99 60');
      play(game, 'd3', 'd4');
      expect(game.result.outcome, GameOutcome.fiftyMoveRule);
      expect(game.result.isDraw, isTrue);
    });

    test('threefold repetition ends the game', () {
      final ChessGame game = ChessGame();
      for (int i = 0; i < 2; i++) {
        play(game, 'g1', 'f3');
        play(game, 'g8', 'f6');
        play(game, 'f3', 'g1');
        play(game, 'f6', 'g8');
      }
      expect(game.repetitionCount, greaterThanOrEqualTo(3));
      expect(game.result.outcome, GameOutcome.threefoldRepetition);
    });
  });
}
