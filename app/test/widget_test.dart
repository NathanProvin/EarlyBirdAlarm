import 'dart:convert';
import 'dart:math';

import 'package:early_bird/birds.dart';
import 'package:early_bird/cards.dart';
import 'package:early_bird/store.dart';
import 'package:flutter_test/flutter_test.dart';

// id, order, family, months
const _fake = [
  ('robin', 'Passeriformes', 'Muscicapidae', {'5': 'common', '10': 'common'}),
  ('redstart', 'Passeriformes', 'Muscicapidae', {'5': 'uncommon'}),
  ('flycatcher', 'Passeriformes', 'Muscicapidae', {'5': 'epic'}),
  ('chaffinch', 'Passeriformes', 'Fringillidae', {'5': 'common'}),
  ('tit', 'Passeriformes', 'Paridae', {'5': 'common'}),
  ('pigeon', 'Columbiformes', 'Columbidae', {'5': 'common'}),
  ('dove', 'Columbiformes', 'Columbidae', {'5': 'common'}),
  ('woodpecker', 'Piciformes', 'Picidae', {'5': 'common'}),
  ('heron', 'Pelecaniformes', 'Ardeidae', {'5': 'uncommon'}),
  ('warbler', 'Passeriformes', 'Phylloscopidae', {'10': 'rare'}),
];

Bird _b(String id) => birdById(id)!;

void main() {
  setUp(() {
    birds = parseCatalog(
      jsonEncode({
        'cell': 'TEST',
        'birds': [
          for (final (id, order, family, months) in _fake)
            {
              'id': id, 'latin': id, 'en': id, 'fr': id, //
              'order': order, 'family': family, 'months': months,
              'audio': 'audio/$id.m4a', 'photo': 'photos/$id.jpg',
              'audioCredit': 'a', 'photoCredit': 'p',
              'rarity': months.values.first,
              'number': _fake.indexWhere((f) => f.$1 == id) + 1,
              'stats': {
                'weight': [20, 2],
                'wingspan': [22, 1],
                'length': null,
                'distance': [0, 50],
              },
            },
        ],
      }),
    );
  });

  test('catalog parsing', () {
    expect(birds.length, _fake.length);
    expect(_b('robin').audio, 'assets/content/audio/robin.m4a');
    expect(_b('robin').months, {5: 'common', 10: 'common'});
    expect(_b('redstart').tierIn(null), 'uncommon');
    expect(_b('warbler').tierIn(5), isNull);
  });

  test('pool follows season and difficulty', () {
    Set<String> ids(int? m, Difficulty d) =>
        pool(m, d).keys.map((b) => b.id).toSet();
    expect(ids(10, Difficulty.easy), {'robin'});
    expect(ids(10, Difficulty.hard), {'robin', 'warbler'});
    expect(ids(5, Difficulty.medium), containsAll(['redstart', 'heron']));
    expect(ids(5, Difficulty.medium), isNot(contains('flycatcher')));
    expect(ids(null, Difficulty.hard).length, _fake.length); // "All birds"
    expect(
      pool(1, Difficulty.easy).length,
      _fake.length,
    ); // empty month falls back
    expect(pool(5, Difficulty.hard)[_b('flycatcher')], 2);
    expect(pool(5, Difficulty.hard)[_b('robin')], 16);
  });

  test('pickBird avoids recent birds, falls back when all are recent', () {
    for (var seed = 0; seed < 50; seed++) {
      expect(
        pickBird(['tit'], 10, Difficulty.hard, Random(seed)).id,
        isNot('tit'),
      );
    }
    expect(pickBird(['robin'], 10, Difficulty.easy).id, 'robin');
  });

  test('choices: 4 distinct birds from the right groups', () {
    for (var seed = 0; seed < 50; seed++) {
      final r = Random(seed);
      for (final d in Difficulty.values) {
        final c = choicesFor(_b('robin'), 5, d, r);
        expect(c.length, 4);
        expect(c.toSet().length, 4);
        expect(c, contains(_b('robin')));
      }
      final easy = choicesFor(_b('robin'), 5, Difficulty.easy, r)
        ..remove(_b('robin'));
      expect(easy.every((b) => b.order != 'Passeriformes'), isTrue);
      final hard = choicesFor(_b('robin'), 5, Difficulty.hard, r)
        ..remove(_b('robin'));
      expect(
        hard.where((b) => b.family == 'Muscicapidae').length,
        2,
      ); // redstart + flycatcher
      expect(hard.every((b) => b.order == 'Passeriformes'), isTrue);
    }
  });

  test('cards: rolls stay within ±2 sd, unknown stats are left out', () {
    expect(_b('robin').stats.keys, ['weight', 'wingspan', 'distance']);
    expect(_b('robin').number, 1);
    expect(_b('flycatcher').rarity, 'epic');
    for (var seed = 0; seed < 200; seed++) {
      final c = rollCard(_b('robin'), Random(seed));
      expect(c.stats['weight'], inInclusiveRange(16, 24));
      expect(c.stats['wingspan'], inInclusiveRange(20, 24));
      expect(c.stats['distance'], inInclusiveRange(0, 100)); // never negative
      expect(c.stats.containsKey('length'), isFalse);
      expect(c.quality, inInclusiveRange(0, 100));
      expect(CardData.fromJson(c.toJson()).stats, c.stats);
    }
    final mean = CardData(
      birdId: 'robin',
      stats: {},
      quality: 0,
      earned: DateTime(2026),
    );
    expect(percentileOf(_b('robin'), 'weight', 20), closeTo(0.5, 1e-6));
    expect(percentileOf(_b('robin'), 'weight', 24), closeTo(0.977, 1e-3));
    expect(mean.toJson()['bird'], 'robin');
  });

  test('nextRing', () {
    final mon8 = DateTime(2026, 10, 26, 8); // a Monday
    AlarmData at(int h, [Set<int> days = const {}]) =>
        AlarmData(id: 1, hour: h, minute: 0, days: days);
    expect(nextRing(at(9), mon8), DateTime(2026, 10, 26, 9));
    expect(nextRing(at(7), mon8), DateTime(2026, 10, 27, 7));
    expect(nextRing(at(8), mon8), DateTime(2026, 10, 27, 8));
    expect(nextRing(at(7, {DateTime.monday}), mon8), DateTime(2026, 11, 2, 7));
    expect(
      nextRing(at(7, {DateTime.saturday}), mon8),
      DateTime(2026, 10, 31, 7),
    );
  });
}
