import 'dart:math';

import 'package:early_bird/birds.dart';
import 'package:early_bird/names.dart';
import 'package:flutter_test/flutter_test.dart';

Bird _bird(String en) => Bird.fromJson({
  'id': en, 'latin': en, 'en': en, 'fr': en, 'order': 'o', 'family': 'f', //
  'photo': 'p.jpg', 'photoCredit': 'c', 'number': 1, 'recordings': [],
  'stats': <String, dynamic>{},
});

void main() {
  test('names: 3-20 letters, digits or _, no banned word', () {
    expect(nameProblem('RedRobin4821'), isNull);
    expect(nameProblem('ab'), NameProblem.length);
    expect(nameProblem('a' * 21), NameProblem.length);
    expect(nameProblem('Red Robin'), NameProblem.characters);
    expect(nameProblem('@robin'), NameProblem.characters);
    expect(nameProblem('Grand_Admin'), NameProblem.banned);
    expect(nameProblem('earlyBIRD_fan'), NameProblem.banned);
  });

  test(
    'an automatic name is a bird without spaces and 4 digits, never banned',
    () {
      final r = Random(3);
      // A banned word and a name too long to fit whole are left out.
      final pool = [
        _bird('European Robin'),
        _bird('Dickcissel'),
        _bird('Spotted Flycatcher'),
      ];
      for (var i = 0; i < 50; i++) {
        final name = autoName(pool, r);
        expect(name, matches(RegExp(r'^EuropeanRobin\d{4}$')));
        expect(nameProblem(name), isNull);
      }
      expect(autoName([_bird("Cetti's Warbler-Wren Long Name")], r).length, 20);
    },
  );
}
