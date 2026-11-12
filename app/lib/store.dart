import 'dart:async';
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

  /// The pile's cards held by scheduled alarms (alarm id → song): the next draw takes the
  /// top card no alarm holds, so two alarms, or an alarm and a booster, never share one.
  final _held = <int, String>{};
  final _heldBird =
      <int, String>{}; // alarm id → bird, for its Shiny photo (#10)

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

  /// The longest streak ever (alarms and Training).
  int get bestStreak => max(_prefs.getInt('bestStreak') ?? 0, streak);

  /// Alarm answers only, for the streak achievements ("Perfect week", "Iron streak"):
  /// Training would make them too easy (decided 2026-11-10). Until 1.0.1 the streak was
  /// alarms only, so the old values seed these.
  int get alarmStreak =>
      _prefs.getInt('alarmStreak') ?? _prefs.getInt('streak') ?? 0;
  int get bestAlarmStreak => max(
    _prefs.getInt('bestAlarmStreak') ?? _prefs.getInt('bestStreak') ?? 0,
    alarmStreak,
  );

  /// Series and achievements already collected ("region:id" for series, "id#n" for an
  /// achievement's tier n; before the tiers, the achievement's id). Before 2026-10-31
  /// completing one gave a Twitch booster at once; those stay collected.
  Set<String> get _collected => {...?_prefs.getStringList('seriesDone')};
  String _collectKey(SeriesState s) =>
      s.series == null ? '${s.id}#${s.tier + 1}' : '$region:${s.id}';

  /// Friends who joined through this player's invite link, as last counted online
  /// (account.dart): the Influencer achievement works offline.
  int get friends => _prefs.getInt('friends') ?? 0;
  set friends(int n) {
    if (n == friends) return;
    _prefs.setInt('friends', n);
    notifyListeners();
  }

  /// The region's series and the achievements, as they stand.
  List<SeriesState> get seriesNow => seriesStates(birds, achievementCards, (
    bestStreak: bestStreak,
    bestAlarmStreak: bestAlarmStreak,
    given: given.length,
    friends: friends,
    collected: _collected,
  ));

  /// Completed and not collected yet: its badge glows until tapped.
  bool claimable(SeriesState s) =>
      s.complete && !_collected.contains(_collectKey(s));

  /// Anything to collect on the Series screen (a dot on its button).
  bool get anyClaimable => seriesNow.any(claimable);

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
    await _add(card);
    await _prefs.setStringList('seriesDone', [..._collected, _collectKey(s)]);
    notifyListeners();
    return card;
  }

  /// Saves a card won outside a quiz (a series, a gift): its bird is no longer "heard".
  /// Its own photo (a variant, a Shiny) is waited for as at a quiz's reveal (4 s at most;
  /// else the catalog photo shows until the next sync fetches it).
  Future<void> _add(CardData card) async {
    await _saveCards([...cards, card]);
    if (card.photo case final p? when !localFile(p).existsSync()) {
      await download(p)
          .timeout(const Duration(seconds: 4), onTimeout: () => false);
    }
    await _prefs.setStringList('heard', [
      for (final id in heard)
        if (id != card.birdId) id,
    ]);
    notifyListeners();
  }

  /// A gift card of [rarity] from the region (a code, the welcome card): 'shiny' gives one
  /// of the region's Shiny birds, or a Legendary when it has none. Null before the region's
  /// birds are known (the gift waits for the next launch).
  Future<CardData?> gift(String rarity, [Random? random]) async {
    random ??= Random();
    final shinies = [
      for (final b in birds)
        if (b.shiny.isNotEmpty) b,
    ];
    final bird = rarity == 'shiny' && shinies.isNotEmpty
        ? shinies[random.nextInt(shinies.length)]
        : pickBird(
            recent,
            monthFor(DateTime.now()),
            difficulty,
            (_) => true,
            random,
          )?.$1;
    if (bird == null) return null;
    final card = rollCard(
      bird,
      region,
      rarity: rarity, // rollCard turns 'shiny' into Legendary for a bird without one
      recording: bird.recordings.firstOrNull?.file,
      random: random,
    );
    await _add(card);
    return card;
  }

  /// The friend whose invite link brought this install (their account id), read once from
  /// the Play referrer (see account.dart); their welcome card is given while [welcomed] is false.
  String? get invitedBy => _prefs.getString('invitedBy');
  set invitedBy(String? uid) => uid == null
      ? _prefs.remove('invitedBy')
      : _prefs.setString('invitedBy', uid);
  bool get welcomed => _prefs.getBool('welcomed') ?? false;
  set welcomed(bool v) => _prefs.setBool('welcomed', v);

  /// The Play referrer was read and the referral written (or there was none).
  bool get referrerDone => _prefs.getBool('referrerDone') ?? false;
  set referrerDone(bool v) => _prefs.setBool('referrerDone', v);

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
  /// Reads which pile cards the scheduled alarms hold: before the first screen, so a
  /// booster opened at launch can't take an alarm's card (2026-11-11).
  Future<void> loadHeld() async {
    try {
      for (final a in await Alarm.getAlarms()) {
        if (_songOf(a.payload) case final song?) _held[a.id] = song;
        if (_birdOf(a.payload) case final bird?) _heldBird[a.id] = bird;
      }
    } on Object catch (e) {
      debugPrint('alarms: $e');
    }
  }

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
      played: resting(monthFor(DateTime.now())),
      keep: scheduled,
      // Read when needed, so a draw made during this sync keeps its photo too.
      wanted: () => {...ownedPhotos, ..._pendingPhotos},
    )) {
      await rescheduleAll();
      notifyListeners();
    }
    _prepareQuizzes();
  }

  /// The song file an alarm will play, from its payload {"bird", "rec"} (null if older).
  static String? _songOf(String? payload) => _field(payload, 'rec');
  static String? _birdOf(String? payload) => _field(payload, 'bird');
  static String? _field(String? payload, String key) {
    try {
      return (jsonDecode(payload ?? '') as Map<String, dynamic>)[key]
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
    final (bird, rec) = pickNext(at, forAlarm: a.id);
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
    _held[a.id] = recFile;
    _heldBird[a.id] = birdId;
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
    _held.remove(mainIdOf(id));
    _heldBird.remove(mainIdOf(id));
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

  /// The bird and recording to play at [at]: the top card of the pile ([deckPile]) that
  /// no other alarm holds ([forAlarm]: the alarm being scheduled may take its own card
  /// back). An empty pile (offline, first launch): any downloaded song, then the bundled
  /// birds of the region, then any.
  (Bird, Recording) pickNext(DateTime at, {int? forAlarm}) {
    final clock = Stopwatch()..start();
    final held = {
      for (final MapEntry(:key, :value) in _held.entries)
        if (key != forAlarm) value,
    };
    final next =
        deckPile(
          monthFor(at),
          difficulty,
          resting(monthFor(at)),
        ).where((c) => !held.contains(c.$2.file)).firstOrNull ??
        _fallback(at);
    _drawPhoto(next.$1, next.$2.file, alarm: forAlarm != null);
    _drawChoices(next.$1, next.$2.file, monthFor(at));
    // Timing log (dev builds): the draw, pile building included.
    if (devTools) {
      debugPrint('perf: draw ${clock.elapsedMicroseconds / 1000} ms');
    }
    return next;
  }

  /// The card photo of each pending draw (song → photo, "" for the catalog photo), picked
  /// at the draw so it downloads while the song plays: the reveal needn't wait
  /// (2026-11-11). Kept in the preferences: an alarm's draw outlives an app restart.
  Map<String, String> get _drawn => {
    for (final e
        in (jsonDecode(_prefs.getString('drawnPhotos') ?? '{}') as Map).entries)
      e.key as String: e.value as String,
  };

  void _drawPhoto(Bird bird, String song, {bool alarm = false}) {
    final photo = drawPhoto(bird);
    // An alarm may ring offline: its bird's Shiny photo comes along too (#10), so a
    // Shiny card won then still shows it. A booster is played online: fetched at the win.
    if (alarm) {
      for (final s in bird.shiny) {
        if (!localFile(s.photo).existsSync()) {
          _fetching[s.photo] = _fetch(s.photo);
        }
      }
    }
    // Only the draws still pending: this one and the scheduled alarms'.
    final pending = {..._held.values, song};
    unawaited(
      _prefs.setString(
        'drawnPhotos',
        jsonEncode({
          for (final MapEntry(:key, :value) in _drawn.entries)
            if (pending.contains(key)) key: value,
          song: photo ?? '',
        }),
      ),
    );
    if (photo != null && !localFile(photo).existsSync()) {
      _fetching[photo] = _fetch(photo);
    }
  }

  /// Each pile card's quiz (song → the 4 bird ids), picked when the card joins the pile
  /// and its catalog photos fetched then: when it's drawn ~14 cards later, the whole quiz
  /// is on the phone. On mobile data the region's photos aren't all there, and wrong
  /// answers picked when the quiz opened showed blank while they came (2026-11-11).
  Map<String, List<String>> get _choicesDrawn => {
    for (final e in (jsonDecode(
      _prefs.getString('drawnChoices') ?? '{}',
    ) as Map).entries)
      e.key as String: (e.value as List).cast<String>(),
  };

  Future<void> _saveChoices(Map<String, List<String>> m) =>
      _prefs.setString('drawnChoices', jsonEncode(m));

  /// Gives each pile card without one its quiz, forgets the cards gone, fetches photos.
  void _prepareQuizzes() {
    final month = monthFor(DateTime.now());
    final pile = deckPile(month, difficulty, resting(month));
    final keep = {..._held.values, for (final (_, r) in pile) r.file};
    final m = {
      for (final MapEntry(:key, :value) in _choicesDrawn.entries)
        if (keep.contains(key)) key: value,
    };
    for (final (b, r) in pile) {
      m[r.file] ??= [for (final c in choicesFor(b, month, difficulty)) c.id];
    }
    unawaited(_saveChoices(m));
    for (final id in {for (final ids in m.values) ...ids}) {
      if (birdById(id) case final b? when phonePath(b.photo) == null) {
        unawaited(keepPhoto(b.photo));
      }
    }
  }

  /// A drawn card without a quiz yet (the pile was empty, or a card from before this
  /// version) gets one now; its photos come while the quiz opens.
  void _drawChoices(Bird bird, String song, int? month) {
    if (_choicesDrawn.containsKey(song)) return;
    final choices = choicesFor(bird, month, difficulty);
    unawaited(
      _saveChoices({
        ..._choicesDrawn,
        song: [for (final b in choices) b.id],
      }),
    );
    for (final b in choices) {
      if (phonePath(b.photo) == null) unawaited(keepPhoto(b.photo));
    }
  }

  /// The quiz choices picked when [song] was drawn; null if drawn before this version or
  /// no longer valid (a bird gone from the catalog, or not the one ringing).
  List<Bird>? drawnChoices(Bird bird, String? song) {
    final ids = _choicesDrawn[song];
    if (ids == null || !ids.contains(bird.id)) return null;
    final choices = [for (final id in ids) ?birdById(id)];
    return choices.length == ids.length ? choices : null;
  }

  /// Photo downloads under way, so the reveal waits for the same one, never a second.
  final _fetching = <String, Future<bool>>{};

  Future<bool> _fetch(String photo) async {
    final clock = Stopwatch()..start();
    final ok = await download(photo);
    if (devTools) {
      // Timing log (dev builds): the download itself, during the quiz.
      debugPrint(
        'photo fetch: ${clock.elapsedMilliseconds} ms, '
        '${ok ? '${localFile(photo).lengthSync() ~/ 1024} KB' : 'failed'}',
      );
    }
    return ok;
  }

  /// How many of the last songs played can't come back yet: [playedCount], or half the
  /// songs that can ring now when that's fewer (2026-11-11: Easy has ~110 songs in a
  /// region, so a 200-song rest held them all after a week and the pile ran dry).
  int _rest(int? month) {
    final songs = pool(
      month,
      difficulty,
    ).keys.fold(0, (n, b) => n + b.playable(difficulty).length);
    return min(playedCount, max(1, songs ~/ 2));
  }

  /// The photo of each card owned (its variant or Shiny photo, else the catalog one):
  /// downloaded once and kept, so the collection works offline.
  Set<String> get ownedPhotos => {
    for (final c in cards)
      if (birdById(c.birdId) case final b?) b.photoOf(c.photo).photo,
  };

  /// Photos of draws not answered yet: the quiz in progress and the scheduled alarms
  /// (with their bird's Shiny photo). The clean-up keeps them (#2: an alarm's photo,
  /// fetched at scheduling, was deleted by the next sync).
  Set<String> get _pendingPhotos => {
    for (final p in _drawn.values)
      if (p.isNotEmpty) p,
    for (final id in _heldBird.values)
      ...?birdById(id)?.shiny.map((s) => s.photo),
  };

  /// The songs still resting: out of the pile until enough others have rung.
  Set<String> resting(int? month) => played.take(_rest(month)).toSet();

  (Bird, Recording) _fallback(DateTime at) =>
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

  /// Every card earned, oldest first (duplicates included). Decoded once and kept: it was
  /// decoded at every read, several times per redraw, and froze the app at 10,000 cards
  /// (5 MB of JSON; 2026-11-11). Changed only through [_saveCards].
  List<CardData> get cards => _cards ??= _decode('cards');

  /// Cards given away in face-to-face trades (see [trade]).
  List<CardData> get given => _given ??= _decode('given');

  List<CardData>? _cards, _given, _achievement;

  List<CardData> _decode(String key) => List.unmodifiable([
    for (final j in jsonDecode(_prefs.getString(key) ?? '[]') as List)
      CardData.fromJson(j as Map<String, dynamic>),
  ]);

  /// Saves the cards (and the given ones) and keeps them decoded.
  Future<void> _saveCards(List<CardData> list, [List<CardData>? gave]) async {
    _cards = List.unmodifiable(list);
    _achievement = null;
    await _prefs.setString('cards', jsonEncode(list));
    if (gave != null) {
      _given = List.unmodifiable(gave);
      await _prefs.setString('given', jsonEncode(gave));
    }
  }

  /// What series and achievements count: the cards owned plus the ones given away, so a
  /// trade never takes progress back (decided 2026-10-31).
  List<CardData> get achievementCards =>
      _achievement ??= List.unmodifiable([...cards, ...given]);

  /// A face-to-face trade: [give] leaves the collection (kept in [given]), [get] joins it.
  /// Both are marked as traded now.
  Future<void> trade(List<CardData> give, List<CardData> get) async {
    final now = DateTime.now();
    final gone = {for (final c in give) c.key};
    await _saveCards(
      [
        for (final c in cards)
          if (!gone.contains(c.key)) c,
        for (final c in get) c.tradedAt(now),
      ],
      [...given, for (final c in give) c.tradedAt(now)],
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

  /// The collection as mirrored to the cloud (account.dart), in the form it is saved.
  Map<String, Object?> get backup => {
    'cards': _prefs.getString('cards') ?? '[]',
    'given': _prefs.getString('given') ?? '[]',
    'heard': heard.toList(),
    'seriesDone': _collected.toList(),
    'streak': streak,
    'bestStreak': bestStreak,
    'alarmStreak': alarmStreak,
    'bestAlarmStreak': bestAlarmStreak,
    'twitchBonus': twitchBonus,
  };

  /// Replaces the collection with [b] (a merged [backup]).
  Future<void> restore(Map<String, Object?> b) async {
    await _prefs.setString('cards', b['cards'] as String);
    await _prefs.setString('given', b['given'] as String);
    _cards = _given = _achievement = null; // decoded again at the next read
    for (final k in ['heard', 'seriesDone']) {
      await _prefs.setStringList(k, (b[k] as List).cast<String>());
    }
    for (final k in [
      'streak',
      'bestStreak',
      'alarmStreak',
      'bestAlarmStreak',
      'twitchBonus',
    ]) {
      await _prefs.setInt(k, b[k] as int);
    }
    notifyListeners();
  }

  /// Set when the player deleted their account: no new anonymous account, no backup,
  /// until they sign in with Google again.
  bool get cloudOff => _prefs.getBool('cloudOff') ?? false;
  set cloudOff(bool on) =>
      _prefs.setBool('cloudOff', on).then((_) => notifyListeners());

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
    final clock = Stopwatch()..start();
    // Seeded from the old keys on the first answer of any kind, before 'streak' changes.
    final best = bestAlarmStreak, current = alarmStreak;
    await _prefs.setInt('bestAlarmStreak', best); // before a miss resets it
    if (alarmId != null) {
      await _prefs.setInt('alarmStreak', correct ? current + 1 : 0);
    } else if (!_prefs.containsKey('alarmStreak')) {
      await _prefs.setInt('alarmStreak', current);
    }
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
      // The song whose rest just ended goes under the pile, as a new card would (its file
      // is old: it would come back on top).
      if (played.elementAtOrNull(_rest(monthFor(DateTime.now())))
          case final back?) {
        try {
          toBottom(back);
        } on Error catch (e) {
          debugPrint('pile: $e'); // no content folder (tests)
        }
      }
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
              ownsLegendary: achievementCards.any(
                (c) => c.birdId == bird.id && c.rarity == 'legendary',
              ),
            ),
            recording: recording?.file,
            drawnPhoto: switch (_drawn[recording?.file]) {
              final String p => (path: p.isEmpty ? null : p),
              null => null, // drawn before this version, or a bundled bird
            },
          )
        : null;
    if (card != null) {
      await _saveCards([...cards, card]);
      // Timing log (dev builds): the answer's bookkeeping, up to the card saved.
      if (devTools) {
        debugPrint('perf: answer ${clock.elapsedMicroseconds / 1000} ms');
      }
      // Its own photo: usually already fetched during the quiz; else waited for here (4 s
      // at most; offline the catalog photo shows and the next sync fetches it).
      if (card.photo case final p?) {
        final clock = Stopwatch()..start();
        var how = 'ready';
        if (!localFile(p).existsSync()) {
          final ok = await (_fetching[p] ?? download(p)).timeout(
            const Duration(seconds: 4),
            onTimeout: () => false,
          );
          how = ok ? 'waited' : 'not yet';
        }
        if (devTools) {
          // Timing log (dev builds): what the player waits at the reveal.
          debugPrint('photo reveal: ${clock.elapsedMilliseconds} ms ($how)');
        }
      }
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
