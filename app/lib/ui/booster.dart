import 'dart:math';

import 'package:flutter/gestures.dart';
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
    final x = shine * 3 - 1.5; // the sweep crosses the wrapper as shine goes 0 → 1
    return ClipRRect(
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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Logo(),
                const SizedBox(height: 16),
                Text(
                  'Early Bird',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) => const ClipPath(
    clipper: _TearClipper(strip: false),
    child: BoosterFace(),
  );
}

const boosterWidth = 200.0;
const boosterHeight = 290.0;

/// [count] boosters in a loose pile that floats and leans toward the finger. Swiping
/// across the top part of the top booster tears it open, then [onTorn] runs.
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
    duration: const Duration(milliseconds: 350),
  );
  Offset _tilt = Offset.zero; // -1..1 from the centre, follows the finger
  Offset? _start; // where a tear began
  double _tear = 0; // 0..1 how far the strip is lifted
  double _side = 1; // 1 = torn left to right

  @override
  void dispose() {
    _float.dispose();
    _fly.dispose();
    super.dispose();
  }

  Size get _box => const Size(_w + 2 * _margin, _h + 2 * _margin);

  void _onStart(DragStartDetails d) {
    final p = d.localPosition;
    // Tolerant: anywhere on the top half of the booster, or just above it.
    final inZone =
        p.dy > _margin - 32 &&
        p.dy < _margin + _h * 0.5 &&
        p.dx > _margin - 24 &&
        p.dx < _margin + _w + 24;
    _start = widget.count > 0 && !_fly.isAnimating && inZone ? p : null;    _onMove(d.localPosition);
  }

  void _onMove(Offset p) {
    final c = _box.center(Offset.zero);
    setState(() {
      _tilt = Offset(
        ((p.dx - c.dx) / (_box.width / 2)).clamp(-1.0, 1.0),
        ((p.dy - c.dy) / (_box.height / 2)).clamp(-1.0, 1.0),
      );
      if (_start case final s?) {
        final dx = p.dx - s.dx;
        if (dx.abs() > 4) _side = dx.sign;
        final t = (dx.abs() / (_w * 0.6)).clamp(0.0, 1.0);
        if ((t * 4).floor() > (_tear * 4).floor()) {
          HapticFeedback.selectionClick(); // a tick as the tear goes on
        }
        _tear = t;
      }
    });
  }

  Future<void> _onEnd(DragEndDetails d) async {
    final fling = d.velocity.pixelsPerSecond.dx.abs() > 600;    setState(() => _tilt = Offset.zero);
    if (_start == null) return;
    _start = null;
    if (_tear > 0.3 || (fling && _tear > 0.1)) {
      await _open();
    } else {
      setState(() => _tear = 0);
    }
  }

  Future<void> _open() async {
    HapticFeedback.mediumImpact();
    setState(() => _tear = 1);
    await _fly.forward(from: 0);
    widget.onTorn();
    if (mounted) {
      setState(() => _tear = 0);
      _fly.reset();
    }
  }

  Widget _top() {
    final strip = AnimatedBuilder(
      animation: _fly,
      builder: (_, child) {
        final f = Curves.easeIn.transform(_fly.value);
        return Opacity(
          opacity: 1 - f,
          child: Transform.translate(
            offset: Offset(_side * f * 220, -f * 160),
            child: Transform.rotate(
              angle: -_side * (_tear * 0.35 + f * 0.6),
              alignment: _side > 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
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
        // Measure the tear from where the finger landed, so quick flicks count.
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: _onStart,
        onPanUpdate: (d) => _onMove(d.localPosition),
        onPanEnd: _onEnd,
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
                          child: SizedBox(
                            width: _w,
                            height: _h,
                            child: depth == 0
                                ? _top()
                                : BoosterFace(shine: 0.5 + tilt.dx / 3),
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

/// The card reveal: the card rises (out of an open booster if [fromBooster]), flips from
/// its back to [front], and a burst of [color] spreads behind it; then [onDone].
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
    duration: const Duration(milliseconds: 1900),
  );
  bool _buzzed = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (!_buzzed && _c.value > 0.6) {
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
          // Rise: out of the booster (up, then back to the centre) or from below.
          final rise = widget.fromBooster
              ? -h * 0.55 * _phase(t, 0, 0.25) + h * 0.55 * _phase(t, 0.3, 0.45)
              : h * (1 - _phase(t, 0, 0.4));
          final flip = pi * _phase(t, 0.45, 0.75);
          final burst = _phase(t, 0.7, 1);
          final faceUp = flip > pi / 2;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (burst > 0)
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
              Transform.translate(
                offset: Offset(0, rise),
                child: Opacity(
                  opacity: widget.fromBooster
                      ? 1
                      : _phase(t, 0, 0.2), // fades in from below
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
              if (widget.fromBooster && t < 0.45)
                Transform.translate(
                  offset: Offset(0, h * 0.2 + h * _phase(t, 0.25, 0.45)),
                  child: Opacity(
                    opacity: 1 - _phase(t, 0.3, 0.45),
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
