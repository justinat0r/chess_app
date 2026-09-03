import 'package:chess_app/game/game_result.dart';
import 'package:chess_app/game/move.dart';
import 'package:chess_app/main.dart';
import 'package:chess_app/screens/game_screen.dart';
import 'package:chess_app/screens/start_screen.dart';
import 'package:chess_app/screens/tie_screen.dart';
import 'package:chess_app/screens/win_screen.dart';
import 'package:chess_app/widgets/chess_board_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder squareFinder(String name) =>
    find.byKey(ChessBoardView.squareKey(Move.squareFromName(name)!));

Future<void> tapSquare(WidgetTester tester, String name) async {
  await tester.tap(squareFinder(name));
  await tester.pumpAndSettle();
}

Future<void> playMove(WidgetTester tester, String from, String to) async {
  await tapSquare(tester, from);
  await tapSquare(tester, to);
}

void main() {
  testWidgets('start screen leads to the board', (WidgetTester tester) async {
    await tester.pumpWidget(const ChessApp());
    expect(find.byType(StartScreen), findsOneWidget);
    expect(find.text('CHESS'), findsOneWidget);
    expect(find.text('NEW GAME'), findsOneWidget);
    expect(find.text('PLAY THE COMPUTER'), findsOneWidget);

    await tester.tap(find.text('NEW GAME'));
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byType(ChessBoardView), findsOneWidget);
    expect(find.text('White to move'), findsOneWidget);
  });

  testWidgets('tapping through a checkmate shows the win screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ChessApp());
    await tester.tap(find.text('NEW GAME'));
    await tester.pumpAndSettle();

    await playMove(tester, 'f2', 'f3');
    await playMove(tester, 'e7', 'e5');
    await playMove(tester, 'g2', 'g4');
    expect(find.textContaining('1. f3 e5'), findsOneWidget);

    await playMove(tester, 'd8', 'h4');
    await tester.pumpAndSettle();

    expect(find.byType(WinScreen), findsOneWidget);
    expect(find.text('CHECKMATE'), findsOneWidget);
    expect(find.text('Black\nwins'), findsOneWidget);

    await tester.tap(find.text('PLAY AGAIN'));
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byType(WinScreen), findsNothing);
    expect(find.text('White to move'), findsOneWidget);
  });

  testWidgets('illegal moves are ignored and undo takes a move back',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ChessApp());
    await tester.tap(find.text('NEW GAME'));
    await tester.pumpAndSettle();

    // A rook cannot jump its own pawn.
    await playMove(tester, 'a1', 'a4');
    expect(find.textContaining('1.'), findsNothing);

    await playMove(tester, 'e2', 'e4');
    expect(find.textContaining('1. e4'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.undo_rounded));
    await tester.pumpAndSettle();
    expect(find.text('White to move'), findsOneWidget);
  });

  testWidgets('resigning from the menu shows the win screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ChessApp());
    await tester.tap(find.text('NEW GAME'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resign'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Resign'));
    await tester.pumpAndSettle();

    expect(find.byType(WinScreen), findsOneWidget);
    expect(find.text('RESIGNATION'), findsOneWidget);
    expect(find.text('Black\nwins'), findsOneWidget);

    await tester.tap(find.text('MAIN MENU'));
    await tester.pumpAndSettle();
    expect(find.byType(StartScreen), findsOneWidget);
  });

  testWidgets('tie screen names the drawing rule', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const TieScreen(result: GameResult(GameOutcome.stalemate)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('STALEMATE'), findsOneWidget);
    expect(find.text('Draw'), findsOneWidget);
    expect(find.text('PLAY AGAIN'), findsOneWidget);
    expect(find.text('MAIN MENU'), findsOneWidget);
  });

  testWidgets('threefold repetition renders as a tie',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: TieScreen(result: GameResult(GameOutcome.threefoldRepetition)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('REPETITION'), findsOneWidget);
    expect(
      find.textContaining('same position occurred three times'),
      findsOneWidget,
    );
  });
}
