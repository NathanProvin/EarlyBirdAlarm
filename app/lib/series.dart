import 'dart:math';

import 'birds.dart';
import 'cards.dart';
import 'ui/profile.dart' show collectionPoints;

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

/// Series made in the app from the birds' AVONET diet or habitat (2026-11-24): id, page,
/// reward, the values that count, names in EN / FR / DE / ES. The biggest groups (insect
/// eaters, forest…) are left out: a hundred birds in one region is no series.
const _traitSeries = [
  (
    'trait-nectarivores',
    'diets',
    'rare',
    {'Nectarivore'},
    ['Nectarivores', 'Nectarivores', 'Nektarfresser', 'Nectarívoros'],
  ),
  (
    'trait-frugivores',
    'diets',
    'epic',
    {'Frugivore'},
    ['Frugivores', 'Frugivores', 'Fruchtfresser', 'Frugívoros'],
  ),
  (
    'trait-granivores',
    'diets',
    'rare',
    {'Granivore'},
    ['Granivores', 'Granivores', 'Körnerfresser', 'Granívoros'],
  ),
  (
    'trait-predators',
    'diets',
    'epic',
    {'Vertivore', 'Scavenger'},
    ['Predators', 'Prédateurs', 'Beutegreifer', 'Depredadores'],
  ),
  (
    'trait-piscivores',
    'diets',
    'epic',
    {'Aquatic predator'},
    ['Piscivores', 'Piscivores', 'Fischfresser', 'Piscívoros'],
  ),
  (
    'trait-herbivores',
    'diets',
    'rare',
    {'Herbivore aquatic', 'Herbivore terrestrial'},
    ['Herbivores', 'Herbivores', 'Pflanzenfresser', 'Herbívoros'],
  ),
  (
    'trait-marine',
    'habitats',
    'epic',
    {'Marine'},
    ['Seabirds', 'Marins', 'Meeresvögel', 'Marinos'],
  ),
  (
    'trait-coastal',
    'habitats',
    'rare',
    {'Coastal'},
    ['Coastal', 'Côtiers', 'Küstenvögel', 'Costeros'],
  ),
  (
    'trait-rock',
    'habitats',
    'epic',
    {'Rock'},
    ['Rupicolous', 'Rupicoles', 'Felsbewohner', 'Rupícolas'],
  ),
  (
    'trait-riverine',
    'habitats',
    'rare',
    {'Riverine'},
    ['Riparian', 'Ripicoles', 'Uferbewohner', 'Ribereños'],
  ),
  (
    'trait-grassland',
    'habitats',
    'epic',
    {'Grassland'},
    ['Grassland birds', 'Prairiaux', 'Wiesenvögel', 'Pratenses'],
  ),
];

/// The diet and habitat series, from every bird of the catalog ([seriesStates] keeps
/// those with 3 birds or more in the region).
List<Series> traitSeries(Iterable<Bird> birds) => [
  for (final (id, group, reward, values, names) in _traitSeries)
    Series.fromJson({
      'id': id,
      for (final (i, g) in const ['en', 'fr', 'de', 'es'].indexed) g: names[i],
      'group': group,
      'reward': reward,
      'birds': [
        for (final b in birds)
          if (values.contains(b.diet) || values.contains(b.habitat)) b.id,
      ],
    }),
];

/// The covered zone of a card's [region] (a 2° cell or a list id), as the pipeline's
/// CELL_AREAS boxes and country lists draw them: Europe, North America, Australia,
/// New Zealand, North Africa + Middle East, Mexico + Central America; null if unknown.
String? zoneOf(String? region) {
  if (region == null) return null;
  final cell = RegExp(r'^([NS])(\d\d)([EW])(\d{3})$').firstMatch(region);
  if (cell != null) {
    final lat = int.parse(cell[2]!) * (cell[1] == 'N' ? 1 : -1);
    final lon = int.parse(cell[4]!) * (cell[3] == 'E' ? 1 : -1);
    const boxes = [
      (34, 72, -12, 42, 'eu'),
      (24, 72, -170, -52, 'na'),
      (-44, -10, 112, 154, 'au'),
      (-48, -34, 166, 180, 'nz'),
      (18, 34, -18, 34, 'mena'),
      (12, 34, 34, 62, 'mena'),
      (34, 44, 42, 62, 'mena'),
      (6, 24, -118, -76, 'mxca'),
    ];
    for (final (a0, a1, b0, b1, zone) in boxes) {
      if (a0 <= lat && lat < a1 && b0 <= lon && lon < b1) return zone;
    }
    return null;
  }
  if (region.startsWith(RegExp('US-|CA-'))) return 'na';
  if (region.startsWith('AU-')) return 'au';
  if (region.startsWith('NZ')) return 'nz';
  if (const {'MX', 'GT', 'BZ', 'SV', 'HN', 'NI', 'CR', 'PA'}.contains(region)) {
    return 'mxca';
  }
  const mena = {
    'MA', 'DZ', 'TN', 'LY', 'EG', 'TR', 'SY', 'LB', 'IL', 'PS', 'JO', //
    'IQ', 'IR', 'SA', 'AE', 'OM', 'QA', 'KW', 'BH', 'YE',
  };
  return mena.contains(region) ? 'mena' : 'eu';
}

/// The Podium's tiers: the top share of a month's world ranking, in %.
const podiumTops = [50.0, 25.0, 10.0, 2.0, 0.1];

/// How many Podium tiers a place of [rank] among [total] players reaches. #1 counts as
/// the top 0.1 % from 100 players on (before 1,000 nobody else could reach it).
int podiumTiers(int rank, int total) => podiumTops
    .where(
      (top) =>
          100 * rank / total <= top ||
          (top == 0.1 && rank == 1 && total >= 100),
    )
    .length;

/// Game achievements, computed from play rather than from bird groups. Reworked
/// 2026-11-12 (user): 5 tiers (I…V) each, collected one at a time, tier n giving a card
/// of the n-th rarity (Common … Legendary). 2026-11-24 (user): harder goals, Early riser
/// removed (its tiers collected stay), 6 new: 23 on 4 pages. 2026-11-28 (user, 1.4.1):
/// easier tiers, set one by one (a month of play stayed at Rare), Bird Caller added: 24.
const collector = 'collector',
    localExpert = 'local-expert',
    twitcher = 'twitcher',
    ornithologist = 'ornithologist',
    duplicates = 'duplicates',
    fullSet = 'full-set';
const perfectSpecimen = 'perfect-specimen',
    rareFinds = 'rare-finds',
    epicFinds =
        'epic-finds', // "Rarities" since 2026-11-24 (ids never change)
    legendaryHunter = 'legendary-hunter',
    gallery = 'gallery',
    crafter = 'crafter';
const sharpEar = 'sharp-ear',
    wakeUpStreak = 'wake-up-streak',
    dailyBirder = 'daily-birder',
    fidelity = 'fidelity',
    globetrotter = 'globetrotter',
    explorer = 'explorer';
const fullHouse = 'full-house',
    trader = 'trader',
    influencer = 'influencer',
    score = 'score',
    podium = 'podium',
    birdCaller = 'bird-caller';

/// Each achievement's page (1-4) and the goal of each of its 5 tiers.
const achievementGoals = <String, (int, List<int>)>{
  collector: (1, [10, 50, 200, 750, 2500]),
  localExpert: (1, [15, 40, 100, 175, 250]),
  twitcher: (1, [30, 75, 200, 500, 1000]),
  ornithologist: (1, [8, 16, 40, 90, 150]), // bird families owned
  duplicates: (1, [2, 4, 8, 20, 40]),
  fullSet: (1, [2, 3, 4, 5, 6]), // rarities owned; 6 = Shiny too
  perfectSpecimen: (2, [76, 81, 91, 96, 100]), // best quality, %: >75 … 100
  rareFinds: (2, [5, 25, 75, 250, 1000]),
  epicFinds: (2, [2, 8, 20, 75, 200]),
  legendaryHunter: (2, [1, 3, 5, 10, 25]),
  gallery: (2, [1, 3, 10, 25, 50]), // species with all their arts (2 or more)
  crafter: (2, [1, 5, 15, 45, 100]), // cards forged
  sharpEar: (3, [5, 10, 25, 50, 100]), // right answers in a row
  wakeUpStreak: (3, [3, 7, 20, 100, 365]), // days in a row
  dailyBirder: (3, [7, 21, 75, 150, 365]), // days with a card
  fidelity: (3, [2, 3, 6, 9, 12]), // months of the year with a card
  globetrotter: (3, [2, 5, 15, 40, 75]),
  explorer: (3, [2, 3, 4, 5, 6]), // covered zones with a card (zoneOf)
  fullHouse: (4, [1, 3, 5, 10, 20]),
  trader: (4, [1, 5, 15, 40, 100]), // cards traded away
  influencer: (4, [1, 3, 5, 10, 25]), // friends joined through the invite link
  score: (4, [300, 2000, 5000, 20000, 100000]), // collection points
  podium: (4, [1, 2, 3, 4, 5]), // Podium tiers reached (podiumTiers)
  birdCaller: (4, [3, 15, 45, 200, 500]), // Lures used
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
  'achievements4',
  'families',
  'habitats',
  'diets',
  'themes',
  'voices',
];

/// What else than the cards an achievement counts.
typedef Play = ({
  int bestStreak, // right answers in a row, alarms and Training
  int bestAlarmStreak, // days of right alarm answers in a row
  int given, // cards traded away
  int friends, // friends joined through the invite link
  int crafted, // cards forged
  int podium, // Podium tiers reached
  int lured, // Lures used
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
  // Each species' arts owned (Art x of n), for the Gallery.
  final arts = <String, Set<int>>{};
  for (final c in cards) {
    if (birdById(c.birdId)?.artOf(c.photo) case (final x, final n) when n > 1) {
      (arts[c.birdId] ??= {}).add(x);
    }
  }
  final values = {
    collector: cards.length,
    localExpert: have.where(byId.containsKey).length,
    twitcher: have.length,
    ornithologist: {for (final id in have) ?birdById(id)?.family}.length,
    duplicates: copies.values.fold(0, max),
    fullSet: {for (final c in cards) rarityOf(c)}.whereType<String>().length,
    perfectSpecimen: cards.fold(0, (m, c) => max(m, c.quality)),
    rareFinds: atLeast('rare'),
    epicFinds: atLeast('epic'),
    legendaryHunter: atLeast('legendary'),
    gallery: arts.entries
        .where((e) => e.value.length >= birdById(e.key)!.artOf(null)!.$2)
        .length,
    crafter: play.crafted,
    sharpEar: play.bestStreak,
    wakeUpStreak: play.bestAlarmStreak,
    dailyBirder: {
      for (final c in cards)
        DateTime(c.earned.year, c.earned.month, c.earned.day),
    }.length,
    fidelity: {for (final c in cards) c.earned.month}.length,
    globetrotter: {for (final c in cards) ?c.region}.length,
    explorer: {for (final c in cards) ?zoneOf(c.region)}.length,
    fullHouse: series.where((s) => s.complete).length,
    trader: play.given,
    influencer: play.friends,
    score: collectionPoints(cards),
    podium: play.podium,
    birdCaller: play.lured,
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
