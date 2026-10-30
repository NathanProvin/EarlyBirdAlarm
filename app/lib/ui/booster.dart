import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../birds.dart';
import 'theme.dart';

/// The app icon (half-sun on the horizon, perched bird), drawn from the shapes of
/// res/drawable/ic_launcher_foreground.xml.
class LogoPainter extends CustomPainter {
  const LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final inkPaint = Paint()..color = ink;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(size.shortestSide / 56)
      ..translate(-55.75, -55.5) // centre of the drawing (x 30..81.5, y 42..69)
      ..drawArc(
        Rect.fromCircle(center: const Offset(54, 66), radius: 24),
        pi,
        pi,
        true,
        Paint()..color = coral,
      )
      ..drawRect(const Rect.fromLTWH(24, 66, 60, 3), inkPaint)
      ..drawOval(
        Rect.fromCenter(center: const Offset(66, 59), width: 16, height: 12),
        inkPaint,
      )
      ..drawCircle(const Offset(73, 52), 4, inkPaint)
      ..drawPath(
        Path()..addPolygon(const [
          Offset(76.5, 50.8),
          Offset(81.5, 52.5),
          Offset(76.5, 54.2),
        ], true),
        inkPaint,
      )
      ..drawPath(
        Path()..addPolygon(const [
          Offset(59, 57),
          Offset(50, 63),
          Offset(54.5, 64.2),
          Offset(61.5, 61),
        ], true),
        inkPaint,
      )
      ..drawRect(const Rect.fromLTWH(64, 64, 1.4, 2.5), inkPaint)
      ..drawRect(const Rect.fromLTWH(68.5, 64, 1.4, 2.5), inkPaint)
      ..drawCircle(const Offset(74.5, 51.4), 0.9, Paint()..color = paper)
      ..restore();
  }

  @override
  bool shouldRepaint(LogoPainter oldDelegate) => false;
}

/// The logo on a paper disc, readable on any background.
class Logo extends StatelessWidget {
  const Logo({this.size = 96, super.key});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * 0.12),
    decoration: const BoxDecoration(color: paper, shape: BoxShape.circle),
    child: const CustomPaint(painter: LogoPainter()),
  );
}

/// A booster wrapper: silver-to-accent foil with the logo. [shine] (0..1) moves the
/// light sweep, following the tilt. The foil is the one gradient the Dawn rules allow.
class BoosterFace extends StatelessWidget {
  const BoosterFace({this.shine = 0.5, super.key});
  final double shine;

  @override
  Widget build(BuildContext context) {
    const silver = Color(0xFFDADBE0);
    final accent = Theme.of(context).colorScheme.primary;
    final x =
        shine * 3 - 1.5; // the sweep crosses the wrapper as shine goes 0 → 1
    return Container(
      // A thin dark edge sets each booster apart in the pile.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ink.withValues(alpha: 0.35), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [silver, accent, silver],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(x - 1, -1),
                    end: Alignment(x + 1, 1),
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.45),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0.4, 0.5, 0.6],
                  ),
                ),
              ),
              const CustomPaint(painter: _FoilTexture()),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Logo(),
                  const SizedBox(height: 16),
                  Text(
                    'Early Bird',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: ink, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Foil grain (fine diagonal lines) and the crimped seals at the top and bottom.
class _FoilTexture extends CustomPainter {
  const _FoilTexture();

  @override
  void paint(Canvas canvas, Size size) {
    final grain = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var d = -size.height; d < size.width; d += 6) {
      canvas.drawLine(
        Offset(d, size.height),
        Offset(d + size.height, 0),
        grain,
      );
    }
    const seal = 14.0;
    final band = Paint()..color = ink.withValues(alpha: 0.12);
    final ridge = Paint()
      ..color = ink.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    final light = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (final top in [0.0, size.height - seal]) {
      canvas.drawRect(Rect.fromLTWH(0, top, size.width, seal), band);
      for (var x = 2.0; x < size.width; x += 4) {
        canvas.drawLine(Offset(x, top + 2), Offset(x, top + seal - 2), ridge);
      }
    }
    // A highlight just inside each seal, as on a pressed wrapper.
    canvas
      ..drawLine(const Offset(0, seal + 1), Offset(size.width, seal + 1), light)
      ..drawLine(
        Offset(0, size.height - seal - 1),
        Offset(size.width, size.height - seal - 1),
        light,
      );
  }

  @override
  bool shouldRepaint(_FoilTexture oldDelegate) => false;
}

/// The back of a card: paper with the logo, in the "unknown" frame.
class CardBack extends StatelessWidget {
  const CardBack({super.key});

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 0.68,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: unknownColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: paper,
          borderRadius: BorderRadius.circular(radius - 6),
        ),
        alignment: Alignment.center,
        child: const Logo(size: 120),
      ),
    ),
  );
}

/// Where the booster tears: a zig-zag line [_tearAt] of the way down.
const _tearAt = 0.16;

class _TearClipper extends CustomClipper<Path> {
  const _TearClipper({required this.strip});
  final bool strip; // the top strip that comes off, or the rest

  @override
  Path getClip(Size size) {
    const teeth = 12;
    final y = size.height * _tearAt;
    final zigzag = [
      for (var i = 0; i <= teeth; i++)
        Offset(size.width * i / teeth, y + (i.isEven ? -3 : 3)),
    ];
    return strip
        ? (Path()..addPolygon([
            Offset.zero,
            Offset(size.width, 0),
            ...zigzag.reversed,
          ], true))
        : (Path()..addPolygon([
            ...zigzag,
            Offset(size.width, size.height),
            Offset(0, size.height),
          ], true));
  }

  @override
  bool shouldReclip(_TearClipper oldClipper) => false;
}

const boosterWidth = 200.0;
const boosterHeight = 290.0;

/// [count] boosters in a loose pile that floats and leans toward the finger. A tap
/// tears the top one open, then [onTorn] runs.
class BoosterPile extends StatefulWidget {
  const BoosterPile({
    required this.count,
    required this.onTorn,
    required this.label,
    super.key,
  });
  final int count;
  final VoidCallback onTorn;
  final String label; // TalkBack: "Open a booster"

  @override
  State<BoosterPile> createState() => _BoosterPileState();
}

class _BoosterPileState extends State<BoosterPile>
    with TickerProviderStateMixin {
  static const _w = boosterWidth, _h = boosterHeight, _margin = 40.0;
  // Each booster under the top one sits a little askew (top first).
  static const _angles = [0.0, -0.07, 0.09, -0.11, 0.05];
  static const _shifts = [
    Offset.zero,
    Offset(-8, 5),
    Offset(9, 8),
    Offset(-11, 11),
    Offset(7, 14),
  ];

  late final _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();
  late final _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  Offset _tilt = Offset.zero; // -1..1 from the centre, follows the finger

  @override
  void dispose() {
    _float.dispose();
    _fly.dispose();
    super.dispose();
  }

  Size get _box => const Size(_w + 2 * _margin, _h + 2 * _margin);

  void _onMove(Offset p) {
    final c = _box.center(Offset.zero);
    setState(
      () => _tilt = Offset(
        ((p.dx - c.dx) / (_box.width / 2)).clamp(-1.0, 1.0),
        ((p.dy - c.dy) / (_box.height / 2)).clamp(-1.0, 1.0),
      ),
    );
  }

  /// One tap: the top strip lifts, tears off and flies away, then [onTorn].
  Future<void> _open() async {
    if (widget.count == 0 || _fly.isAnimating) return;
    // A discreet hint: a tick on the tap, a light tap as the strip tears free.
    HapticFeedback.selectionClick();
    final flown = _fly.forward(from: 0);
    // The quiz starts fading in while the strip is still flying off.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    widget.onTorn();
    await flown;
    if (mounted) _fly.reset();
  }

  Widget _top() {
    final strip = AnimatedBuilder(
      animation: _fly,
      builder: (_, child) {
        // The first 40%: the strip lifts from its left end; then it flies off.
        final lift = (_fly.value / 0.4).clamp(0.0, 1.0);
        final f = Curves.easeIn.transform(
          ((_fly.value - 0.4) / 0.6).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: 1 - f,
          child: Transform.translate(
            offset: Offset(f * 220, -f * 160),
            child: Transform.rotate(
              angle: -(lift * 0.35 + f * 0.6),
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        );
      },
      child: ClipPath(
        clipper: const _TearClipper(strip: true),
        child: BoosterFace(shine: 0.5 + _tilt.dx / 2),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipPath(
          clipper: const _TearClipper(strip: false),
          child: BoosterFace(shine: 0.5 + _tilt.dx / 2),
        ),
        strip,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.count;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: n > 0,
      label: widget.label,
      onTap: n > 0 ? _open : null,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _open,
        // Dragging only tilts the pile.
        onPanStart: (d) => _onMove(d.localPosition),
        onPanUpdate: (d) => _onMove(d.localPosition),
        onPanEnd: (_) => setState(() => _tilt = Offset.zero),
        child: SizedBox.fromSize(
          size: _box,
          child: TweenAnimationBuilder<Offset>(
            tween: Tween(end: _tilt),
            duration: const Duration(milliseconds: 200),
            builder: (context, tilt, _) => AnimatedBuilder(
              animation: _float,
              builder: (context, _) => Transform(
                alignment: Alignment.center,
                // Perspective, then lean toward the finger.
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateX(-tilt.dy * 0.3)
                  ..rotateY(tilt.dx * 0.3),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (n == 0)
                      Container(
                        width: _w,
                        height: _h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          border: Border.all(
                            color: scheme.onSurface.withValues(alpha: 0.25),
                            width: 2,
                          ),
                        ),
                      ),
                    // Bottom of the pile first; each floats on its own phase.
                    for (var depth = n - 1; depth >= 0; depth--)
                      Transform.translate(
                        offset:
                            _shifts[depth] +
                            // Deeper boosters move less with the finger: parallax.
                            tilt * (12.0 - depth * 3) +
                            Offset(
                              0,
                              6 * sin(2 * pi * (_float.value + depth * 0.19)),
                            ),
                        child: Transform.rotate(
                          angle: _angles[depth],
                          // The one shadow the Dawn rules allow: boosters are objects.
                          // It shifts against the tilt, as if lit from above.
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radius),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: Offset(-tilt.dx * 6, 6 - tilt.dy * 4),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: _w,
                              height: _h,
                              child: depth == 0
                                  ? _top()
                                  : BoosterFace(shine: 0.5 + tilt.dx / 3),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A point on the edge of a [size] box, [p] (0..1) of the way round from the top left,
/// pushed [out] beyond it.
Offset _onEdge(Size size, double p, double out) {
  final (w, h) = (size.width, size.height);
  final d = (p % 1) * 2 * (w + h);
  if (d < w) return Offset(d, -out);
  if (d < w + h) return Offset(w + out, d - w);
  if (d < 2 * w + h) return Offset(w - (d - w - h), h + out);
  return Offset(-out, h - (d - 2 * w - h));
}

/// A four-pointed star of radius [r] at [c].
Path _star(Offset c, double r) => Path()
  ..addPolygon([
    for (var i = 0; i < 8; i++)
      c +
          Offset(cos(i * pi / 4 - pi / 2), sin(i * pi / 4 - pi / 2)) *
              (i.isEven ? r : r * 0.25),
  ], true);

/// The reveal's effects at [ms] since it began, richer with the rarity [level] (0 common …
/// 4 legendary). [behind]: a glowing aura round the card; otherwise what shows over it:
/// firework sparks leaving its border, twinkling stars round the edge (uncommon+), glints
/// orbiting the edge (epic+), and a sheen across the card (legendary).
class _Sparkle extends CustomPainter {
  const _Sparkle(
    this.fx,
    this.ms,
    this.level,
    this.color, {
    required this.behind,
  });
  final _Effects fx;
  final double ms;
  final int level;
  final Color color;
  final bool behind;

  Color _tint(int i, double alpha) => (i.isEven ? color : Colors.white)
      .withValues(alpha: alpha.clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final end = _CardFlipState.lengthMs(level);
    final fade = ((end - ms) / 300).clamp(
      0.0,
      1.0,
    ); // everything fades at the end
    if (behind) {
      // An aura round the card in its rarity color, swelling then fading.
      final t = ((ms - 450) / (end - 450)).clamp(0.0, 1.0);
      if (t == 0 || t == 1) return;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).inflate(4 + 10 * t),
          const Radius.circular(radius + 8),
        ),
        Paint()
          ..color = color.withValues(alpha: (0.45 + 0.1 * level) * sin(pi * t))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14.0 + 3 * level),
      );
      return;
    }
    // Fireworks: sparks start on the card's border and fly outward with a short trail.
    final bt = ((ms - 450) / (700 + 100 * level)).clamp(0.0, 1.0);
    if (bt > 0 && bt < 1) {
      final e = Curves.easeOut.transform(bt);
      for (final (i, (p, speed, r)) in fx.burst.indexed) {
        final start = _onEdge(size, p, 0);
        final dir = (start - c) / (start - c).distance;
        final at = start + dir * size.width * 0.6 * speed * e;
        final paint = Paint()
          ..color = _tint(i, 0.95 * (1 - e))
          ..strokeWidth = r * 0.8
          ..strokeCap = StrokeCap.round;
        canvas
          ..drawLine(at - dir * 14 * (1 - e), at, paint)
          ..drawCircle(at, r * (1 - e * 0.6), paint);
      }
    }
    for (final (i, (p, out, phase, period, r)) in fx.twinkles.indexed) {
      final s = sin(2 * pi * (ms - 500) / period + phase);
      if (ms < 500 || s <= 0) continue;
      final at = _onEdge(size, p, out);
      canvas.drawPath(_star(at, r * s), Paint()..color = _tint(i, s * fade));
    }
    for (var i = 0; i < fx.orbits; i++) {
      if (ms < 500) break;
      final p = i / fx.orbits + (ms - 500) / (end - 500);
      final at = _onEdge(size, p, 2);
      canvas
        ..drawCircle(
          at,
          9,
          Paint()
            ..color = color.withValues(alpha: 0.6 * fade)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        )
        ..drawCircle(
          at,
          2.5,
          Paint()..color = Colors.white.withValues(alpha: fade),
        );
    }
    if (level == 4 && ms > 600 && ms < 1400) {
      // One sheen across the face, top left to bottom right.
      final x = (ms - 600) / 800 * 3 - 1.5;
      canvas
        ..save()
        ..clipRRect(
          RRect.fromRectAndRadius(
            Offset.zero & size,
            const Radius.circular(radius),
          ),
        )
        ..drawRect(
          Offset.zero & size,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment(x - 1, -1),
              end: Alignment(x + 1, 1),
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.4),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0.4, 0.5, 0.6],
            ).createShader(Offset.zero & size),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_Sparkle old) => old.ms != ms;
}

/// The random parts of one reveal, drawn once.
class _Effects {
  _Effects(int level) {
    final r = Random();
    burst = List.generate(
      const [12, 18, 26, 36, 50][level],
      (_) => (
        r.nextDouble(), // where on the card's border it starts
        0.3 + r.nextDouble() * (0.3 + 0.1 * level),
        1.5 + r.nextDouble() * 2 + 0.4 * level,
      ),
    );
    twinkles = List.generate(
      const [0, 6, 10, 14, 20][level],
      (_) => (
        r.nextDouble(), // where on the edge
        4 + r.nextDouble() * 14, // how far out
        r.nextDouble() * 2 * pi, // phase
        500 + r.nextDouble() * 400, // twinkle period, ms
        3 + r.nextDouble() * 4 + level, // size
      ),
    );
    orbits = const [0, 0, 0, 2, 3][level];
  }
  late final List<(double, double, double)> burst;
  late final List<(double, double, double, double, double)> twinkles;
  late final int orbits;
}

/// A card just won: it flips face up in place, from its [CardBack] to [child], with
/// sparkles of its [rarity] that grow richer from Common to Legendary.
class CardFlip extends StatefulWidget {
  const CardFlip({required this.rarity, required this.child, super.key});
  final String rarity;
  final Widget child;

  @override
  State<CardFlip> createState() => _CardFlipState();
}

class _CardFlipState extends State<CardFlip>
    with SingleTickerProviderStateMixin {
  /// The whole reveal: 1.1 s for a Common card, up to 2.5 s for a Legendary one.
  static double lengthMs(int level) => 1100.0 + 350 * level;

  late final int _level = max(0, tiers.indexOf(widget.rarity));
  late final _fx = _Effects(_level);
  late final _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: lengthMs(_level).round()),
  );
  // Haptics along the reveal (ms → feedback): a tick as the card starts to turn, a
  // strong buzz face up, then one light pop per rarity step with the sparkles.
  late final _haptics = <(double, Future<void> Function())>[
    (0, HapticFeedback.selectionClick),
    (275, HapticFeedback.heavyImpact),
    for (var i = 0; i <= _level; i++)
      (480.0 + 110 * i, HapticFeedback.lightImpact),
    if (_level == 4) (900, HapticFeedback.mediumImpact), // the Legendary sheen
  ];
  var _felt = 0;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      final ms = _c.value * lengthMs(_level);
      while (_felt < _haptics.length && _haptics[_felt].$1 <= ms) {
        _haptics[_felt++].$2();
      }
    });
    // Flip once the screen has finished sliding in, so the whole flip is seen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arriving = ModalRoute.of(context)?.animation;
      if (arriving == null || arriving.isCompleted) {
        _c.forward();
      } else {
        void go(AnimationStatus s) {
          if (s != AnimationStatus.completed) return;
          arriving.removeStatusListener(go);
          if (mounted) _c.forward();
        }

        arriving.addStatusListener(go);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Each face is painted once and reused while it turns: smooth frames.
    final front = RepaintBoundary(child: widget.child);
    const back = RepaintBoundary(child: CardBack());
    final color = rarityColor[widget.rarity] ?? rarityColor['common']!;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final ms = _c.value * lengthMs(_level);
        final flip =
            pi * Curves.easeInOutCubic.transform((ms / 550).clamp(0.0, 1.0));
        final faceUp = flip > pi / 2;
        final running = _c.isAnimating;
        Widget fx({required bool behind}) => Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _Sparkle(_fx, ms, _level, color, behind: behind),
            ),
          ),
        );
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (running) fx(behind: true),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(faceUp ? flip - pi : flip),
              child: faceUp ? front : back,
            ),
            if (running && faceUp) fx(behind: false),
          ],
        );
      },
    );
  }
}

/// A card shown in 3D, like the boosters: flat at rest, it follows the finger while
/// pressed and held (a long press, so swipes between cards still work). With [shine]
/// (Epic and Legendary cards), a glossy plastic reflection slides across it as it tilts;
/// it shows after [shineAfter], so it doesn't sit flat over a card that's still flipping.
class CardTilt extends StatefulWidget {
  const CardTilt({
    required this.child,
    this.shine = false,
    this.shineAfter = Duration.zero,
    super.key,
  });
  final Widget child;
  final bool shine;
  final Duration shineAfter;

  @override
  State<CardTilt> createState() => _CardTiltState();
}

class _CardTiltState extends State<CardTilt> {
  Offset? _finger; // -1..1 from the centre while held
  bool _shining = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.shineAfter, () {
      if (mounted) setState(() => _shining = true);
    });
  }

  void _follow(Offset p, Size size) => setState(() {
    _finger = Offset(
      (p.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
      (p.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
    );
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => GestureDetector(
      onLongPressStart: (d) => _follow(d.localPosition, box.biggest),
      onLongPressMoveUpdate: (d) => _follow(d.localPosition, box.biggest),
      onLongPressEnd: (_) => setState(() => _finger = null),
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(end: _finger ?? Offset.zero),
        duration: const Duration(milliseconds: 160),
        builder: (context, v, child) {
          // Where the highlight band sits: upper left at rest, sliding with the tilt.
          final s = -0.5 + 1.4 * v.dx + 0.7 * v.dy;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(-v.dy * 0.3)
              ..rotateY(v.dx * 0.3),
            child: Stack(
              children: [
                child!,
                if (widget.shine)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _shining ? 1 : 0,
                        duration: const Duration(milliseconds: 400),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(radius),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(s - 1, -1),
                                end: Alignment(s + 1, 1),
                                colors: [
                                  for (final a in const [
                                    0.0,
                                    0.1,
                                    0.32,
                                    0.1,
                                    0.0,
                                  ])
                                    Colors.white.withValues(alpha: a),
                                ],
                                stops: const [0.3, 0.45, 0.5, 0.55, 0.7],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        child: widget.child,
      ),
    ),
  );
}
