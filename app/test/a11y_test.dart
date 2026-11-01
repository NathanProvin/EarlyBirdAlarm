// Accessibility pass (2026-11-01): the main screens against Flutter's accessibility
// guidelines (48 dp touch targets, labelled tap targets, text contrast), and rendered at
// 200 % font size, where any overflow fails the test.
import 'dart:io';

import 'package:early_bird/birds.dart';
import 'package:early_bird/content.dart';
import 'package:early_bird/l10n/app_localizations.dart';
import 'package:early_bird/main.dart';
import 'package:early_bird/series.dart';
import 'package:early_bird/sfx.dart';
import 'package:early_bird/store.dart';
import 'package:early_bird/ui/collection.dart';
import 'package:early_bird/ui/credits.dart';
import 'package:early_bird/ui/edit.dart';
import 'package:early_bird/ui/onboarding.dart';
import 'package:early_bird/ui/ring.dart';
import 'package:early_bird/ui/series.dart';
import 'package:early_bird/ui/settings.dart';
import 'package:early_bird/ui/theme.dart';
import 'package:early_bird/ui/twitch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Bird _bird(String id, int number, String tier) => Bird.fromJson(
  {
    'id': id, 'latin': '$id latin', 'en': id, 'fr': id, //
    'order': 'Passeriformes', 'family': 'Paridae',
    'photo': 'photos/$id.jpg', 'photoCredit': 'p', 'number': number,
    'recordings': [
      {'file': 'audio/$id.m4a', 'kind': 'song', 'credit': 'c'},
    ],
    'stats': {
      'weight': [20, 2],
      'wingspan': [22, 1],
      'length': [14, 1],
      'distance': [100, 50],
    },
  },
  {for (var m = 1; m <= 12; m++) m: tier},
  7, // rarity level: the card shows its stars row
);

void main() {
  Sfx.enabled = false;
  setUpAll(() async {
    debugContentDir(Directory.systemTemp.createTempSync('eb_a11y'));
    birds = [
      for (final (i, (id, t)) in [
        ('robin', 'common'),
        ('blue tit', 'common'),
        ('great tit', 'uncommon'),
        ('wren', 'rare'),
        ('firecrest', 'epic'),
      ].indexed)
        _bird(id, i + 1, t),
    ];
    species = {for (final b in birds) b.id: b};
    allSeries = [
      Series.fromJson({
        'id': 'tits', 'en': 'Tits', 'fr': 'Mésanges', 'signature': 'great tit',
        'group': 'families', 'reward': 'rare', //
        'birds': ['blue tit', 'great tit', 'robin'],
      }),
    ];
    SharedPreferences.setMockInitialValues({'onboarded': true});
    store = await Store.load();
    for (final b in birds.take(3)) {
      await store.answered(null, b, b.recordings.first, true, '');
    }
  });

  final screens = <String, Widget Function()>{
    'settings': () => const SettingsScreen(),
    'collection': () => const Scaffold(body: CollectionScreen()),
    'series': () => const SeriesScreen(),
    'credits': () => const CreditsScreen(),
    'twitch': () => const Scaffold(body: TwitchScreen()),
    'onboarding': () => const OnboardingScreen(),
    'alarm editor': () => const EditScreen(),
    'card pager': () => CardPager(
      entries: [for (final c in store.cards) (birdById(c.birdId)!, c)],
      initial: 0,
    ),
    'card reveal': () => RevealScreen(
      bird: birds.first,
      card: store.cards.first,
      firstOfSpecies: true,
    ),
  };

  Future<void> show(
    WidgetTester tester,
    Widget screen, {
    double text = 1,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340); // the S22's screen
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: themeFor(lightTheme),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery.withClampedTextScaling(
          minScaleFactor: text,
          maxScaleFactor: text,
          child: screen,
        ),
      ),
    );
    // Some screens animate forever (badges, timers): pump a few frames, not settle.
    for (var i = 0; i < 20; i++) {
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // timers up to 2 s run out
    }
  }

  for (final MapEntry(key: name, value: build) in screens.entries) {
    testWidgets('$name: touch targets, labels, contrast', (tester) async {
      final handle = tester.ensureSemantics();
      await show(tester, build());
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('$name: no overflow at 200 % font size', (tester) async {
      await show(tester, build(), text: 2);
      expect(tester.takeException(), isNull);
    });

    // The 3-button navigation bar (48 dp, opaque) is drawn over the app edge to edge:
    // scrolled to the end, no button may sit under it.
    testWidgets('$name: buttons clear of the navigation bar', (tester) async {
      tester.view.padding = const FakeViewPadding(bottom: 48 * 2.625);
      await show(tester, build());
      for (final s in find.byType(Scrollable).evaluate().toList()) {
        if ((s.widget as Scrollable).axisDirection == AxisDirection.down) {
          await tester.drag(find.byWidget(s.widget), const Offset(0, -5000));
        }
        await tester.pump(const Duration(seconds: 1));
      }
      final bar = tester.view.physicalSize.height / 2.625 - 48;
      final buttons = find.byWidgetPredicate(
        (w) => w is ButtonStyleButton || w is IconButton || w is InkWell,
      );
      for (final e in buttons.evaluate()) {
        final r = tester.getRect(find.byWidget(e.widget).first);
        if (r.top >= bar + 48 || r.height == 0) continue; // off screen
        expect(
          r.bottom,
          lessThanOrEqualTo(bar + 0.5),
          reason: '${e.widget} $r',
        );
      }
    });
  }
}
