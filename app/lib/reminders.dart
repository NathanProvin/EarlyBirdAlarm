import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';

import 'birds.dart';
import 'l10n/app_localizations.dart';
import 'store.dart';
import 'ui/region.dart';
import 'ui/series.dart';

/// Come-back reminders (2026-11-22): set each time the app goes to the background, so a
/// daily player never sees one. The first after [reminderFirst] (by then the habit is
/// slipping, but the game is still fresh in mind), one follow-up [reminderFollowUp] later
/// (a week away in all), then silence: a third nudge mostly gets the app muted.
const reminderFirst = Duration(days: 3);
const reminderFollowUp = Duration(days: 4);

const _channel = MethodChannel('early_bird/reminders'); // Reminders.kt

/// What a reminder says, by fear of missing out (strongest first): a friend waiting on a
/// trade (social, and it expires), a series 1–2 birds from complete (so close to done), a
/// new month's birds (seasonal novelty), a full booster pile (always true after 75 min,
/// so the weakest), the region's missing species (the follow-up's fallback).
enum Nudge { trade, series, month, pile, missing }

/// The first reminder takes the strongest nudge true at [first]; the follow-up the
/// strongest true at [second] that isn't the same (repeating it reads as nagging). Null:
/// no follow-up.
(Nudge, Nudge?) pickNudges({
  required DateTime now,
  required DateTime first,
  required DateTime second,
  required bool trade,
  required bool series,
  required bool seasonal,
  required int missing,
}) {
  List<Nudge> at(DateTime d) => [
    if (trade) Nudge.trade,
    if (series) Nudge.series,
    if (seasonal && (d.year, d.month) != (now.year, now.month)) Nudge.month,
    Nudge.pile,
    if (missing > 0) Nudge.missing,
  ];
  final one = at(first).first;
  return (one, at(second).where((n) => n != one).firstOrNull);
}

/// When the reminder [after] from [now] shows: at the hour the player used the app (their
/// habit), kept between 9:00 and 20:59.
DateTime reminderTime(DateTime now, Duration after) => DateTime(
  now.year,
  now.month,
  now.day + after.inDays,
  now.hour.clamp(9, 20),
  now.minute,
);

/// Sets the two reminders from what the player has now, or cancels them when off.
Future<void> scheduleReminders(Store store) async {
  try {
    if (!store.reminders) return await _channel.invokeMethod<void>('set');
    final code =
        store.language ?? PlatformDispatcher.instance.locale.languageCode;
    final l = lookupAppLocalizations(
      Locale(catalogLangs.contains(code) ? code : 'en'),
    );
    final now = DateTime.now();
    final first = reminderTime(now, reminderFirst);
    final second = reminderTime(first, reminderFollowUp);
    final close = [
      for (final s in store.seriesNow)
        if (s.series != null && const [1, 2].contains(s.total - s.owned)) s,
    ]..sort((a, b) => (a.total - a.owned).compareTo(b.total - b.owned));
    final owned = {for (final c in store.cards) c.birdId};
    final missing = birds.where((b) => !owned.contains(b.id)).length;
    final (one, two) = pickNudges(
      now: now,
      first: first,
      second: second,
      trade: store.tradeWaiting,
      series: close.isNotEmpty,
      seasonal: !store.allBirds,
      missing: store.region == null ? 0 : missing,
    );
    Map<String, Object> reminder(Nudge n, DateTime at) {
      final (title, body) = switch (n) {
        Nudge.trade => (l.reminderTradeTitle, l.reminderTradeBody),
        Nudge.series => (
          l.reminderSeriesTitle,
          l.reminderSeriesBody(
            close.first.total - close.first.owned,
            seriesName(l, close.first),
          ),
        ),
        Nudge.month => (l.reminderMonthTitle, l.reminderMonthBody),
        Nudge.pile => (
          l.reminderPileTitle,
          l.reminderPileBody(store.twitchReady(at)),
        ),
        Nudge.missing => (
          l.reminderMissingTitle,
          l.reminderMissingBody(missing, regionName(l, store.region!)),
        ),
      };
      return {
        'at': at.millisecondsSinceEpoch,
        'title': title,
        'body': body,
        'channel': l.reminders,
      };
    }

    await _channel.invokeMethod<void>(
      'set',
      jsonEncode([
        reminder(one, first),
        if (two != null) reminder(two, second),
      ]),
    );
  } on Exception {
    // No platform side (tests): the next time the app goes to the background tries again.
  }
}
