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
    this.backupMinutes = 3,
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
        backupMinutes: j['backupMinutes'] as int? ?? 3, // older alarms: on
      );

  final int id;
  int hour;
  int minute;
  Set<int> days; // DateTime.monday..sunday; empty = rings once
  bool enabled;
  String label;
  int snoozeMinutes;
  int backupMinutes; // the rooster rings this long after the bird if unanswered; 0 = off

  Map<String, dynamic> toJson() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'days': days.toList()..sort(),
    'enabled': enabled,
    'label': label,
    'snoozeMinutes': snoozeMinutes,
    'backupMinutes': backupMinutes,
  };
}

/// The backup alarm of alarm [id]: a rooster at full volume over the bird if nobody
/// answers (see Store.save). Alarm ids stay far below this offset.
int backupId(int id) => id + backupOffset;
const backupOffset = 100000;

/// A ringing bird starts silent and rises linearly to full volume over [ringFade]; the
/// phone starts vibrating after [ringVibrate] (RingScreen). Testers found the old start
/// harsh (2026-11-10).
const ringFade = Duration(seconds: 60);
const ringVibrate = Duration(seconds: 40);
const roosterAsset = 'assets/rooster.m4a'; // credit: l10n creditsBody

/// The alarm a ringing id belongs to: itself, or the one it backs up.
int mainIdOf(int id) => id >= backupOffset ? id - backupOffset : id;

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

/// Developer tools, off in every normal build (test or release): the dev rows in Credits
/// and a 1-minute Twitch Zone. On only with `flutter build … --dart-define=DEV_TOOLS=true`.
const devTools = bool.fromEnvironment('DEV_TOOLS');

// 15 min (10 until the 2026-10-31 balance pass); 1 min with devTools to try it quickly.
const twitchEvery = Duration(minutes: devTools ? 1 : 15);

/// Twitch Plus (one-time purchase, see purchases.dart): a booster every minute.
const twitchPlusEvery = Duration(minutes: 1);

int twitchCharges(
  DateTime start,
  DateTime now, [
  Duration every = twitchEvery,
]) => min(twitchMax, now.difference(start).inSeconds ~/ every.inSeconds);

/// Time until the next quiz comes back (meaningless when full).
Duration twitchNextIn(
  DateTime start,
  DateTime now, [
  Duration every = twitchEvery,
]) =>
    every -
    Duration(seconds: now.difference(start).inSeconds % every.inSeconds);

/// The new start after using one quiz: charges above the cap are dropped first.
DateTime twitchUse(
  DateTime start,
  DateTime now, [
  Duration every = twitchEvery,
]) {
  final full = now.subtract(every * twitchMax);
  return (start.isBefore(full) ? full : start).add(every);
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

  /// Twitch Plus bought (restored from Google Play after a reinstall).
  bool get twitchPlus => _prefs.getBool('twitchPlus') ?? false;
  set twitchPlus(bool on) =>
      _prefs.setBool('twitchPlus', on).then((_) => notifyListeners());

  /// Time between two Twitch boosters.
  Duration get twitchPeriod => twitchPlus ? twitchPlusEvery : twitchEvery;

  /// Twitch quizzes available now: the timed ones plus the bonus.
  int twitchReady(DateTime now) =>
      twitchCharges(twitchStart, now, twitchPeriod) + twitchBonus;

  /// Uses one Twitch quiz (the caller checks there is one): a bonus one first, so the
  /// timed ones keep coming back.
  Future<void> useTwitch() async {
    if (twitchBonus > 0) {
      await _prefs.setInt('twitchBonus', twitchBonus - 1);
    } else {
      final start = twitchUse(twitchStart, DateTime.now(), twitchPeriod);
      await _prefs.setInt('twitchStart', start.millisecondsSinceEpoch);
    }
    notifyListeners();
  }

  /// The longest streak ever (for the "Perfect week" achievement).
  int get bestStreak => max(_prefs.getInt('bestStreak') ?? 0, streak);

  /// Series and achievements already collected ("region:id" for series, the id for
  /// achievements). Before 2026-10-31 completing one gave a Twitch booster at once; those
  /// stay collected.
  Set<String> get _collected => {...?_prefs.getStringList('seriesDone')};
  String _collectKey(SeriesState s) =>
      s.series == null ? s.id : '$region:${s.id}';

  /// Completed and not collected yet: its badge glows until tapped.
  bool claimable(SeriesState s) =>
      s.complete && !_collected.contains(_collectKey(s));

  /// Anything to collect on the Series screen (a dot on its button).
  bool get anyClaimable =>
      seriesStates(birds, achievementCards, bestStreak).any(claimable);

  /// Collects a completed series or achievement: a card of its guaranteed [SeriesState.reward]
  /// rarity, of one of the series' birds (an achievement: a bird drafted as for a ring).
  Future<CardData> claim(SeriesState s, [Random? random]) async {
    random ??= Random();
    final bird = s.birds.isNotEmpty
        ? s.birds[random.nextInt(s.birds.length)]
        : pickBird(
            recent,
            monthFor(DateTime.now()),
            difficulty,
            (_) => true,
            random,
          )!.$1;
    final card = rollCard(
      bird,
      region,
      rarity: s.reward,
      recording: bird.recordings.firstOrNull?.file,
      random: random,
    );
    await _prefs.setString('cards', jsonEncode([...cards, card]));
    await _prefs.setStringList('heard', [
      for (final id in heard)
        if (id != bird.id) id,
    ]);
    await _prefs.setStringList('seriesDone', [..._collected, _collectKey(s)]);
    notifyListeners();
    return card;
  }

  /// Ids of the last birds heard, newest first.
  List<String> get recent => _prefs.getStringList('recent') ?? [];

  /// Song files that already rang, newest first (see [fresh]): the deck moves on to new
  /// songs. Longer than the songs kept on the phone (keepSongs), so all of those count.
  List<String> get played => _prefs.getStringList('played') ?? [];
  static const playedCount = 200;

  Difficulty get difficulty =>
      Difficulty.values[_prefs.getInt('difficulty') ?? Difficulty.easy.index];
  set difficulty(Difficulty d) =>
      _prefs.setInt('difficulty', d.index).then((_) => notifyListeners());

  /// The introduction was seen (or skipped): it shows once, on first launch.
  bool get onboarded => _prefs.getBool('onboarded') ?? false;
  set onboarded(bool on) =>
      _prefs.setBool('onboarded', on).then((_) => notifyListeners());

  /// Closing a card reveal asks Google's in-app review once, from 15 cards, and the
  /// reveal shows a support line once, from 30 cards (decided 2026-11-10).
  bool get reviewAsked => _prefs.getBool('reviewAsked') ?? false;
  set reviewAsked(bool on) => _prefs.setBool('reviewAsked', on);
  bool get supportNudged => _prefs.getBool('supportNudged') ?? false;
  set supportNudged(bool on) => _prefs.setBool('supportNudged', on);

  /// Cards and boosters lean as the phone moves (ui/gyro.dart).
  bool get gyro => _prefs.getBool('gyro') ?? true;
  set gyro(bool on) =>
      _prefs.setBool('gyro', on).then((_) => notifyListeners());

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
  /// Where the user dropped the region pin (lat, lon); null before the pin picker.
  (double, double)? get pin =>
      switch ((_prefs.getDouble('pinLat'), _prefs.getDouble('pinLon'))) {
        (final lat?, final lon?) => (lat, lon),
        _ => null,
      };
  Future<void> setPin(double lat, double lon) async {
    await _prefs.setDouble('pinLat', lat);
    await _prefs.setDouble('pinLon', lon);
  }

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
      (a) =>
          a.enabled &&
          (!scheduled.contains(a.id) ||
              (a.backupMinutes > 0 && !scheduled.contains(backupId(a.id)))),
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
      played: played.toSet(),
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
      await stopRing(a.id);
      return;
    }
    final at = nextRing(a, DateTime.now());
    final (bird, rec) = pickNext(at);
    await _schedule(a, at, bird.id, rec.file, notificationTitle);
  }

  /// Sets alarm [a] to ring at [at] with [birdId]'s recording [recFile], and its backup.
  Future<void> _schedule(
    AlarmData a,
    DateTime at,
    String birdId,
    String recFile,
    String notificationTitle,
  ) async {
    final payload = jsonEncode({'bird': birdId, 'rec': recFile});
    final notification = NotificationSettings(
      title: notificationTitle, // big bold line of the banner
      body: a.label.isEmpty ? 'Early Bird' : a.label,
      androidStopAlarmOnDismiss: false, // only a guess stops it
      icon: 'ic_notification', // white bird, res/drawable
      iconColor: coral,
    );
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: a.id,
        dateTime: at,
        assetAudioPath: phonePath(recFile),
        payload: payload,
        // The phone's alarm volume goes to the maximum while it rings (put back after):
        // a low alarm volume once let the user sleep through. The song fades up from
        // silence (the plugin interpolates linearly between steps), so the start is gentle.
        volumeSettings: VolumeSettings.staircaseFade(
          volume: 1,
          fadeSteps: [
            VolumeFadeStep(Duration.zero, 0),
            VolumeFadeStep(ringFade, 1),
          ],
        ),
        // The plugin's vibration starts at once: RingScreen starts one at ringVibrate.
        vibrate: false,
        notificationSettings: notification,
      ),
    );
    if (a.backupMinutes == 0) {
      await Alarm.stop(backupId(a.id));
      return;
    }
    // The backup: a rooster at full volume over the bird, the volume buttons locked.
    // Scheduled by Android like the alarm, so it rings even if the app was closed.
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: backupId(a.id),
        dateTime: at.add(Duration(minutes: a.backupMinutes)),
        assetAudioPath: roosterAsset,
        payload: payload, // the same quiz, whichever of the two opens the app
        allowAlarmOverlap: true,
        volumeSettings: const VolumeSettings.fixed(
          volume: 1,
          volumeEnforced: true,
        ),
        notificationSettings: notification,
      ),
    );
  }

  /// Stops alarm [id] (or the one a backup id belongs to) and its backup.
  Future<void> stopRing(int id) async {
    await Alarm.stop(mainIdOf(id));
    await Alarm.stop(backupId(mainIdOf(id)));
  }

  /// Snooze: the ringing alarm and its backup ring again after its snooze time, with
  /// the same bird.
  Future<void> snooze(AlarmSettings ringing) async {
    final a = byId(mainIdOf(ringing.id));
    await stopRing(ringing.id);
    final at = DateTime.now().add(Duration(minutes: a?.snoozeMinutes ?? 10));
    final song = jsonDecode(ringing.payload ?? '{}') as Map<String, dynamic>;
    if (a == null || song['bird'] == null || song['rec'] == null) {
      // An alarm deleted meanwhile, or an older payload: the same settings again.
      await Alarm.set(
        alarmSettings: ringing.copyWith(id: mainIdOf(ringing.id), dateTime: at),
      );
      return;
    }
    await _schedule(
      a,
      at,
      song['bird'] as String,
      song['rec'] as String,
      _prefs.getString('notificationTitle') ?? 'Guess the bird!',
    );
  }

  /// The bird and recording to play at [at]. Only a recording already on the phone can
  /// play: a fresh song of the deck first (not rung yet), then any downloaded one, then
  /// the bundled birds of the region, then any.
  (Bird, Recording) pickNext(DateTime at) =>
      pickBird(
        recent,
        monthFor(at),
        difficulty,
        (r) => fresh(r, played.toSet()),
      ) ??
      pickBird(recent, monthFor(at), difficulty, downloaded) ??
      pickBird(recent, monthFor(at), difficulty, onPhone) ??
      species.values
          .where((b) => b.recordings.any(onPhone))
          .map((b) => (b, b.recordings.firstWhere(onPhone)))
          .first;

  Future<void> delete(AlarmData a) async {
    await stopRing(a.id);
    await _write(alarms.where((x) => x.id != a.id).toList());
  }

  /// Every card earned, oldest first (duplicates included).
  List<CardData> get cards => [
    for (final j in jsonDecode(_prefs.getString('cards') ?? '[]') as List)
      CardData.fromJson(j as Map<String, dynamic>),
  ];

  /// Cards given away in face-to-face trades (see [trade]).
  List<CardData> get given => [
    for (final j in jsonDecode(_prefs.getString('given') ?? '[]') as List)
      CardData.fromJson(j as Map<String, dynamic>),
  ];

  /// What series and achievements count: the cards owned plus the ones given away, so a
  /// trade never takes progress back (decided 2026-10-31).
  List<CardData> get achievementCards => [...cards, ...given];

  /// A face-to-face trade: [give] leaves the collection (kept in [given]), [get] joins it.
  /// Both are marked as traded now.
  Future<void> trade(List<CardData> give, List<CardData> get) async {
    final now = DateTime.now();
    final gone = {for (final c in give) c.key};
    await _prefs.setString(
      'cards',
      jsonEncode([
        for (final c in cards)
          if (!gone.contains(c.key)) c,
        for (final c in get) c.tradedAt(now),
      ]),
    );
    await _prefs.setString(
      'given',
      jsonEncode([...given, for (final c in give) c.tradedAt(now)]),
    );
    final won = {for (final c in get) c.birdId};
    await _prefs.setStringList('heard', [
      for (final id in heard)
        if (!won.contains(id)) id,
    ]);
    notifyListeners();
  }

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
    // Alarms and Training both count (decided 2026-11-10).
    await _prefs.setInt(
      'bestStreak',
      bestStreak,
    ); // before a miss resets the streak
    await _prefs.setInt('streak', correct ? streak + 1 : 0);
    await _prefs.setStringList('recent', [
      bird.id,
      ...recent.take(recentCount - 1),
    ]);
    if (recording != null) {
      await _prefs.setStringList('played', [
        recording.file,
        ...played.where((f) => f != recording.file).take(playedCount - 1),
      ]);
    }
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
