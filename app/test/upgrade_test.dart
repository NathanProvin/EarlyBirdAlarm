import 'dart:convert';

import 'package:early_bird/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saved data as 1.0.0+3 (the closed-test build, 2026-11) wrote it, oldest card shapes
/// included. Every release must still read it: testers' collections live in this file.
/// Keep this fixture as it is; add a new one when the saved format changes.
final _v1_0_0_3 = <String, Object>{
  'onboarded': true,
  'region': 'N48E002',
  'streak': 4,
  'bestStreak': 9,
  'difficulty': 1,
  'theme': 'bluetit',
  'cards': jsonEncode([
    // A card from before regions and rarities (Iteration 3b).
    {
      'bird': 'erithacus_rubecula',
      'stats': {'weight': 18.2, 'wingspan': 21.0},
      'quality': 64,
      'earned': '2026-10-27T07:00:00.000',
    },
    // A full card, then one received in a trade.
    {
      'bird': 'pica_pica',
      'stats': {'weight': 210.5, 'wingspan': 56.0, 'length': 45.0},
      'quality': 91,
      'earned': '2026-11-05T06:30:00.000',
      'rarity': 'epic',
      'region': 'N48E002',
      'level': 2,
      'recording': 'audio/pica_pica-1.m4a',
    },
    {
      'bird': 'turdus_merula',
      'stats': {'weight': 95.0},
      'quality': 40,
      'earned': '2026-11-06T06:30:00.000',
      'rarity': 'common',
      'region': 'N48E002',
      'traded': '2026-11-07T18:00:00.000',
    },
  ]),
  'given': jsonEncode([
    {
      'bird': 'parus_major',
      'stats': {'weight': 17.0},
      'quality': 55,
      'earned': '2026-11-04T06:30:00.000',
      'rarity': 'uncommon',
      'traded': '2026-11-07T18:00:00.000',
    },
  ]),
  'heard': ['sitta_europaea'],
  'seriesDone': ['N48E002/crows'],
  'alarms': jsonEncode([
    // An alarm from before the backup alarm existed (no backupMinutes).
    {
      'id': 1,
      'hour': 6,
      'minute': 30,
      'days': [1, 2, 3, 4, 5],
      'enabled': true,
      'label': '',
      'snoozeMinutes': 10,
    },
  ]),
};

void main() {
  test('a 1.0.0+3 collection still loads', () async {
    SharedPreferences.setMockInitialValues(_v1_0_0_3);
    final s = await Store.load();
    expect(s.cards.map((c) => c.birdId), [
      'erithacus_rubecula',
      'pica_pica',
      'turdus_merula',
    ]);
    expect(s.cards[0].rarity, isNull);
    expect(s.cards[1].rarity, 'epic');
    expect(s.cards[1].quality, 91);
    expect(s.cards[2].traded, isNotNull);
    expect(s.given.single.birdId, 'parus_major');
    expect(s.achievementCards.length, 4);
    expect(s.heard, {'sitta_europaea'});
    expect(s.streak, 4);
    expect(s.alarms.single.backupMinutes, 3); // older alarms get the backup
    expect(s.region, 'N48E002');
  });
}
