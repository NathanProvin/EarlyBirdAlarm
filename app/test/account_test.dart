import 'dart:convert';

import 'package:early_bird/account.dart';
import 'package:early_bird/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Object> _card(String bird, String earned) => {
  'bird': bird,
  'stats': {'weight': 20.0},
  'quality': 50,
  'earned': earned,
};

void main() {
  test(
    'merging two backups: union of cards, given stays given, higher counters',
    () {
      final robin = _card('erithacus_rubecula', '2026-10-27T07:00:00.000');
      final magpie = _card('pica_pica', '2026-11-05T06:30:00.000');
      final wren = _card('troglodytes_troglodytes', '2026-11-07T06:30:00.000');
      final phone = {
        'cards': jsonEncode([robin, wren]),
        'given': jsonEncode([magpie]), // traded away on this phone
        'heard': ['turdus_merula', 'parus_major'],
        'seriesDone': ['N48E002:owls'],
        'streak': 2,
        'bestStreak': 9,
        'twitchBonus': 1,
      };
      final cloud = <String, Object?>{
        'cards': jsonEncode([
          robin,
          magpie,
        ]), // an older backup still holds the magpie
        'given': '[]',
        'heard': ['troglodytes_troglodytes', 'sturnus_vulgaris'],
        'seriesDone': ['legendary_hunter'],
        'streak': 5,
        'bestStreak': 5,
      };
      final m = mergeBackups(phone, cloud);
      final cards = [
        for (final c in jsonDecode(m['cards'] as String)) c['bird'],
      ];
      expect(cards, ['erithacus_rubecula', 'troglodytes_troglodytes']);
      expect(
        (jsonDecode(m['given'] as String) as List).single['bird'],
        'pica_pica',
      );
      // The wren was won on the phone: no longer "heard".
      expect(
        {...m['heard'] as List},
        {'turdus_merula', 'parus_major', 'sturnus_vulgaris'},
      );
      expect(
        {...m['seriesDone'] as List},
        {'N48E002:owls', 'legendary_hunter'},
      );
      expect(
        [m['streak'], m['bestStreak'], m['alarmStreak'], m['twitchBonus']],
        [5, 9, 0, 1],
      );
    },
  );

  test(
    'a backup restores into a fresh phone and reads back the same',
    () async {
      SharedPreferences.setMockInitialValues({
        'streak': 3,
        'cards': jsonEncode([_card('pica_pica', '2026-11-05T06:30:00.000')]),
        'heard': ['parus_major'],
      });
      final old = await Store.load();
      final saved = old.backup;
      SharedPreferences.setMockInitialValues({});
      final fresh = await Store.load();
      await fresh.restore(mergeBackups(fresh.backup, saved));
      expect(fresh.cards.single.birdId, 'pica_pica');
      expect(fresh.heard, {'parus_major'});
      expect(fresh.streak, 3);
    },
  );
}
