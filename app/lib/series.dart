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

/// Game achievements, computed from play rather than from bird groups. Reworked
/// 2026-11-12 (user): 18 achievements on 3 pages, each with 5 tiers (I…V) collected one
/// at a time, tier n giving a card of the n-th rarity (Common … Legendary).
const collector = 'collector',
    localExpert = 'local-expert',
    twitcher = 'twitcher',
    duplicates = 'duplicates',
    fullSet = 'full-set',
    perfectSpecimen = 'perfect-specimen';
const rareFinds = 'rare-finds',
    epicFinds = 'epic-finds',
    legendaryHunter = 'legendary-hunter',
    sharpEar = 'sharp-ear',
    wakeUpStreak = 'wake-up-streak',
    earlyRiser = 'early-riser';
const dailyBirder = 'daily-birder',
    fidelity = 'fidelity',
    globetrotter = 'globetrotter',
    fullHouse = 'full-house',
    trader = 'trader',
    influencer = 'influencer';

/// Each achievement's page (1-3) and the goal of each of its 5 tiers.
const achievementGoals = <String, (int, List<int>)>{
  collector: (1, [10, 50, 100, 500, 2500]),
  localExpert: (1, [10, 25, 50, 100, 150]),
  twitcher: (1, [25, 75, 150, 300, 600]),
  duplicates: (1, [3, 5, 10, 20, 40]),
  fullSet: (1, [2, 3, 4, 5, 6]), // rarities owned; 6 = Shiny too
  perfectSpecimen: (1, [80, 85, 90, 95, 99]), // best quality, %
  rareFinds: (2, [5, 25, 75, 200, 500]),
  epicFinds: (2, [1, 5, 15, 40, 100]),
  legendaryHunter: (2, [1, 3, 5, 10, 25]),
  sharpEar: (2, [5, 10, 25, 50, 100]), // right answers in a row
  wakeUpStreak: (2, [3, 7, 30, 100, 365]), // days in a row
  earlyRiser: (2, [5, 20, 50, 150, 365]), // cards won before 7:00
  dailyBirder: (3, [7, 30, 90, 180, 365]), // days with a card
  fidelity: (3, [2, 3, 6, 9, 12]), // months of the year with a card
  globetrotter: (3, [2, 3, 5, 10, 20]),
  fullHouse: (3, [1, 3, 5, 10, 20]),
  trader: (3, [1, 5, 15, 40, 100]), // cards traded away
  influencer: (3, [1, 3, 5, 10, 25]), // friends joined through the invite link
};

/// Achievements collected before the tiers (one goal each, saved as their id): the
/// tiers they stand for, so nothing is collected twice.
const _oldAchievements = <String, (String, int)>{
  'collector': (collector, 3), // 100 cards
  'local-expert': (localExpert, 3), // 50 species
  'rare-finds': (rareFinds, 1), // 5 cards
  'legendary-hunter': (legendaryHunter, 3), // 5 Legendary cards
  'full-set': (fullSet, 4), // 5 rarities
  'five-of-a-kind': (duplicates, 2), // 5 copies
  'dawn-chorus': (earlyRiser, 1), // 10 cards before 7:00
  'globetrotter': (globetrotter, 2), // 3 regions
  'full-house': (fullHouse, 2), // 3 series
  'perfect-specimen': (perfectSpecimen, 4), // 95 %
  'perfect-week': (wakeUpStreak, 2), // 7 days
  'iron-streak': (wakeUpStreak, 3), // 30 days
};

/// The tiers of [id] collected so far ("id#n" for tier n, or an old achievement).
int tiersDone(String id, Set<String> collected) {
  var n = 0;
  for (final MapEntry(key: old, value: (to, t)) in _oldAchievements.entries) {
    if (to == id && collected.contains(old)) n = max(n, t);
  }
  while (n < 5 && collected.contains('$id#${n + 1}')) {
    n++;
  }
  return n;
}

/// Pages of the Series screen, in order (a series' group, or an achievements page).
const seriesGroups = [
  'achievements1',
  'achievements2',
  'achievements3',
  'families',
  'habitats',
  'themes',
  'voices',
];

/// What else than the cards an achievement counts.
typedef Play = ({
  int bestStreak, // right answers in a row, alarms and Training
  int bestAlarmStreak, // days of right alarm answers in a row
  int given, // cards traded away
  int friends, // friends joined through the invite link
  Set<String> collected, // series and achievement tiers collected
});

/// A series or an achievement as it stands for the player.
class SeriesState {
  SeriesState({
    required this.id,
    required this.owned,
    required this.total,
    this.series,
    this.birds = const [],
    this.face,
    this.group = 'achievements1',
    this.tier = 0,
  });
  final String id;
  final Series? series; // null for an achievement
  final String group; // its page (see seriesGroups)
  final int owned, total;
  final List<Bird> birds; // the region's birds of the series, by number
  final Bird? face; // the badge photo
  final int
  tier; // an achievement's tiers collected (0-5); its goal is tier + 1

  /// All 5 tiers of an achievement collected.
  bool get maxed => series == null && tier >= 5;

  bool get complete => owned >= total && !maxed;

  /// The rarity of the card collected on completing it: an achievement's tier.
  String get reward => series?.reward ?? tiers[min(tier, 4)];
}

/// The series that count in the [region] (at least 3 of their birds live there), then the
/// achievements at their current tier, with what [cards] and [play] have earned.
List<SeriesState> seriesStates(
  List<Bird> region,
  List<CardData> cards,
  Play play,
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
  final values = {
    collector: cards.length,
    localExpert: have.where(byId.containsKey).length,
    twitcher: have.length,
    duplicates: copies.values.fold(0, max),
    fullSet: {for (final c in cards) rarityOf(c)}.whereType<String>().length,
    perfectSpecimen: cards.fold(0, (m, c) => max(m, c.quality)),
    rareFinds: atLeast('rare'),
    epicFinds: atLeast('epic'),
    legendaryHunter: atLeast('legendary'),
    sharpEar: play.bestStreak,
    wakeUpStreak: play.bestAlarmStreak,
    earlyRiser: cards.where((c) => c.earned.hour < 7).length,
    dailyBirder: {
      for (final c in cards)
        DateTime(c.earned.year, c.earned.month, c.earned.day),
    }.length,
    fidelity: {for (final c in cards) c.earned.month}.length,
    globetrotter: {for (final c in cards) ?c.region}.length,
    fullHouse: series.where((s) => s.complete).length,
    trader: play.given,
    influencer: play.friends,
  };
  return [
    ...series,
    for (final MapEntry(key: id, value: (page, goals))
        in achievementGoals.entries)
      if (tiersDone(id, play.collected) case final tier)
        SeriesState(
          id: id,
          owned: min(values[id]!, goals[min(tier, 4)]),
          total: goals[min(tier, 4)],
          group: 'achievements$page',
          tier: tier,
        ),
  ];
}

int _byNumber(Bird a, Bird b) => a.number.compareTo(b.number);
