import 'dart:math';

import 'package:early_bird/birds.dart';
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
}
