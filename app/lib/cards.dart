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
    this.recording,
    this.traded,
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
        recording: j['recording'] as String?,
        traded: DateTime.tryParse(j['traded'] as String? ?? ''),
      );

  final String birdId;
  final Map<String, double> stats; // stat key -> rolled value
  final int quality; // 0-100: average percentile of the rolls
  final DateTime earned;
  // Rarity and region where it was won: a card stays Legendary even if you move.
  // Null on cards from before Iteration 3c.
  final String? rarity, region;
  final String?
  recording; // file of the recording that rang (null before UI round 1)
  final DateTime? traded; // when it changed hands in a face-to-face trade

  /// Identifies one card among all copies: its bird and the moment it was won.
  String get key => '$birdId@${earned.toIso8601String()}';

  /// The same card, marked as traded at [when].
  CardData tradedAt(DateTime when) => CardData(
    birdId: birdId,
    stats: stats,
    quality: quality,
    earned: earned,
    rarity: rarity,
    region: region,
    recording: recording,
    traded: when,
  );

  Map<String, dynamic> toJson() => {
    'bird': birdId,
    'stats': stats,
    'quality': quality,
    'earned': earned.toIso8601String(),
    'rarity': ?rarity,
    'region': ?region,
    'recording': ?recording,
    'traded': ?traded?.toIso8601String(),
  };
}

/// Rolls each stat around the species mean, in standard deviations z (clamped to ±3):
/// z = 0.8 × a "fine specimen" factor shared by the card + 0.6 × the stat's own noise.
/// The shared factor has a fat upward tail (Student-t, 3 degrees of freedom) and only a
/// narrow downward spread, so great cards turn up now and then and poor ones rarely:
/// quality ≥ 80 % for ~8.5 % of cards, ≥ 95 % for ~1.7 %, ≤ 20 % for ~1 % (decided
/// 2026-10-30; before: independent normals, 1.7 % / 0 % / 1.7 %). The card's [rarity] is
/// drawn apart (see drawRarity) and doesn't change the stats.
CardData rollCard(
  Bird bird,
  String? region, {
  required String rarity,
  String? recording,
  Random? random,
}) {
  final r = random ?? Random();
  final t = _studentT3(r);
  final specimen = t > 0 ? t : -_normal(r).abs() * 0.35;
  final rolls = {
    for (final e in bird.stats.entries)
      e.key: (e.value, (0.8 * specimen + 0.6 * _normal(r)).clamp(-3.0, 3.0)),
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
    rarity: rarity,
    region: region,
    recording: recording,
  );
}

/// Standard normal value (Box-Muller).
double _normal(Random r) =>
    sqrt(-2 * log(1 - r.nextDouble())) * cos(2 * pi * r.nextDouble());

/// Student-t with 3 degrees of freedom, scaled to variance 1: like a normal, with fat tails.
double _studentT3(Random r) {
  final chi2 = [for (var i = 0; i < 3; i++) pow(_normal(r), 2)]
      .reduce((a, b) => a + b);
  return _normal(r) / sqrt(chi2 / 3) / sqrt(3);
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
