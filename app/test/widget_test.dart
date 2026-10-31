import 'dart:convert';
import 'dart:math';

import 'package:early_bird/birds.dart';
import 'package:early_bird/cards.dart';
import 'package:early_bird/content.dart';
import 'package:early_bird/l10n/app_localizations.dart';
import 'package:early_bird/main.dart';
import 'package:early_bird/series.dart';
import 'package:early_bird/store.dart';
import 'package:early_bird/trade.dart';
import 'package:early_bird/ui/booster.dart';
import 'package:early_bird/ui/card.dart';
import 'package:early_bird/ui/region.dart';
import 'package:flutter/material.dart';
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
    expect(pool(5, Difficulty.hard)[_b('flycatcher')], 3); // Epic this month
    expect(pool(5, Difficulty.hard)[_b('robin')], 16); // Common this month
  });

  test('card rarity: drawn from the odds of the difficulty', () {
    final r = Random(7);
    for (final (d, odds) in [
      (Difficulty.easy, [60, 32, 7, 1, 0]),
      (Difficulty.medium, [45.7, 32, 16, 5.4, 0.9]),
      (Difficulty.hard, [28.2, 34, 27, 10.4, 2.4]),
    ]) {
      final seen = <String, int>{};
      for (var i = 0; i < 20000; i++) {
        final t = drawRarity(d, random: r);
        seen[t] = (seen[t] ?? 0) + 1;
      }
      for (final (i, t) in tiers.indexed) {
        expect(
          (seen[t] ?? 0) / 20000,
          closeTo(odds[i] / 100, 0.012),
          reason: '$d $t',
        );
      }
    }
  });

  test('card rarity leans toward the bird: scarce birds, rare cards', () {
    Map<String, double> shares(String birdTier) {
      final r = Random(3);
      final seen = <String, int>{};
      for (var i = 0; i < 20000; i++) {
        final t = drawRarity(Difficulty.hard, birdTier: birdTier, random: r);
        seen[t] = (seen[t] ?? 0) + 1;
      }
      return {for (final t in tiers) t: (seen[t] ?? 0) / 20000};
    }

    // Hard, tilt 2: a common bird 53/32/13/2/0.3 %, a legendary one 9/21/33/26/12 %.
    final common = shares('common'), legendary = shares('legendary');
    expect(common['common'], closeTo(0.53, 0.015));
    expect(common['legendary'], lessThan(0.01));
    expect(legendary['common'], closeTo(0.087, 0.01));
    expect(legendary['legendary'], closeTo(0.118, 0.012));
    // Easy never gives a Legendary card, even for a legendary bird.
    for (var i = 0; i < 2000; i++) {
      expect(
        drawRarity(Difficulty.easy, birdTier: 'legendary'),
        isNot('legendary'),
      );
    }
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
    // The only bird of October at Easy was heard recently: it can still ring.
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

  test('cards: rolls stay within ±3 sd, keep rarity and region', () {
    expect(_b('robin').stats.keys, ['weight', 'wingspan', 'distance']);
    for (var seed = 0; seed < 200; seed++) {
      final c = rollCard(
        _b('robin'),
        'FR',
        rarity: 'epic', // a card's rarity is its own, not the species'
        recording: 'audio/robin-2.m4a',
        random: Random(seed),
      );
      expect(c.stats['weight'], inInclusiveRange(14, 26));
      expect(c.stats['wingspan'], inInclusiveRange(19, 25));
      expect(c.stats['distance'], inInclusiveRange(0, 150)); // never negative
      expect(c.stats.containsKey('length'), isFalse);
      expect(c.quality, inInclusiveRange(0, 100));
      expect((c.rarity, c.region), ('epic', 'FR'));
      final back = CardData.fromJson(c.toJson());
      expect(
        back.stats,
        c.stats,
      ); // maps compare by content only outside records
      expect((back.rarity, back.region), ('epic', 'FR'));
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
    expect(
      ringsIn(l, at(7, 0, {DateTime.wednesday}), mon8),
      'Rings in 1 d 23 h',
    );
    expect(formatStat('weight', 1080, l), '1.1 kg');
    expect(formatStat('weight', 12400, l), '12 kg');
    expect(formatStat('weight', 8.5, l), '8.5 g');
    expect(formatStat('distance', 292, l), '292 km');
    expect(formatStat('distance', 0.02, l), 'Resident');
  });

  test('Twitch quizzes: 5 max, one more every 15 min', () {
    final t0 = DateTime(2026, 10, 29, 8);
    final fresh = DateTime.fromMillisecondsSinceEpoch(0);
    expect(twitchCharges(fresh, t0), 5); // a new player starts full
    var start = twitchUse(fresh, t0);
    expect(twitchCharges(start, t0), 4);
    expect(twitchNextIn(start, t0), const Duration(minutes: 15));
    final later = t0.add(const Duration(minutes: 3, seconds: 20));
    expect(twitchCharges(start, later), 4);
    expect(
      twitchNextIn(start, later),
      const Duration(minutes: 11, seconds: 40),
    );
    expect(twitchCharges(start, t0.add(const Duration(minutes: 15))), 5);
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

  testWidgets('booster: a tap opens it, a drag only tilts the pile', (
    tester,
  ) async {
    var torn = 0;
    Future<void> pileOf(int n) => tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: BoosterPile(count: n, onTorn: () => torn++, label: 'Open'),
        ),
      ),
    );
    await pileOf(3);
    final pile = find.byType(BoosterPile);
    await tester.drag(pile, const Offset(120, 0));
    await tester.pump(); // the float never settles: pump frames by hand
    await tester.pump(const Duration(milliseconds: 500));
    expect(torn, 0);
    await tester.tap(pile);
    await tester.pump(); // the strip starts flying off…
    await tester.pump(const Duration(milliseconds: 500)); // …and is gone
    expect(torn, 1);
    await pileOf(0); // nothing to open
    await tester.tap(pile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(torn, 1);
  });

  testWidgets('card flip: the back first, the face from mid-flip on', (
    tester,
  ) async {
    // Common: the burst only; Legendary: every effect layer gets painted.
    for (final rarity in ['common', 'legendary']) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(rarity),
          home: Center(
            child: SizedBox(
              width: 200,
              child: CardFlip(rarity: rarity, child: const Text('face')),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CardBack), findsOneWidget);
      expect(find.text('face'), findsNothing);
      await tester.pump(const Duration(milliseconds: 400)); // past mid-flip
      expect(find.text('face'), findsOneWidget);
      for (var i = 0; i < 25; i++) {
        await tester.pump(
          const Duration(milliseconds: 100),
        ); // sparkles run out
      }
      expect(find.byType(CardBack), findsNothing);
    }
  });

  test(
    'series: region filter, progress, one-time reward, bonus booster',
    () async {
      allSeries = [
        Series.fromJson({
          'id': 'small', 'en': 'Small', 'fr': 'Petits', 'signature': 'gone', //
          'birds': ['tit', 'robin', 'chaffinch', 'redstart', 'gone'],
        }),
        Series.fromJson({
          'id': 'doves',
          'en': 'Doves',
          'fr': 'Colombes',
          'signature': 'dove', //
          'birds': ['pigeon', 'dove', 'gone'], // only 2 in the region: hidden
        }),
      ];
      SharedPreferences.setMockInitialValues({'streak': 8});
      final s = await Store.load();
      final small = seriesStates(birds, s.cards, s.bestStreak);
      expect(small.map((x) => x.id), [
        'small',
        legendaryHunter, // now always: 5 Legendary cards
        perfectWeek,
        fullSet,
        collector,
        localExpert,
        rareFinds,
      ]);
      expect(small[0].total, 4);
      expect(
        small[0].face!.id,
        'robin',
      ); // signature not in the region: first by number
      expect(
        small.firstWhere((x) => x.id == perfectWeek).complete,
        isTrue,
      ); // an 8-day streak is a perfect week
      for (final id in ['robin', 'redstart', 'tit']) {
        await s.answered(null, _b(id), null, true, '');
      }
      expect((await s.claimSeries()).map((x) => x.id), [perfectWeek]);
      await s.answered(null, _b('chaffinch'), null, true, '');
      expect((await s.claimSeries()).map((x) => x.id), ['small']);
      expect(await s.claimSeries(), isEmpty); // rewarded once
      expect(s.twitchBonus, 2);
      final start = s.twitchStart;
      await s.useTwitch();
      expect(s.twitchBonus, 1); // the bonus goes first…
      expect(s.twitchStart, start); // …the timed boosters are untouched
    },
  );

  test('a theme from an older version falls back to Phone', () async {
    SharedPreferences.setMockInitialValues({'theme': 'dusk'});
    final s = await Store.load();
    expect(s.theme, 'system');
    s.theme = 'gull';
    await Future<void>.delayed(Duration.zero);
    expect(s.theme, 'gull');
  });

  test('card quality: a fat upward tail, few poor cards', () {
    // The fake robin has 3 stats (weight, wingspan, distance).
    final r = Random(11);
    final q = [
      for (var i = 0; i < 20000; i++)
        rollCard(_b('robin'), null, rarity: 'common', random: r).quality,
    ];
    double share(bool Function(int) f) => q.where(f).length / q.length;
    expect(share((x) => x >= 80), inInclusiveRange(0.06, 0.13));
    expect(share((x) => x >= 95), inInclusiveRange(0.008, 0.04));
    expect(share((x) => x <= 20), lessThan(0.03));
  });

  testWidgets('card tilt: flat at rest, follows a held finger, shine moves', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 300,
            child: CardTilt(
              shine: true,
              // A card has its own size (the tilt stacks the shine over it).
              child: SizedBox(
                width: 200,
                height: 300,
                child: ColoredBox(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
    Matrix4 now() => tester
        .widget<Transform>(
          find.descendant(
            of: find.byType(CardTilt),
            matching: find.byType(Transform),
          ),
        )
        .transform;
    Alignment shine() =>
        ((tester
                                .widget<DecoratedBox>(
                                  find.descendant(
                                    of: find.byType(CardTilt),
                                    matching: find.byType(DecoratedBox),
                                  ),
                                )
                                .decoration
                            as BoxDecoration)
                        .gradient!
                    as LinearGradient)
                .begin
            as Alignment;
    await tester.pump(const Duration(milliseconds: 900));
    expect(now().entry(0, 2), 0); // no sway: flat until touched
    final resting = shine();
    // Held at the right edge: turned toward the right, the reflection slides along.
    final g = await tester.startGesture(
      tester.getCenter(find.byType(CardTilt)) + const Offset(95, 0),
    );
    await tester.pump(const Duration(milliseconds: 600)); // long press
    await g.moveBy(const Offset(1, 0));
    await tester.pump(); // the tween starts…
    await tester.pump(const Duration(milliseconds: 300)); // …and settles
    expect(now().entry(0, 2), greaterThan(0.2)); // rotateY toward the finger
    expect(shine().x, greaterThan(resting.x + 1));
    await g.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(now().entry(0, 2), closeTo(0, 1e-6)); // back to flat
  });

  test('continent of a region, or of the phone before any region', () {
    expect(continentOf('US-NE', null), 'na');
    expect(continentOf('CA-ON', 'FR'), 'na'); // the region wins over the phone
    expect(continentOf('N42W072', null), 'na'); // a 2° cell in America
    expect(continentOf('N48E002', 'US'), 'eu');
    expect(continentOf('FR', null), 'eu');
    expect(continentOf(null, 'US'), 'na');
    expect(continentOf(null, 'FR'), 'eu');
    expect(continentOf(null, null), 'eu');
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
    expect(ordinal(3, 'de'), '3.');
    expect(ordinal(3, 'es'), '3.ª');
  });

  test('region map: cell under a tap, projection round trip', () {
    expect(cellAt(48.85, 2.35), 'N48E002'); // Paris
    expect(cellAt(42.36, -71.06), 'N42W072'); // Boston
    expect(cellAt(-33.9, 18.4), 'S34E018'); // Cape Town
    for (final (lat, lon) in [(48.85, 2.35), (64.1, -21.9), (25.8, -80.2)]) {
      final (la, lo) = unproject(project(lat, lon));
      expect(la, closeTo(lat, 1e-6));
      expect(lo, closeTo(lon, 1e-6));
    }
  });

  group('face-to-face trade', () {
    CardData card(String bird, {int quality = 50, double weight = 20}) =>
        CardData(
          birdId: bird,
          stats: {'weight': weight},
          quality: quality,
          earned: DateTime(2026, 10, 1, quality),
          rarity: 'rare',
        );

    // Two phones wired to each other; messages go through JSON as on the air.
    (TradeSession, TradeSession) pair() {
      late TradeSession a, b;
      Map<String, Object?> air(Map<String, Object?> m) =>
          jsonDecode(jsonEncode(m)) as Map<String, Object?>;
      a = TradeSession(send: (m) => b.receive(air(m)), onChange: () {});
      b = TradeSession(send: (m) => a.receive(air(m)), onChange: () {});
      a.start();
      b.start();
      return (a, b);
    }

    test('swaps only once both validated what is shown', () {
      final (a, b) = pair();
      a.offer([card('robin')]);
      b.offer([card('heron'), card('dove')]);
      expect(b.theirs.single.birdId, 'robin');
      a.validate();
      expect(a.done || b.done, isFalse);
      b.offer([card('heron')]); // a change clears both validations
      expect(a.iValidated || b.theyValidated, isFalse);
      b.validate();
      expect(a.done, isFalse);
      a.validate();
      expect(a.done && b.done, isTrue);
      expect(a.theirs.single.birdId, 'heron');
      expect(b.theirs.single.birdId, 'robin');
      a.offer([]); // nothing changes after the swap
      expect(b.theirs.single.birdId, 'robin');
    });

    test('a different app version refuses to trade', () {
      late TradeSession a;
      a = TradeSession(send: (_) {}, onChange: () {});
      a.receive({'t': 'hello', 'v': tradeProtocol + 1});
      expect(a.error, TradeError.version);
    });

    test('forged cards are refused', () {
      expect(checkCard(card('robin').toJson()), isNotNull);
      expect(checkCard(card('nobody').toJson()), isNull); // unknown bird
      expect(checkCard(card('robin', quality: 150).toJson()), isNull);
      expect(checkCard(card('robin', weight: 99).toJson()), isNull); // 20 ± 3×2
      expect(checkCard({'bird': 'robin'}), isNull); // malformed
      final b = TradeSession(send: (_) {}, onChange: () {});
      b.receive({
        't': 'offer',
        'cards': [card('robin', quality: 150).toJson()],
      });
      expect(b.error, TradeError.invalid);
    });

    test('pairing names: same token, same birds; two different birds', () {
      const list = ['a', 'b', 'c', 'd', 'e'];
      expect(pairingBirds('X7Q2', list), pairingBirds('X7Q2', list));
      for (final t in ['A', 'BB', 'C3PO', '1234']) {
        final (x, y) = pairingBirds(t, list);
        expect(x, isNot(y));
      }
    });

    test('given cards leave the collection but still count', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await Store.load();
      await s.answered(null, _b('robin'), null, true, '');
      final mine = s.cards.single;
      await s.trade([mine], [card('heron')]);
      expect(s.cards.single.birdId, 'heron');
      expect(s.cards.single.traded, isNotNull);
      expect(s.given.single.birdId, 'robin');
      expect(s.achievementCards.map((c) => c.birdId).toSet(), {
        'robin',
        'heron',
      });
    });
  });

  test('names: the language of the phone, else English', () {
    final j = {'en': 'Blackbird', 'fr': 'Merle noir', 'de': 'Amsel'};
    expect(localName(j, 'de'), 'Amsel');
    expect(localName(j, 'de_AT'), 'Amsel');
    expect(localName(j, 'fr'), 'Merle noir');
    expect(localName(j, 'es'), 'Blackbird'); // no Spanish name yet
    expect(_b('robin').nameIn('es'), 'robin');
  });
}
