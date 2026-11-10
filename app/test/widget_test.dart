import 'dart:convert';
import 'dart:io';
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
import 'package:early_bird/ui/collection.dart';
import 'package:early_bird/ui/gyro.dart';
import 'package:early_bird/ui/onboarding.dart';
import 'package:early_bird/ui/region.dart';
import 'package:early_bird/ui/ring.dart';
import 'package:early_bird/ui/settings.dart';
import 'package:early_bird/ui/tips.dart';
import 'package:early_bird/ui/twitch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    gyroOn = () => false; // no sensor plugin in tests
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

  test('a card keeps the rarity stars of the region where it was won', () {
    Bird inRegion(int? level) => Bird.fromJson(
      {
        'id': 'vulture', 'latin': 'v', 'en': 'v', 'fr': 'v', //
        'order': 'o', 'family': 'f', 'photo': 'p', 'photoCredit': 'p',
        'number': 1, 'recordings': <Object>[], 'stats': <String, Object>{},
      },
      const {},
      level,
    );
    final card = rollCard(inRegion(8), 'NO', rarity: 'epic');
    expect(card.level, 8);
    // Saved and read back; the bird's level elsewhere doesn't change it.
    final back = CardData.fromJson(jsonDecode(jsonEncode(card.toJson())));
    expect(back.level, 8);
    expect(back.level ?? inRegion(4).level, 8);
    // Cards from before 2026-11-03 have none: the current region's stars show.
    expect(
      CardData.fromJson({...card.toJson()}..remove('level')).level,
      isNull,
    );
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
      // 2026-11-03: tiers above Common × 0.8 (Easy Uncommon / Rare × 0.95, Expert × 1).
      (Difficulty.easy, [76.7, 17.9, 4.5, 0.9, 0]),
      (Difficulty.medium, [72.3, 18.3, 6.4, 2.2, 0.8]),
      (Difficulty.hard, [61.3, 20.6, 10.3, 5.2, 2.6]),
      // Hard's curve with Epic and Legendary × 1.2, unscaled.
      (Difficulty.expert, [50.6, 25.3, 12.7, 7.6, 3.8]),
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

    // Hard (each step ×½, × 0.8 above Common, lean ×3): a common bird 88/9.9/1.6/0.3/0 %,
    // a legendary one 11/11/16.5/25/37 %: the card peaks at the bird's own tier.
    final common = shares('common'), legendary = shares('legendary');
    expect(common['common'], closeTo(0.881, 0.015));
    expect(common['legendary'], lessThan(0.01));
    expect(legendary['common'], closeTo(0.109, 0.01));
    expect(legendary['legendary'], closeTo(0.37, 0.015));
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

  test('backup alarm: saved with the alarm, on by default, its own id', () {
    final a = AlarmData(id: 7, hour: 7, minute: 0, backupMinutes: 5);
    expect(AlarmData.fromJson(a.toJson()).backupMinutes, 5);
    // An alarm saved before the backup existed gets it, 3 min after.
    final old = a.toJson()..remove('backupMinutes');
    expect(AlarmData.fromJson(old).backupMinutes, 3);
    expect(AlarmData(id: 1, hour: 7, minute: 0).backupMinutes, 3);
    expect(backupId(7), isNot(7));
    expect(mainIdOf(backupId(7)), 7);
    expect(mainIdOf(7), 7);
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

  // twitchEvery: 15 min; 1 min only in a --dart-define=DEV_TOOLS=true build.
  test('Twitch quizzes: 5 max, one more every twitchEvery', () {
    final t0 = DateTime(2026, 10, 29, 8);
    expect(
      twitchEvery,
      const Duration(minutes: 15),
    ); // no dev tools in normal builds
    final fresh = DateTime.fromMillisecondsSinceEpoch(0);
    expect(twitchCharges(fresh, t0), 5); // a new player starts full
    var start = twitchUse(fresh, t0);
    expect(twitchCharges(start, t0), 4);
    expect(twitchNextIn(start, t0), twitchEvery);
    final later = t0.add(twitchEvery * 0.25);
    expect(twitchCharges(start, later), 4);
    expect(twitchNextIn(start, later), twitchEvery * 0.75);
    expect(twitchCharges(start, t0.add(twitchEvery)), 5);
    expect(twitchCharges(start, t0.add(const Duration(hours: 5))), 5); // capped
    for (var i = 0; i < 4; i++) {
      start = twitchUse(start, t0);
    }
    expect(twitchCharges(start, t0), 0);
    // Using one when full long after: the excess is dropped, 4 left.
    final much = t0.add(const Duration(days: 1));
    expect(twitchCharges(twitchUse(start, much), much), 4);
  });

  test('Twitch Plus: one more every minute, and buying it fills the pile', () async {
    final t0 = DateTime(2026, 11, 3, 8);
    var start = twitchUse(
      DateTime.fromMillisecondsSinceEpoch(0),
      t0,
      twitchPlusEvery,
    );
    expect(twitchCharges(start, t0, twitchPlusEvery), 4);
    expect(
      twitchNextIn(start, t0, twitchPlusEvery),
      const Duration(minutes: 1),
    );
    expect(twitchCharges(start, t0.add(twitchPlusEvery), twitchPlusEvery), 5);
    for (var i = 0; i < 4; i++) {
      start = twitchUse(start, t0, twitchPlusEvery);
    }
    expect(
      twitchCharges(start, t0.add(const Duration(minutes: 3)), twitchPlusEvery),
      3,
    );

    // Empty pile, 5 minutes into a 15-minute wait: Plus makes it full at once.
    SharedPreferences.setMockInitialValues({
      'twitchStart': DateTime.now()
          .subtract(const Duration(minutes: 5))
          .millisecondsSinceEpoch,
    });
    final s = await Store.load();
    expect(s.twitchReady(DateTime.now()), 0);
    s.twitchPlus = true;
    await Future<void>.delayed(Duration.zero);
    expect(s.twitchPeriod, twitchPlusEvery);
    expect(s.twitchReady(DateTime.now()), 5);
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

  test(
    'a song that rang leaves the deck (played), newest first, no repeats',
    () async {
      SharedPreferences.setMockInitialValues({});
      final s = await Store.load();
      final song = _b('robin').recordings.first,
          other = _b('tit').recordings.first;
      await s.answered(null, _b('robin'), song, true, '');
      await s.answered(null, _b('tit'), other, false, '');
      await s.answered(null, _b('robin'), song, true, '');
      expect(s.played, [song.file, other.file]);
    },
  );

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

  test('series: region filter, progress, groups, a card collected once per completion', () async {
    allSeries = [
      Series.fromJson({
        'id': 'small', 'en': 'Small', 'fr': 'Petits', 'signature': 'gone', //
        'group': 'habitats', 'reward': 'epic',
        'birds': ['tit', 'robin', 'chaffinch', 'redstart', 'gone'],
      }),
      Series.fromJson({
        'id': 'doves',
        'en': 'Doves',
        'fr': 'Colombes',
        'signature': 'dove', // no group / reward: an older series.json
        'birds': ['pigeon', 'dove', 'gone'], // only 2 in the region: hidden
      }),
    ];
    expect((allSeries[1].group, allSeries[1].reward), ('families', 'rare'));
    SharedPreferences.setMockInitialValues({'streak': 8, 'twitchBonus': 1});
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
      fiveOfAKind,
      dawnChorus,
      globetrotter,
      fullHouse,
      perfectSpecimen,
      ironStreak,
    ]);
    expect(small[0].total, 4);
    expect(small[0].group, 'habitats');
    expect(small.last.group, 'achievements2');
    expect(
      small[0].face!.id,
      'robin',
    ); // signature not in the region: first by number
    final week = small.firstWhere((x) => x.id == perfectWeek);
    expect(week.complete, isTrue); // an 8-day streak is a perfect week
    expect(s.claimable(week), isTrue);
    for (final id in ['robin', 'redstart', 'tit', 'chaffinch']) {
      await s.answered(null, _b(id), null, true, '');
    }
    final done = seriesStates(birds, s.cards, s.bestStreak).first;
    expect(s.claimable(done), isTrue);
    final card = await s.claim(done);
    expect(card.rarity, 'epic'); // the series' guaranteed reward
    expect(done.birds.map((b) => b.id), contains(card.birdId));
    expect(s.cards.length, 5);
    expect(s.claimable(done), isFalse); // collected once
    expect((await s.claim(week)).rarity, 'rare');
    // Not anyClaimable: a random card may roll 95 % and complete Perfect specimen.
    expect(s.claimable(week), isFalse);
    // A booster earned the old way is still used first.
    final start = s.twitchStart;
    await s.useTwitch();
    expect(s.twitchBonus, 0);
    expect(s.twitchStart, start);
  });

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
    double shine() =>
        (tester
                    .widget<CustomPaint>(
                      find.descendant(
                        of: find.byType(CardTilt),
                        matching: find.byWidgetPredicate(
                          (w) => w is CustomPaint && w.painter is CardShine,
                        ),
                      ),
                    )
                    .painter!
                as CardShine)
            .s;
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
    expect(shine(), greaterThan(resting + 1));
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

  test('covered area outline: outer cell sides only', () {
    expect(outlineEdges({'N48E002'}).length, 4);
    expect(outlineEdges({'N48E002', 'N48E004'}).length, 6); // the shared side goes
    expect(outlineEdges({'N48E002', 'N50E002'}).length, 6);
  });

  test('collection search ignores case and accents', () {
    expect(plainText('Eider à duvet'), 'eider a duvet');
    expect(plainText('Ánsar común'), 'ansar comun');
    expect(plainText('Großtrappe'), 'grostrappe');
    expect(plainText('Bécasseau'), 'becasseau');
  });

  test('name search matches the start of a word', () {
    final sandpiper = Bird.fromJson({
      'id': 'actitis_hypoleucos', 'latin': 'Actitis hypoleucos', //
      'en': 'Common Sandpiper', 'fr': 'Chevalier guignette',
      'order': 'o', 'family': 'f', 'photo': 'p', 'photoCredit': 'c',
      'number': 1, 'recordings': [], 'stats': <String, dynamic>{},
    });
    expect(nameMatches(sandpiper, 'tit', 'en'), isFalse); // inside "Actitis"
    expect(nameMatches(sandpiper, 'sand', 'en'), isTrue);
    expect(nameMatches(sandpiper, 'guig', 'fr'), isTrue);
    expect(nameMatches(sandpiper, 'common s', 'en'), isTrue);
    expect(nameMatches(sandpiper, 'hypo', 'en'), isTrue); // Latin
  });

  testWidgets('rarity stars: 4 and 5 stars glint, without errors', (
    tester,
  ) async {
    debugContentDir(Directory.systemTemp.createTempSync('eb_stars'));
    for (final level in [8, 10]) {
      final bird = Bird.fromJson(
        {
          'id': 'wallcreeper', 'latin': 'Tichodroma muraria', //
          'en': 'Wallcreeper', 'fr': 'Tichodrome',
          'order': 'o', 'family': 'f', 'photo': 'p', 'photoCredit': 'c',
          'number': 1, 'recordings': [], 'stats': <String, dynamic>{},
        },
        {6: 'legendary'},
        level,
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Center(
            child: SizedBox(
              width: 340,
              child: BirdCardView(
                bird: bird,
                card: rollCard(bird, null, rarity: 'rare'),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.star), findsNWidgets(level ~/ 2));
    }
  });

  testWidgets('card frames: each rarity\'s material paints, without errors', (
    tester,
  ) async {
    debugContentDir(Directory.systemTemp.createTempSync('eb_frames'));
    final bird = Bird.fromJson(
      {
        'id': 'wallcreeper', 'latin': 'Tichodroma muraria', //
        'en': 'Wallcreeper', 'fr': 'Tichodrome',
        'order': 'o', 'family': 'f', 'photo': 'p', 'photoCredit': 'c',
        'number': 1, 'recordings': [], 'stats': <String, dynamic>{},
      },
      {6: 'legendary'},
      8,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          children: [
            for (final tier in tiers)
              BirdCardView(
                bird: bird,
                card: rollCard(bird, null, rarity: tier),
              ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'onboarding: Skip leads to the region and permissions, then ends',
    (tester) async {
      // The permission rows read Android: the full-screen permission is missing here.
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('early_bird/wake'),
        (call) async => call.method == 'fullScreen' ? false : true,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (call) async => 1, // granted
      );
      SharedPreferences.setMockInitialValues({});
      store = await Store.load();
      expect(store.onboarded, isFalse);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const OnboardingScreen(),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Early Bird'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(store.onboarded, isFalse); // Skip doesn't skip the permissions
      expect(find.text('Choose a region'), findsOneWidget);
      expect(find.text('Alarm permissions'), findsOneWidget);
      expect(find.text('Fix'), findsOneWidget); // only the full-screen row
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(store.onboarded, isTrue);
      expect(find.text('open'), findsOneWidget); // back where it started
    },
  );

  testWidgets('settings: a difficulty tap shows at once', (tester) async {
    // The store set by the onboarding test above (it can be set only once).
    store.difficulty = Difficulty.easy;
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    );
    Set<Difficulty> shown() => tester
        .widget<SegmentedButton<Difficulty>>(
          find.byType(SegmentedButton<Difficulty>),
        )
        .selected;
    expect(shown(), {Difficulty.easy});
    for (final (label, d) in [
      ('Expert', Difficulty.expert),
      ('Medium', Difficulty.medium),
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(shown(), {d});
    }
  });

  testWidgets(
    'training: Plus offered on a full pile, countdown centered when empty',
    (tester) async {
      // The store set by the onboarding test above (it can be set only once).
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: TwitchScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('Training'), findsOneWidget);
      expect(find.text('Early Bird Plus'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsNothing);
      while (store.twitchReady(DateTime.now()) > 0) {
        await store.useTwitch();
      }
      await tester.pump(
        const Duration(seconds: 1),
      ); // the screen redraws each second
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      expect(find.textContaining(':'), findsOneWidget); // the countdown, once
      await tester.pumpWidget(const SizedBox()); // stops the pile's animations
    },
  );

  testWidgets(
    'reveal: review asked once from 15 cards, support line once from 30',
    (tester) async {
      final asked = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.britannio.in_app_review'),
        (call) async => asked.add(call.method),
      );
      // The store set by the onboarding test above (it can be set only once).
      while (store.cards.length < 30) {
        await store.answered(null, _b('robin'), null, true, '');
      }
      Future<void> reveal() async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        RevealScreen(bird: _b('robin'), card: store.cards.last),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
      }

      await reveal();
      expect(find.text('Enjoying Early Bird? Buy me a coffee'), findsOneWidget);
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      expect(asked, ['requestReview']);
      await reveal();
      expect(find.text('Enjoying Early Bird? Buy me a coffee'), findsNothing);
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      expect(asked, ['requestReview']); // not again
    },
  );

  testWidgets('collection: region view first, world view, sort by name', (
    tester,
  ) async {
    // The store set by the onboarding test above (it can be set only once).
    debugContentDir(Directory.systemTemp.createTempSync('eb_views'));
    species = {for (final b in birds) b.id: b};
    store.region = 'N48E002';
    tester.view.physicalSize = const Size(1080, 6000); // every tile built at once
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: CollectionScreen()),
      ),
    );
    await tester.pump();
    List<String> ids() => [
      for (final t in tester.widgetList<CardTile>(find.byType(CardTile)))
        t.bird.id,
    ];
    // The default view: the region's birds, in card-number order.
    expect(find.textContaining('/${birds.length})'), findsOneWidget);
    expect(ids(), [for (final b in birds) b.id]);
    // Sort by name.
    await tester.tap(find.byTooltip('Sort and filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // closes the sheet
    await tester.pumpAndSettle();
    expect(ids(), [for (final b in birds) b.id]..sort());
    // Every bird of the world.
    await tester.tap(find.byTooltip('Choose the view'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('All birds of the world').last);
    await tester.pumpAndSettle();
    expect(ids().length, species.length);
    store.region = null;
  });

  testWidgets('tips: four tiles, unavailable without Google Play', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TipsScreen(),
      ),
    );
    // The Play lookup is a platform call: it needs real time to fail.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final name in [
      'Espresso',
      'Cappuccino',
      'Breakfast',
      'Stabilized binoculars',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(
      find.text('Purchases are not available on this phone.'),
      findsOneWidget,
    );
    // No price, no purchase: every tile is disabled.
    for (final b in tester.widgetList<OutlinedButton>(
      find.byType(OutlinedButton),
    )) {
      expect(b.onPressed, isNull);
    }
  });
}
