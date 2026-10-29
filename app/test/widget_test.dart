import 'dart:math';

import 'package:early_bird/birds.dart';
import 'package:early_bird/cards.dart';
import 'package:early_bird/l10n/app_localizations.dart';
import 'package:early_bird/main.dart';
import 'package:early_bird/store.dart';
import 'package:early_bird/ui/card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// id, order, family, months, recording kinds
const _fake = [
  (
    'robin',
    'Passeriformes',
    'Muscicapidae',
    {5: 'common', 10: 'common'},
    ['song', 'call', 'alarm'],
  ),
  ('redstart', 'Passeriformes', 'Muscicapidae', {5: 'uncommon'}, ['song']),
  ('flycatcher', 'Passeriformes', 'Muscicapidae', {5: 'epic'}, ['call']),
  ('chaffinch', 'Passeriformes', 'Fringillidae', {5: 'common'}, ['song']),
  ('tit', 'Passeriformes', 'Paridae', {5: 'common'}, ['song', 'call']),
  ('pigeon', 'Columbiformes', 'Columbidae', {5: 'common'}, ['song']),
  ('dove', 'Columbiformes', 'Columbidae', {5: 'common'}, ['song']),
  ('woodpecker', 'Piciformes', 'Picidae', {5: 'common'}, ['song']),
  ('heron', 'Pelecaniformes', 'Ardeidae', {5: 'uncommon'}, ['call']),
  ('warbler', 'Passeriformes', 'Phylloscopidae', {10: 'rare'}, ['call']),
];

Bird _b(String id) => birdById(id)!;
bool _all(Recording r) => true;

void main() {
  setUp(() {
    birds = [
      for (final (i, (id, order, family, months, kinds)) in _fake.indexed)
        Bird.fromJson({
          'id': id, 'latin': id, 'en': id, 'fr': id, //
          'order': order, 'family': family,
          'photo': 'photos/$id.jpg', 'photoCredit': 'p', 'number': i + 1,
          'recordings': [
            for (final (n, k) in kinds.indexed)
              {
                'file': 'audio/$id-${n + 1}.m4a',
                'kind': k,
                'credit': 'c',
                if (id == 'heron') 'nc': true,
              },
          ],
          'stats': {
            'weight': [20, 2],
            'wingspan': [22, 1],
            'length': null,
            'distance': [0, 50],
          },
        }, months),
    ];
  });

  test('catalog parsing', () {
    expect(birds.length, _fake.length);
    expect(_b('robin').recordings.map((r) => r.kind), [
      'song',
      'call',
      'alarm',
    ]);
    expect(_b('robin').months, {5: 'common', 10: 'common'});
    expect(_b('robin').rarity, 'common');
    expect(_b('redstart').tierIn(null), 'uncommon');
    expect(_b('warbler').tierIn(5), isNull);
    expect(_b('heron').recordings.single.nc, isTrue);
    expect(_b('robin').recordings.first.nc, isFalse);
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

  test(
    'vocalizations follow difficulty; no song falls back to the best recording',
    () {
      List<String> kinds(String id, Difficulty d) =>
          _b(id).playable(d).map((r) => r.kind).toList();
      expect(kinds('robin', Difficulty.easy), ['song']);
      expect(kinds('robin', Difficulty.medium), ['song', 'call']);
      expect(kinds('robin', Difficulty.hard), ['song', 'call', 'alarm']);
      expect(kinds('heron', Difficulty.easy), ['call']);
    },
  );

  test('pickBird: only recordings on the phone, avoids recent birds', () {
    for (var seed = 0; seed < 50; seed++) {
      final (bird, rec) = pickBird(
        ['tit'],
        10,
        Difficulty.hard,
        _all,
        Random(seed),
      )!;
      expect(bird.id, isNot('tit'));
      expect(bird.recordings, contains(rec));
      // Easy rings a song when the bird has one.
      final (b2, r2) = pickBird([], 5, Difficulty.easy, _all, Random(seed))!;
      if (b2.recordings.any((r) => r.kind == 'song')) expect(r2.kind, 'song');
    }
    expect(pickBird(['robin'], 10, Difficulty.easy, _all)!.$1.id, 'robin');
    // Only the warbler's call is on the phone: it's the only bird that can ring.
    final onlyWarbler = pickBird(
      [],
      10,
      Difficulty.hard,
      (r) => r.file == 'audio/warbler-1.m4a',
    )!;
    expect(onlyWarbler.$1.id, 'warbler');
    expect(pickBird([], 5, Difficulty.easy, (r) => false), isNull);
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
      expect(hard.where((b) => b.family == 'Muscicapidae').length, 2);
      expect(hard.every((b) => b.order == 'Passeriformes'), isTrue);
    }
  });

  test('cards: rolls stay within ±2 sd, keep rarity and region', () {
    expect(_b('robin').stats.keys, ['weight', 'wingspan', 'distance']);
    for (var seed = 0; seed < 200; seed++) {
      final c = rollCard(
        _b('robin'),
        'FR',
        recording: 'audio/robin-2.m4a',
        random: Random(seed),
      );
      expect(c.stats['weight'], inInclusiveRange(16, 24));
      expect(c.stats['wingspan'], inInclusiveRange(20, 24));
      expect(c.stats['distance'], inInclusiveRange(0, 100)); // never negative
      expect(c.stats.containsKey('length'), isFalse);
      expect(c.quality, inInclusiveRange(0, 100));
      expect((c.rarity, c.region), ('common', 'FR'));
      final back = CardData.fromJson(c.toJson());
      expect(
        back.stats,
        c.stats,
      ); // maps compare by content only outside records
      expect((back.rarity, back.region), ('common', 'FR'));
      expect(back.recording, 'audio/robin-2.m4a');
    }
    // A card from before 3c has no rarity or region.
    final old = CardData.fromJson({
      'bird': 'robin',
      'stats': <String, dynamic>{},
      'quality': 50,
      'earned': '2026-10-27T07:00:00',
    });
    expect((old.rarity, old.region), (null, null));
    expect(old.toJson().containsKey('rarity'), isFalse);
    expect(percentileOf(_b('robin'), 'weight', 20), closeTo(0.5, 1e-6));
    expect(percentileOf(_b('robin'), 'weight', 24), closeTo(0.977, 1e-3));
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

  test('ringsIn and stat formats', () {
    final l = lookupAppLocalizations(const Locale('en'));
    final mon8 = DateTime(2026, 10, 26, 8, 0, 30); // a Monday
    AlarmData at(int h, int m, [Set<int> days = const {}]) =>
        AlarmData(id: 1, hour: h, minute: m, days: days);
    expect(ringsIn(l, at(8, 5), mon8), 'Rings in 5 min'); // 4.5 min, rounded up
    expect(ringsIn(l, at(15, 7), mon8), 'Rings in 7 h 07');
    expect(ringsIn(l, at(7, 0, {DateTime.wednesday}), mon8), 'Rings in 1 d 23 h');
    expect(formatStat('weight', 1080, 'en'), '1.1 kg');
    expect(formatStat('weight', 12400, 'en'), '12 kg');
    expect(formatStat('weight', 8.5, 'en'), '8.5 g');
    expect(formatStat('distance', 292, 'en'), '292 km');
  });

  test('Twitch quizzes: 5 max, one more every 10 min', () {
    final t0 = DateTime(2026, 10, 29, 8);
    final fresh = DateTime.fromMillisecondsSinceEpoch(0);
    expect(twitchCharges(fresh, t0), 5); // a new player starts full
    var start = twitchUse(fresh, t0);
    expect(twitchCharges(start, t0), 4);
    expect(twitchNextIn(start, t0), const Duration(minutes: 10));
    final later = t0.add(const Duration(minutes: 3, seconds: 20));
    expect(twitchCharges(start, later), 4);
    expect(twitchNextIn(start, later), const Duration(minutes: 6, seconds: 40));
    expect(twitchCharges(start, t0.add(const Duration(minutes: 10))), 5);
    expect(twitchCharges(start, t0.add(const Duration(hours: 5))), 5); // capped
    for (var i = 0; i < 4; i++) {
      start = twitchUse(start, t0);
    }
    expect(twitchCharges(start, t0), 0);
    // Using one when full long after: the excess is dropped, 4 left.
    final much = t0.add(const Duration(days: 1));
    expect(twitchCharges(twitchUse(start, much), much), 4);
  });

  test('a Twitch answer wins a card but leaves the streak alone', () async {
    SharedPreferences.setMockInitialValues({'streak': 3});
    final s = await Store.load();
    final card = await s.answered(null, _b('robin'), null, true, '');
    expect(card, isNotNull);
    expect(s.cards.length, 1);
    expect(s.streak, 3);
    await s.answered(null, _b('robin'), null, false, '');
    expect(s.streak, 3);
    expect(s.heard, {'robin'});
  });

  test('ordinals for "nth species collected"', () {
    expect(
      [1, 2, 3, 4, 11, 12, 13, 21, 22, 101, 112].map((n) => ordinal(n, 'en')),
      [
        '1st',
        '2nd',
        '3rd',
        '4th',
        '11th',
        '12th',
        '13th',
        '21st',
        '22nd',
        '101st',
        '112th',
      ],
    );
    expect([1, 2, 12].map((n) => ordinal(n, 'fr')), ['1re', '2e', '12e']);
  });
}
