import 'package:flutter/material.dart';

import '../game/game_result.dart';
import '../game/piece.dart';
import '../theme.dart';
import '../widgets/chess_piece_view.dart';
import '../widgets/result_layout.dart';
import 'result_action.dart';

/// Shown for every drawn ending: stalemate, insufficient material, the
/// fifty-move rule and threefold repetition.
class TieScreen extends StatelessWidget {
  const TieScreen({super.key, required this.result});

  final GameResult result;

  String get _eyebrow {
    switch (result.outcome) {
      case GameOutcome.stalemate:
        return 'STALEMATE';
      case GameOutcome.insufficientMaterial:
        return 'INSUFFICIENT MATERIAL';
      case GameOutcome.fiftyMoveRule:
        return 'FIFTY-MOVE RULE';
      case GameOutcome.threefoldRepetition:
        return 'REPETITION';
      case GameOutcome.ongoing:
      case GameOutcome.checkmate:
      case GameOutcome.resignation:
        return 'DRAWN';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  colors: <Color>[Color(0x338FA3B0), Color(0x008FA3B0)],
                ),
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: ChessPieceView(
                    piece: Piece(PieceColor.white, PieceType.king),
                    size: 104,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: ChessPieceView(
                    piece: Piece(PieceColor.black, PieceType.king),
                    size: 104,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      eyebrow: _eyebrow,
      headline: 'Draw',
      detail: result.reason,
      accent: AppTheme.drawSlate,
      onRematch: () => close(ResultAction.rematch),
      onMainMenu: () => close(ResultAction.mainMenu),
      onReviewBoard: () => close(ResultAction.reviewBoard),
    );
  }
}
