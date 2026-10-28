import 'dart:math';

enum Difficulty { easy, medium, hard }

/// Rarity tiers, most common first, with how often each is picked to ring.
const _weight = {
  'common': 16,
  'uncommon': 8,
  'rare': 4,
  'epic': 2,
  'legendary': 1,
};
const tiers = ['common', 'uncommon', 'rare', 'epic', 'legendary'];
const _allowed = {
  Difficulty.easy: {'common', 'uncommon'},
  Difficulty.medium: {'common', 'uncommon', 'rare'},
  Difficulty.hard: {'common', 'uncommon', 'rare', 'epic', 'legendary'},
};

/// Vocalizations that can ring at each difficulty (decisions.md "Vocalizations").
const _kinds = {
  Difficulty.easy: {'song'},
  Difficulty.medium: {'song', 'call'},
  Difficulty.hard: {'song', 'call', 'alarm'},
};

/// Card stats, in card order.
const statKeys = ['weight', 'wingspan', 'length', 'distance'];

class Recording {
  Recording.fromJson(Map<String, dynamic> j)
    : file = j['file'] as String,
      kind = j['kind'] as String,
      credit = j['credit'] as String,
      nc = j['nc'] == true;

  final String
  file; // relative to the content root, e.g. audio/turdus_merula-2.m4a
  final String kind; // song, call or alarm
  final String credit;
  final bool nc; // non-commercial license: replace before any monetization
}

class Bird {
  /// A species from species.json, with its [months] in the current region.
  Bird.fromJson(Map<String, dynamic> j, [this.months = const {}])
    : id = j['id'] as String,
      latin = j['latin'] as String,
      name = j['en'] as String,
      nameFr = j['fr'] as String,
      order = j['order'] as String,
      family = j['family'] as String,
      photo = j['photo'] as String,
      photoCredit = j['photoCredit'] as String,
      number = j['number'] as int,
      recordings = [
        for (final r in j['recordings'] as List)
          Recording.fromJson(r as Map<String, dynamic>),
      ],
      stats = {
        for (final e in (j['stats'] as Map<String, dynamic>).entries)
          if (e.value != null)
            e.key: (
              mean: ((e.value as List)[0] as num).toDouble(),
              sd: ((e.value as List)[1] as num).toDouble(),
            ),
      };

  final String id, latin, name, nameFr, order, family, photo, photoCredit;
  final int number; // card number, in taxonomic order over all species
  final List<Recording> recordings;
  final Map<String, ({double mean, double sd})> stats; // missing = unknown
  final Map<int, String>
  months; // month 1-12 -> tier in the region; absent = not around

  String nameIn(String locale) => locale.startsWith('fr') ? nameFr : name;

  /// Card tier: the bird's commonest tier of the year in the region.
  String get rarity => tierIn(null) ?? 'legendary';

  /// The tier in [month], or the most common tier of the year when [month] is null.
  String? tierIn(int? month) => month != null
      ? months[month]
      : _weight.keys.where(months.containsValue).firstOrNull;

  /// Recordings that can ring at [difficulty]; a bird without that kind keeps its best one.
  List<Recording> playable(Difficulty difficulty) {
    final r = [
      for (final r in recordings)
        if (_kinds[difficulty]!.contains(r.kind)) r,
    ];
    return r.isNotEmpty ? r : recordings.take(1).toList();
  }
}

/// Birds of the current region (or the bundled fallback birds).
List<Bird> birds = [];

/// Every species known to the app, for cards won in another region.
Map<String, Bird> species = {};

Bird? birdById(String id) =>
    birds.where((b) => b.id == id).firstOrNull ?? species[id];

/// Birds that can ring in [month] (null = any month) at [difficulty], with their pick weight.
/// Falls back to every bird so a ring always has one.
Map<Bird, int> pool(int? month, Difficulty difficulty) {
  final p = {
    for (final b in birds)
      if (_allowed[difficulty]!.contains(b.tierIn(month)))
        b: _weight[b.tierIn(month)]!,
  };
  return p.isNotEmpty ? p : {for (final b in birds) b: 1};
}

/// A weighted random bird and recording for a ring, among recordings on the phone
/// ([onPhone]), avoiding [recent] bird ids when possible. Null if nothing is on the phone.
(Bird, Recording)? pickBird(
  List<String> recent,
  int? month,
  Difficulty difficulty,
  bool Function(Recording) onPhone, [
  Random? random,
]) {
  random ??= Random();
  final all = {
    for (final MapEntry(key: b, value: w) in pool(month, difficulty).entries)
      if (b.playable(difficulty).any(onPhone)) b: w,
  };
  if (all.isEmpty) return null;
  final fresh = {...all}..removeWhere((b, _) => recent.contains(b.id));
  final p = fresh.isNotEmpty ? fresh : all;
  var r = random.nextInt(p.values.reduce((a, b) => a + b));
  final bird = p.entries.firstWhere((e) => (r -= e.value) < 0).key;
  final recs = bird.playable(difficulty).where(onPhone).toList();
  return (bird, recs[random.nextInt(recs.length)]);
}

/// The answer plus 3 wrong birds from the same pool, shuffled. Wrong birds are from another
/// order (easy), the same order (medium) or the same family (hard); when a group runs short
/// the next easier group fills in.
List<Bird> choicesFor(
  Bird answer,
  int? month,
  Difficulty difficulty, [
  Random? random,
]) {
  var others = pool(month, difficulty).keys.where((b) => b != answer).toList();
  if (others.length < 3) others = birds.where((b) => b != answer).toList();
  bool sameFamily(Bird b) => b.family == answer.family;
  bool sameOrder(Bird b) => b.order == answer.order;
  final groups = switch (difficulty) {
    Difficulty.easy => [(Bird b) => !sameOrder(b)],
    Difficulty.medium => [sameOrder],
    Difficulty.hard => [sameFamily, sameOrder],
  };
  final wrong = <Bird>[];
  for (final g in [...groups, (Bird _) => true]) {
    wrong.addAll(
      (others.where((b) => g(b) && !wrong.contains(b)).toList()
            ..shuffle(random))
          .take(3 - wrong.length),
    );
  }
  return [...wrong, answer]..shuffle(random);
}
