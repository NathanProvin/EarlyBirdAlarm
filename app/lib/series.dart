import 'dart:math';

import 'birds.dart';
import 'cards.dart';

/// A series of birds to collect, from series.json (pipeline/series.md).
class Series {
  Series.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      en = j['en'] as String,
      fr = j['fr'] as String,
      signature = j['signature'] as String?,
      birds = [for (final b in j['birds'] as List) b as String];
  final String id, en, fr;
  final String? signature; // the bird on the badge, when it lives in the region
  final List<String> birds;

  String nameIn(String locale) => locale.startsWith('fr') ? fr : en;
}

/// All series of the catalog; loaded by initContent.
List<Series> allSeries = [];

/// Game achievements, computed from play rather than from bird groups.
const legendaryHunter = 'legendary-hunter', perfectWeek = 'perfect-week';
const fullSet = 'full-set';

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
  final legendary = [
    for (final b in region)
      if (b.rarity == 'legendary') b,
  ];
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
    if (legendary.isNotEmpty)
      SeriesState(
        id: legendaryHunter,
        birds: legendary,
        owned: owned(legendary),
        total: legendary.length,
      ),
    SeriesState(id: perfectWeek, owned: min(bestStreak, 7), total: 7),
    SeriesState(
      id: fullSet,
      owned: {for (final c in cards) c.rarity ?? birdById(c.birdId)?.rarity}
          .whereType<String>()
          .length,
      total: tiers.length,
    ),
  ];
}

int _byNumber(Bird a, Bird b) => a.number.compareTo(b.number);
