import 'package:flutter/foundation.dart';

import 'chess_ai.dart';
import 'chess_game.dart';
import 'game_result.dart';
import 'move.dart';
import 'piece.dart';

/// Who controls a side. Only [human] is wired up in this build; [computer] is
/// the seam a future engine opponent plugs into.
enum PlayerType { human, computer }

/// Holds the board state plus the selection, notation and result state the
/// screens need, and notifies listeners whenever any of it changes.
class GameController extends ChangeNotifier {
  GameController({
    this.whitePlayer = PlayerType.human,
    this.blackPlayer = PlayerType.human,
    this.ai,
    bool rotateForBlack = false,
  }) {
    _rotateForBlack = rotateForBlack;
  }

  final ChessGame game = ChessGame();

  /// Who plays White and Black. Both are human in this build.
  final PlayerType whitePlayer;
  final PlayerType blackPlayer;

  /// Engine opponent, if one is ever supplied. Null means human-only play.
  final ChessAi? ai;

  bool _rotateForBlack = false;
  int? _selectedSquare;
  List<Move> _movesForSelection = <Move>[];
  final List<String> _notation = <String>[];
  GameResult _result = GameResult.ongoing;
  bool _thinking = false;

  // ------------------------------------------------------------------ state

  int? get selectedSquare => _selectedSquare;
  List<String> get notation => List<String>.unmodifiable(_notation);
  GameResult get result => _result;
  bool get isGameOver => _result.isOver;
  PieceColor get turn => game.turn;
  Move? get lastMove => game.lastMove;
  bool get canUndo => game.canUndo && !_thinking && !isGameOver;

  /// True while a computer opponent is choosing a move, so the board can lock.
  bool get isThinking => _thinking;

  /// When true the board rotates so the player to move always sits at the
  /// bottom, which suits two people sharing one phone.
  bool get rotateForBlack => _rotateForBlack;
  set rotateForBlack(bool value) {
    if (_rotateForBlack == value) return;
    _rotateForBlack = value;
    notifyListeners();
  }

  /// Whether the board is currently drawn from Black's side.
  bool get isBoardFlipped =>
      _rotateForBlack && game.turn == PieceColor.black && !isGameOver;

  PlayerType playerFor(PieceColor color) =>
      color == PieceColor.white ? whitePlayer : blackPlayer;

  /// Display name for a side: the colour, or the engine's name.
  String nameFor(PieceColor color) {
    final ChessAi? engine = ai;
    if (playerFor(color) == PlayerType.computer && engine != null) {
      return engine.name;
    }
    return color.label;
  }

  bool get isHumanTurn => playerFor(game.turn) == PlayerType.human;

  /// The king square to flag when its owner is in check, else null.
  int? get checkedKingSquare =>
      game.isInCheck ? game.kingSquare(game.turn) : null;

  /// Pieces captured from [color], in the order they were taken.
  List<Piece> capturedFrom(PieceColor color) => game.playedMoves
      .map((Move m) => m.captured)
      .whereType<Piece>()
      .where((Piece p) => p.color == color)
      .toList();

  /// Material lead for [color] in pawns, or 0 when [color] is not ahead.
  int materialLead(PieceColor color) {
    int taken(PieceColor side) => capturedFrom(side.opposite)
        .fold(0, (int sum, Piece p) => sum + p.type.value);
    final int lead = taken(color) - taken(color.opposite);
    return lead > 0 ? lead : 0;
  }

  // ------------------------------------------------------------ interaction

  /// Legal destinations from the selected square.
  Set<int> get targetSquares =>
      _movesForSelection.map((Move m) => m.to).toSet();

  bool isTarget(int square) => targetSquares.contains(square);

  /// Moves from the current selection to [square]. More than one result means
  /// a promotion choice is pending.
  List<Move> movesTo(int square) =>
      _movesForSelection.where((Move m) => m.to == square).toList();

  bool _isOwnPiece(int square) {
    final Piece? piece = game.pieceAt(square);
    return piece != null && piece.color == game.turn;
  }

  /// Selects [square] when it holds a piece of the side to move, and clears
  /// the selection otherwise.
  void select(int square) {
    if (isGameOver || !isHumanTurn) return;
    if (_isOwnPiece(square)) {
      _selectedSquare = square;
      _movesForSelection = game.legalMovesFrom(square);
    } else {
      _selectedSquare = null;
      _movesForSelection = <Move>[];
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedSquare == null) return;
    _selectedSquare = null;
    _movesForSelection = <Move>[];
    notifyListeners();
  }

  /// Plays [move], records notation and re-evaluates the result.
  void playMove(Move move) {
    if (isGameOver) return;
    _notation.add(game.toSan(move));
    game.makeMove(move);
    _selectedSquare = null;
    _movesForSelection = <Move>[];
    _result = game.result;
    notifyListeners();
    _maybeRunComputerMove();
  }

  /// Takes back the last move, plus the engine's reply when playing a computer.
  void undo() {
    if (_thinking || !game.canUndo) return;
    game.undoLastMove();
    if (_notation.isNotEmpty) _notation.removeLast();
    if (!isHumanTurn && game.canUndo) {
      game.undoLastMove();
      if (_notation.isNotEmpty) _notation.removeLast();
    }
    _selectedSquare = null;
    _movesForSelection = <Move>[];
    _result = game.result;
    notifyListeners();
  }

  /// Ends the game in favour of [color]'s opponent.
  void resign(PieceColor color) {
    if (isGameOver) return;
    _result = GameResult(GameOutcome.resignation, winner: color.opposite);
    _selectedSquare = null;
    _movesForSelection = <Move>[];
    notifyListeners();
  }

  /// Starts a fresh game from the initial position.
  void restart() {
    game.reset();
    _notation.clear();
    _selectedSquare = null;
    _movesForSelection = <Move>[];
    _result = GameResult.ongoing;
    _thinking = false;
    notifyListeners();
    _maybeRunComputerMove();
  }

  /// Hands the turn to the engine when the side to move is a computer.
  ///
  /// With no [ChessAi] supplied this returns immediately, which keeps the
  /// current build purely two-player without any dead UI states.
  Future<void> _maybeRunComputerMove() async {
    final ChessAi? engine = ai;
    if (engine == null || isGameOver || isHumanTurn || _thinking) return;
    _thinking = true;
    notifyListeners();
    try {
      final Move? move = await engine.chooseMove(game);
      if (move != null && !isGameOver) {
        _notation.add(game.toSan(move));
        game.makeMove(move);
        _result = game.result;
      }
    } finally {
      _thinking = false;
      notifyListeners();
    }
  }
}
