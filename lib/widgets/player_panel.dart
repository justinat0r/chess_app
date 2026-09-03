import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../game/piece.dart';
import '../theme.dart';
import 'chess_piece_view.dart';

/// One player's strip: name, whose turn it is, the pieces they have captured
/// and their material lead.
class PlayerPanel extends StatelessWidget {
  const PlayerPanel({
    super.key,
    required this.controller,
    required this.color,
  });

  final GameController controller;
  final PieceColor color;

  @override
  Widget build(BuildContext context) {
    final bool isTurn = controller.turn == color && !controller.isGameOver;
    final bool inCheck = isTurn && controller.game.isColorInCheck(color);
    final List<Piece> captured = controller.capturedFrom(color.opposite);
    final int lead = controller.materialLead(color);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isTurn ? const Color(0xFF3A312A) : AppTheme.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTurn ? AppTheme.accent : Colors.transparent,
          width: 1.4,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color == PieceColor.white
                  ? const Color(0xFFFAF6EC)
                  : const Color(0xFF2B2724),
              border: Border.all(color: const Color(0xFF7A6A57), width: 1.5),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                controller.nameFor(color),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                inCheck
                    ? 'In check'
                    : isTurn
                        ? 'Your move'
                        : 'Waiting',
                style: TextStyle(
                  fontSize: 12,
                  color: inCheck ? const Color(0xFFE9736A) : AppTheme.textMuted,
                  fontWeight: inCheck ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 26,
              child: ListView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                children: <Widget>[
                  if (lead > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Center(
                        child: Text(
                          '+$lead',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accent,
                          ),
                        ),
                      ),
                    ),
                  for (final Piece piece in captured.reversed)
                    ChessPieceView(piece: piece, size: 24, shadow: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
