import 'package:flutter/material.dart';

import '../game/piece.dart';
import '../theme.dart';
import 'chess_piece_view.dart';

/// Asks which piece a promoting pawn becomes. Returns null if dismissed.
Future<PieceType?> showPromotionDialog(
  BuildContext context,
  PieceColor color,
) {
  return showDialog<PieceType>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Promote pawn to'),
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            for (final PieceType type in <PieceType>[
              PieceType.queen,
              PieceType.rook,
              PieceType.bishop,
              PieceType.knight,
            ])
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.of(context).pop(type),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A312A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ChessPieceView(piece: Piece(color, type), size: 52),
                ),
              ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
        ],
      );
    },
  );
}
