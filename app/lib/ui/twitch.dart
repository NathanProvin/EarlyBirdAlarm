import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../purchases.dart';
import '../store.dart';
import 'booster.dart';
import 'header.dart';
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
    final ready = store.twitchReady(now);
    final countdown = Text(
      '${next.inMinutes.toString().padLeft(2, '0')}:'
      '${(next.inSeconds % 60).toString().padLeft(2, '0')}',
      style: text.displaySmall?.copyWith(
        color: scheme.primary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    return Column(
      children: [
        PageHeader(
          center: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Flexible(
                child: Text(
                  l.twitchZone,
                  style: text.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (store.twitchPlus)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
        ),
        Expanded(
          child: Center(
            // An empty pile gives its place to the countdown.
            child: ready == 0
                ? Semantics(
                    liveRegion: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: 48,
                          color: scheme.primary,
                        ),
                        const SizedBox(height: 8),
                        countdown,
                      ],
                    ),
                  )
                : FittedBox(
                    child: BoosterPile(
                      // Bonus boosters from series add to the pile, drawn up to 5 high.
                      count: min(ready, twitchMax),
                      onTorn: _open,
                      label: l.openBooster,
                    ),
                  ),
          ),
        ),
        // The countdown while the pile refills (the pile shows how many are left).
        if (ready > 0 && charges < twitchMax) countdown,
        // Plus is offered until bought, full pile or not; it pulses when the pile is
        // empty, the moment it's worth it.
        if (!store.twitchPlus) ...[
          const SizedBox(height: 12),
          _PlusButton(
            attract: ready == 0,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => const _PlusSheet(),
            ),
          ),
        ],
        // Higher than the glass bottom bar's edge.
        SizedBox(height: 32 + MediaQuery.paddingOf(context).bottom),
      ],
    );
  }
}

/// The Plus button: the bolt and the name, tonal. With [attract] (no booster left) it
/// pulses every 2 s: it swells with a glow and the bolt gives a little jolt.
class _PlusButton extends StatefulWidget {
  const _PlusButton({required this.attract, required this.onPressed});
  final bool attract;
  final VoidCallback onPressed;

  @override
  State<_PlusButton> createState() => _PlusButtonState();
}

class _PlusButtonState extends State<_PlusButton>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final on = widget.attract && !MediaQuery.disableAnimationsOf(context);
    if (on && !_pulse.isAnimating) _pulse.repeat();
    if (!on && _pulse.isAnimating) _pulse.reset();
    // Its own layer: the pulse repaints only the button.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          // A beat in the first 30 % of each cycle, then rest.
          final t = (_pulse.value / 0.3).clamp(0.0, 1.0);
          final beat = sin(t * pi);
          return Transform.scale(
            scale: 1 + 0.15 * beat,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  if (beat > 0)
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.45 * beat),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: FilledButton.tonalIcon(
                // The theme's buttons are full width (Size.fromHeight): not here.
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: widget.onPressed,
                icon: Transform.rotate(
                  angle: 0.25 * sin(t * 3 * pi) * (1 - t),
                  child: Icon(Icons.bolt, color: scheme.primary),
                ),
                label: Text(l.twitchPlus),
              ),
            ),
          );
        },
      ),
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
