import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../store.dart';
import 'ring.dart';

/// Twitch mode: a training quiz that can win cards, up to [twitchMax] stacked, one more
/// every [twitchEvery]; the countdown to the next one ticks every second.
class TwitchScreen extends StatefulWidget {
  const TwitchScreen({super.key});

  @override
  State<TwitchScreen> createState() => _TwitchScreenState();
}

class _TwitchScreenState extends State<TwitchScreen> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final quiz = store.pickNext(DateTime.now());
    await store.useTwitch();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => RingScreen.training(quiz)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final charges = twitchCharges(store.twitchStart, now);
    final next = twitchNextIn(store.twitchStart, now);
    final mmss =
        '${next.inMinutes.toString().padLeft(2, '0')}:'
        '${(next.inSeconds % 60).toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l.twitch, style: text.headlineMedium),
          const SizedBox(height: 8),
          Text(l.twitchInfo, style: text.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Semantics(
            label: '$charges/$twitchMax',
            excludeSemantics: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: [
                for (var i = 0; i < twitchMax; i++)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < charges ? scheme.primary : null,
                      border: Border.all(color: scheme.primary, width: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            charges == twitchMax ? l.quizzesFull : l.nextQuizIn(mmss),
            style: text.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: charges > 0 ? _start : null,
            child: Text(l.start),
          ),
        ],
      ),
    );
  }
}
