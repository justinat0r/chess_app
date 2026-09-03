import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/game_controller.dart';
import '../game/move.dart';
import '../game/piece.dart';
import '../theme.dart';
import '../widgets/chess_board_view.dart';
import '../widgets/player_panel.dart';
import '../widgets/promotion_dialog.dart';
import 'result_action.dart';
import 'tie_screen.dart';
import 'win_screen.dart';

/// The board screen: two player panels, the board itself, the move list, and
/// the routing to the win and tie screens when the game ends.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.rotateForBlack = false});

  /// Rotate the board each turn so the player to move sits at the bottom.
  final bool rotateForBlack;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller =
      GameController(rotateForBlack: widget.rotateForBlack);
  final ScrollController _notationScroll = ScrollController();
  bool _resultShown = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _notationScroll.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_notationScroll.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_notationScroll.hasClients) return;
        _notationScroll.jumpTo(_notationScroll.position.maxScrollExtent);
      });
    }
    if (_controller.isGameOver && !_resultShown) {
      _resultShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openResultScreen());
    }
  }

  Future<void> _openResultScreen() async {
    if (!mounted) return;
    final bool draw = _controller.result.isDraw;
    final ResultAction? action = await Navigator.of(context).push<ResultAction>(
      PageRouteBuilder<ResultAction>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (BuildContext context, Animation<double> animation, _) {
          return FadeTransition(
            opacity: animation,
            child: draw
                ? TieScreen(result: _controller.result)
                : WinScreen(result: _controller.result),
          );
        },
      ),
    );
    if (!mounted) return;
    switch (action) {
      case ResultAction.rematch:
        _restart();
        break;
      case ResultAction.mainMenu:
        Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
        break;
      case ResultAction.reviewBoard:
      case null:
        break;
    }
  }

  void _restart() {
    _resultShown = false;
    _controller.restart();
  }

  Future<void> _onSquareTap(int square) async {
    if (_controller.isGameOver || _controller.isThinking) return;
    if (_controller.selectedSquare != null) {
      final List<Move> moves = _controller.movesTo(square);
      if (moves.isNotEmpty) {
        Move chosen = moves.first;
        if (moves.length > 1 && moves.first.promotion != null) {
          final PieceType? type =
              await showPromotionDialog(context, _controller.turn);
          if (type == null) {
            _controller.clearSelection();
            return;
          }
          chosen = moves.firstWhere(
            (Move m) => m.promotion == type,
            orElse: () => moves.first,
          );
        }
        // Fire and forget: haptics must never delay or block the move.
        unawaited(HapticFeedback.selectionClick());
        _controller.playMove(chosen);
        return;
      }
    }
    _controller.select(square);
  }

  Future<void> _confirmResign() async {
    final PieceColor resigning = _controller.turn;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('${resigning.label} resigns?'),
        content: Text(
          '${resigning.opposite.label} wins the game.',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep playing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) _controller.resign(resigning);
  }

  Future<void> _confirmNewGame() async {
    if (!_controller.game.canUndo) {
      _restart();
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Start a new game?'),
        content: const Text(
          'The current game will be discarded.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            child: const Text('New game'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) _restart();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, _) {
        final bool flipped = _controller.isBoardFlipped;
        final PieceColor topColor =
            flipped ? PieceColor.white : PieceColor.black;
        final PieceColor bottomColor =
            flipped ? PieceColor.black : PieceColor.white;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'CHESS',
              style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w700),
            ),
            actions: <Widget>[
              IconButton(
                tooltip: 'Undo move',
                onPressed: _controller.canUndo ? _controller.undo : null,
                icon: const Icon(Icons.undo_rounded),
              ),
              PopupMenuButton<String>(
                color: AppTheme.panel,
                onSelected: (String value) {
                  switch (value) {
                    case 'new':
                      _confirmNewGame();
                      break;
                    case 'resign':
                      _confirmResign();
                      break;
                    case 'rotate':
                      _controller.rotateForBlack = !_controller.rotateForBlack;
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'new',
                    child: Text('New game'),
                  ),
                  PopupMenuItem<String>(
                    value: 'resign',
                    enabled: !_controller.isGameOver,
                    child: const Text('Resign'),
                  ),
                  PopupMenuItem<String>(
                    value: 'rotate',
                    child: Text(
                      _controller.rotateForBlack
                          ? 'Stop rotating board'
                          : 'Rotate board each turn',
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: DecoratedBox(
            decoration: AppTheme.backdrop,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Column(
                  children: <Widget>[
                    PlayerPanel(controller: _controller, color: topColor),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ChessBoardView(
                        controller: _controller,
                        onSquareTap: _onSquareTap,
                      ),
                    ),
                    const SizedBox(height: 10),
                    PlayerPanel(controller: _controller, color: bottomColor),
                    const SizedBox(height: 8),
                    if (_controller.isGameOver)
                      _GameOverBar(
                        headline: _controller.result.headline,
                        onRematch: _restart,
                        onViewResult: () {
                          _resultShown = true;
                          _openResultScreen();
                        },
                      )
                    else
                      _NotationStrip(
                        notation: _controller.notation,
                        scrollController: _notationScroll,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Scrolling list of the moves played, in algebraic notation.
class _NotationStrip extends StatelessWidget {
  const _NotationStrip({
    required this.notation,
    required this.scrollController,
  });

  final List<String> notation;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (notation.isEmpty) {
      return const SizedBox(
        height: 34,
        child: Center(
          child: Text(
            'White to move',
            style: TextStyle(color: AppTheme.textMuted, letterSpacing: 0.8),
          ),
        ),
      );
    }

    final List<String> entries = <String>[];
    for (int i = 0; i < notation.length; i += 2) {
      final String number = '${i ~/ 2 + 1}.';
      final String white = notation[i];
      final String black = i + 1 < notation.length ? ' ${notation[i + 1]}' : '';
      entries.add('$number $white$black');
    }

    return SizedBox(
      height: 34,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final bool isLast = index == entries.length - 1;
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isLast ? const Color(0xFF3A312A) : AppTheme.panel,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entries[index],
                style: TextStyle(
                  fontSize: 13.5,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                  color: isLast ? AppTheme.accent : AppTheme.textMuted,
                  fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Replaces the move list once the game is decided.
class _GameOverBar extends StatelessWidget {
  const _GameOverBar({
    required this.headline,
    required this.onRematch,
    required this.onViewResult,
  });

  final String headline;
  final VoidCallback onRematch;
  final VoidCallback onViewResult;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x55D3A84C)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              headline,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          TextButton(onPressed: onViewResult, child: const Text('Result')),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: onRematch,
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, 34),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Rematch'),
          ),
        ],
      ),
    );
  }
}
