import 'dart:convert';
import 'dart:math';

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'birds.dart';
import 'cards.dart';
import 'content.dart';
import 'series.dart';
import 'ui/theme.dart';

class AlarmData {
  AlarmData({
    required this.id,
    required this.hour,
    required this.minute,
    this.days = const {},
    this.enabled = true,
    this.label = '',
    this.snoozeMinutes = 10,
  });

  AlarmData.fromJson(Map<String, dynamic> j)
    : this(
        id: j['id'] as int,
        hour: j['hour'] as int,
        minute: j['minute'] as int,
        days: {...(j['days'] as List).cast<int>()},
        enabled: j['enabled'] as bool,
        label: j['label'] as String,
        snoozeMinutes: j['snoozeMinutes'] as int,
      );

  final int id;
  int hour;
  int minute;
  Set<int> days; // DateTime.monday..sunday; empty = rings once
  bool enabled;
  String label;
  int snoozeMinutes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'days': days.toList()..sort(),
    'enabled': enabled,
    'label': label,
    'snoozeMinutes': snoozeMinutes,
  };
}

/// The first time after [now] at [a]'s hour and minute on one of its days.
DateTime nextRing(AlarmData a, DateTime now) {
  for (var i = 0; ; i++) {
    final t = DateTime(now.year, now.month, now.day + i, a.hour, a.minute);
    if (t.isAfter(now) && (a.days.isEmpty || a.days.contains(t.weekday))) {
      return t;
    }
  }
}

/// Twitch mode: up to [twitchMax] quizzes, one more every [twitchEvery]. The count is
/// derived from one timestamp: whole periods elapsed since [start], capped.
const twitchMax = 5;
const twitchEvery = Duration(minutes: 15); // 10 until 2026-10-31 (balance)

int twitchCharges(DateTime start, DateTime now) =>
    min(twitchMax, now.difference(start).inSeconds ~/ twitchEvery.inSeconds);

/// Time until the next quiz comes back (meaningless when full).
Duration twitchNextIn(DateTime start, DateTime now) =>
    twitchEvery -
    Duration(seconds: now.difference(start).inSeconds % twitchEvery.inSeconds);

/// The new start after using one quiz: charges above the cap are dropped first.
DateTime twitchUse(DateTime start, DateTime now) {
  final full = now.subtract(twitchEvery * twitchMax);
  return (start.isBefore(full) ? full : start).add(twitchEvery);
}

/// How many recently heard birds a new ring avoids.
const recentCount = 10;

/// Alarms, streak, recent birds and settings, saved in shared_preferences.
class Store extends ChangeNotifier {
  Store._(this._prefs);
  final SharedPreferences _prefs;

  static Future<Store> load() async =>
      Store._(await SharedPreferences.getInstance());

  List<AlarmData> get alarms => [
    for (final j in jsonDecode(_prefs.getString('alarms') ?? '[]') as List)
      AlarmData.fromJson(j as Map<String, dynamic>),
  ]..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

  int get streak => _prefs.getInt('streak') ?? 0;

  /// See [twitchCharges]; a new player starts full.
  DateTime get twitchStart =>
      DateTime.fromMillisecondsSinceEpoch(_prefs.getInt('twitchStart') ?? 0);

  /// Boosters won by completing series: on top of the timed ones, used first.
  int get twitchBonus => _prefs.getInt('twitchBonus') ?? 0;

  /// Twitch quizzes available now: the timed ones plus the bonus.
  int twitchReady(DateTime now) =>
      twitchCharges(twitchStart, now) + twitchBonus;

  /// Uses one Twitch quiz (the caller checks there is one): a bonus one first, so the
  /// timed ones keep coming back.
  Future<void> useTwitch() async {
    if (twitchBonus > 0) {
      await _prefs.setInt('twitchBonus', twitchBonus - 1);
    } else {
      final start = twitchUse(twitchStart, DateTime.now());
      await _prefs.setInt('twitchStart', start.millisecondsSinceEpoch);
    }
    notifyListeners();
  }

  /// The longest streak ever (for the "Perfect week" achievement).
  int get bestStreak => max(_prefs.getInt('bestStreak') ?? 0, streak);

  /// Series and achievements completed for the first time since the last call: each gives
  /// one bonus booster, once ("region:id" for series, the id for achievements).
  Future<List<SeriesState>> claimSeries() async {
    final done = {...?_prefs.getStringList('seriesDone')};
    String key(SeriesState s) => s.series == null ? s.id : '$region:${s.id}';
    final fresh = [
      for (final s in seriesStates(birds, cards, bestStreak))
        if (s.complete && !done.contains(key(s))) s,
    ];
    if (fresh.isEmpty) return fresh;
    await _prefs.setStringList('seriesDone', [...done, ...fresh.map(key)]);
    await _prefs.setInt('twitchBonus', twitchBonus + fresh.length);
    notifyListeners();
    return fresh;
  }

  /// Ids of the last birds heard, newest first.
  List<String> get recent => _prefs.getStringList('recent') ?? [];

  Difficulty get difficulty =>
      Difficulty.values[_prefs.getInt('difficulty') ?? Difficulty.easy.index];
  set difficulty(Difficulty d) =>
      _prefs.setInt('difficulty', d.index).then((_) => notifyListeners());

  /// Ignore the season: any bird of the region can ring.
  bool get allBirds => _prefs.getBool('allBirds') ?? false;
  set allBirds(bool on) =>
      _prefs.setBool('allBirds', on).then((_) => notifyListeners());

  /// Color theme: 'system' (Blue Tit, or Blackbird in the phone's dark mode) or a bird
  /// of [palettes]. A theme from an older version (dawn, dusk, forest) falls back to 'system'.
  String get theme => switch (_prefs.getString('theme')) {
    final t? when palettes.containsKey(t) => t,
    _ => 'system',
  };
  set theme(String name) =>
      _prefs.setString('theme', name).then((_) => notifyListeners());

  /// 'en', 'fr', or null to follow the phone.
  String? get language => _prefs.getString('language');
  set language(String? code) =>
      (code == null
              ? _prefs.remove('language')
              : _prefs.setString('language', code))
          .then((_) => notifyListeners());

  /// Region id from the catalog (a GPS cell like N48E002, or a country / bioregion like FR, US-NE).
  String? get region => _prefs.getString('region');
  set region(String? id) =>
      (id == null ? _prefs.remove('region') : _prefs.setString('region', id))
          .then((_) => notifyListeners());

  /// Schedules every enabled alarm the alarm plugin doesn't have, e.g. after a Google
  /// backup restore (only our preferences are backed up, not the plugin's schedule).
  Future<void> healAlarms() async {
    final scheduled = {for (final a in await Alarm.getAlarms()) a.id};
    final title = _prefs.getString('notificationTitle') ?? 'Guess the bird!';
    for (final a in alarms.where(
      (a) => a.enabled && !scheduled.contains(a.id),
    )) {
      await save(a, title);
    }
  }

  /// Picks new birds for every alarm, e.g. after a region change.
  Future<void> rescheduleAll() async {
    // The banner title last used, in the app's language (the store has no locale).
    final title = _prefs.getString('notificationTitle') ?? 'Guess the bird!';
    for (final a in alarms.where((a) => a.enabled)) {
      await save(a, title);
    }
  }

  /// Background catch-up with the chosen region (see syncRegion); when its data
  /// changed, every alarm gets a bird from the new data.
  Future<void> sync() async {
    final r = region;
    if (r == null) return;
    // Songs of scheduled alarms must stay on the phone through the clean-up.
    final scheduled = {
      for (final a in await Alarm.getAlarms()) ?_songOf(a.payload),
    };
    if (await syncRegion(
      r,
      monthFor(DateTime.now()),
      difficulty,
      heard: recent.toSet(), // the deck rotates past the birds just heard
      keep: scheduled,
    )) {
      await rescheduleAll();
      notifyListeners();
    }
  }

  /// The song file an alarm will play, from its payload {"bird", "rec"} (null if older).
  static String? _songOf(String? payload) {
    try {
      return (jsonDecode(payload ?? '') as Map<String, dynamic>)['rec']
          as String?;
    } on Object {
      return null;
    }
  }

  /// The month whose birds ring at [at], or null with "All birds".
  int? monthFor(DateTime at) => allBirds ? null : at.month;

  AlarmData? byId(int id) => alarms.where((a) => a.id == id).firstOrNull;

  int get nextId => alarms.fold(0, (m, a) => a.id > m ? a.id : m) + 1;

  /// Saves [a] (adds it if new) and schedules or cancels its ring.
  /// [notificationTitle] is passed in because the store has no locale.
  Future<void> save(AlarmData a, String notificationTitle) async {
    await _prefs.setString('notificationTitle', notificationTitle);
    await _write([...alarms.where((x) => x.id != a.id), a]);
    if (!a.enabled) {
      await Alarm.stop(a.id);
      return;
    }
    final at = nextRing(a, DateTime.now());
    final (bird, rec) = pickNext(at);
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: a.id,
        dateTime: at,
        assetAudioPath: phonePath(rec.file),
        payload: jsonEncode({'bird': bird.id, 'rec': rec.file}),
        // Fade up over 60 s, but from 30%: starting silent hid the first seconds of song.
        volumeSettings: VolumeSettings.staircaseFade(
          fadeSteps: [
            VolumeFadeStep(Duration.zero, 0.3),
            VolumeFadeStep(const Duration(seconds: 60), 1),
          ],
        ),
        notificationSettings: NotificationSettings(
          title: notificationTitle, // big bold line of the banner
          body: a.label.isEmpty ? 'Early Bird' : a.label,
          androidStopAlarmOnDismiss: false, // only a guess stops it
          icon: 'ic_notification', // white bird, res/drawable
          iconColor: coral,
        ),
      ),
    );
  }

  /// The bird and recording to play at [at]. Only a recording already on the phone can
  /// play: the downloaded deck first, then the bundled birds of the region, then any.
  (Bird, Recording) pickNext(DateTime at) =>
      pickBird(recent, monthFor(at), difficulty, downloaded) ??
      pickBird(recent, monthFor(at), difficulty, onPhone) ??
      species.values
          .where((b) => b.recordings.any(onPhone))
          .map((b) => (b, b.recordings.firstWhere(onPhone)))
          .first;

  Future<void> delete(AlarmData a) async {
    await Alarm.stop(a.id);
    await _write(alarms.where((x) => x.id != a.id).toList());
  }

  /// Every card earned, oldest first (duplicates included).
  List<CardData> get cards => [
    for (final j in jsonDecode(_prefs.getString('cards') ?? '[]') as List)
      CardData.fromJson(j as Map<String, dynamic>),
  ];

  /// Ids of birds guessed wrong and not yet won as a card.
  Set<String> get heard => {...?_prefs.getStringList('heard')};

  /// Records a guess (a correct one wins a card, returned), then schedules
  /// the alarm's next ring or turns it off. A null [alarmId] is a Twitch quiz:
  /// the wake-up streak and alarms are left alone.
  Future<CardData?> answered(
    int? alarmId,
    Bird bird,
    Recording? recording, // the one that rang, kept on the card
    bool correct,
    String notificationTitle,
  ) async {
    if (alarmId != null) {
      await _prefs.setInt(
        'bestStreak',
        bestStreak,
      ); // before a miss resets the streak
      await _prefs.setInt('streak', correct ? streak + 1 : 0);
    }
    await _prefs.setStringList('recent', [
      bird.id,
      ...recent.take(recentCount - 1),
    ]);
    // The bird was drafted when the alarm was set; the card's rarity is drawn now,
    // leaning toward how scarce the bird is this month (all year with "All birds").
    final card = correct
        ? rollCard(
            bird,
            region,
            rarity: drawRarity(
              difficulty,
              birdTier: bird.tierIn(monthFor(DateTime.now())) ?? bird.rarity,
            ),
            recording: recording?.file,
          )
        : null;
    if (card != null) {
      await _prefs.setString('cards', jsonEncode([...cards, card]));
    }
    await _prefs.setStringList(
      'heard',
      (correct ? (heard..remove(bird.id)) : {...heard, bird.id}).toList(),
    );
    final a = alarmId == null ? null : byId(alarmId);
    if (a == null) {
      notifyListeners();
      return card;
    }
    if (a.days.isEmpty) a.enabled = false;
    await save(a, notificationTitle);
    return card;
  }

  Future<void> _write(List<AlarmData> list) async {
    await _prefs.setString('alarms', jsonEncode(list));
    notifyListeners();
  }
}
