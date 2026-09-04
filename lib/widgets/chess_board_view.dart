import 'package:flutter/material.dart';

import '../game/chess_game.dart';
import '../game/game_controller.dart';
import '../game/move.dart';
import '../game/piece.dart';
import 'chess_piece_view.dart';

/// The 8x8 board: classic light/dark squares, coordinates, move highlights and
/// tap handling. Rendering is driven entirely by [controller].
class ChessBoardView extends StatefulWidget {
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

  @override
  State<ChessBoardView> createState() => _ChessBoardViewState();
}

class _ChessBoardViewState extends State<ChessBoardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(vsync: this);
  late final CurvedAnimation _progress =
      CurvedAnimation(parent: _animation, curve: Curves.easeInOutCubic);

  /// The move currently being drawn in flight, or null when the board is idle.
  Move? _animating;

  /// Moves that have been played but not yet drawn, oldest first.
  ///
  /// A computer opponent answers within the same frame the player moves in, so
  /// two moves can land before a single one has been drawn. They queue here and
  /// play out in turn instead of the newer one cutting the older one short.
  final List<Move> _pending = <Move>[];

  /// Moves seen so far, so a fresh entry can be told from an undo or a reset.
  int _seenMoveCount = 0;

  @override
  void initState() {
    super.initState();
    _seenMoveCount = widget.controller.game.playedMoves.length;
    widget.controller.addListener(_onControllerChanged);
    _animation.addStatusListener(_onAnimationStatus);
  }

  @override
  void didUpdateWidget(covariant ChessBoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _seenMoveCount = widget.controller.game.playedMoves.length;
      _stopAnimation();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _progress.dispose();
    _animation.dispose();
    super.dispose();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _startNext();
  }

  void _onControllerChanged() {
    final List<Move> played = widget.controller.game.playedMoves;
    final int count = played.length;
    if (count == _seenMoveCount) return;
    if (count > _seenMoveCount) {
      // Queue every move played since the last look; usually one, but two when
      // an engine has already answered.
      _pending.addAll(played.getRange(_seenMoveCount, count));
      _seenMoveCount = count;
      if (_animating == null) {
        _startNext();
      } else {
        setState(() {});
      }
      return;
    }
    // Fewer moves than before: an undo or a reset, which simply snaps.
    _seenMoveCount = count;
    _stopAnimation();
  }

  /// Begins the next queued move, or goes idle when the queue empties.
  void _startNext() {
    if (_pending.isEmpty) {
      if (_animating != null) setState(() => _animating = null);
      return;
    }
    final Move move = _pending.removeAt(0);
    _animation.duration = _durationFor(_pathLength(_pathFor(move, false)));
    setState(() => _animating = move);
    _animation.forward(from: 0);
  }

  void _stopAnimation() {
    _animation.stop();
    final bool wasBusy = _animating != null || _pending.isNotEmpty;
    _pending.clear();
    if (wasBusy) setState(() => _animating = null);
  }

  /// Every move still waiting to be drawn, the one in flight first. The board
  /// has already applied all of them, so these are what the overlay must undo.
  List<Move> get _undrawn =>
      <Move>[?_animating, ..._pending];

  /// Board index shown at [row]/[col] of the drawn grid, honouring the flip.
  int _indexFor(int row, int col, bool flipped) =>
      flipped ? row * 8 + (7 - col) : (7 - row) * 8 + col;

  /// Centre of [index] in grid units, where one unit is one square and the
  /// origin is the top-left corner of the drawn grid.
  static Offset _centreOf(int index, bool flipped) {
    final int file = index % 8;
    final int rank = index ~/ 8;
    return Offset(
      (flipped ? 7 - file : file) + 0.5,
      (flipped ? rank : 7 - rank) + 0.5,
    );
  }

  /// The route a piece is seen to take, in grid units. Every piece but the
  /// knight travels in a straight line along its rank, file or diagonal; the
  /// knight turns a corner so its flight traces the L it is named for.
  static List<Offset> _pathFor(Move move, bool flipped) {
    final Offset from = _centreOf(move.from, flipped);
    final Offset to = _centreOf(move.to, flipped);
    if (move.piece.type != PieceType.knight) {
      return <Offset>[from, to];
    }
    // Long leg first, then the short one, matching how the move is read out.
    final bool longLegIsHorizontal =
        (to.dx - from.dx).abs() > (to.dy - from.dy).abs();
    final Offset corner = longLegIsHorizontal
        ? Offset(to.dx, from.dy)
        : Offset(from.dx, to.dy);
    return <Offset>[from, corner, to];
  }

  /// Straight-line route for the rook half of a castle.
  static List<Offset> _rookPathFor(Move move, bool flipped) => <Offset>[
        _centreOf(move.rookFrom!, flipped),
        _centreOf(move.rookTo!, flipped),
      ];

  static double _pathLength(List<Offset> points) {
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).distance;
    }
    return total;
  }

  /// Point [t] of the way along [points], measured by distance travelled so
  /// the piece keeps an even speed through any corner.
  static Offset _pointAlong(List<Offset> points, double t) {
    final double total = _pathLength(points);
    if (total == 0) return points.first;
    double remaining = t.clamp(0.0, 1.0) * total;
    for (int i = 1; i < points.length; i++) {
      final double leg = (points[i] - points[i - 1]).distance;
      if (remaining <= leg || i == points.length - 1) {
        final double f = leg == 0 ? 1.0 : (remaining / leg).clamp(0.0, 1.0);
        return Offset.lerp(points[i - 1], points[i], f)!;
      }
      remaining -= leg;
    }
    return points.last;
  }

  /// Longer journeys take a little longer, but every move lands quickly: this
  /// is the pace of a hand picking a piece up and setting it down again.
  static Duration _durationFor(double squaresTravelled) => Duration(
        milliseconds: (120 + squaresTravelled * 28).round().clamp(155, 350),
      );

  /// Squares a not-yet-drawn move has already filled. The grid must leave
  /// these empty so the overlay can put the piece where the eye expects it.
  Set<int> get _squaresInFlight {
    final Set<int> squares = <int>{};
    for (final Move move in _undrawn) {
      squares.add(move.to);
      if (move.rookTo != null) squares.add(move.rookTo!);
    }
    return squares;
  }

  @override
  Widget build(BuildContext context) {
    final bool flipped = widget.controller.isBoardFlipped;
    final Move? last = widget.controller.lastMove;
    final int? checkedKing = widget.controller.checkedKingSquare;
    final Set<int> inFlight = _squaresInFlight;

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
              child: Stack(
                children: <Widget>[
                  Column(
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
                            inFlight: inFlight,
                          );
                        }),
                      );
                    }),
                  ),
                  _buildMoveAnimation(squareSize, flipped),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// The pieces the grid cannot draw itself while moves play out: the one in
  /// flight, the pieces it is about to take, and any queued move still holding
  /// its starting square.
  Widget _buildMoveAnimation(double squareSize, bool flipped) {
    final Move? current = _animating;
    if (current == null) return const SizedBox.shrink();

    // Squares an earlier undrawn move will arrive on. A piece standing there
    // has not been taken yet as far as the eye is concerned, so a later move
    // must not also draw it.
    final Set<int> claimed = <int>{};

    final List<Widget> waiting = <Widget>[];
    for (final Move move in _undrawn) {
      final Piece? captured = move.captured;
      final int capturedSquare = move.capturedSquare ?? move.to;
      if (captured != null &&
          !claimed.contains(capturedSquare) &&
          move != current) {
        waiting.add(_flyingPiece(
          piece: captured,
          centre: _centreOf(capturedSquare, flipped),
          size: squareSize,
        ));
      }
      if (move != current) {
        // Queued: still standing where it started.
        waiting.add(_flyingPiece(
          piece: move.piece,
          centre: _centreOf(move.from, flipped),
          size: squareSize,
        ));
        if (move.rookFrom != null) {
          waiting.add(_flyingPiece(
            piece: Piece(move.piece.color, PieceType.rook),
            centre: _centreOf(move.rookFrom!, flipped),
            size: squareSize,
          ));
        }
      }
      claimed.add(move.to);
      if (move.rookTo != null) claimed.add(move.rookTo!);
    }

    final List<Offset> path = _pathFor(current, flipped);
    final List<Offset>? rookPath =
        current.isCastle ? _rookPathFor(current, flipped) : null;
    final Piece? captured = current.captured;
    final int capturedSquare = current.capturedSquare ?? current.to;

    return AnimatedBuilder(
      animation: _progress,
      builder: (BuildContext context, _) {
        final double t = _progress.value;
        return Stack(
          children: <Widget>[
            ...waiting,
            // The taken piece holds its square until the mover arrives on it.
            if (captured != null)
              _flyingPiece(
                piece: captured,
                centre: _centreOf(capturedSquare, flipped),
                size: squareSize,
                opacity: (1 - (t - 0.55) / 0.45).clamp(0.0, 1.0),
              ),
            if (rookPath != null)
              _flyingPiece(
                piece: Piece(current.piece.color, PieceType.rook),
                centre: _pointAlong(rookPath, t),
                size: squareSize,
              ),
            _flyingPiece(
              piece: current.piece,
              centre: _pointAlong(path, t),
              size: squareSize,
            ),
          ],
        );
      },
    );
  }

  /// A piece drawn free of the grid, centred on [centre] in grid units.
  Widget _flyingPiece({
    required Piece piece,
    required Offset centre,
    required double size,
    double opacity = 1,
  }) {
    return Positioned(
      left: (centre.dx - 0.5) * size,
      top: (centre.dy - 0.5) * size,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Padding(
            padding: EdgeInsets.all(size * 0.06),
            child: ChessPieceView(piece: piece),
          ),
        ),
      ),
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
    required Set<int> inFlight,
  }) {
    final bool light = ChessGame.isLightSquare(index);
    final Color base = light
        ? ChessBoardView.lightSquare
        : ChessBoardView.darkSquare;
    final Piece? piece = widget.controller.game.pieceAt(index);
    final bool selected = widget.controller.selectedSquare == index;
    final bool isTarget = widget.controller.isTarget(index);
    final bool partOfLastMove =
        lastMove != null && (lastMove.from == index || lastMove.to == index);
    final bool inCheck = checkedKing == index;
    final bool isInFlight = inFlight.contains(index);

    return GestureDetector(
      key: ChessBoardView.squareKey(index),
      onTap: () => widget.onSquareTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(color: base),
            if (partOfLastMove)
              const ColoredBox(color: ChessBoardView.lastMoveTint),
            if (selected) const ColoredBox(color: ChessBoardView.selectedTint),
            if (inCheck)
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: <Color>[
                      ChessBoardView.checkTint,
                      Color(0x00E05B4B),
                    ],
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
                    color: light
                        ? ChessBoardView.darkSquare
                        : ChessBoardView.lightSquare,
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
                      color: light
                          ? ChessBoardView.darkSquare
                          : ChessBoardView.lightSquare,
                    ),
                  ),
                ),
              ),
            if (piece != null && !isInFlight)
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
