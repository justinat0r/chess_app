import 'package:flutter/material.dart';

import '../game/game_result.dart';
import '../game/piece.dart';
import '../theme.dart';
import '../widgets/chess_piece_view.dart';
import '../widgets/result_layout.dart';
import 'result_action.dart';

/// Shown when a player wins by checkmate or resignation. Every exit returns a
/// [ResultAction] to the board screen, which owns the game state.
class WinScreen extends StatelessWidget {
  const WinScreen({super.key, required this.result});

  final GameResult result;

  @override
  Widget build(BuildContext context) {
    final PieceColor winner = result.winner ?? PieceColor.white;
    final String loser = winner.opposite.label;
    final String detail = result.outcome == GameOutcome.resignation
        ? '$loser resigned, so ${winner.label} takes the game.'
        : 'The $loser king is attacked and has no legal escape.';

    void close(ResultAction action) => Navigator.of(context).pop(action);

    return ResultLayout(
      artwork: SizedBox(
        height: 148,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: 148,
              height: 148,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[Color(0x40E0B44E), Color(0x00E0B44E)],
                ),
              ),
            ),
            ChessPieceView(piece: Piece(winner, PieceType.king), size: 132),
          ],
        ),
      ),
      eyebrow:
          result.outcome == GameOutcome.resignation ? 'RESIGNATION' : 'CHECKMATE',
      headline: '${winner.label}\nwins',
      detail: detail,
      accent: AppTheme.winGold,
      onRematch: () => close(ResultAction.rematch),
      onMainMenu: () => close(ResultAction.mainMenu),
      onReviewBoard: () => close(ResultAction.reviewBoard),
    );
  }
}
