import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../content.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

/// Display name of a region id: a country / bioregion name, or "Around 48°N 2°E" for a GPS cell.
String regionName(AppLocalizations l, String id) {
  final f = localFile('regions.json');
  final info = f.existsSync()
      ? (jsonDecode(f.readAsStringSync()) as List)
            .cast<Map<String, dynamic>>()
            .where((r) => r['id'] == id)
            .firstOrNull
      : null;
  final name = info?[l.localeName.startsWith('fr') ? 'fr' : 'en'] as String?;
  if (name != null) return name;
  final m = RegExp(r'^([NS])(\d+)([EW])(\d+)$').firstMatch(id);
  return m == null
      ? id
      : l.nearCell(
          '${int.parse(m[2]!) + 1}°${m[1]}',
          '${int.parse(m[4]!) + 1}°${m[3]}',
        );
}

/// Center (lat, lon) of a 2°×2° cell id like N48E002 or N40W074.
(double, double)? _cellCenter(String id) {
  final m = RegExp(r'^([NS])(\d+)([EW])(\d+)$').firstMatch(id);
  if (m == null) return null;
  return (
    (m[1] == 'N' ? 1 : -1) * double.parse(m[2]!) + 1,
    (m[3] == 'E' ? 1 : -1) * double.parse(m[4]!) + 1,
  );
}

/// Where the user lives: their GPS cell, or a country / bioregion from the list.
class RegionScreen extends StatefulWidget {
  const RegionScreen({super.key});

  @override
  State<RegionScreen> createState() => _RegionScreenState();
}

class _RegionScreenState extends State<RegionScreen> {
  List<Map<String, dynamic>>? _regions;
  bool _offline = false;
  double? _progress; // downloading the chosen region
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _offline = false);
    final r = await fetchRegions();
    if (mounted) setState(() => (_regions = r, _offline = r == null));
  }

  Future<void> _locate() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('denied');
      }
      // City-level is enough; the position never leaves the phone.
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      // The nearest cell with birds (the user's own may be sea, or have too few records).
      final cells = [
        for (final r in _regions!)
          if (_cellCenter(r['id'] as String) case (final lat, final lon))
            (
              r['id'] as String,
              (lat - pos.latitude) * (lat - pos.latitude) +
                  (lon - pos.longitude) * (lon - pos.longitude),
            ),
      ]..sort((a, b) => a.$2.compareTo(b.$2));
      await _choose(cells.first.$1);
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l.locationDenied)));
    }
  }

  Future<void> _choose(String id) async {
    final title = AppLocalizations.of(context).guessTheBird;
    setState(() => _progress = 0);
    final ok = await downloadRegion(id, (p) {
      if (mounted) setState(() => _progress = p);
    });
    if (!mounted) return;
    if (!ok) {
      setState(() => (_progress = null, _offline = true));
      return;
    }
    store.region = id;
    await topUpDeck(store.monthFor(DateTime.now()), store.difficulty);
    await store.rescheduleAll(title); // new region, new birds
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final regions = _regions;
    final lang = l.localeName.startsWith('fr') ? 'fr' : 'en';
    final listed = [
      for (final r in regions ?? <Map<String, dynamic>>[])
        if (r['kind'] != 'cell' &&
            (r[lang] as String).toLowerCase().contains(_query.toLowerCase()))
          r,
    ]..sort((a, b) => (a[lang] as String).compareTo(b[lang] as String));
    return Scaffold(
      appBar: AppBar(title: Text(l.chooseRegion)),
      body: switch (_progress) {
        final p? => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l.downloading,
                style: text.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: p),
            ],
          ),
        ),
        _ when _offline => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l.offline,
                style: text.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: Text(l.retry)),
            ],
          ),
        ),
        _ when regions == null => const Center(
          child: CircularProgressIndicator(),
        ),
        _ => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            FilledButton.icon(
              onPressed: _locate,
              icon: const Icon(Icons.my_location),
              label: Text(l.useMyLocation),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.searchRegion,
              ),
              onChanged: (q) => setState(() => _query = q),
            ),
            for (final r in listed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(r[lang] as String),
                selected: r['id'] == store.region,
                onTap: () => _choose(r['id'] as String),
              ),
          ],
        ),
      },
    );
  }
}
