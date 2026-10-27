import 'dart:math';

import 'package:early_bird/birds.dart';
import 'package:early_bird/store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('choices: 4 distinct birds, answer always included', () {
    for (var seed = 0; seed < 50; seed++) {
      final answer = birds[seed % birds.length];
      final choices = choicesFor(answer, Random(seed));
      expect(choices.length, 4);
      expect(choices.toSet().length, 4);
      expect(choices, contains(answer));
    }
  });

  test('pickBird avoids recent birds, falls back when all are recent', () {
    for (var seed = 0; seed < 50; seed++) {
      expect([0, 1, 2], isNot(contains(pickBird([0, 1, 2], Random(seed)))));
    }
    expect(pickBird([0, 1, 2, 3, 4]), inInclusiveRange(0, 4));
  });

  test('nextRing', () {
    final mon8 = DateTime(2026, 10, 26, 8); // a Monday
    AlarmData at(int h, [Set<int> days = const {}]) =>
        AlarmData(id: 1, hour: h, minute: 0, days: days);
    expect(nextRing(at(9), mon8), DateTime(2026, 10, 26, 9)); // later today
    expect(nextRing(at(7), mon8), DateTime(2026, 10, 27, 7)); // tomorrow
    expect(nextRing(at(8), mon8), DateTime(2026, 10, 27, 8)); // not "now"
    expect(
      nextRing(at(7, {DateTime.monday}), mon8),
      DateTime(2026, 11, 2, 7),
    ); // next week
    expect(
      nextRing(at(7, {DateTime.saturday}), mon8),
      DateTime(2026, 10, 31, 7),
    );
  });
}
