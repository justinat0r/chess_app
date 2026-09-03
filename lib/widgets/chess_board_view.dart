import 'package:flutter/material.dart';

import '../game/chess_game.dart';
import '../game/game_controller.dart';
import '../game/move.dart';
import '../game/piece.dart';
import 'chess_piece_view.dart';

/// The 8x8 board: classic light/dark squares, coordinates, move highlights and
/// tap handling. Rendering is driven entirely by [controller].
class ChessBoardView extends StatelessWidget {
  const ChessBoardView({
    super.key,
    required this.controller,
    required this.onSquareTap,
  });

  final GameController controller;
  final ValueChanged<int> onSquareTap;

  static const Color lightSquare = Color(0xFFF0D9B5);
  static const Color darkSquare = Color(0xFFB58863);
  static const Color selectedTint = Color(0x8AF7D157);
  static const Color lastMoveTint = Color(0x66F7D157);
  static const Color checkTint = Color(0x9AE05B4B);

  /// Widget key for a board square, so taps can be targeted by square.
  static ValueKey<String> squareKey(int index) =>
      ValueKey<String>('square-${Move.squareName(index)}');

  /// Board index shown at [row]/[col] of the drawn grid, honouring the flip.
  int _indexFor(int row, int col, bool flipped) =>
      flipped ? row * 8 + (7 - col) : (7 - row) * 8 + col;

  @override
  Widget build(BuildContext context) {
    final bool flipped = controller.isBoardFlipped;
    final Move? last = controller.lastMove;
    final int? checkedKing = controller.checkedKingSquare;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double borderWidth = 3;
        final double boardSize = constraints.biggest.shortestSide;
        // The border is drawn inside the box, so the squares share what is
        // left over. Without this the grid would overflow by twice the border.
        final double squareSize = (boardSize - borderWidth * 2) / 8;
        return Center(
          child: Container(
            width: boardSize,
            height: boardSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF4E3524),
                width: borderWidth,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x59000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Column(
                children: List<Widget>.generate(8, (int row) {
                  return Row(
                    children: List<Widget>.generate(8, (int col) {
                      final int index = _indexFor(row, col, flipped);
                      return _buildSquare(
                        context: context,
                        index: index,
                        size: squareSize,
                        isBottomRow: row == 7,
                        isLeftColumn: col == 0,
                        lastMove: last,
                        checkedKing: checkedKing,
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSquare({
    required BuildContext context,
    required int index,
    required double size,
    required bool isBottomRow,
    required bool isLeftColumn,
    required Move? lastMove,
    required int? checkedKing,
  }) {
    final bool light = ChessGame.isLightSquare(index);
    final Color base = light ? lightSquare : darkSquare;
    final Piece? piece = controller.game.pieceAt(index);
    final bool selected = controller.selectedSquare == index;
    final bool isTarget = controller.isTarget(index);
    final bool partOfLastMove =
        lastMove != null && (lastMove.from == index || lastMove.to == index);
    final bool inCheck = checkedKing == index;

    return GestureDetector(
      key: squareKey(index),
      onTap: () => onSquareTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(color: base),
            if (partOfLastMove) const ColoredBox(color: lastMoveTint),
            if (selected) const ColoredBox(color: selectedTint),
            if (inCheck)
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: <Color>[checkTint, Color(0x00E05B4B)],
                    radius: 0.75,
                  ),
                ),
              ),
            if (isLeftColumn)
              Padding(
                padding: const EdgeInsets.only(left: 2, top: 1),
                child: Text(
                  '${ChessGame.rankOf(index) + 1}',
                  style: TextStyle(
                    fontSize: size * 0.20,
                    fontWeight: FontWeight.w700,
                    color: light ? darkSquare : lightSquare,
                  ),
                ),
              ),
            if (isBottomRow)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 2, bottom: 1),
                  child: Text(
                    Move.squareName(index)[0],
                    style: TextStyle(
                      fontSize: size * 0.20,
                      fontWeight: FontWeight.w700,
                      color: light ? darkSquare : lightSquare,
                    ),
                  ),
                ),
              ),
            if (piece != null)
              Padding(
                padding: EdgeInsets.all(size * 0.06),
                child: ChessPieceView(piece: piece),
              ),
            if (isTarget)
              CustomPaint(
                painter: _TargetMarkerPainter(isCapture: piece != null),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dot for a quiet move, ring for a capture.
class _TargetMarkerPainter extends CustomPainter {
  const _TargetMarkerPainter({required this.isCapture});

  final bool isCapture;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    if (isCapture) {
      canvas.drawCircle(
        center,
        size.shortestSide * 0.44,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.shortestSide * 0.09
          ..color = const Color(0x7A1B1B1B),
      );
    } else {
      canvas.drawCircle(
        center,
        size.shortestSide * 0.16,
        Paint()..color = const Color(0x6B1B1B1B),
      );
    }
  }

  @override
  bool shouldRepaint(_TargetMarkerPainter oldDelegate) =>
      oldDelegate.isCapture != isCapture;
}
