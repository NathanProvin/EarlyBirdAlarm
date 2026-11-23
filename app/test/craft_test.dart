import 'dart:math';

import 'package:early_bird/cards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recipes', () {
    expect(craftResult(List.filled(4, 'common'), const ['x']), 'uncommon');
    expect(craftResult(List.filled(3, 'uncommon'), const ['x']), 'rare');
    expect(craftResult(List.filled(3, 'epic'), const ['x']), 'legendary');
    expect(craftResult(['rare', 'common'], const ['x']), 'booster');
    expect(craftResult(['common', 'common', 'common'], const ['x']), isNull);
    expect(
      craftResult(['common', 'common', 'common', 'rare'], const ['x']),
      isNull,
    );
    expect(craftResult(List.filled(3, 'legendary'), const ['x']), isNull);
    expect(craftResult(['shiny', 'common'], const ['x']), isNull);
    expect(craftResult([], const []), isNull);
    // Two species never combine, for a card or a booster.
    expect(
      craftResult(List.filled(4, 'common'), const ['x', 'x', 'y', 'x']),
      isNull,
    );
    expect(craftResult(['rare', 'common'], const ['x', 'y']), isNull);
  });

  test('forged stats move by -2 % to +5 %, same for every stat', () {
    final best = CardData(
      birdId: 'x',
      stats: {'weight': 100, 'wingspan': 50},
      quality: 70,
      earned: DateTime(2026),
      rarity: 'common',
      photo: 'p.jpg',
    );
    final r = Random(1);
    for (var i = 0; i < 1000; i++) {
      final f = forgeCard(best, null, 'uncommon', r);
      final m = f.stats['weight']! / 100;
      expect(m, inInclusiveRange(0.98, 1.05));
      expect(f.stats['wingspan']! / 50, closeTo(m, 1e-9));
      expect((f.rarity, f.photo, f.quality), ('uncommon', 'p.jpg', 70));
    }
  });
}
