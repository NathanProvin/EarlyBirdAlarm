import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'birds.dart';
import 'series.dart';

/// The catalog built by pipeline/build.py, on GitHub Pages (decisions.md "Delivery").
const baseUrl = 'https://nathanprovin.github.io/EarlyBirdAlarm/v1/';

/// Songs kept on the phone for upcoming rings.
const deckSize = 14;

late Directory _root; // downloaded content, same layout as the site
Set<String> _bundled =
    {}; // files bundled in assets/content (the offline fallback birds)

File localFile(String path) => File('${_root.path}/$path');

/// Where a catalog file can be read on the phone: a downloaded file, a bundled asset, or null.
String? phonePath(String path) {
  final f = localFile(path);
  if (f.existsSync()) return f.path;
  return _bundled.contains(path) ? 'assets/content/$path' : null;
}

bool onPhone(Recording r) => phonePath(r.file) != null;

/// Downloaded for the region (the deck), as opposed to bundled with the app.
bool downloaded(Recording r) => localFile(r.file).existsSync();

/// "na" or "eu": the continent of [region] (a list id like US-NE / CA-ON, or a 2° cell
/// like N42W072), or of the phone's [country] when no region is known yet.
String continentOf(String? region, String? country) => region != null
    ? (region.startsWith(RegExp('US-|CA-')) ||
              (region.startsWith(RegExp('[NS]')) && region.contains('W'))
          ? 'na'
          : 'eu')
    : (const {'US', 'CA', 'MX'}.contains(country) ? 'na' : 'eu');

/// Loads what is on the phone: the region's birds if downloaded, else the fallback birds.
Future<void> initContent(String? region) async {
  _root = Directory(
    '${(await getApplicationDocumentsDirectory()).path}/content',
  );
  final fallback = [
    for (final j in jsonDecode(
      await rootBundle.loadString('assets/content/species.json'),
    ) as List)
      j as Map<String, dynamic>,
  ];
  _bundled = {
    for (final j in fallback) ...[
      j['photo'] as String,
      for (final r in j['recordings'] as List) (r as Map)['file'] as String,
    ],
  };
  final speciesFile = localFile('species.json');
  final all = speciesFile.existsSync()
      ? [
          for (final j in jsonDecode(speciesFile.readAsStringSync()) as List)
            j as Map<String, dynamic>,
        ]
      : fallback;
  // A fallback bird's bundled song has the same path as on the site, so phonePath finds it.
  final byId = {for (final j in all) j['id'] as String: j};
  species = {
    for (final MapEntry(:key, :value) in byId.entries)
      key: Bird.fromJson(value),
  };
  final seriesFile = localFile('series.json');
  allSeries = [
    for (final j in jsonDecode(
      seriesFile.existsSync()
          ? seriesFile.readAsStringSync()
          : await rootBundle.loadString('assets/content/series.json'),
    ) as List)
      Series.fromJson(j as Map<String, dynamic>),
  ];
  final regionFile = localFile('regions/$region.json');
  if (region != null && regionFile.existsSync()) {
    final months =
        jsonDecode(regionFile.readAsStringSync()) as Map<String, dynamic>;
    birds = [
      for (final MapEntry(:key, :value) in months.entries)
        if (byId[key] case final j?)
          Bird.fromJson(j, {
            for (final m in (value as Map<String, dynamic>).entries)
              int.parse(m.key): m.value as String,
          }),
    ];
  } else {
    // shortcut: offline before any region download, the fallback birds of the user's
    // continent count as common all year.
    final continent = continentOf(
      region,
      PlatformDispatcher.instance.locale.countryCode,
    );
    birds = [
      for (final j in fallback)
        if ((j['continent'] ?? continent) == continent)
          Bird.fromJson(j, {for (var m = 1; m <= 12; m++) m: 'common'}),
    ];
  }
}

final _regionBirds = <String, Set<String>>{};

/// The bird ids of [region] when its list is on the phone, else null (see [download]).
Set<String>? regionBirdIds(String region) {
  if (_regionBirds[region] case final ids?) return ids;
  final f = localFile('regions/$region.json');
  if (!f.existsSync()) return null;
  return _regionBirds[region] =
      (jsonDecode(f.readAsStringSync()) as Map<String, dynamic>).keys.toSet();
}

/// Downloads one catalog file to the phone; false on any network error.
Future<bool> download(String path) async {
  try {
    final r = await http
        .get(Uri.parse('$baseUrl$path'))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) return false;
    final f = localFile(path);
    await f.parent.create(recursive: true);
    await f.writeAsBytes(r.bodyBytes);
    return true;
  } on Exception {
    return false;
  }
}

/// The list of regions to choose from: [{id, kind, en, fr}]. Null when offline.
Future<List<Map<String, dynamic>>?> fetchRegions() async {
  if (!await download('regions.json')) return null;
  return [
    for (final j
        in jsonDecode(await localFile('regions.json').readAsString()) as List)
      j as Map<String, dynamic>,
  ];
}

/// Brings the phone up to date with [region] in the background: species list and seasons
/// (re-fetched weekly, as the catalog is rebuilt), every photo, and the song deck.
/// Best effort: whatever fails is fetched at the next call (app start, after each guess).
/// Returns true when new region data arrived, so alarms should pick new birds.
Future<bool> syncRegion(
  String region,
  int? month,
  Difficulty difficulty, {
  Set<String> heard = const {},
  Set<String> keep = const {},
}) async {
  final regionFile = localFile('regions/$region.json');
  final stale =
      !regionFile.existsSync() ||
      DateTime.now().difference(regionFile.lastModifiedSync()).inDays >= 7;
  if (stale) {
    if (!await download('species.json') ||
        !await download('regions/$region.json')) {
      return false;
    }
    await download('series.json'); // optional: the bundled copy is the fallback
    await initContent(region);
  }
  final photos = [
    for (final b in birds)
      if (!localFile(b.photo).existsSync()) b.photo,
  ];
  for (var i = 0; i < photos.length; i += 8) {
    await Future.wait(photos.skip(i).take(8).map(download));
  }
  await topUpDeck(month, difficulty, heard: heard);
  await _cleanUp(keep);
  return stale;
}

/// Keeps [deckSize] downloaded songs on the phone for birds that can ring this month at
/// [difficulty] and weren't [heard] recently, so alarms ring a downloaded bird even
/// offline. The deck rotates: a bird just heard stops counting, so each answer brings a
/// new species at the next top-up. Best effort: stops at the first network error.
Future<void> topUpDeck(
  int? month,
  Difficulty difficulty, {
  Set<String> heard = const {},
}) async {
  final random = Random();
  final candidates = [
    for (final b in pool(month, difficulty).keys)
      if (!heard.contains(b.id)) b,
  ]..shuffle(random);
  bool inDeck(Bird b) => b.playable(difficulty).any(downloaded);
  var have = candidates.where(inDeck).length;
  for (final b in candidates) {
    if (have >= deckSize) return;
    if (inDeck(b)) continue;
    final recs = b.playable(difficulty);
    if (!await download(recs[random.nextInt(recs.length)].file)) return;
    have++;
  }
}

/// Downloaded songs kept on the phone at most; the oldest go first.
const keepSongs = 60;

/// Deletes the oldest downloaded songs beyond [keepSongs], never one in [keep] (the songs
/// of scheduled alarms). A card's ▶ streams its song from the site when it's gone.
Future<void> _cleanUp(Set<String> keep) async {
  final dir = Directory('${_root.path}/audio');
  if (!dir.existsSync()) return;
  final songs = dir.listSync().whereType<File>().toList()
    ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  for (final f in songs.skip(keepSongs)) {
    if (!keep.contains('audio/${f.uri.pathSegments.last}')) await f.delete();
  }
}
