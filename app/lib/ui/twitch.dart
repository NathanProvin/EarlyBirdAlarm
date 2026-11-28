import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../purchases.dart';
import '../store.dart';
import 'booster.dart';
import 'header.dart';
import 'family_icon.dart' show groupBadge;
import 'lure.dart';
import 'ring.dart';
import 'streak.dart';

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
    final page = Column(
      children: [
        PageHeader(
          center: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              StreakPill(store.streak),
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
          PulseButton(
            icon: Icons.bolt,
            label: l.twitchPlus,
            attract: ready == 0,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => const PlusSheet(),
            ),
          ),
        ],
        // Higher than the glass bottom bar's edge.
        SizedBox(height: 32 + MediaQuery.paddingOf(context).bottom),
      ],
    );
    // The Lure, bottom left (user, 2026-11-27).
    return Stack(
      children: [
        page,
        Positioned(
          left: 16,
          bottom: 24 + MediaQuery.paddingOf(context).bottom,
          child: const LureButton(),
        ),
      ],
    );
  }
}

/// A tonal button with [icon] and [label] (the Plus button, the map's "Missing species").
/// With [attract] it pulses every 2 s: a glow around it and its fill warming toward the accent.
class PulseButton extends StatefulWidget {
  const PulseButton({
    required this.icon,
    required this.label,
    required this.attract,
    required this.onPressed,
    this.iconOnly = false,
    super.key,
  });
  final IconData icon;
  final String label;
  final bool attract;
  final VoidCallback onPressed;

  /// Only the icon beats (a little larger, a soft glow), not the whole button: the map's
  /// radar (2026-11-19, the button's glow was too aggressive there).
  final bool iconOnly;

  @override
  State<PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<PulseButton>
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
          if (widget.iconOnly) {
            return FilledButton.tonalIcon(
              // An accent outline and label: it stands out on the map (2026-11-23).
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: scheme.primary,
                side: BorderSide(color: scheme.primary, width: 2),
              ),
              onPressed: widget.onPressed,
              icon: Transform.scale(
                scale: 1 + 0.25 * beat,
                child: Icon(
                  widget.icon,
                  color: scheme.primary,
                  shadows: [
                    if (beat > 0)
                      Shadow(
                        color: scheme.primary.withValues(alpha: 0.8 * beat),
                        blurRadius: 8,
                      ),
                  ],
                ),
              ),
              label: Text(widget.label),
            );
          }
          return DecoratedBox(
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
              style: FilledButton.styleFrom(
                // The theme's buttons are full width (Size.fromHeight): not here.
                minimumSize: const Size(0, 48),
                // The colour pulse: the tonal fill warms toward the accent.
                backgroundColor: Color.lerp(
                  scheme.secondaryContainer,
                  Color.alphaBlend(
                    scheme.primary.withValues(alpha: 0.35),
                    scheme.secondaryContainer,
                  ),
                  beat,
                ),
              ),
              onPressed: widget.onPressed,
              icon: Icon(widget.icon, color: scheme.primary),
              label: Text(widget.label),
            ),
          );
        },
      ),
    );
  }
}

/// Early Bird Plus: what it does, then Pigeon (1 month), Duck (6 months) or Eagle (for
/// life) at Google Play's prices (1.4.1, user: one-off purchases, nothing renews); the
/// Eagle highlighted.
class PlusSheet extends StatelessWidget {
  const PlusSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return FutureBuilder(
      future: products(),
      builder: (context, snap) {
        final plus = snap.data?[twitchPlusId];
        // Each choice: the bird's badge in the accent, the length over its name, then the
        // price (user, 2026-11-28).
        Widget choice(
          String id,
          String group,
          String name,
          String length, {
          bool main = false,
        }) {
          final p = snap.data?[id];
          final scheme = Theme.of(context).colorScheme;
          final ink = main ? scheme.onPrimary : scheme.onSecondaryContainer;
          final label = Row(
            spacing: 14,
            children: [
              // The accent, but on the accent-filled Eagle: its ink.
              groupBadge(group, main ? ink : scheme.primary),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      length,
                      style: text.titleMedium?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(name, style: text.bodyMedium?.copyWith(color: ink)),
                  ],
                ),
              ),
              Text(
                p?.price ?? '–',
                style: text.titleMedium?.copyWith(color: ink),
              ),
            ],
          );
          final style = FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(68),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          );
          final onPressed = p == null
              ? null
              : () {
                  Navigator.of(context).pop();
                  buy(p);
                };
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: main
                ? FilledButton(
                    style: style,
                    onPressed: onPressed,
                    child: label,
                  )
                : FilledButton.tonal(
                    style: style,
                    onPressed: onPressed,
                    child: label,
                  ),
          );
        }
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
              const SizedBox(height: 12),
              choice('plus_month', 'pigeon', l.plusPigeon, l.plusMonth),
              choice('plus_year', 'duck', l.plusDuck, l.plusSixMonths),
              choice(
                twitchPlusId,
                'raptor',
                l.plusEagle,
                l.plusLife,
                main: true,
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
