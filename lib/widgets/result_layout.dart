import 'package:flutter/material.dart';

import '../theme.dart';

/// Shared frame for the win and tie screens: artwork, headline, explanation
/// and the action buttons.
class ResultLayout extends StatelessWidget {
  const ResultLayout({
    super.key,
    required this.artwork,
    required this.eyebrow,
    required this.headline,
    required this.detail,
    required this.accent,
    required this.onRematch,
    required this.onMainMenu,
    required this.onReviewBoard,
  });

  final Widget artwork;
  final String eyebrow;
  final String headline;
  final String detail;
  final Color accent;
  final VoidCallback onRematch;
  final VoidCallback onMainMenu;
  final VoidCallback onReviewBoard;

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
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Spacer(),
                          Center(child: artwork),
                          const SizedBox(height: 26),
                          Text(
                            eyebrow,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            headline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 40,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            detail,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: onRematch,
                            child: const Text('PLAY AGAIN'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: onMainMenu,
                            child: const Text('MAIN MENU'),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: onReviewBoard,
                            child: const Text('View final position'),
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
