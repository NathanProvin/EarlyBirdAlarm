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

const _green = Color(0xFF34A853);
const _marine = Color(0xFF1B4F8A); // sea tint and coasts
const _cream = Color(0xFFF2E3B8); // land tint
const _blue = Color(0xFF1A73E8); // the "my position" blue of map apps

/// Where the user lives: tap a 2° cell on the world map, search a country / bioregion,
/// or use the GPS. The choice is saved when leaving the screen.
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
  Offset? _me; // the user's position on the map, once located
  final _view = TransformationController();
  // The zoom, updated in 10 % steps: line widths follow it without repainting on every pan.
  final _zoom = ValueNotifier<double>(1);
  late final _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..value = 1;
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Size _viewport = Size.zero;
  Set<String> _cells = {};

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
    _blink.dispose();
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

  void _pick(String id, {bool focus = false}) {
    setState(() => _picked = id);
    _search.text = _name(id);
    _searchFocus.unfocus();
    if (_cells.contains(id)) _blink.forward(from: 0);
    if (focus) _focus(_areaOf(id));
  }

  void _tap(Offset p) {
    final (lat, lon) = unproject(p);
    final id = cellAt(lat, lon);
    if (_cells.contains(id)) _pick(id);
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
      setState(() => _me = project(pos.latitude, pos.longitude));
      // The user's cell, else the nearest one with birds (it may be sea, or too few records).
      final own = cellAt(pos.latitude, pos.longitude);
      double far(String id) {
        final (lat, lon) = _cellCenter(id)!;
        return (lat - pos.latitude) * (lat - pos.latitude) +
            (lon - pos.longitude) * (lon - pos.longitude);
      }

      _pick(
        _cells.contains(own)
            ? own
            : _cells.reduce((a, b) => far(a) <= far(b) ? a : b),
        focus: true,
      );
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
    return PopScope(
      // The choice is saved on the way back; the downloads then run in the background
      // and, until they land, the previous birds keep ringing.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _picked != null && _picked != store.region) {
          store.region = _picked;
          unawaited(store.sync());
        }
      },
      child: Scaffold(
        appBar: AppBar(),
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
                                    [for (final c in _cells) _cellRect(c)],
                                    _zoom,
                                    border: scheme.outline.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              CustomPaint(
                                size: _mapSize,
                                painter: _MarksPainter(
                                  _view,
                                  _blink,
                                  cell: _cells.contains(_picked)
                                      ? _cellRect(_picked!)
                                      : null,
                                  me: _me,
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
                    bottom: 96,
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
                    bottom: 16,
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
                      onPick: (id) => _pick(id, focus: true),
                    ),
                  ),
                ],
              );
            },
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
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

/// Cream land, marine coasts (lake shores too), thinner borders and the discrete grid of
/// the cells that have birds. Widths are in screen pixels at the current [zoom].
class _MapPainter extends CustomPainter {
  _MapPainter(this.map, this.cells, this.zoom, {required this.border})
    : super(repaint: zoom);

  final (Path, Path) map;
  final List<Rect> cells;
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
    final grid = Path();
    for (final r in cells) {
      grid.addRect(r);
    }
    canvas.drawPath(grid, line(Colors.grey.withValues(alpha: 0.35), 0.6));
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.map != map ||
      old.cells.length != cells.length ||
      old.zoom != zoom ||
      old.border != border;
}

/// The picked cell (blinks three times, then stays green) and the user's position dot,
/// sized for the screen whatever the zoom.
class _MarksPainter extends CustomPainter {
  _MarksPainter(this.view, this.blink, {required this.cell, required this.me})
    : super(repaint: Listenable.merge([view, blink]));

  final TransformationController view;
  final Animation<double> blink;
  final Rect? cell;
  final Offset? me;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = view.value.getMaxScaleOnAxis();
    if (cell case final c?) {
      final on = blink.isCompleted || (blink.value * 6).floor().isEven;
      if (on) {
        canvas.drawRect(c, Paint()..color = _green.withValues(alpha: 0.45));
        canvas.drawRect(
          c,
          Paint()
            ..color = _green
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 / scale,
        );
      }
    }
    if (me case final m?) {
      canvas.drawCircle(
        m,
        16 / scale,
        Paint()..color = _blue.withValues(alpha: 0.15),
      );
      canvas.drawCircle(m, 8 / scale, Paint()..color = Colors.white);
      canvas.drawCircle(m, 6 / scale, Paint()..color = _blue);
    }
  }

  @override
  bool shouldRepaint(_MarksPainter old) => old.cell != cell || old.me != me;
}
