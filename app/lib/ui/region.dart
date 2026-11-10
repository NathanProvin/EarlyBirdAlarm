import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../birds.dart';
import '../content.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

/// Display name of a region id: its name from regions.json (a GPS cell: "France · North"), else "Around 48°N 2°E".
String regionName(AppLocalizations l, String id) {
  final f = localFile('regions.json');
  final info = f.existsSync()
      ? (jsonDecode(f.readAsStringSync()) as List)
            .cast<Map<String, dynamic>>()
            .where((r) => r['id'] == id)
            .firstOrNull
      : null;
  if (info != null) return localName(info, l.localeName);
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

/// Map projection (Web Mercator) on a [_world]-wide square, cut at ±80° latitude.
const _world = 1024.0;
double _y(double lat) =>
    _world / 2 -
    _world / (2 * pi) * log(tan(pi / 4 + lat.clamp(-80, 80) * pi / 360));
final _top = _y(80);
@visibleForTesting
Offset project(double lat, double lon) =>
    Offset((lon + 180) / 360 * _world, _y(lat) - _top);
@visibleForTesting
(double, double) unproject(Offset p) => (
  (2 * atan(exp((_world / 2 - p.dy - _top) * 2 * pi / _world)) - pi / 2) *
      180 /
      pi,
  p.dx / _world * 360 - 180,
);
final _mapSize = Size(_world, _y(-80) - _top);

/// The 2° cell id holding (lat, lon), like N48E002 (same format as the pipeline).
@visibleForTesting
String cellAt(double lat, double lon) {
  final la = (lat / 2).floor() * 2, lo = (lon / 2).floor() * 2;
  return '${la >= 0 ? 'N' : 'S'}${la.abs().toString().padLeft(2, '0')}'
      '${lo >= 0 ? 'E' : 'W'}${lo.abs().toString().padLeft(3, '0')}';
}

Rect _cellRect(String id) {
  final (lat, lon) = _cellCenter(id)!;
  return Rect.fromPoints(project(lat + 1, lon - 1), project(lat - 1, lon + 1));
}

/// The outer outline of the covered [cells] (map coordinates): each cell side whose
/// neighbour isn't covered. The grid itself stays hidden (2026-11-10).
@visibleForTesting
List<(Offset, Offset)> outlineEdges(Set<String> cells) => [
  for (final id in cells)
    if (_cellCenter(id) case (final lat, final lon)) ...[
      if (!cells.contains(cellAt(lat + 2, lon)))
        (project(lat + 1, lon - 1), project(lat + 1, lon + 1)),
      if (!cells.contains(cellAt(lat - 2, lon)))
        (project(lat - 1, lon - 1), project(lat - 1, lon + 1)),
      if (!cells.contains(cellAt(lat, lon - 2)))
        (project(lat + 1, lon - 1), project(lat - 1, lon - 1)),
      if (!cells.contains(cellAt(lat, lon + 2)))
        (project(lat + 1, lon + 1), project(lat - 1, lon + 1)),
    ],
];

/// Land and borders of the offline map (assets/map/world.json, from pipeline/world_map.py).
Future<(Path, Path)>? _worldPaths;
Future<(Path, Path)> _loadWorld() async {
  final j = jsonDecode(
    await rootBundle.loadString('assets/map/world.json'),
  ) as Map<String, dynamic>;
  Path paths(String key, {required bool close}) {
    // Land: lakes inside it are holes (even-odd).
    final path = Path()..fillType = PathFillType.evenOdd;
    for (final line in (j[key] as List).cast<List<dynamic>>()) {
      for (var i = 0; i < line.length; i += 2) {
        final p = project((line[i + 1] as int) / 100, (line[i] as int) / 100);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      if (close) path.close();
    }
    return path;
  }

  return (paths('land', close: true), paths('borders', close: false));
}

const _red = Color(0xFFD93025); // the covered area's outline
const _marine = Color(0xFF1B4F8A); // sea tint and coasts
const _cream = Color(0xFFF2E3B8); // land tint
const _blue = Color(0xFF1A73E8); // the "my position" blue of map apps

/// Where the user lives: drop a pin inside the covered area (red outline) or use the
/// GPS; the region is the 2° cell under the pin. Search only moves the map. Confirm
/// saves, back cancels.
class RegionScreen extends StatefulWidget {
  const RegionScreen({super.key});

  @override
  State<RegionScreen> createState() => _RegionScreenState();
}

class _RegionScreenState extends State<RegionScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>>? _regions;
  (Path, Path)? _map;
  bool _offline = false;
  String? _picked = store.region;
  late Offset? _pin = switch (store.pin) {
    (final lat, final lon) => project(lat, lon),
    null => null,
  };
  Offset? _me; // the user's position on the map, once located
  final _view = TransformationController();
  // The zoom, updated in 10 % steps: line widths follow it without repainting on every pan.
  final _zoom = ValueNotifier<double>(1);
  late final _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Size _viewport = Size.zero;
  Set<String> _cells = {};
  List<(Offset, Offset)> _edges = const [];

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
    _view.addListener(() {
      final s = _view.value.getMaxScaleOnAxis();
      if ((s / _zoom.value - 1).abs() > 0.1) _zoom.value = s;
    });
    _load();
  }

  @override
  void dispose() {
    _view.dispose();
    _zoom.dispose();
    _fly.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _offline = false);
    final r = await fetchRegions();
    final map = await (_worldPaths ??= _loadWorld());
    if (!mounted) return;
    setState(() {
      _regions = r;
      _map = map;
      _offline = r == null;
      _cells = {
        for (final x in r ?? const <Map<String, dynamic>>[])
          if (x['kind'] == 'cell') x['id'] as String,
      };
      _edges = outlineEdges(_cells);
    });
    if (r == null) return;
    if (_picked case final p?) _search.text = _name(p);
    // Opens on the current region, else on the area the catalog covers.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focus(
        _picked == null
            ? Rect.fromPoints(project(72, -130), project(34, 42))
            : _areaOf(_picked!),
        animate: false,
      ),
    );
  }

  String get _lang => AppLocalizations.of(context).localeName;
  String _name(String id) => regionName(AppLocalizations.of(context), id);

  /// The map area of a region: its cell (with some surroundings), or the cells named
  /// after a country / bioregion ("France" → "France · North"…).
  Rect _areaOf(String id) {
    if (_cells.contains(id)) {
      return _cellRect(id).inflate(_cellRect(id).width * 3);
    }
    final name = _name(id);
    final rects = [
      for (final r in _regions!)
        if (r['kind'] == 'cell' &&
            (localName(r, _lang) == name ||
                localName(r, _lang).startsWith('$name ·')))
          _cellRect(r['id'] as String),
    ];
    return rects.isEmpty
        ? Offset.zero & _mapSize
        : rects.reduce((a, b) => a.expandToInclude(b)).inflate(rects[0].width);
  }

  double get _minScale => _viewport.isEmpty
      ? 0.1
      : max(
          _viewport.width / _mapSize.width,
          _viewport.height / _mapSize.height,
        );

  /// Moves the view to show [area] whole, centered.
  void _focus(Rect area, {bool animate = true}) {
    if (_viewport.isEmpty) return;
    final s = min(
      _viewport.width / area.width,
      _viewport.height / area.height,
    ).clamp(_minScale, 80.0);
    final c = area.center;
    final tx = (_viewport.width / 2 - c.dx * s).clamp(
      _viewport.width - _mapSize.width * s,
      0.0,
    );
    final ty = (_viewport.height / 2 - c.dy * s).clamp(
      _viewport.height - _mapSize.height * s,
      0.0,
    );
    final target = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
    if (!animate) {
      _view.value = target;
      return;
    }
    final tween = Matrix4Tween(begin: _view.value, end: target);
    final curve = CurvedAnimation(parent: _fly, curve: Curves.easeInOut);
    void step() => _view.value = tween.evaluate(curve);
    _fly.addListener(step);
    _fly.forward(from: 0).whenComplete(() => _fly.removeListener(step));
  }

  /// Drops the pin at [p] (map coordinates); the region is the cell [id].
  void _drop(Offset p, String id) {
    setState(() {
      _pin = p;
      _picked = id;
    });
    _search.text = _name(id);
    _searchFocus.unfocus();
  }

  void _tap(Offset p) {
    final (lat, lon) = unproject(p);
    final id = cellAt(lat, lon);
    if (_cells.contains(id)) {
      _drop(p, id);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).notCovered)),
        );
    }
  }

  /// Saves the region under the pin, then leaves; the downloads run in the background
  /// and, until they land, the previous birds keep ringing.
  Future<void> _confirm() async {
    final (lat, lon) = unproject(_pin!);
    await store.setPin(lat, lon);
    if (_picked != store.region) {
      store.region = _picked;
      unawaited(store.sync());
    }
    if (mounted) Navigator.of(context).pop();
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
      if (!mounted) return;
      final me = project(pos.latitude, pos.longitude);
      setState(() => _me = me);
      // The user's cell, else the nearest one with birds (it may be sea, or too few records).
      final own = cellAt(pos.latitude, pos.longitude);
      double far(String id) {
        final (lat, lon) = _cellCenter(id)!;
        return (lat - pos.latitude) * (lat - pos.latitude) +
            (lon - pos.longitude) * (lon - pos.longitude);
      }

      final id = _cells.contains(own)
          ? own
          : _cells.reduce((a, b) => far(a) <= far(b) ? a : b);
      _drop(me, id);
      _focus(_areaOf(id));
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l.locationDenied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final map = _map;
    final query = _search.text.toLowerCase();
    return Scaffold(
      appBar: AppBar(title: Text(l.coveredArea, style: text.titleMedium)),
      // Once a pin is down: one plain button.
      bottomNavigationBar: _pin == null || _picked == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _confirm,
                  child: Text(l.confirmRegion),
                ),
              ),
            ),
      body: switch (_regions) {
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
        final regions? when map != null => LayoutBuilder(
          builder: (context, box) {
            _viewport = box.biggest;
            return Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: Color.alphaBlend(
                      _marine.withValues(alpha: 0.10),
                      scheme.surface,
                    ),
                    child: InteractiveViewer(
                      transformationController: _view,
                      constrained: false,
                      minScale: _minScale,
                      maxScale: 80,
                      child: GestureDetector(
                        onTapUp: (d) => _tap(d.localPosition),
                        child: Stack(
                          children: [
                            RepaintBoundary(
                              child: CustomPaint(
                                size: _mapSize,
                                painter: _MapPainter(
                                  map,
                                  _edges,
                                  _zoom,
                                  border: scheme.outline.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            CustomPaint(
                              size: _mapSize,
                              painter: _MarksPainter(
                                _view,
                                pin: _pin,
                                me: _me,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 96 + MediaQuery.paddingOf(context).bottom,
                  child: FloatingActionButton.small(
                    heroTag: null,
                    tooltip: l.useMyLocation,
                    shape: const CircleBorder(),
                    backgroundColor: scheme.surfaceContainerLowest,
                    foregroundColor: _blue,
                    onPressed: _locate,
                    child: const Icon(Icons.my_location),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16 + MediaQuery.paddingOf(context).bottom,
                  child: _SearchBar(
                    controller: _search,
                    focus: _searchFocus,
                    hint: l.searchRegion,
                    results: query.isEmpty
                        ? const []
                        : [
                            for (final r in regions)
                              if (r['kind'] != 'cell' &&
                                  localName(
                                    r,
                                    _lang,
                                  ).toLowerCase().contains(query))
                                r,
                          ].take(6).toList(),
                    lang: _lang,
                    comingSoon: l.comingSoon,
                    onChanged: () => setState(() {}),
                    // Search only moves the map; the pin chooses.
                    onPick: (id) {
                      _search.text = _name(id);
                      _searchFocus.unfocus();
                      _focus(_areaOf(id));
                    },
                  ),
                ),
              ],
            );
          },
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// The bottom search field, with matching countries / bioregions listed above it.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focus,
    required this.hint,
    required this.results,
    required this.lang,
    required this.comingSoon,
    required this.onChanged,
    required this.onPick,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final String hint;
  final List<Map<String, dynamic>> results;
  final String lang;
  final String comingSoon;
  final VoidCallback onChanged;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 3,
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (focus.hasFocus)
            for (final r in results)
              ListTile(
                dense: true,
                title: Text(localName(r, lang)),
                // Placeholder regions: listed, not choosable yet.
                subtitle: r['kind'] == 'planned' ? Text(comingSoon) : null,
                enabled: r['kind'] != 'planned',
                onTap: () => onPick(r['id'] as String),
              ),
          TextField(
            controller: controller,
            focusNode: focus,
            onChanged: (_) => onChanged(),
            onTap: () => controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: hint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cream land, marine coasts (lake shores too), thinner borders and the red outline of
/// the covered area. Widths are in screen pixels at the current [zoom].
class _MapPainter extends CustomPainter {
  _MapPainter(this.map, this.edges, this.zoom, {required this.border})
    : super(repaint: zoom);

  final (Path, Path) map;
  final List<(Offset, Offset)> edges;
  final ValueListenable<double> zoom;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final px = 1 / zoom.value;
    canvas.drawPath(map.$1, Paint()..color = _cream.withValues(alpha: 0.35));
    Paint line(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * px;
    canvas.drawPath(map.$2, line(border, 0.6));
    canvas.drawPath(map.$1, line(_marine.withValues(alpha: 0.7), 1.2));
    final outline = Path();
    for (final (a, b) in edges) {
      outline
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
    }
    canvas.drawPath(outline, line(_red, 1.6));
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.map != map ||
      old.edges.length != edges.length ||
      old.zoom != zoom ||
      old.border != border;
}

/// The pin (a plain map-pin icon in the accent, its tip on the spot) and the user's
/// position dot, sized for the screen whatever the zoom.
class _MarksPainter extends CustomPainter {
  _MarksPainter(
    this.view, {
    required this.pin,
    required this.me,
    required this.color,
  }) : super(repaint: view);

  final TransformationController view;
  final Offset? pin;
  final Offset? me;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = view.value.getMaxScaleOnAxis();
    if (me case final m?) {
      canvas.drawCircle(
        m,
        16 / scale,
        Paint()..color = _blue.withValues(alpha: 0.15),
      );
      canvas.drawCircle(m, 8 / scale, Paint()..color = Colors.white);
      canvas.drawCircle(m, 6 / scale, Paint()..color = _blue);
    }
    if (pin case final p?) {
      final size = 40 / scale;
      final icon = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.place.codePoint),
          style: TextStyle(
            fontSize: size,
            fontFamily: Icons.place.fontFamily,
            package: Icons.place.fontPackage,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // The icon's tip sits about 8 % above its bottom edge.
      icon.paint(canvas, p - Offset(icon.width / 2, icon.height * 0.92));
    }
  }

  @override
  bool shouldRepaint(_MarksPainter old) =>
      old.pin != pin || old.me != me || old.color != color;
}
