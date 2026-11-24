import 'package:early_bird/birds.dart';
import 'package:early_bird/series.dart';
import 'package:flutter_test/flutter_test.dart';

Bird _bird(String id, {String? diet, String? habitat}) => Bird.fromJson({
  'id': id, 'latin': id, 'en': id, 'fr': id, 'order': 'o', 'family': 'f', //
  'photo': 'p.jpg', 'photoCredit': 'c', 'number': 1, 'recordings': [],
  'stats': <String, dynamic>{}, 'diet': ?diet, 'habitat': ?habitat,
});

void main() {
  test('zones: the 6 covered areas from cells and list ids', () {
    expect(
      [
        'N48E002', 'FR', 'N40W074', 'US-NE', 'S34E150', 'AU-NSW', 'NZ', //
        'S46E168', 'N30W010', 'N24E046', 'N38E044', 'SA', 'MX', 'N08W080',
        'N10E100', null,
      ].map(zoneOf),
      [
        'eu', 'eu', 'na', 'na', 'au', 'au', 'nz', 'nz', 'mena', 'mena', //
        'mena', 'mena', 'mxca', 'mxca', null, null,
      ],
    );
  });

  test(
    'podium: top 50 / 25 / 10 / 2 / 0.1 %, #1 as 0.1 % from 100 players',
    () {
      expect(podiumTiers(1, 1), 0); // alone: 100 %
      expect(podiumTiers(1, 2), 1);
      expect(podiumTiers(3, 10), 1); // 30 %
      expect(podiumTiers(1, 10), 3); // 10 %
      expect(podiumTiers(1, 50), 4); // 2 %
      expect(podiumTiers(1, 99), 4);
      expect(podiumTiers(1, 100), 5);
      expect(podiumTiers(2, 1000), 4);
      expect(podiumTiers(1, 1000), 5);
    },
  );

  test('diet and habitat series group the birds by their AVONET traits', () {
    final series = {
      for (final s in traitSeries([
        _bird('hawk', diet: 'Vertivore'),
        _bird('vulture', diet: 'Scavenger', habitat: 'Rock'),
        _bird('robin', diet: 'Invertivore', habitat: 'Forest'),
        _bird('old'), // a catalog without traits
      ]))
        s.id: s,
    };
    expect(series['trait-predators']!.birds, ['hawk', 'vulture']);
    expect(series['trait-rock']!.birds, ['vulture']);
    expect(series['trait-predators']!.group, 'diets');
    expect(series['trait-rock']!.nameIn('fr'), 'Rupicoles');
  });
}
