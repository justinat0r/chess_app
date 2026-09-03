import 'game_result.dart';
import 'move.dart';
import 'piece.dart';

/// Snapshot of the irreversible state needed to unmake a move.
class _UndoRecord {
  _UndoRecord({
    required this.move,
    required this.castlingRights,
    required this.epSquare,
    required this.halfmoveClock,
    required this.fullmoveNumber,
  });

  final Move move;
  final int castlingRights;
  final int? epSquare;
  final int halfmoveClock;
  final int fullmoveNumber;
}

/// A complete implementation of the rules of chess.
///
/// The board is a flat list of 64 squares. Index 0 is a1 and index 63 is h8,
/// so `index = rank * 8 + file`, with rank 0 being White's back rank.
///
/// The class is deliberately UI-free, which is what makes it reusable for a
/// future engine opponent: [generateLegalMoves], [makeMove], [undoLastMove]
/// and [perft] are all a search routine needs.
class ChessGame {
  ChessGame() {
    reset();
  }

  ChessGame.fromFen(String fen) {
    loadFen(fen);
  }

  static const String startingFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  // Castling right bit flags.
  static const int whiteKingSide = 1;
  static const int whiteQueenSide = 2;
  static const int blackKingSide = 4;
  static const int blackQueenSide = 8;

  static const List<List<int>> _knightDeltas = <List<int>>[
    <int>[1, 2], <int>[2, 1], <int>[2, -1], <int>[1, -2],
    <int>[-1, -2], <int>[-2, -1], <int>[-2, 1], <int>[-1, 2],
  ];
  static const List<List<int>> _kingDeltas = <List<int>>[
    <int>[1, 0], <int>[1, 1], <int>[0, 1], <int>[-1, 1],
    <int>[-1, 0], <int>[-1, -1], <int>[0, -1], <int>[1, -1],
  ];
  static const List<List<int>> _rookDirs = <List<int>>[
    <int>[1, 0], <int>[-1, 0], <int>[0, 1], <int>[0, -1],
  ];
  static const List<List<int>> _bishopDirs = <List<int>>[
    <int>[1, 1], <int>[1, -1], <int>[-1, 1], <int>[-1, -1],
  ];
  static const List<List<int>> _queenDirs = <List<int>>[
    <int>[1, 0], <int>[-1, 0], <int>[0, 1], <int>[0, -1],
    <int>[1, 1], <int>[1, -1], <int>[-1, 1], <int>[-1, -1],
  ];

  final List<Piece?> _board = List<Piece?>.filled(64, null);
  final List<_UndoRecord> _undoStack = <_UndoRecord>[];
  final List<Move> _playedMoves = <Move>[];
  final Map<String, int> _positionCounts = <String, int>{};

  PieceColor _turn = PieceColor.white;
  int _castlingRights = 15;
  int? _epSquare;
  int _halfmoveClock = 0;
  int _fullmoveNumber = 1;

  // ---------------------------------------------------------------- geometry

  static int fileOf(int index) => index % 8;
  static int rankOf(int index) => index ~/ 8;
  static int squareAt(int file, int rank) => rank * 8 + file;
  static bool _inBounds(int file, int rank) =>
      file >= 0 && file < 8 && rank >= 0 && rank < 8;

  /// True for light squares. Drives board colouring and the
  /// same-coloured-bishops draw test.
  static bool isLightSquare(int index) =>
      (fileOf(index) + rankOf(index)) % 2 == 1;

  // ------------------------------------------------------------------- state

  Piece? pieceAt(int index) => _board[index];
  PieceColor get turn => _turn;
  int get castlingRights => _castlingRights;
  int? get enPassantSquare => _epSquare;
  int get halfmoveClock => _halfmoveClock;
  int get fullmoveNumber => _fullmoveNumber;
  List<Move> get playedMoves => List<Move>.unmodifiable(_playedMoves);
  Move? get lastMove => _playedMoves.isEmpty ? null : _playedMoves.last;
  bool get canUndo => _playedMoves.isNotEmpty;

  void reset() => loadFen(startingFen);

  void loadFen(String fen) {
    final List<String> parts = fen.trim().split(RegExp(r'\s+'));
    for (int i = 0; i < 64; i++) {
      _board[i] = null;
    }
    final List<String> rows = parts[0].split('/');
    for (int row = 0; row < rows.length && row < 8; row++) {
      int file = 0;
      for (final String ch in rows[row].split('')) {
        final int? skip = int.tryParse(ch);
        if (skip != null) {
          file += skip;
          continue;
        }
        final PieceColor color =
            ch == ch.toUpperCase() ? PieceColor.white : PieceColor.black;
        final PieceType? type = _typeFromLetter(ch.toUpperCase());
        if (type != null && file < 8) {
          _board[squareAt(file, 7 - row)] = Piece(color, type);
        }
        file++;
      }
    }

    _turn = (parts.length > 1 && parts[1] == 'b')
        ? PieceColor.black
        : PieceColor.white;

    _castlingRights = 0;
    final String rights = parts.length > 2 ? parts[2] : '-';
    if (rights.contains('K')) _castlingRights |= whiteKingSide;
    if (rights.contains('Q')) _castlingRights |= whiteQueenSide;
    if (rights.contains('k')) _castlingRights |= blackKingSide;
    if (rights.contains('q')) _castlingRights |= blackQueenSide;

    _epSquare = (parts.length > 3 && parts[3] != '-')
        ? Move.squareFromName(parts[3])
        : null;
    _halfmoveClock = parts.length > 4 ? (int.tryParse(parts[4]) ?? 0) : 0;
    _fullmoveNumber = parts.length > 5 ? (int.tryParse(parts[5]) ?? 1) : 1;

    _undoStack.clear();
    _playedMoves.clear();
    _positionCounts
      ..clear()
      ..[positionKey] = 1;
  }

  static PieceType? _typeFromLetter(String letter) {
    switch (letter) {
      case 'P':
        return PieceType.pawn;
      case 'N':
        return PieceType.knight;
      case 'B':
        return PieceType.bishop;
      case 'R':
        return PieceType.rook;
      case 'Q':
        return PieceType.queen;
      case 'K':
        return PieceType.king;
    }
    return null;
  }

  String get fen {
    final StringBuffer sb = StringBuffer();
    for (int rank = 7; rank >= 0; rank--) {
      int empty = 0;
      for (int file = 0; file < 8; file++) {
        final Piece? piece = _board[squareAt(file, rank)];
        if (piece == null) {
          empty++;
        } else {
          if (empty > 0) {
            sb.write(empty);
            empty = 0;
          }
          sb.write(piece.fenChar);
        }
      }
      if (empty > 0) sb.write(empty);
      if (rank > 0) sb.write('/');
    }
    sb.write(_turn == PieceColor.white ? ' w ' : ' b ');
    final StringBuffer rights = StringBuffer();
    if ((_castlingRights & whiteKingSide) != 0) rights.write('K');
    if ((_castlingRights & whiteQueenSide) != 0) rights.write('Q');
    if ((_castlingRights & blackKingSide) != 0) rights.write('k');
    if ((_castlingRights & blackQueenSide) != 0) rights.write('q');
    sb.write(rights.isEmpty ? '-' : rights.toString());
    sb.write(' ');
    sb.write(_epSquare == null ? '-' : Move.squareName(_epSquare!));
    sb.write(' ');
    sb.write(_halfmoveClock);
    sb.write(' ');
    sb.write(_fullmoveNumber);
    return sb.toString();
  }

  /// Compact key identifying a position for repetition detection: placement,
  /// side to move, castling rights and en passant square.
  String get positionKey {
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i < 64; i++) {
      final Piece? piece = _board[i];
      sb.write(piece == null ? '.' : piece.fenChar);
    }
    sb.write(_turn == PieceColor.white ? 'w' : 'b');
    sb.write(_castlingRights);
    sb.write(_epSquare ?? '-');
    return sb.toString();
  }

  int get repetitionCount => _positionCounts[positionKey] ?? 1;

  // -------------------------------------------------------- move generation

  /// Every legal move for [forColor], defaulting to the side to move.
  List<Move> generateLegalMoves([PieceColor? forColor]) {
    final PieceColor side = forColor ?? _turn;
    final List<Move> legal = <Move>[];
    for (final Move move in _generatePseudoLegalMoves(side)) {
      _applyMove(move);
      final bool ok = !_isKingInCheck(side);
      _undoMove();
      if (ok) legal.add(move);
    }
    return legal;
  }

  List<Move> legalMovesFrom(int square) =>
      generateLegalMoves().where((Move m) => m.from == square).toList();

  List<Move> _generatePseudoLegalMoves(PieceColor side) {
    final List<Move> moves = <Move>[];
    for (int from = 0; from < 64; from++) {
      final Piece? piece = _board[from];
      if (piece == null || piece.color != side) continue;
      switch (piece.type) {
        case PieceType.pawn:
          _pawnMoves(from, piece, moves);
          break;
        case PieceType.knight:
          _stepMoves(from, piece, _knightDeltas, moves);
          break;
        case PieceType.bishop:
          _slidingMoves(from, piece, _bishopDirs, moves);
          break;
        case PieceType.rook:
          _slidingMoves(from, piece, _rookDirs, moves);
          break;
        case PieceType.queen:
          _slidingMoves(from, piece, _queenDirs, moves);
          break;
        case PieceType.king:
          _stepMoves(from, piece, _kingDeltas, moves);
          _castlingMoves(from, piece, moves);
          break;
      }
    }
    return moves;
  }

  void _stepMoves(
      int from, Piece piece, List<List<int>> deltas, List<Move> moves) {
    final int file = fileOf(from);
    final int rank = rankOf(from);
    for (final List<int> delta in deltas) {
      final int nf = file + delta[0];
      final int nr = rank + delta[1];
      if (!_inBounds(nf, nr)) continue;
      final int to = squareAt(nf, nr);
      final Piece? target = _board[to];
      if (target != null && target.color == piece.color) continue;
      moves.add(Move(
        from: from,
        to: to,
        piece: piece,
        captured: target,
        capturedSquare: target == null ? null : to,
      ));
    }
  }

  void _slidingMoves(
      int from, Piece piece, List<List<int>> dirs, List<Move> moves) {
    final int file = fileOf(from);
    final int rank = rankOf(from);
    for (final List<int> dir in dirs) {
      int nf = file + dir[0];
      int nr = rank + dir[1];
      while (_inBounds(nf, nr)) {
        final int to = squareAt(nf, nr);
        final Piece? target = _board[to];
        if (target == null) {
          moves.add(Move(from: from, to: to, piece: piece));
        } else {
          if (target.color != piece.color) {
            moves.add(Move(
              from: from,
              to: to,
              piece: piece,
              captured: target,
              capturedSquare: to,
            ));
          }
          break;
        }
        nf += dir[0];
        nr += dir[1];
      }
    }
  }

  void _pawnMoves(int from, Piece piece, List<Move> moves) {
    final int file = fileOf(from);
    final int rank = rankOf(from);
    final int dir = piece.isWhite ? 1 : -1;
    final int startRank = piece.isWhite ? 1 : 6;
    final int promotionRank = piece.isWhite ? 7 : 0;
    final int nextRank = rank + dir;
    if (!_inBounds(file, nextRank)) return;

    final int oneAhead = squareAt(file, nextRank);
    if (_board[oneAhead] == null) {
      _addPawnMove(
          moves, from, oneAhead, piece, null, nextRank == promotionRank);
      final int doubleRank = rank + 2 * dir;
      if (rank == startRank && _inBounds(file, doubleRank)) {
        final int twoAhead = squareAt(file, doubleRank);
        if (_board[twoAhead] == null) {
          moves.add(Move(
            from: from,
            to: twoAhead,
            piece: piece,
            isDoublePawnPush: true,
          ));
        }
      }
    }

    for (final int df in <int>[-1, 1]) {
      final int nf = file + df;
      if (!_inBounds(nf, nextRank)) continue;
      final int to = squareAt(nf, nextRank);
      final Piece? target = _board[to];
      if (target != null) {
        if (target.color != piece.color) {
          _addPawnMove(
              moves, from, to, piece, target, nextRank == promotionRank);
        }
      } else if (_epSquare != null && to == _epSquare) {
        final int capturedSquare = squareAt(nf, rank);
        final Piece? capturedPawn = _board[capturedSquare];
        if (capturedPawn != null &&
            capturedPawn.type == PieceType.pawn &&
            capturedPawn.color != piece.color) {
          moves.add(Move(
            from: from,
            to: to,
            piece: piece,
            captured: capturedPawn,
            capturedSquare: capturedSquare,
            isEnPassant: true,
          ));
        }
      }
    }
  }

  void _addPawnMove(List<Move> moves, int from, int to, Piece piece,
      Piece? captured, bool isPromotion) {
    final int? capturedSquare = captured == null ? null : to;
    if (isPromotion) {
      for (final PieceType type in <PieceType>[
        PieceType.queen,
        PieceType.rook,
        PieceType.bishop,
        PieceType.knight,
      ]) {
        moves.add(Move(
          from: from,
          to: to,
          piece: piece,
          captured: captured,
          capturedSquare: capturedSquare,
          promotion: type,
        ));
      }
    } else {
      moves.add(Move(
        from: from,
        to: to,
        piece: piece,
        captured: captured,
        capturedSquare: capturedSquare,
      ));
    }
  }

  void _castlingMoves(int from, Piece king, List<Move> moves) {
    final int home = king.isWhite ? 4 : 60;
    if (from != home) return;
    final PieceColor enemy = king.color.opposite;
    if (_isSquareAttacked(home, enemy)) return;

    final int kingSide = king.isWhite ? whiteKingSide : blackKingSide;
    final int queenSide = king.isWhite ? whiteQueenSide : blackQueenSide;

    if ((_castlingRights & kingSide) != 0) {
      final int rookSquare = home + 3;
      final Piece? rook = _board[rookSquare];
      if (rook != null &&
          rook.type == PieceType.rook &&
          rook.color == king.color &&
          _board[home + 1] == null &&
          _board[home + 2] == null &&
          !_isSquareAttacked(home + 1, enemy) &&
          !_isSquareAttacked(home + 2, enemy)) {
        moves.add(Move(
          from: home,
          to: home + 2,
          piece: king,
          rookFrom: rookSquare,
          rookTo: home + 1,
        ));
      }
    }

    if ((_castlingRights & queenSide) != 0) {
      final int rookSquare = home - 4;
      final Piece? rook = _board[rookSquare];
      if (rook != null &&
          rook.type == PieceType.rook &&
          rook.color == king.color &&
          _board[home - 1] == null &&
          _board[home - 2] == null &&
          _board[home - 3] == null &&
          !_isSquareAttacked(home - 1, enemy) &&
          !_isSquareAttacked(home - 2, enemy)) {
        moves.add(Move(
          from: home,
          to: home - 2,
          piece: king,
          rookFrom: rookSquare,
          rookTo: home - 1,
        ));
      }
    }
  }

  // -------------------------------------------------------------- attack map

  bool _isSquareAttacked(int square, PieceColor byColor) {
    final int file = fileOf(square);
    final int rank = rankOf(square);

    // A white pawn attacking this square sits one rank below it.
    final int pawnRank = rank + (byColor == PieceColor.white ? -1 : 1);
    for (final int df in <int>[-1, 1]) {
      final int nf = file + df;
      if (!_inBounds(nf, pawnRank)) continue;
      final Piece? piece = _board[squareAt(nf, pawnRank)];
      if (piece != null &&
          piece.color == byColor &&
          piece.type == PieceType.pawn) {
        return true;
      }
    }

    for (final List<int> delta in _knightDeltas) {
      final int nf = file + delta[0];
      final int nr = rank + delta[1];
      if (!_inBounds(nf, nr)) continue;
      final Piece? piece = _board[squareAt(nf, nr)];
      if (piece != null &&
          piece.color == byColor &&
          piece.type == PieceType.knight) {
        return true;
      }
    }

    for (final List<int> delta in _kingDeltas) {
      final int nf = file + delta[0];
      final int nr = rank + delta[1];
      if (!_inBounds(nf, nr)) continue;
      final Piece? piece = _board[squareAt(nf, nr)];
      if (piece != null &&
          piece.color == byColor &&
          piece.type == PieceType.king) {
        return true;
      }
    }

    for (final List<int> dir in _bishopDirs) {
      if (_rayHits(file, rank, dir, byColor, PieceType.bishop)) return true;
    }
    for (final List<int> dir in _rookDirs) {
      if (_rayHits(file, rank, dir, byColor, PieceType.rook)) return true;
    }
    return false;
  }

  bool _rayHits(int file, int rank, List<int> dir, PieceColor byColor,
      PieceType slider) {
    int nf = file + dir[0];
    int nr = rank + dir[1];
    while (_inBounds(nf, nr)) {
      final Piece? piece = _board[squareAt(nf, nr)];
      if (piece != null) {
        return piece.color == byColor &&
            (piece.type == slider || piece.type == PieceType.queen);
      }
      nf += dir[0];
      nr += dir[1];
    }
    return false;
  }

  int? kingSquare(PieceColor color) {
    for (int i = 0; i < 64; i++) {
      final Piece? piece = _board[i];
      if (piece != null &&
          piece.type == PieceType.king &&
          piece.color == color) {
        return i;
      }
    }
    return null;
  }

  bool _isKingInCheck(PieceColor color) {
    final int? square = kingSquare(color);
    if (square == null) return false;
    return _isSquareAttacked(square, color.opposite);
  }

  bool get isInCheck => _isKingInCheck(_turn);
  bool isColorInCheck(PieceColor color) => _isKingInCheck(color);

  // ----------------------------------------------------------- make / unmake

  void _applyMove(Move move) {
    _undoStack.add(_UndoRecord(
      move: move,
      castlingRights: _castlingRights,
      epSquare: _epSquare,
      halfmoveClock: _halfmoveClock,
      fullmoveNumber: _fullmoveNumber,
    ));

    if (move.capturedSquare != null) _board[move.capturedSquare!] = null;
    _board[move.from] = null;
    _board[move.to] = move.promotion == null
        ? move.piece
        : Piece(move.piece.color, move.promotion!);

    if (move.rookFrom != null) {
      final Piece? rook = _board[move.rookFrom!];
      _board[move.rookFrom!] = null;
      _board[move.rookTo!] = rook;
    }

    _castlingRights = _rightsAfter(move);
    _epSquare = move.isDoublePawnPush
        ? squareAt(
            fileOf(move.from), (rankOf(move.from) + rankOf(move.to)) ~/ 2)
        : null;

    if (move.piece.type == PieceType.pawn || move.captured != null) {
      _halfmoveClock = 0;
    } else {
      _halfmoveClock++;
    }
    if (_turn == PieceColor.black) _fullmoveNumber++;
    _turn = _turn.opposite;
  }

  int _rightsAfter(Move move) {
    int rights = _castlingRights;
    if (move.piece.type == PieceType.king) {
      rights &= move.piece.isWhite
          ? ~(whiteKingSide | whiteQueenSide)
          : ~(blackKingSide | blackQueenSide);
    }
    rights = _clearRightsForSquare(rights, move.from);
    rights = _clearRightsForSquare(rights, move.to);
    if (move.capturedSquare != null) {
      rights = _clearRightsForSquare(rights, move.capturedSquare!);
    }
    return rights;
  }

  static int _clearRightsForSquare(int rights, int square) {
    switch (square) {
      case 0:
        return rights & ~whiteQueenSide;
      case 7:
        return rights & ~whiteKingSide;
      case 56:
        return rights & ~blackQueenSide;
      case 63:
        return rights & ~blackKingSide;
    }
    return rights;
  }

  void _undoMove() {
    if (_undoStack.isEmpty) return;
    final _UndoRecord record = _undoStack.removeLast();
    final Move move = record.move;

    _board[move.to] = null;
    _board[move.from] = move.piece;

    if (move.rookFrom != null) {
      final Piece? rook = _board[move.rookTo!];
      _board[move.rookTo!] = null;
      _board[move.rookFrom!] = rook;
    }
    if (move.captured != null && move.capturedSquare != null) {
      _board[move.capturedSquare!] = move.captured;
    }

    _castlingRights = record.castlingRights;
    _epSquare = record.epSquare;
    _halfmoveClock = record.halfmoveClock;
    _fullmoveNumber = record.fullmoveNumber;
    _turn = _turn.opposite;
  }

  /// Plays [move] and records it in the game history.
  void makeMove(Move move) {
    _applyMove(move);
    _playedMoves.add(move);
    final String key = positionKey;
    _positionCounts[key] = (_positionCounts[key] ?? 0) + 1;
  }

  /// Takes back the last played move. False when there is nothing to undo.
  bool undoLastMove() {
    if (_playedMoves.isEmpty) return false;
    final String key = positionKey;
    final int remaining = (_positionCounts[key] ?? 1) - 1;
    if (remaining <= 0) {
      _positionCounts.remove(key);
    } else {
      _positionCounts[key] = remaining;
    }
    _undoMove();
    _playedMoves.removeLast();
    return true;
  }

  /// The legal move matching [from]/[to] and optionally [promotion], or null
  /// when no such move is legal.
  Move? findMove(int from, int to, {PieceType? promotion}) {
    for (final Move move in generateLegalMoves()) {
      if (move.from == from &&
          move.to == to &&
          (promotion == null || move.promotion == promotion)) {
        return move;
      }
    }
    return null;
  }

  // ------------------------------------------------------------ conclusions

  /// True when neither side has mating material: bare kings, king and one
  /// minor piece, or bishops that all stand on one square colour.
  bool get hasInsufficientMaterial {
    int knights = 0;
    final Set<bool> bishopSquares = <bool>{};
    for (int i = 0; i < 64; i++) {
      final Piece? piece = _board[i];
      if (piece == null) continue;
      switch (piece.type) {
        case PieceType.pawn:
        case PieceType.rook:
        case PieceType.queen:
          return false;
        case PieceType.knight:
          knights++;
          break;
        case PieceType.bishop:
          bishopSquares.add(isLightSquare(i));
          break;
        case PieceType.king:
          break;
      }
    }
    if (knights == 0) return bishopSquares.length <= 1;
    return knights == 1 && bishopSquares.isEmpty;
  }

  /// Current state of the game: ongoing, decided, or drawn.
  GameResult get result {
    if (generateLegalMoves().isEmpty) {
      return _isKingInCheck(_turn)
          ? GameResult(GameOutcome.checkmate, winner: _turn.opposite)
          : const GameResult(GameOutcome.stalemate);
    }
    if (hasInsufficientMaterial) {
      return const GameResult(GameOutcome.insufficientMaterial);
    }
    if (_halfmoveClock >= 100) {
      return const GameResult(GameOutcome.fiftyMoveRule);
    }
    if (repetitionCount >= 3) {
      return const GameResult(GameOutcome.threefoldRepetition);
    }
    return GameResult.ongoing;
  }

  /// Standard algebraic notation for [move]. Call it *before* playing the
  /// move, since disambiguation depends on the current position.
  String toSan(Move move) {
    final StringBuffer sb = StringBuffer();
    if (move.isCastle) {
      sb.write(move.isKingSideCastle ? 'O-O' : 'O-O-O');
    } else if (move.piece.type == PieceType.pawn) {
      if (move.isCapture) {
        sb.write(Move.squareName(move.from)[0]);
        sb.write('x');
      }
      sb.write(Move.squareName(move.to));
      if (move.promotion != null) {
        sb.write('=');
        sb.write(move.promotion!.letter);
      }
    } else {
      sb.write(move.piece.type.letter);
      final List<Move> rivals = generateLegalMoves()
          .where((Move m) =>
              m.to == move.to &&
              m.from != move.from &&
              m.piece.type == move.piece.type &&
              m.piece.color == move.piece.color)
          .toList();
      if (rivals.isNotEmpty) {
        final bool fileShared =
            rivals.any((Move m) => fileOf(m.from) == fileOf(move.from));
        final bool rankShared =
            rivals.any((Move m) => rankOf(m.from) == rankOf(move.from));
        if (!fileShared) {
          sb.write(Move.squareName(move.from)[0]);
        } else if (!rankShared) {
          sb.write(rankOf(move.from) + 1);
        } else {
          sb.write(Move.squareName(move.from));
        }
      }
      if (move.isCapture) sb.write('x');
      sb.write(Move.squareName(move.to));
    }

    _applyMove(move);
    final bool givesCheck = _isKingInCheck(_turn);
    final bool noReplies = generateLegalMoves().isEmpty;
    _undoMove();
    if (givesCheck) sb.write(noReplies ? '#' : '+');

    return sb.toString();
  }

  /// Node count of the legal move tree to [depth]. The tests use it to verify
  /// move generation; a future search-based opponent can reuse it.
  int perft(int depth) {
    if (depth <= 0) return 1;
    final List<Move> moves = generateLegalMoves();
    if (depth == 1) return moves.length;
    int nodes = 0;
    for (final Move move in moves) {
      _applyMove(move);
      nodes += perft(depth - 1);
      _undoMove();
    }
    return nodes;
  }
}
