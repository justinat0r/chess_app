import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/piece.dart';

/// Draws the six chess pieces as vector Staunton silhouettes in the classic
/// ivory-and-black colouring. Everything is authored in a 100x100 space and
/// scaled to the widget, so pieces stay crisp at any board size.
class ChessPieceView extends StatelessWidget {
  const ChessPieceView({
    super.key,
    required this.piece,
    this.size,
    this.shadow = true,
  });

  final Piece piece;
  final double? size;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final Widget painted = CustomPaint(
      painter: _PiecePainter(piece: piece, shadow: shadow),
      isComplex: true,
      willChange: false,
    );
    if (size == null) return painted;
    return SizedBox(width: size, height: size, child: painted);
  }
}

class _PiecePainter extends CustomPainter {
  _PiecePainter({required this.piece, required this.shadow});

  final Piece piece;
  final bool shadow;

  static const Color _lightFill = Color(0xFFFAF6EC);
  static const Color _darkFill = Color(0xFF2B2724);
  static const Color _outline = Color(0xFF1A1714);
  static const Color _lightDetail = Color(0xFF1A1714);
  static const Color _darkDetail = Color(0xFFE6DDCB);

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.shortestSide / 100.0;
    canvas.save();
    canvas.translate(
      (size.width - 100 * scale) / 2,
      (size.height - 100 * scale) / 2,
    );
    canvas.scale(scale);

    final Path body = _bodyPath(piece.type);
    final bool isWhite = piece.isWhite;

    if (shadow) {
      canvas.save();
      canvas.translate(1.5, 2.5);
      canvas.drawPath(
        body,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.22)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.5),
      );
      canvas.restore();
    }

    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.fill
        ..color = isWhite ? _lightFill : _darkFill,
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeJoin = StrokeJoin.round
        ..color = _outline,
    );

    final Paint detail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = isWhite ? _lightDetail : _darkDetail;
    _paintDetails(canvas, piece.type, detail, isWhite);

    canvas.restore();
  }

  /// The flared foot every piece stands on.
  void _addBase(Path path, {double topY = 68, double halfWidth = 20}) {
    final double left = 50 - halfWidth;
    final double right = 50 + halfWidth;
    path.moveTo(left, topY);
    path.lineTo(right, topY);
    path.cubicTo(right + 2, topY + 6, right + 5, topY + 9, right + 9, topY + 12);
    path.lineTo(right + 9, 89);
    path.lineTo(left - 9, 89);
    path.lineTo(left - 9, topY + 12);
    path.cubicTo(left - 5, topY + 9, left - 2, topY + 6, left, topY);
    path.close();
  }

  Path _bodyPath(PieceType type) {
    switch (type) {
      case PieceType.pawn:
        return _pawn();
      case PieceType.rook:
        return _rook();
      case PieceType.knight:
        return _knight();
      case PieceType.bishop:
        return _bishop();
      case PieceType.queen:
        return _queen();
      case PieceType.king:
        return _king();
    }
  }

  Path _pawn() {
    final Path p = Path();
    p.addOval(Rect.fromCircle(center: const Offset(50, 26), radius: 12));
    p.addRRect(RRect.fromLTRBR(38, 37, 62, 46, const Radius.circular(3)));
    p.moveTo(41, 45);
    p.cubicTo(41, 55, 37, 62, 33, 68);
    p.lineTo(67, 68);
    p.cubicTo(63, 62, 59, 55, 59, 45);
    p.close();
    _addBase(p, halfWidth: 17);
    return p;
  }

  Path _rook() {
    final Path p = Path();
    p.moveTo(24, 18);
    p.lineTo(36, 18);
    p.lineTo(36, 27);
    p.lineTo(44, 27);
    p.lineTo(44, 18);
    p.lineTo(56, 18);
    p.lineTo(56, 27);
    p.lineTo(64, 27);
    p.lineTo(64, 18);
    p.lineTo(76, 18);
    p.lineTo(76, 36);
    p.lineTo(68, 43);
    p.lineTo(70, 68);
    p.lineTo(30, 68);
    p.lineTo(32, 43);
    p.lineTo(24, 36);
    p.close();
    _addBase(p);
    return p;
  }

  Path _bishop() {
    final Path p = Path();
    p.addOval(Rect.fromCircle(center: const Offset(50, 11), radius: 5));
    p.moveTo(50, 15);
    p.cubicTo(62, 24, 68, 35, 67, 46);
    p.cubicTo(59, 51, 41, 51, 33, 46);
    p.cubicTo(32, 35, 38, 24, 50, 15);
    p.close();
    p.addRRect(RRect.fromLTRBR(32, 45, 68, 55, const Radius.circular(4)));
    p.moveTo(39, 54);
    p.cubicTo(39, 60, 36, 65, 32, 68);
    p.lineTo(68, 68);
    p.cubicTo(64, 65, 61, 60, 61, 54);
    p.close();
    _addBase(p);
    return p;
  }

  Path _knight() {
    final Path p = Path();
    p.moveTo(31, 68);
    p.cubicTo(29, 60, 30, 53, 36, 47);
    p.cubicTo(33, 47, 28, 49, 24, 51);
    p.cubicTo(19, 50, 16, 46, 17, 41);
    p.cubicTo(21, 35, 27, 32, 32, 28);
    p.cubicTo(35, 24, 36, 19, 39, 15);
    p.lineTo(43, 22);
    p.lineTo(48, 11);
    p.lineTo(52, 20);
    p.cubicTo(60, 21, 66, 28, 69, 38);
    p.cubicTo(72, 48, 72, 59, 70, 68);
    p.close();
    _addBase(p);
    return p;
  }

  Path _queen() {
    final Path p = Path();
    for (final Offset c in const <Offset>[
      Offset(21, 22),
      Offset(35, 15),
      Offset(50, 11),
      Offset(65, 15),
      Offset(79, 22),
    ]) {
      p.addOval(Rect.fromCircle(center: c, radius: 5));
    }
    p.moveTo(20, 25);
    p.lineTo(30, 46);
    p.lineTo(35, 18);
    p.lineTo(44, 46);
    p.lineTo(50, 14);
    p.lineTo(56, 46);
    p.lineTo(65, 18);
    p.lineTo(70, 46);
    p.lineTo(80, 25);
    p.lineTo(75, 53);
    p.lineTo(25, 53);
    p.close();
    p.addRRect(RRect.fromLTRBR(25, 50, 75, 59, const Radius.circular(4)));
    p.moveTo(33, 58);
    p.cubicTo(33, 63, 31, 66, 29, 68);
    p.lineTo(71, 68);
    p.cubicTo(69, 66, 67, 63, 67, 58);
    p.close();
    _addBase(p, halfWidth: 21);
    return p;
  }

  Path _king() {
    final Path p = Path();
    p.addRRect(RRect.fromLTRBR(46, 2, 54, 27, const Radius.circular(2)));
    p.addRRect(RRect.fromLTRBR(38, 9, 62, 17, const Radius.circular(2)));
    p.moveTo(24, 53);
    p.lineTo(28, 33);
    p.lineTo(38, 43);
    p.lineTo(50, 25);
    p.lineTo(62, 43);
    p.lineTo(72, 33);
    p.lineTo(76, 53);
    p.close();
    p.addRRect(RRect.fromLTRBR(25, 50, 75, 59, const Radius.circular(4)));
    p.moveTo(33, 58);
    p.cubicTo(33, 63, 31, 66, 29, 68);
    p.lineTo(71, 68);
    p.cubicTo(69, 66, 67, 63, 67, 58);
    p.close();
    _addBase(p, halfWidth: 21);
    return p;
  }

  void _paintDetails(
      Canvas canvas, PieceType type, Paint detail, bool isWhite) {
    switch (type) {
      case PieceType.bishop:
        canvas.drawPath(
          Path()
            ..moveTo(46, 22)
            ..cubicTo(52, 28, 55, 32, 56, 38),
          detail,
        );
        break;
      case PieceType.knight:
        canvas.drawCircle(
          const Offset(33, 35),
          2.6,
          Paint()..color = isWhite ? _lightDetail : _darkDetail,
        );
        canvas.drawPath(
          Path()
            ..moveTo(24, 45)
            ..lineTo(33, 44),
          detail,
        );
        canvas.drawPath(
          Path()
            ..moveTo(52, 22)
            ..cubicTo(58, 30, 61, 42, 61, 55),
          detail,
        );
        break;
      case PieceType.rook:
        canvas.drawPath(
          Path()
            ..moveTo(32, 43)
            ..lineTo(68, 43),
          detail,
        );
        break;
      case PieceType.king:
      case PieceType.queen:
        canvas.drawPath(
          Path()
            ..moveTo(28, 50)
            ..lineTo(72, 50),
          detail,
        );
        break;
      case PieceType.pawn:
        break;
    }
  }

  @override
  bool shouldRepaint(_PiecePainter oldDelegate) =>
      oldDelegate.piece != piece || oldDelegate.shadow != shadow;
}
