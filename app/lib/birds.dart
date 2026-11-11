import 'dart:math';

// Expert (2026-11-01) is last: the saved difficulty is the index.
enum Difficulty { easy, medium, hard, expert }

/// Rarity tiers, most common first.
const tiers = ['common', 'uncommon', 'rare', 'epic', 'legendary'];

/// Card rarities: the bird tiers plus Shiny (1.1), a card only, never a bird's tier: a
/// leucistic or melanistic photo, [shinyOdds] per card of a species that has one.
const cardTiers = [...tiers, 'shiny'];
const shinyOdds = 1 / 1000;

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
  Difficulty.expert: {'common', 'uncommon', 'rare', 'epic', 'legendary'},
};

/// Step 2, the card won: its rarity, drawn independently of the bird (decided
/// 2026-10-30; a Blackbird can come as a Legendary copy). The odds decay exponentially
/// with the tier, like radioactive decay: each step up is [rarityDecay] times as likely
/// as the one below, so Common is always the most frequent card (2026-10-31; before,
/// Uncommon beat Common on Hard). Easy never gives a Legendary card.
/// Final odds, after [rarityScale] (Common / Uncommon / Rare / Epic / Legendary):
/// Easy 76.7 / 17.9 / 4.5 / 0.9 / 0 %, Medium 72.3 / 18.3 / 6.4 / 2.2 / 0.8 %,
/// Hard 61.3 / 20.6 / 10.3 / 5.2 / 2.6 %, Expert 50.6 / 25.3 / 12.7 / 7.6 / 3.8 %.
const rarityDecay = {
  Difficulty.easy: 0.25,
  Difficulty.medium: 0.35,
  Difficulty.hard: 0.5, // each step twice as rare
  Difficulty.expert:
      0.5, // as Hard, with the Epic and Legendary odds × [expertBoost]
};

/// Expert types the name without choices: 20 % more Epic and Legendary cards than Hard.
const expertBoost = 1.2;

/// Share kept from the decay curve for each tier above Common (Uncommon → Legendary);
/// Common takes the rest. 2026-11-03, rare cards dropped too often: 20 % fewer, except
/// Uncommon and Rare on Easy (5 % fewer, to hook new players) and Expert (unchanged, to
/// reward experts).
const rarityScale = {
  Difficulty.easy: [0.95, 0.95, 0.8, 0.8],
  Difficulty.medium: [0.8, 0.8, 0.8, 0.8],
  Difficulty.hard: [0.8, 0.8, 0.8, 0.8],
  Difficulty.expert: [1.0, 1.0, 1.0, 1.0],
};

/// The odds of each rarity by difficulty (they sum to 1).
final cardOdds = {for (final d in Difficulty.values) d: _odds(d)};

Map<String, double> _odds(Difficulty d) {
  final w = [
    for (final (k, t) in tiers.indexed)
      d == Difficulty.easy && t == 'legendary'
          ? 0.0
          : pow(rarityDecay[d]!, k) *
                (d == Difficulty.expert && k >= tiers.indexOf('epic')
                    ? expertBoost
                    : 1.0),
  ];
  final sum = w.reduce((a, b) => a + b);
  final up = [
    for (var k = 1; k < tiers.length; k++) w[k] / sum * rarityScale[d]![k - 1],
  ];
  return {
    tiers.first: 1 - up.reduce((a, b) => a + b),
    for (var k = 1; k < tiers.length; k++) tiers[k]: up[k - 1],
  };
}

/// How strongly a card's rarity leans toward its bird's scarcity: each rarity's odds are
/// divided by [rarityLean] / [rarityDecay] for every tier between it and the bird's tier
/// (Hard: 3). Being stronger than the decay, it makes a scarce bird's cards peak at its
/// own tier (a Legendary bird on Hard: 11 / 11 / 16 / 25 / 37 %); with a flat 2 they
/// came out even at 20 % each (2026-10-31).
const rarityLean = 1.5;

/// The rarity of a card won at [difficulty]: [cardOdds], tilted toward [birdTier] (how
/// scarce the bird is this month) so a scarce bird rarely comes as a Common card and a
/// common one rarely as a Legendary.
String drawRarity(Difficulty difficulty, {String? birdTier, Random? random}) {
  final bird = birdTier == null ? null : tiers.indexOf(birdTier);
  final w = {
    for (final (i, t) in tiers.indexed)
      t:
          cardOdds[difficulty]![t]! /
          (bird == null
              ? 1
              : pow(rarityLean / rarityDecay[difficulty]!, (i - bird).abs())),
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
  Difficulty.expert: {'song', 'call', 'alarm'},
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
  Bird.fromJson(Map<String, dynamic> j, [this.months = const {}, this.level])
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
      variants = [
        for (final v in j['variants'] as List? ?? const [])
          (photo: v['photo'] as String, credit: v['credit'] as String),
      ],
      shiny = [
        for (final v in j['shiny'] as List? ?? const [])
          (
            photo: v['photo'] as String,
            credit: v['credit'] as String,
            kind: v['kind'] as String,
          ),
      ],
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
  /// Extra photos (catalog 1.1), best first: the best one goes to Legendary cards.
  final List<({String photo, String credit})> variants;

  /// Leucistic / melanistic photos for Shiny cards (picked by hand).
  final List<({String photo, String credit, String kind})> shiny;
  final int number; // card number, in taxonomic order over all species
  final List<Recording> recordings;
  final Map<String, ({double mean, double sd})> stats; // missing = unknown
  final Map<int, String>
  months; // month 1-12 -> tier in the region; absent = not around
  /// How rare the species is in the region, 1 (commonest) to 10, from the share of its
  /// records in its commonest month (pipeline level()); null when unknown.
  final int? level;

  String nameIn(String locale) => localName(names, locale);

  /// The photo of a card (its variant or Shiny photo, saved when won) and its credit; the
  /// catalog photo for older cards, heard birds, or a photo the catalog no longer has.
  ({String photo, String credit, String? kind}) photoOf(String? photo) =>
      [
        for (final v in variants)
          (photo: v.photo, credit: v.credit, kind: null),
        for (final v in shiny) (photo: v.photo, credit: v.credit, kind: v.kind),
      ].firstWhere(
        (v) => v.photo == photo,
        orElse: () => (photo: this.photo, credit: photoCredit, kind: null),
      );

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
    Difficulty.hard || Difficulty.expert => [sameFamily, sameOrder],
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
