import 'dart:math';

import 'birds.dart';

/// One earned card: a bird with its own rolled stats.
class CardData {
  CardData({
    required this.birdId,
    required this.stats,
    required this.quality,
    required this.earned,
    this.rarity,
    this.region,
  });

  CardData.fromJson(Map<String, dynamic> j)
    : this(
        birdId: j['bird'] as String,
        stats: {
          for (final e in (j['stats'] as Map<String, dynamic>).entries)
            e.key: (e.value as num).toDouble(),
        },
        quality: j['quality'] as int,
        earned: DateTime.parse(j['earned'] as String),
        rarity: j['rarity'] as String?,
        region: j['region'] as String?,
      );

  final String birdId;
  final Map<String, double> stats; // stat key -> rolled value
  final int quality; // 0-100: average percentile of the rolls
  final DateTime earned;
  // Rarity and region where it was won: a card stays Legendary even if you move.
  // Null on cards from before Iteration 3c.
  final String? rarity, region;

  Map<String, dynamic> toJson() => {
    'bird': birdId,
    'stats': stats,
    'quality': quality,
    'earned': earned.toIso8601String(),
    'rarity': ?rarity,
    'region': ?region,
  };
}

/// Rolls each stat from a Gaussian around the species mean, clamped to ±2 sd.
CardData rollCard(Bird bird, String? region, [Random? random]) {
  final r = random ?? Random();
  final rolls = {
    for (final e in bird.stats.entries) e.key: (e.value, _gaussian(r)),
  };
  final percentiles = [for (final (_, z) in rolls.values) _cdf(z)];
  return CardData(
    birdId: bird.id,
    stats: {
      for (final MapEntry(:key, value: (s, z)) in rolls.entries)
        key: max(0, s.mean + z * s.sd),
    },
    quality: percentiles.isEmpty
        ? 50
        : (100 * percentiles.reduce((a, b) => a + b) / percentiles.length)
              .round(),
    earned: DateTime.now(),
    rarity: bird.rarity,
    region: region,
  );
}

/// Standard normal value (Box-Muller), clamped to ±2.
double _gaussian(Random r) {
  final z = sqrt(-2 * log(1 - r.nextDouble())) * cos(2 * pi * r.nextDouble());
  return z.clamp(-2, 2);
}

/// Where [value] sits in the species' spread for [stat], 0-1 (for the stat bars).
double percentileOf(Bird bird, String stat, double value) {
  final s = bird.stats[stat];
  return s == null || s.sd == 0 ? 0.5 : _cdf((value - s.mean) / s.sd);
}

/// Standard normal cumulative distribution (Abramowitz-Stegun 7.1.26, error < 1.5e-7).
double _cdf(double z) {
  final x = z.abs() / sqrt2;
  final t = 1 / (1 + 0.3275911 * x);
  final erf =
      1 -
      ((((1.061405429 * t - 1.453152027) * t + 1.421413741) * t - 0.284496736) *
                  t +
              0.254829592) *
          t *
          exp(-x * x);
  return 0.5 * (1 + (z < 0 ? -erf : erf));
}
