import 'dart:math';

enum Difficulty { easy, medium, hard }

/// Rarity tiers, most common first.
const tiers = ['common', 'uncommon', 'rare', 'epic', 'legendary'];

/// Step 1 of a ring, the bird: how often a species rings, by how common it is this month
/// in the region (scarce birds a little more often than the 16/8/4/2/1 of 3b; 2026-10-30),
/// and which of those tiers each difficulty drafts from.
const _weight = {
  'common': 16,
  'uncommon': 9,
  'rare': 6,
  'epic': 3,
  'legendary': 2,
};
const _allowed = {
  Difficulty.easy: {'common', 'uncommon'},
  Difficulty.medium: {'common', 'uncommon', 'rare'},
  Difficulty.hard: {'common', 'uncommon', 'rare', 'epic', 'legendary'},
};

/// Step 2, the card won: its rarity (%) by difficulty, drawn independently of the bird
/// (decided 2026-10-30). A Blackbird can come as a Legendary copy.
const cardOdds = {
  Difficulty.easy: {
    'common': 60,
    'uncommon': 32,
    'rare': 7,
    'epic': 1,
    'legendary': 0,
  },
  // Epic and Legendary lowered on 2026-10-31 (balance): −10 % on Medium, −20 % on Hard,
  // given to Common.
  Difficulty.medium: {
    'common': 45.7,
    'uncommon': 32,
    'rare': 16,
    'epic': 5.4,
    'legendary': 0.9,
  },
  Difficulty.hard: {
    'common': 28.2,
    'uncommon': 34,
    'rare': 27,
    'epic': 10.4,
    'legendary': 2.4,
  },
};

/// How strongly a card's rarity leans toward its bird's scarcity: each rarity's odds are
/// divided by this for every tier between it and the bird's tier (decided 2026-10-30).
const rarityTilt = 2.0;

/// The rarity of a card won at [difficulty]: [cardOdds], tilted toward [birdTier] (how
/// scarce the bird is this month) so a scarce bird rarely comes as a Common card and a
/// common one rarely as a Legendary.
String drawRarity(Difficulty difficulty, {String? birdTier, Random? random}) {
  final bird = birdTier == null ? null : tiers.indexOf(birdTier);
  final w = {
    for (final (i, t) in tiers.indexed)
      t:
          cardOdds[difficulty]![t]! /
          (bird == null ? 1 : pow(rarityTilt, (i - bird).abs())),
  };
  var r = (random ?? Random()).nextDouble() * w.values.reduce((a, b) => a + b);
  return w.entries
      .firstWhere(
        (e) => e.value > 0 && (r -= e.value) < 0,
        orElse: () => w.entries.lastWhere((e) => e.value > 0),
      )
      .key;
}

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

/// Languages of the catalog's names (pipeline LANGS); EN and FR always present.
const catalogLangs = ['en', 'fr', 'de', 'es'];

/// The name in [locale]'s language from a catalog entry's `en` / `fr` / `de` / `es`
/// fields, else English (German and Spanish names may be missing).
String localName(Map<String, dynamic> j, String locale) =>
    (j[locale.split(RegExp('[_-]')).first] ?? j['en']) as String;

class Bird {
  /// A species from species.json, with its [months] in the current region.
  Bird.fromJson(Map<String, dynamic> j, [this.months = const {}])
    : id = j['id'] as String,
      latin = j['latin'] as String,
      name = j['en'] as String,
      names = {
        for (final g in catalogLangs)
          if (j[g] case final String n) g: n,
      },
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

  final String id, latin, name, order, family, photo, photoCredit;
  final Map<String, String> names; // language -> common name (see localName)
  final int number; // card number, in taxonomic order over all species
  final List<Recording> recordings;
  final Map<String, ({double mean, double sd})> stats; // missing = unknown
  final Map<int, String>
  months; // month 1-12 -> tier in the region; absent = not around

  String nameIn(String locale) => localName(names, locale);

  /// How common the species is: its commonest tier of the year in the region. Cards
  /// have their own rarity (drawn when won); this one is for cards from before 2026-10-30.
  String get rarity => tierIn(null) ?? 'legendary';

  /// The tier in [month], or the most common tier of the year when [month] is null.
  String? tierIn(int? month) => month != null
      ? months[month]
      : tiers.where(months.containsValue).firstOrNull;

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
