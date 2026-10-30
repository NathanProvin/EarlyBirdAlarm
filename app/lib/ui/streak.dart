import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import 'bird_icon.dart';
import 'theme.dart';

/// The wake-up streak as a pill: the theme's bird and the count. The bird livens up as
/// the streak grows: asleep at 0, bobbing at 1–2, hopping with a flame from 3, hopping
/// and flapping with a bigger flame from 7 (bigger still from 14).
class StreakPill extends StatefulWidget {
  const StreakPill(this.streak, {super.key});
  final int streak;

  @override
  State<StreakPill> createState() => _StreakPillState();
}

class _StreakPillState extends State<StreakPill>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final n = widget.streak;
    final bird = store.theme != 'system'
        ? store.theme
        : Theme.of(context).brightness == Brightness.dark
        ? darkTheme
        : lightTheme;
    return Semantics(
      label: l.streak(n),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 2, 12, 2),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final v = n == 0 ? 0.0 : _c.value;
            final hop = (v / 0.22).clamp(
              0.0,
              1.0,
            ); // the first 22 % of each cycle
            final y = switch (n) {
              0 => 0.0,
              < 3 => -1.5 * sin(2 * pi * v), // bobbing
              _ => hop < 1 ? -6 * sin(pi * hop) : 0.0, // a hop
            };
            final flap = n >= 7 && hop < 1
                ? 0.6 * sin(2 * pi * hop * 2).abs()
                : 0.0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(0, y),
                  child: CustomPaint(
                    size: const Size.square(32),
                    painter: BirdPainter.of(bird, flap: flap, asleep: n == 0),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$n',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: n == 0
                        ? scheme.onSurface.withValues(alpha: 0.5)
                        : null,
                  ),
                ),
                if (n >= 3)
                  Transform.scale(
                    scale: 1 + 0.08 * sin(2 * pi * v * 3), // flicker
                    child: Icon(
                      Icons.local_fire_department,
                      size: n >= 14 ? 26 : (n >= 7 ? 22 : 18),
                      color: scheme.primary,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
