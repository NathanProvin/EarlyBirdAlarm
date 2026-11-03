import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../purchases.dart';
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
    final charges = twitchCharges(store.twitchStart, now, store.twitchPeriod);
    final next = twitchNextIn(store.twitchStart, now, store.twitchPeriod);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Flexible(child: Text(l.twitchZone, style: text.headlineMedium)),
            if (store.twitchPlus)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Plus',
                  style: text.labelMedium?.copyWith(color: scheme.onPrimary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(l.twitchInfo, style: text.bodyMedium),
        Expanded(
          child: Center(
            child: FittedBox(
              child: BoosterPile(
                // Bonus boosters from series add to the pile, drawn up to 5 high.
                count: min(store.twitchReady(now), twitchMax),
                onTorn: _open,
                label: l.openBooster,
              ),
            ),
          ),
        ),
        // Only the countdown: the pile itself shows how many are left. While it runs,
        // Twitch Plus is offered in the corner (until bought).
        SizedBox(
          height: 64,
          child: charges < twitchMax
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${next.inMinutes.toString().padLeft(2, '0')}:'
                      '${(next.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: text.displaySmall?.copyWith(
                        color: scheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (!store.twitchPlus)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: IconButton.filledTonal(
                            tooltip: l.twitchPlus,
                            // The bolt in the theme accent, to catch the eye.
                            icon: Icon(Icons.bolt, color: scheme.primary),
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              showDragHandle: true,
                              builder: (_) => const _PlusSheet(),
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : null,
        ),
        // Clear of the glass bottom bar.
        SizedBox(height: MediaQuery.paddingOf(context).bottom),
      ],
    );
  }
}

/// Twitch Plus: what it does, Google Play's price, one tap to buy (bought once, kept for good).
class _PlusSheet extends StatelessWidget {
  const _PlusSheet();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return FutureBuilder(
      future: products(),
      builder: (context, snap) {
        final plus = snap.data?[twitchPlusId];
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.twitchPlus, style: text.titleLarge),
              const SizedBox(height: 8),
              Text(l.twitchPlusPitch, style: text.bodyMedium),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.bolt),
                label: Text(plus?.price ?? l.twitchPlus),
                onPressed: plus == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        buy(plus);
                      },
              ),
              const SizedBox(height: 8),
              Text(
                snap.connectionState == ConnectionState.done && plus == null
                    ? l.purchasesUnavailable
                    : l.paymentsGoogle,
                style: text.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
