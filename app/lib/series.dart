import 'dart:math';

import 'birds.dart';
import 'cards.dart';

/// A series of birds to collect, from series.json (pipeline/series.md).
class Series {
  Series.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      names = {
        for (final g in catalogLangs)
          if (j[g] case final String n) g: n,
      },
      signature = j['signature'] as String?,
      // Older series.json (before 2026-10-31) had neither: one page, Rare rewards.
      group = j['group'] as String? ?? 'families',
      reward = j['reward'] as String? ?? 'rare',
      birds = [for (final b in j['birds'] as List) b as String];
  final String id;
  final Map<String, String> names; // language -> series name (see localName)
  final String? signature; // the bird on the badge, when it lives in the region
  final String group; // its page: families, habitats, themes
  final String reward; // rarity of the card collected on completing it
  final List<String> birds;

  String nameIn(String locale) => localName(names, locale);
}

/// All series of the catalog; loaded by initContent.
List<Series> allSeries = [];

/// Game achievements, computed from play rather than from bird groups.
const legendaryHunter = 'legendary-hunter', perfectWeek = 'perfect-week';
const fullSet = 'full-set',
    collector = 'collector',
    localExpert = 'local-expert';
const rareFinds = 'rare-finds';
const fiveOfAKind = 'five-of-a-kind',
    dawnChorus = 'dawn-chorus',
    globetrotter = 'globetrotter';
const fullHouse = 'full-house',
    perfectSpecimen = 'perfect-specimen',
    ironStreak = 'iron-streak';

/// Pages of the Series screen, in order (a series' group, or an achievements page).
const seriesGroups = [
  'achievements',
  'achievements2',
  'families',
  'habitats',
  'themes',
];

/// The rarity of the card each achievement gives once completed (2026-10-31).
const achievementReward = {
  rareFinds: 'rare',
  perfectWeek: 'rare',
  collector: 'rare',
  fullSet: 'epic',
  localExpert: 'epic',
  legendaryHunter: 'legendary',
  fiveOfAKind: 'uncommon',
  dawnChorus: 'uncommon',
  globetrotter: 'rare',
  fullHouse: 'epic',
  perfectSpecimen: 'epic',
  ironStreak: 'legendary',
};

/// A series or an achievement as it stands for the player.
class SeriesState {
  SeriesState({
    required this.id,
    required this.owned,
    required this.total,
    this.series,
    this.birds = const [],
    this.face,
    this.group = 'achievements',
  });
  final String id;
  final Series? series; // null for an achievement
  final String group; // its page (see seriesGroups)
  final int owned, total;
  final List<Bird> birds; // the region's birds of the series, by number
  final Bird? face; // the badge photo

  bool get complete => owned >= total;

  /// The rarity of the card collected on completing it.
  String get reward => series?.reward ?? achievementReward[id] ?? 'rare';
}

/// The series that count in the [region] (at least 3 of their birds live there), then the
/// achievements, with what [cards] and [bestStreak] have earned.
List<SeriesState> seriesStates(
  List<Bird> region,
  List<CardData> cards,
  int bestStreak,
) {
  final have = {for (final c in cards) c.birdId};
  final byId = {for (final b in region) b.id: b};
  int owned(List<Bird> bs) => bs.where((b) => have.contains(b.id)).length;
  // Rarity belongs to cards (drawn when won); old cards take their species' tier.
  String? rarityOf(CardData c) => c.rarity ?? birdById(c.birdId)?.rarity;
  int atLeast(String tier) => cards.where((c) {
    final r = rarityOf(c);
    return r != null && cardTiers.indexOf(r) >= cardTiers.indexOf(tier);
  }).length;
  final series = [
    for (final s in allSeries)
      if ([for (final id in s.birds) ?byId[id]]..sort(_byNumber) case final bs
          when bs.length >= 3)
        SeriesState(
          id: s.id,
          series: s,
          birds: bs,
          owned: owned(bs),
          total: bs.length,
          face: byId[s.signature] ?? bs.first,
          group: s.group,
        ),
  ];
  final copies = <String, int>{};
  for (final c in cards) {
    copies[c.birdId] = (copies[c.birdId] ?? 0) + 1;
  }
  SeriesState next(String id, int owned, int total) => SeriesState(
    id: id,
    owned: min(owned, total),
    total: total,
    group: 'achievements2',
  );
  return [
    ...series,
    // 5 Legendary cards.
    SeriesState(
      id: legendaryHunter,
      owned: min(atLeast('legendary'), 5),
      total: 5,
    ),
    SeriesState(id: perfectWeek, owned: min(bestStreak, 7), total: 7),
    SeriesState(
      id: fullSet,
      owned: {for (final c in cards) rarityOf(c)}.whereType<String>().length,
      total: tiers.length,
    ),
    // 100 cards, duplicates included.
    SeriesState(id: collector, owned: min(cards.length, 100), total: 100),
    // 50 species of the region.
    SeriesState(
      id: localExpert,
      owned: min(have.where(byId.containsKey).length, 50),
      total: 50,
    ),
    // 5 cards Rare or better.
    SeriesState(id: rareFinds, owned: min(atLeast('rare'), 5), total: 5),
    // Page 2, from easy to hard: 5 copies of one species; 10 cards won before 7:00;
    // cards from 3 regions; 3 series completed; a card of 95 % quality; a 30-day streak.
    next(fiveOfAKind, copies.values.fold(0, max), 5),
    next(dawnChorus, cards.where((c) => c.earned.hour < 7).length, 10),
    next(globetrotter, {for (final c in cards) ?c.region}.length, 3),
    next(fullHouse, series.where((s) => s.complete).length, 3),
    next(perfectSpecimen, cards.any((c) => c.quality >= 95) ? 1 : 0, 1),
    next(ironStreak, bestStreak, 30),
  ];
}

int _byNumber(Bird a, Bird b) => a.number.compareTo(b.number);
