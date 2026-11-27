import 'package:early_bird/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('3 lures a day, back the next day', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await Store.load();
    final day = DateTime(2026, 11, 27, 8);
    expect(s.lureLeft(day), 3);
    for (var i = 0; i < 3; i++) {
      await s.lure('turdus_merula', day);
    }
    expect(s.lureLeft(day), 0);
    expect(s.lureLeft(day.add(const Duration(days: 1))), 3);
  });
}
