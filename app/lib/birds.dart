import 'dart:math';

class Bird {
  const Bird(this.name, this.nameFr, this.latin, this.audio);
  final String name;
  final String nameFr;
  final String latin;
  final String audio;

  String nameIn(String locale) => locale.startsWith('fr') ? nameFr : name;
}

// shortcut: 5 placeholder birds with synthetic chirps, replaced by the real catalog in Iteration 3.
const birds = [
  Bird(
    'European Robin',
    'Rougegorge familier',
    'Erithacus rubecula',
    'assets/birds/robin.wav',
  ),
  Bird(
    'Common Blackbird',
    'Merle noir',
    'Turdus merula',
    'assets/birds/blackbird.wav',
  ),
  Bird(
    'Eurasian Wren',
    'Troglodyte mignon',
    'Troglodytes troglodytes',
    'assets/birds/wren.wav',
  ),
  Bird(
    'Common Chaffinch',
    'Pinson des arbres',
    'Fringilla coelebs',
    'assets/birds/chaffinch.wav',
  ),
  Bird(
    'Great Tit',
    'Mésange charbonnière',
    'Parus major',
    'assets/birds/great_tit.wav',
  ),
];

/// How many recently heard birds a new ring avoids.
const recentCount = 3;

/// A random bird index not in [recent] (any bird if all are recent).
int pickBird(List<int> recent, [Random? random]) {
  final fresh = [
    for (var i = 0; i < birds.length; i++)
      if (!recent.contains(i)) i,
  ];
  final pool = fresh.isEmpty
      ? [for (var i = 0; i < birds.length; i++) i]
      : fresh;
  return pool[(random ?? Random()).nextInt(pool.length)];
}

/// The answer plus 3 other birds, shuffled.
List<Bird> choicesFor(Bird answer, [Random? random]) =>
    ([...birds]
          ..remove(answer)
          ..shuffle(random))
        .take(3)
        .followedBy([answer])
        .toList()
      ..shuffle(random);
