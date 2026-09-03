import 'package:chess_app/game/chess_game.dart';
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
  test('board indexing matches algebraic squares', () {
    expect(sq('a1'), 0);
    expect(sq('h1'), 7);
    expect(sq('a8'), 56);
    expect(sq('h8'), 63);
    expect(Move.squareName(28), 'e4');
    expect(ChessGame.isLightSquare(sq('a1')), isFalse);
    expect(ChessGame.isLightSquare(sq('h1')), isTrue);
  });

  test('starting position is set up correctly', () {
    final ChessGame game = ChessGame();
    expect(game.pieceAt(sq('e1')), const Piece(PieceColor.white, PieceType.king));
    expect(game.pieceAt(sq('d8')), const Piece(PieceColor.black, PieceType.queen));
    expect(game.pieceAt(sq('a2')), const Piece(PieceColor.white, PieceType.pawn));
    expect(game.pieceAt(sq('e4')), isNull);
    expect(game.turn, PieceColor.white);
    expect(game.fen, ChessGame.startingFen);
  });

  test('kingside castling moves both king and rook', () {
    final ChessGame game =
        ChessGame.fromFen('rnbqkbnr/pppppppp/8/8/8/5NP1/PPPPPPBP/RNBQK2R w KQkq - 0 1');
    play(game, 'e1', 'g1');
    expect(game.pieceAt(sq('g1')), const Piece(PieceColor.white, PieceType.king));
    expect(game.pieceAt(sq('f1')), const Piece(PieceColor.white, PieceType.rook));
    expect(game.pieceAt(sq('h1')), isNull);
    expect(game.pieceAt(sq('e1')), isNull);
    expect(game.castlingRights & ChessGame.whiteKingSide, 0);
  });

  test('queenside castling works and rights are dropped after a rook move', () {
    final ChessGame game =
        ChessGame.fromFen('r3kbnr/pppqpppp/2np4/8/8/2NPB3/PPPQPPPP/R3KBNR w KQkq - 0 1');
    play(game, 'e1', 'c1');
    expect(game.pieceAt(sq('c1')), const Piece(PieceColor.white, PieceType.king));
    expect(game.pieceAt(sq('d1')), const Piece(PieceColor.white, PieceType.rook));
    expect(game.castlingRights & ChessGame.whiteQueenSide, 0);
    expect(game.castlingRights & ChessGame.blackQueenSide,
        ChessGame.blackQueenSide);
  });

  test('castling is illegal through check and out of check', () {
    final ChessGame throughCheck =
        ChessGame.fromFen('4k3/8/8/8/8/8/5r2/4K2R w K - 0 1');
    expect(throughCheck.findMove(sq('e1'), sq('g1')), isNull);

    final ChessGame inCheck =
        ChessGame.fromFen('4k3/8/8/8/8/8/4r3/4K2R w K - 0 1');
    expect(inCheck.findMove(sq('e1'), sq('g1')), isNull);

    final ChessGame allowed =
        ChessGame.fromFen('4k3/8/8/8/8/8/7r/4K2R w K - 0 1');
    expect(allowed.findMove(sq('e1'), sq('g1')), isNotNull);
  });

  test('en passant captures the passed pawn', () {
    final ChessGame game =
        ChessGame.fromFen('rnbqkbnr/pp1ppppp/8/8/4pP2/8/PPPPP1PP/RNBQKBNR b KQkq f3 0 3');
    final Move? capture = game.findMove(sq('e4'), sq('f3'));
    expect(capture, isNotNull);
    expect(capture!.isEnPassant, isTrue);
    game.makeMove(capture);
    expect(game.pieceAt(sq('f3')), const Piece(PieceColor.black, PieceType.pawn));
    expect(game.pieceAt(sq('f4')), isNull);
  });

  test('en passant is only available for one move', () {
    final ChessGame game = ChessGame();
    play(game, 'e2', 'e4');
    play(game, 'a7', 'a6');
    play(game, 'e4', 'e5');
    play(game, 'd7', 'd5');
    expect(game.enPassantSquare, sq('d6'));
    expect(game.findMove(sq('e5'), sq('d6')), isNotNull);
    play(game, 'h2', 'h3');
    play(game, 'h7', 'h6');
    expect(game.findMove(sq('e5'), sq('d6')), isNull);
  });

  test('promotion offers four choices and applies the chosen piece', () {
    final ChessGame game = ChessGame.fromFen('8/4P1k1/8/8/8/8/8/4K3 w - - 0 1');
    final List<Move> promotions = game
        .generateLegalMoves()
        .where((Move m) => m.from == sq('e7') && m.to == sq('e8'))
        .toList();
    expect(promotions.length, 4);
    play(game, 'e7', 'e8', promotion: PieceType.knight);
    expect(game.pieceAt(sq('e8')),
        const Piece(PieceColor.white, PieceType.knight));
  });

  test('a pinned piece may not move', () {
    final ChessGame game = ChessGame.fromFen('4r2k/8/8/8/8/8/4N3/4K3 w - - 0 1');
    expect(game.legalMovesFrom(sq('e2')), isEmpty);
    expect(game.legalMovesFrom(sq('e1')), isNotEmpty);
  });

  test('a king may not move into check', () {
    final ChessGame game = ChessGame.fromFen('4k3/8/8/8/8/8/5r2/4K3 w - - 0 1');
    final List<int> destinations =
        game.legalMovesFrom(sq('e1')).map((Move m) => m.to).toList();
    expect(destinations, isNot(contains(sq('f1'))));
    expect(destinations, isNot(contains(sq('e2'))));
    expect(destinations, contains(sq('d1')));
  });

  test('undo restores the exact previous position', () {
    final ChessGame game = ChessGame();
    final String before = game.fen;
    play(game, 'e2', 'e4');
    play(game, 'd7', 'd5');
    play(game, 'e4', 'd5');
    expect(game.canUndo, isTrue);
    game.undoLastMove();
    game.undoLastMove();
    game.undoLastMove();
    expect(game.fen, before);
    expect(game.canUndo, isFalse);
  });

  test('undo restores castling rights and en passant state', () {
    final ChessGame game =
        ChessGame.fromFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
    final String before = game.fen;
    play(game, 'e1', 'g1');
    game.undoLastMove();
    expect(game.fen, before);
    expect(game.pieceAt(sq('h1')), const Piece(PieceColor.white, PieceType.rook));
  });

  test('algebraic notation covers captures, castling, promotion and mate', () {
    final ChessGame game = ChessGame();
    expect(game.toSan(game.findMove(sq('g1'), sq('f3'))!), 'Nf3');
    play(game, 'f2', 'f3');
    play(game, 'e7', 'e5');
    play(game, 'g2', 'g4');
    expect(game.toSan(game.findMove(sq('d8'), sq('h4'))!), 'Qh4#');

    final ChessGame castle =
        ChessGame.fromFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
    expect(castle.toSan(castle.findMove(sq('e1'), sq('g1'))!), 'O-O');
    expect(castle.toSan(castle.findMove(sq('e1'), sq('c1'))!), 'O-O-O');

    final ChessGame promo = ChessGame.fromFen('7k/4P3/8/8/8/8/8/4K3 w - - 0 1');
    expect(
      promo.toSan(promo.findMove(sq('e7'), sq('e8'), promotion: PieceType.queen)!),
      'e8=Q+',
    );
  });
}
