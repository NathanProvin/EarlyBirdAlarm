import 'package:early_bird/cards.dart';
import 'package:early_bird/ui/profile.dart';
import 'package:flutter_test/flutter_test.dart';

CardData card(String rarity, int quality) => CardData(
  birdId: 'unknown',
  stats: const {},
  quality: quality,
  earned: DateTime(2026),
  rarity: rarity,
);

void main() {
  test('rarity outweighs numbers; quality adds up to 25 %', () {
    expect(collectionPoints([card('epic', 0)]), 60);
    expect(collectionPoints([card('epic', 100)]), 75); // 60 × 1.25
    final many = [
      for (var i = 0; i < 1000; i++)
        card(i % 5 == 0 ? 'uncommon' : 'common', 50),
    ];
    final few = [
      for (var i = 0; i < 100; i++)
        card(
          i < 82
              ? 'rare'
              : i < 97
              ? 'epic'
              : 'legendary',
          50,
        ),
    ];
    expect(collectionPoints(few), greaterThan(collectionPoints(many)));
  });
}
