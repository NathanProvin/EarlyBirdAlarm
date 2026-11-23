import 'package:early_bird/cards.dart';
import 'package:early_bird/ranking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UTC month keys, last month across a new year', () {
    expect(monthKey(DateTime.utc(2026, 11, 30, 23, 59)), '202611');
    expect(lastMonthKey(DateTime.utc(2027, 1, 1)), '202612');
  });

  test('reward by top percentile', () {
    expect(rankReward(1, 100), 'legendary');
    expect(rankReward(5, 100), 'epic');
    expect(rankReward(15, 100), 'rare');
    expect(rankReward(40, 100), 'uncommon');
    expect(rankReward(41, 100), 'common');
    expect(
      rankReward(1, 14),
      'rare',
    ); // 7 %: few players, no Legendary for first
  });

  test("only this month's cards score", () {
    CardData card(DateTime earned) => CardData(
      birdId: 'unknown',
      stats: const {},
      quality: 0,
      earned: earned,
      rarity: 'rare',
    );
    final now = DateTime.utc(2026, 11, 15);
    expect(
      monthPoints([
        card(DateTime.utc(2026, 11, 2)),
        card(DateTime.utc(2026, 10, 31)),
      ], now),
      20,
    );
  });
}
