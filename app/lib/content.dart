import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'birds.dart';
import 'series.dart';

/// The catalog built by pipeline/build.py, on Cloudflare R2 behind our domain (decisions.md
/// "Delivery"); 1.0.0+3 phones still read nathanprovin.github.io.
const baseUrl = 'https://cdn.earlybirdalarm.app/v1/';

/// Songs kept on the phone for upcoming rings.
const deckSize = 14;

late Directory _root; // downloaded content, same layout as the site

/// Tests only: where downloaded content would live (initContent sets it in the app).
@visibleForTesting
void debugContentDir(Directory dir) => _root = dir;
Set<String> _bundled =
    {}; // files bundled in assets/content (the offline fallback birds)

/// Ids of the birds bundled with the app, sorted: the same list on every phone running
/// the same version (the trade pairing code is drawn from it).
List<String> bundledBirds = [];

File localFile(String path) => File('${_root.path}/$path');

/// Where a catalog file can be read on the phone: a downloaded file, a bundled asset, or null.
String? phonePath(String path) {
  final f = localFile(path);
  // Under 2 kB is an empty clip from an older catalog: never ring an alarm with it.
  if (f.existsSync() && f.lengthSync() > 2000) return f.path;
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
  bundledBirds = [for (final j in fallback) j['id'] as String]..sort();
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
          Bird.fromJson(
            j,
            {
              for (final m in (value as Map<String, dynamic>).entries)
                if (m.key != 'r') int.parse(m.key): m.value as String,
            },
            value['r'] as int?, // rarity level, since 2026-11-01
          ),
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
/// (re-fetched weekly, as the catalog is rebuilt), the song deck, the region's catalog
/// photos, then the photos still missing that the player [wanted]: owned cards' and
/// pending draws' (read again at the clean-up, so a draw made meanwhile is kept).
/// Best effort: whatever fails is fetched at the next call (app start, after each guess).
/// Returns true when new region data arrived, so alarms should pick new birds.
Future<bool> syncRegion(
  String region,
  int? month,
  Difficulty difficulty, {
  Set<String> heard = const {},
  Set<String> played = const {},
  Set<String> keep = const {},
  Set<String> Function()? wanted,
}) async {
  final regionFile = localFile('regions/$region.json');
  // A catalog from before German and Spanish (2026-10-31) is refreshed at once, not
  // within the week, so names show in every language.
  final beforeLanguages = species.values.every((b) => b.names['de'] == null);
  final stale =
      !regionFile.existsSync() ||
      beforeLanguages ||
      DateTime.now().difference(regionFile.lastModifiedSync()).inDays >= 7;
  if (stale) {
    if (!await download('species.json') ||
        !await download('regions/$region.json')) {
      return false;
    }
    await download('series.json'); // optional: the bundled copy is the fallback
    await download(
      'regions.json',
    ); // region names (also fetched by the region screen)
    await initContent(region);
  }
  // The pile first: alarms need its songs, while a missing photo streams from the web.
  // The region's photos come after (~70 MB at 1200 px on a first sync).
  await topUpDeck(month, difficulty, heard: heard, played: played);
  // Then each owned card's photo once (a card won offline shows the catalog photo until
  // then). Variant and Shiny photos are never fetched ahead (2026-11-11: all of a pile
  // bird's photos came down, ~15 MB a day, though a card shows only one). On mobile data
  // only the pile's birds' catalog photos come: the rest of the region waits for Wi-Fi,
  // or comes one by one as it's shown (keepPhoto).
  final bulk = !await metered();
  final photos = [
    for (final p in {
      if (bulk)
        for (final b in birds) b.photo
      else
        for (final (b, _) in deckPile(month, difficulty, played)) b.photo,
      ...?wanted?.call(),
    })
      if (!localFile(p).existsSync()) p,
  ];
  if (const bool.fromEnvironment('DEV_TOOLS')) {
    // Dev builds (store.dart devTools): what the sync fetches, Wi-Fi or mobile data.
    debugPrint(
      'sync: ${bulk ? 'Wi-Fi' : 'mobile data'}, ${photos.length} photos to fetch',
    );
  }
  for (var i = 0; i < photos.length; i += 8) {
    await Future.wait(photos.skip(i).take(8).map(download));
  }
  // The pile's cards are never thrown away: each one waits for its turn to ring.
  final pile = {
    for (final (_, r) in deckPile(month, difficulty, played)) r.file,
  };
  await _cleanUp({...keep, ...pile});
  _cleanPhotos({for (final b in birds) b.photo, ...?wanted?.call()});
  return stale;
}

/// A downloaded song that hasn't rung yet: what the deck is made of (see [topUpDeck]).
bool fresh(Recording r, Set<String> played, Map<String, DateTime> songs) =>
    songs.containsKey(r.file) && !played.contains(r.file);

/// The downloaded songs and their dates, from one listing of the folder (2026-11-11: the
/// pile checked every playable recording on disk, 1,000+ checks per draw).
Map<String, DateTime> songsOnPhone() {
  final dir = Directory('${_root.path}/audio');
  if (!dir.existsSync()) return const {};
  return {
    for (final f in dir.listSync().whereType<File>())
      'audio/${f.uri.pathSegments.last}': f.lastModifiedSync(),
  };
}

/// Keeps [deckSize] fresh songs on the phone (downloaded, never [played]) for birds that
/// can ring this month at [difficulty] and weren't [heard] recently, so alarms ring a
/// downloaded bird even offline. Each song rings once, then the deck brings a new one:
/// before 2026-10-31 a played song kept counting, and the deck froze on ~24 species.
/// The deck is a pile ([deckPile]): rings draw its top card, and each free slot gets a
/// new bird drawn by rarity weight (common birds more often), put under the pile. Every
/// card of the pile ends up ringing, so the birds ring as often as they are drawn here.
/// Best effort: stops at the first network error.
Future<void> topUpDeck(
  int? month,
  Difficulty difficulty, {
  Set<String> heard = const {},
  Set<String> played = const {},
}) async {
  final random = Random();
  // Weighted shuffle (Efraimidis–Spirakis): key u^(1/w), largest first.
  final candidates = [
    for (final MapEntry(key: b, value: w) in pool(month, difficulty).entries)
      if (!heard.contains(b.id)) (b, pow(random.nextDouble(), 1 / w)),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  final songs = songsOnPhone();
  bool inDeck(Bird b) =>
      b.playable(difficulty).any((r) => fresh(r, played, songs));
  var have = candidates.where((c) => inDeck(c.$1)).length;
  for (final (b, _) in candidates) {
    if (have >= deckSize) return;
    if (inDeck(b)) continue;
    final recs = [
      for (final r in b.playable(difficulty))
        if (!played.contains(r.file)) r,
    ];
    if (recs.isEmpty) continue; // every song of this bird has rung lately
    if (!await download(recs[random.nextInt(recs.length)].file)) return;
    have++;
  }
}

/// Deletes every downloaded photo but those in [keep] (the region's catalog photos and the
/// owned cards' photos): extras fetched ahead before 2026-11-11, other regions' birds the
/// player doesn't own, dropped species, the 600 px photos of 1.0 (since 1.1 a photo's
/// name carries its width). Space then grows only with the collection (~850 MB at most:
/// every photo of the catalog).
void _cleanPhotos(Set<String> keep) {
  final dir = Directory('${_root.path}/photos');
  if (!dir.existsSync() || keep.isEmpty) return;
  for (final f in dir.listSync().whereType<File>()) {
    if (!keep.contains('photos/${f.uri.pathSegments.last}')) f.deleteSync();
  }
}

/// The deck as a physical pile (2026-11-11, user): its fresh songs (downloaded, never
/// [played]) for birds that can ring this [month] at [difficulty], top first; the top is
/// the card that has waited longest (the oldest download), a new card goes under.
List<(Bird, Recording)> deckPile(
  int? month,
  Difficulty difficulty,
  Set<String> played,
) {
  final songs = songsOnPhone();
  final cards = [
    for (final b in pool(month, difficulty).keys)
      for (final r in b.playable(difficulty))
        if (fresh(r, played, songs)) (b, r, songs[r.file]!),
  ]..sort((a, b) => a.$3.compareTo(b.$3));
  return [for (final (b, r, _) in cards) (b, r)];
}

const _network = MethodChannel('early_bird/network');

/// True on mobile data (a metered connection; MainActivity.kt). False when unknown.
Future<bool> metered() async {
  try {
    return await _network.invokeMethod<bool>('metered') ?? false;
  } on Exception {
    return false; // no Android channel (tests)
  }
}

final _keeping = <String, Future<bool>>{};

/// A region's catalog photo shown before it's on the phone (mobile data skips the bulk
/// download): fetched once and kept, never streamed and then fetched again. True once
/// fetched; false if it can't be (offline) or is already there.
Future<bool> keepPhoto(String path) {
  if (localFile(path).existsSync()) return Future.value(false);
  return _keeping[path] ??= download(path)
      .whenComplete(() => _keeping.remove(path));
}

/// Puts the downloaded song [path] under the pile, as if just downloaded.
void toBottom(String path) {
  final f = localFile(path);
  if (f.existsSync()) f.setLastModifiedSync(DateTime.now());
}

/// Downloaded songs kept on the phone at most; the oldest go first.
const keepSongs = 60;

/// Deletes the oldest downloaded songs beyond [keepSongs], never one in [keep] (the songs
/// of scheduled alarms and of the pile). A card's ▶ streams its song from the site when
/// it's gone. Before 2026-11-11 the pile's oldest cards could go: scarce birds, drawn
/// less often from a weighted deck, were deleted before ringing (half their share).
Future<void> _cleanUp(Set<String> keep) async {
  final dir = Directory('${_root.path}/audio');
  if (!dir.existsSync()) return;
  final songs = dir.listSync().whereType<File>().toList()
    ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  for (final f in songs.skip(keepSongs)) {
    if (!keep.contains('audio/${f.uri.pathSegments.last}')) await f.delete();
  }
}
