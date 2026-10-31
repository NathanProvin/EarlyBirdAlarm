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
      birds = [for (final b in j['birds'] as List) b as String];
  final String id;
  final Map<String, String> names; // language -> series name (see localName)
  final String? signature; // the bird on the badge, when it lives in the region
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

/// A series or an achievement as it stands for the player.
class SeriesState {
  SeriesState({
    required this.id,
    required this.owned,
    required this.total,
    this.series,
    this.birds = const [],
    this.face,
  });
  final String id;
  final Series? series; // null for an achievement
  final int owned, total;
  final List<Bird> birds; // the region's birds of the series, by number
  final Bird? face; // the badge photo

  bool get complete => owned >= total;
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
    return r != null && tiers.indexOf(r) >= tiers.indexOf(tier);
  }).length;
  return [
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
        ),
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
  ];
}

int _byNumber(Bird a, Bird b) => a.number.compareTo(b.number);
