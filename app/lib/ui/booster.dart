import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// The bottom part of a torn booster.
class OpenBooster extends StatelessWidget {
  const OpenBooster({super.key});

  @override
  Widget build(BuildContext context) =>
      const ClipPath(clipper: _TearClipper(strip: false), child: BoosterFace());
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
    HapticFeedback.mediumImpact();
    final flown = _fly.forward(from: 0);
    // The quiz starts fading in while the strip is still flying off.
    await Future<void>.delayed(const Duration(milliseconds: 150));
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

/// Sparks flying out from behind the card in its rarity [color] (and some white),
/// shrinking and fading as [t] goes 0 → 1.
class _Sparks extends CustomPainter {
  const _Sparks(this.sparks, this.t, this.color, this.reach);
  final List<(double, double, double)> sparks;
  final double t, reach;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (final (i, (angle, speed, r)) in sparks.indexed) {
      final d = reach * speed * t;
      canvas.drawCircle(
        c + Offset(cos(angle), sin(angle)) * d,
        r * (1 - t * 0.7),
        Paint()
          ..color = (i.isEven ? color : Colors.white).withValues(alpha: 1 - t),
      );
    }
  }

  @override
  bool shouldRepaint(_Sparks old) => old.t != t;
}

/// The card reveal (0.9 s): the card flips on the spot from its back to [front] while
/// the open booster drops away ([fromBooster]; alarms: it rises from just below),
/// then a burst and sparks of [color] spread behind it; then [onDone].
class CardReveal extends StatefulWidget {
  const CardReveal({
    required this.front,
    required this.color,
    required this.onDone,
    this.fromBooster = false,
    super.key,
  });
  final Widget front;
  final Color color;
  final VoidCallback onDone;
  final bool fromBooster;

  @override
  State<CardReveal> createState() => _CardRevealState();
}

class _CardRevealState extends State<CardReveal>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _buzzed = false;
  // Particles: an angle, a reach and a size each, fixed for this reveal.
  late final List<(double, double, double)> _sparks;

  @override
  void initState() {
    super.initState();
    final r = Random();
    _sparks = List.generate(
      28,
      (_) => (
        r.nextDouble() * 2 * pi,
        0.5 + r.nextDouble() * 0.7,
        2 + r.nextDouble() * 4,
      ),
    );
    _c.addListener(() {
      if (!_buzzed && _c.value > 0.35) {
        _buzzed = true;
        HapticFeedback.heavyImpact(); // the card turns face up
      }
    });
    _c.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// [t] mapped to 0..1 over [a]..[b] of the animation, eased.
  double _phase(double t, double a, double b) =>
      Curves.easeInOut.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = min(box.maxWidth - 48, (box.maxHeight - 48) * 0.68);
      final h = w / 0.68;
      return AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          // The card is already out: the booster drops away while it flips on the
          // spot (alarms: it rises from just below), then the burst and sparks.
          final rise = widget.fromBooster
              ? 0.0
              : h * 0.3 * (1 - _phase(t, 0, 0.3));
          final flip = pi * _phase(t, 0.1, 0.55);
          final burst = Curves.easeOut.transform(
            ((t - 0.45) / 0.55).clamp(0.0, 1.0),
          );
          final faceUp = flip > pi / 2;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (burst > 0) ...[
                Opacity(
                  opacity: 0.6 * (1 - burst),
                  child: Container(
                    width: w * (0.8 + burst),
                    height: w * (0.8 + burst),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color,
                    ),
                  ),
                ),
                CustomPaint(
                  size: Size(w, h),
                  painter: _Sparks(_sparks, burst, widget.color, w),
                ),
              ],
              Transform.translate(
                offset: Offset(0, rise),
                child: Opacity(
                  opacity: widget.fromBooster
                      ? 1
                      : _phase(t, 0, 0.15), // fades in from below
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(faceUp ? flip - pi : flip),
                    child: SizedBox(
                      width: w,
                      height: h,
                      child: faceUp ? widget.front : const CardBack(),
                    ),
                  ),
                ),
              ),
              // The open booster, in front of the card, then dropping away.
              if (widget.fromBooster && t < 0.35)
                Transform.translate(
                  offset: Offset(0, h * 0.35 + h * _phase(t, 0, 0.35)),
                  child: Opacity(
                    opacity: 1 - _phase(t, 0.1, 0.35),
                    child: SizedBox(
                      width: w * 1.08,
                      height: h * 1.08,
                      child: const OpenBooster(),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}
