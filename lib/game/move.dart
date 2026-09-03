import 'piece.dart';

/// A fully described move. Everything needed to make *and* unmake the move is
/// captured here so the engine can search without extra bookkeeping.
class Move {
  const Move({
    required this.from,
    required this.to,
    required this.piece,
    this.captured,
    this.capturedSquare,
    this.promotion,
    this.isEnPassant = false,
    this.isDoublePawnPush = false,
    this.rookFrom,
    this.rookTo,
  });

  /// Origin square index, 0..63, where 0 is a1 and 63 is h8.
  final int from;

  /// Destination square index.
  final int to;

  final Piece piece;

  /// Piece removed by this move, if any.
  final Piece? captured;

  /// Square the captured piece stood on. Differs from [to] for en passant.
  final int? capturedSquare;

  /// Piece type a pawn is promoted to, if this move promotes.
  final PieceType? promotion;

  final bool isEnPassant;
  final bool isDoublePawnPush;

  /// Rook origin/destination when this move is a castle.
  final int? rookFrom;
  final int? rookTo;

  bool get isCapture => captured != null;
  bool get isCastle => rookFrom != null;
  bool get isKingSideCastle => isCastle && to > from;

  static const String _files = 'abcdefgh';

  static String squareName(int index) =>
      '${_files[index % 8]}${index ~/ 8 + 1}';

  static int? squareFromName(String name) {
    if (name.length < 2) return null;
    final file = _files.indexOf(name[0].toLowerCase());
    final rank = int.tryParse(name[1]);
    if (file < 0 || rank == null || rank < 1 || rank > 8) return null;
    return (rank - 1) * 8 + file;
  }

  /// Long algebraic (UCI) form, e.g. `e2e4` or `e7e8q`.
  String get uci =>
      '${squareName(from)}${squareName(to)}'
      '${promotion == null ? '' : promotion!.letter.toLowerCase()}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Move &&
          other.from == from &&
          other.to == to &&
          other.promotion == promotion);

  @override
  int get hashCode => Object.hash(from, to, promotion);

  @override
  String toString() => uci;
}
