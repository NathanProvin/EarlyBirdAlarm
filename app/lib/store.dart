import 'dart:convert';

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'birds.dart';
import 'cards.dart';

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

  /// 'en', 'fr', or null to follow the phone.
  String? get language => _prefs.getString('language');
  set language(String? code) =>
      (code == null
              ? _prefs.remove('language')
              : _prefs.setString('language', code))
          .then((_) => notifyListeners());

  /// The month whose birds ring at [at], or null with "All birds".
  int? monthFor(DateTime at) => allBirds ? null : at.month;

  AlarmData? byId(int id) => alarms.where((a) => a.id == id).firstOrNull;

  int get nextId => alarms.fold(0, (m, a) => a.id > m ? a.id : m) + 1;

  /// Saves [a] (adds it if new) and schedules or cancels its ring.
  /// [notificationBody] is passed in because the store has no locale.
  Future<void> save(AlarmData a, String notificationBody) async {
    await _write([...alarms.where((x) => x.id != a.id), a]);
    if (!a.enabled) {
      await Alarm.stop(a.id);
      return;
    }
    final at = nextRing(a, DateTime.now());
    final bird = pickBird(recent, monthFor(at), difficulty);
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: a.id,
        dateTime: at,
        assetAudioPath: bird.audio,
        payload: bird.id,
        volumeSettings: VolumeSettings.fade(
          fadeDuration: const Duration(seconds: 60),
        ),
        notificationSettings: NotificationSettings(
          title: a.label.isEmpty ? 'Early Bird' : a.label,
          body: notificationBody,
          androidStopAlarmOnDismiss: false, // only a guess stops it
        ),
      ),
    );
  }

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
  /// the alarm's next ring or turns it off.
  Future<CardData?> answered(
    int alarmId,
    Bird bird,
    bool correct,
    String notificationBody,
  ) async {
    await _prefs.setInt('streak', correct ? streak + 1 : 0);
    await _prefs.setStringList('recent', [
      bird.id,
      ...recent.take(recentCount - 1),
    ]);
    final card = correct ? rollCard(bird) : null;
    if (card != null) {
      await _prefs.setString('cards', jsonEncode([...cards, card]));
    }
    await _prefs.setStringList(
      'heard',
      (correct ? (heard..remove(bird.id)) : {...heard, bird.id}).toList(),
    );
    final a = byId(alarmId);
    if (a == null) {
      notifyListeners();
      return card;
    }
    if (a.days.isEmpty) a.enabled = false;
    await save(a, notificationBody);
    return card;
  }

  Future<void> _write(List<AlarmData> list) async {
    await _prefs.setString('alarms', jsonEncode(list));
    notifyListeners();
  }
}
