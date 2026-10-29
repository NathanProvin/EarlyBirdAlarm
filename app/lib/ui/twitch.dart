import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../store.dart';
import 'booster.dart';
import 'ring.dart';

/// Twitch Zone: a pile of up to [twitchMax] boosters, one more every [twitchEvery].
/// Tearing one open starts a training quiz that can win a card.
class TwitchScreen extends StatefulWidget {
  const TwitchScreen({super.key});

  @override
  State<TwitchScreen> createState() => _TwitchScreenState();
}

class _TwitchScreenState extends State<TwitchScreen> {
  late final Timer _tick; // the countdown, to the second

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  Future<void> _open() async {
    final quiz = store.pickNext(DateTime.now());
    await store.useTwitch();
    if (!mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, _, _) => RingScreen.training(quiz),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final charges = twitchCharges(store.twitchStart, now);
    final next = twitchNextIn(store.twitchStart, now);
    return Column(
      children: [
        const SizedBox(height: 24),
        Text(l.twitchZone, style: text.headlineMedium),
        const SizedBox(height: 4),
        Text(l.twitchInfo, style: text.bodyMedium),
        Expanded(
          child: Center(
            child: FittedBox(
              child: BoosterPile(
                count: charges,
                onTorn: _open,
                label: l.openBooster,
              ),
            ),
          ),
        ),
        // Only the countdown: the pile itself shows how many are left.
        SizedBox(
          height: 64,
          child: charges < twitchMax
              ? Text(
                  '${next.inMinutes.toString().padLeft(2, '0')}:'
                  '${(next.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: text.displaySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                )
              : null,
        ),
        // Clear of the glass bottom bar.
        SizedBox(height: MediaQuery.paddingOf(context).bottom),
      ],
    );
  }
}
