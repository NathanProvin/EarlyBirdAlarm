import 'dart:math';

class Bird {
  const Bird(this.name, this.latin, this.audio);
  final String name;
  final String latin;
  final String audio;
}

// shortcut: 5 placeholder birds with synthetic chirps, replaced by the real catalog in Iteration 3.
const birds = [
  Bird('European Robin', 'Erithacus rubecula', 'assets/birds/robin.wav'),
  Bird('Common Blackbird', 'Turdus merula', 'assets/birds/blackbird.wav'),
  Bird('Eurasian Wren', 'Troglodytes troglodytes', 'assets/birds/wren.wav'),
  Bird('Common Chaffinch', 'Fringilla coelebs', 'assets/birds/chaffinch.wav'),
  Bird('Great Tit', 'Parus major', 'assets/birds/great_tit.wav'),
];

/// The answer plus 3 other birds, shuffled.
List<Bird> choicesFor(Bird answer, [Random? random]) =>
    ([...birds]
          ..remove(answer)
          ..shuffle(random))
        .take(3)
        .followedBy([answer])
        .toList()
      ..shuffle(random);
