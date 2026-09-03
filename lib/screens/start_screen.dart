import 'package:flutter/material.dart';

import '../game/piece.dart';
import '../theme.dart';
import '../widgets/chess_piece_view.dart';
import 'game_screen.dart';

/// Title screen. Starts a local two-player game and holds the pre-game
/// options. The computer-opponent entry is deliberately inert: the seam for it
/// exists in the controller, but no engine ships with this build.
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _rotateForBlack = false;

  void _startGame() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            GameScreen(rotateForBlack: _rotateForBlack),
      ),
    );
  }

  void _showHowToPlay() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('How to play'),
        content: const Text(
          'Two players share one phone. White moves first.\n\n'
          'Tap a piece to see its legal moves, then tap a highlighted square '
          'to move there. Dots mark quiet moves and rings mark captures.\n\n'
          'The game ends on checkmate, stalemate, the fifty-move rule, '
          'threefold repetition, insufficient material, or resignation.',
          style: TextStyle(height: 1.45),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: AppTheme.backdrop,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  // IntrinsicHeight gives the Column a finite height so the
                  // Spacers still work inside the scroll view.
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Spacer(),
                          const _PieceParade(),
                          const SizedBox(height: 28),
                          const Text(
                            'CHESS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 12,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Two players, one board',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              letterSpacing: 1.6,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: _startGame,
                            child: const Text('NEW GAME'),
                          ),
                          const SizedBox(height: 14),
                          const _ComingSoonButton(),
                          const SizedBox(height: 22),
                          _RotateOption(
                            value: _rotateForBlack,
                            onChanged: (bool value) =>
                                setState(() => _rotateForBlack = value),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _showHowToPlay,
                            child: const Text('How to play'),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Row of pieces used as the title-screen artwork.
class _PieceParade extends StatelessWidget {
  const _PieceParade();

  @override
  Widget build(BuildContext context) {
    const List<Piece> pieces = <Piece>[
      Piece(PieceColor.white, PieceType.knight),
      Piece(PieceColor.black, PieceType.queen),
      Piece(PieceColor.white, PieceType.king),
      Piece(PieceColor.black, PieceType.bishop),
      Piece(PieceColor.white, PieceType.rook),
    ];
    return SizedBox(
      height: 96,
      // Scales the row down on narrow phones instead of clipping it.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            for (final Piece piece in pieces)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChessPieceView(
                  piece: piece,
                  size: piece.type == PieceType.king ? 92 : 76,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for the future engine opponent.
class _ComingSoonButton extends StatelessWidget {
  const _ComingSoonButton();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.45,
      child: OutlinedButton(
        onPressed: null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('PLAY THE COMPUTER'),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x33D3A84C),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'SOON',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RotateOption extends StatelessWidget {
  const _RotateOption({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.panel,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.accent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: const Text(
          'Rotate board each turn',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Keeps the player to move at the bottom',
          style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
        ),
      ),
    );
  }
}
