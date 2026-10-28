import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'birds.dart';

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
    // shortcut: offline before any region download, the fallback birds count as common all year.
    birds = [
      for (final j in fallback)
        Bird.fromJson(j, {for (var m = 1; m <= 12; m++) m: 'common'}),
    ];
  }
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
  Difficulty difficulty,
) async {
  final regionFile = localFile('regions/$region.json');
  final stale =
      !regionFile.existsSync() ||
      DateTime.now().difference(regionFile.lastModifiedSync()).inDays >= 7;
  if (stale) {
    if (!await download('species.json') ||
        !await download('regions/$region.json')) {
      return false;
    }
    await initContent(region);
  }
  final photos = [
    for (final b in birds)
      if (!localFile(b.photo).existsSync()) b.photo,
  ];
  for (var i = 0; i < photos.length; i += 8) {
    await Future.wait(photos.skip(i).take(8).map(download));
  }
  await topUpDeck(month, difficulty);
  return stale;
}

/// Keeps [deckSize] songs on the phone for birds that can ring this month at [difficulty],
/// so alarms ring a downloaded bird even offline. Best effort: stops at the first network error.
Future<void> topUpDeck(int? month, Difficulty difficulty) async {
  final random = Random();
  final candidates = pool(month, difficulty).keys.toList()..shuffle(random);
  var have = candidates
      .where((b) => b.playable(difficulty).any(onPhone))
      .length;
  for (final b in candidates) {
    if (have >= deckSize) return;
    if (b.playable(difficulty).any(onPhone)) continue;
    final recs = b.playable(difficulty);
    if (!await download(recs[random.nextInt(recs.length)].file)) return;
    have++;
  }
}
