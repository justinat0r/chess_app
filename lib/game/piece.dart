// Core piece vocabulary shared by the rules engine and the UI layer.

enum PieceColor {
  white,
  black;

  PieceColor get opposite =>
      this == PieceColor.white ? PieceColor.black : PieceColor.white;

  /// Human readable name used on banners and result screens.
  String get label => this == PieceColor.white ? 'White' : 'Black';
}

enum PieceType {
  pawn('P', 1),
  knight('N', 3),
  bishop('B', 3),
  rook('R', 5),
  queen('Q', 9),
  king('K', 0);

  const PieceType(this.letter, this.value);

  /// Standard algebraic notation letter (uppercase).
  final String letter;

  /// Rough material value, used for the captured-material readout.
  final int value;
}

class Piece {
  const Piece(this.color, this.type);

  final PieceColor color;
  final PieceType type;

  bool get isWhite => color == PieceColor.white;

  /// FEN character: uppercase for white, lowercase for black.
  String get fenChar =>
      isWhite ? type.letter : type.letter.toLowerCase();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Piece && other.color == color && other.type == type);

  @override
  int get hashCode => Object.hash(color, type);

  @override
  String toString() => '${color.name} ${type.name}';
}
