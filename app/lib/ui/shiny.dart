import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Shiny cards (1.1) come in two looks, by the bird's aberration (a "treasure" exception
/// to the flat Dawn rules, like the Legendary gold):
/// - leucistic: diamond and ivory, a faceted brilliant-white frame that sparkles;
/// - melanistic: obsidian, deep glassy blacks with dark purple magma veins that glow.
bool isMelanistic(String? kind) => kind == 'melanistic';

/// The frame's material colour.
Color shinyFrameColor(String? kind) =>
    isMelanistic(kind) ? const Color(0xFF15121A) : const Color(0xFFF6F2E9);

/// The accent for stat bars, stars and the play button: readable on the paper face.
Color shinyAccent(String? kind) =>
    isMelanistic(kind) ? const Color(0xFF6E2AB0) : const Color(0xFF8396AE);

/// The reveal's firework colours.
List<Color> shinyPalette(String? kind) => isMelanistic(kind)
    ? const [
        Color(0xFF9B4DFF),
        Color(0xFFD08BFF),
        Color(0xFF6A1FC0),
        Color(0xFFFF7BE5),
      ]
    : const [
        Colors.white,
        Color(0xFFE6F3FF),
        Color(0xFFCADDF2),
        Color(0xFFFFF4DC),
      ];

/// The frame of a Shiny card, under the whole card (the face covers the middle).
void paintShinyFrame(Canvas canvas, Size size, String? kind) {
  final card = RRect.fromRectAndRadius(
    Offset.zero & size,
    const Radius.circular(radius),
  );
  canvas
    ..save()
    ..clipRRect(card);
  isMelanistic(kind) ? _obsidian(canvas, size) : _diamond(canvas, size);
  canvas.restore();
}

/// Ivory and diamond: a pearly white base with brilliant bands, cut into small facets
/// (light and shadowed triangles with bright edges), a hint of icy fire and glints.
void _diamond(Canvas canvas, Size size) {
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        const [
          Color(0xFFFFFFFF),
          Color(0xFFEDE7DB),
          Color(0xFFFDFCF8),
          Color(0xFFE2E0DC),
          Color(0xFFFFFFFF),
          Color(0xFFEAE4D8),
          Color(0xFFF9F7F2),
        ],
        const [0, 0.18, 0.33, 0.5, 0.62, 0.8, 1],
      ),
  );
  final r = Random(21); // the same cut on every leucistic card
  const step = 10.0;
  final cols = (size.width / step).ceil() + 1;
  final rows = (size.height / step).ceil() + 1;
  // A jittered grid of points, each cell cut in two triangles.
  final pts = [
    for (var y = 0; y <= rows; y++)
      [
        for (var x = 0; x <= cols; x++)
          Offset(
            x * step + (r.nextDouble() - 0.5) * step * 0.7,
            y * step + (r.nextDouble() - 0.5) * step * 0.7,
          ),
      ],
  ];
  final edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.45
    ..color = Colors.white.withValues(alpha: 0.75);
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < cols; x++) {
      final (a, b, c, d) = (
        pts[y][x],
        pts[y][x + 1],
        pts[y + 1][x + 1],
        pts[y + 1][x],
      );
      for (final tri in [
        [a, b, c],
        [a, c, d],
      ]) {
        final roll = r.nextDouble();
        final fill = roll < 0.06
            ? const Color(0xFFBFDCF5).withValues(alpha: 0.45) // icy fire
            : roll < 0.5
            ? Colors.white.withValues(alpha: 0.35 + r.nextDouble() * 0.4)
            : const Color(0xFFC9CCD4)
                  .withValues(alpha: 0.12 + r.nextDouble() * 0.2);
        final path = Path()..addPolygon(tri, true);
        canvas
          ..drawPath(path, Paint()..color = fill)
          ..drawPath(path, edge);
      }
    }
  }
  final glint = Paint()..color = Colors.white;
  for (var i = 0; i < size.width * size.height / 900; i++) {
    final c = Offset(r.nextDouble() * size.width, r.nextDouble() * size.height);
    canvas.drawPath(starPath(c, 1.2 + r.nextDouble() * 1.8), glint);
  }
}

/// Obsidian: deep glassy black with sharp reflections, the shell-like ripples of
/// volcanic glass, and dormant magma veins (they glow in [MagmaVeins]).
void _obsidian(Canvas canvas, Size size) {
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        const [
          Color(0xFF070609),
          Color(0xFF1D1924),
          Color(0xFF0B0A0E),
          Color(0xFF2C2635),
          Color(0xFF09080B),
          Color(0xFF16121B),
          Color(0xFF050407),
        ],
        const [0, 0.16, 0.3, 0.45, 0.6, 0.8, 1],
      ),
  );
  final r = Random(23);
  // Conchoidal fracture: sets of concentric arcs, as on a knapped flint.
  for (var i = 0; i < 26; i++) {
    final c = Offset(r.nextDouble() * size.width, r.nextDouble() * size.height);
    final start = r.nextDouble() * 2 * pi;
    for (var k = 1; k <= 5; k++) {
      final rad = 6.0 + k * (4 + r.nextDouble() * 3);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: rad),
        start,
        1.2 + r.nextDouble(),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = Colors.white.withValues(alpha: 0.05 + 0.02 * (5 - k)),
      );
    }
  }
  // Glassy specks.
  for (var i = 0; i < size.width * size.height / 120; i++) {
    canvas.drawCircle(
      Offset(r.nextDouble() * size.width, r.nextDouble() * size.height),
      0.4 + r.nextDouble() * 0.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05 + r.nextDouble() * 0.08),
    );
  }
  // The veins, dormant: dark purple with a soft halo.
  for (final v in magmaVeins(size)) {
    canvas
      ..drawPath(
        v,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFF3A1263).withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      )
      ..drawPath(
        v,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF4F1A86),
      );
  }
}

final _veins = <Size, List<Path>>{};

/// Branching cracks across the card, the same on every melanistic card of a size.
List<Path> magmaVeins(Size size) => _veins.putIfAbsent(size, () {
  final r = Random(29);
  final veins = <Path>[];
  void crack(Offset p, double angle, int steps) {
    final path = Path()..moveTo(p.dx, p.dy);
    for (var i = 0; i < steps; i++) {
      angle += (r.nextDouble() - 0.5) * 0.9;
      p += Offset(cos(angle), sin(angle)) * (6 + r.nextDouble() * 8);
      path.lineTo(p.dx, p.dy);
      if (r.nextDouble() < 0.18 && steps > 4) {
        crack(
          p,
          angle + (r.nextBool() ? 1 : -1) * (0.6 + r.nextDouble()),
          steps ~/ 2,
        );
      }
    }
    veins.add(path);
  }

  final (w, h) = (size.width, size.height);
  for (var i = 0; i < 9; i++) {
    // Starting on the edge, heading inward.
    final side = i % 4;
    final t = r.nextDouble();
    final (start, angle) = switch (side) {
      0 => (Offset(t * w, 0), pi / 2),
      1 => (Offset(w, t * h), pi),
      2 => (Offset(t * w, h), -pi / 2),
      _ => (Offset(0, t * h), 0.0),
    };
    crack(start, angle + (r.nextDouble() - 0.5), 9 + r.nextInt(6));
  }
  return veins;
});

/// A four-pointed star of radius [r] at [c].
Path starPath(Offset c, double r) => Path()
  ..addPolygon([
    for (var i = 0; i < 8; i++)
      c +
          Offset(cos(i * pi / 4 - pi / 2), sin(i * pi / 4 - pi / 2)) *
              (i.isEven ? r : r * 0.22),
  ], true);

/// The face's card stock on a Shiny card, faint enough for the text: a blurred diamond's
/// facets (leucistic), or blurred smoky obsidian ripples with a violet tint (melanistic).
void paintShinyStock(Canvas canvas, Size size, String? kind) {
  final c = size.center(Offset.zero);
  if (isMelanistic(kind)) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF6E2AB0).withValues(alpha: 0.04),
    );
    final r = Random(31);
    final smoke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0xFF2A1840).withValues(alpha: 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (var i = 0; i < 7; i++) {
      final o = Offset(
        r.nextDouble() * size.width,
        r.nextDouble() * size.height,
      );
      for (var k = 1; k <= 4; k++) {
        canvas.drawArc(
          Rect.fromCircle(center: o, radius: 18.0 * k),
          r.nextDouble() * 2 * pi,
          1.6,
          false,
          smoke,
        );
      }
    }
    return;
  }
  // A brilliant cut seen from above, blown up and blurred: a table, star facets and
  // kite facets radiating from the centre, alternately lit and shadowed.
  final rad = size.longestSide * 0.62;
  final blur = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  const n = 16;
  Offset at(double a, double f) => c + Offset(cos(a), sin(a) * 1.15) * rad * f;
  for (var i = 0; i < n; i++) {
    final a0 = 2 * pi * i / n, a1 = 2 * pi * (i + 1) / n, am = (a0 + a1) / 2;
    final lit = i.isEven;
    canvas
      ..drawPath(
        Path()..addPolygon([at(a0, 0.28), at(am, 0.55), at(a1, 0.28)], true),
        blur
          ..color = (lit ? const Color(0xFF9FB0C8) : Colors.white).withValues(
            alpha: lit ? 0.10 : 0.0,
          ),
      )
      ..drawPath(
        Path()..addPolygon([at(am, 0.55), at(a0, 1.0), at(a1, 1.0)], true),
        blur
          ..color = const Color(0xFF9FB0C8)
              .withValues(alpha: lit ? 0.04 : 0.09),
      );
  }
  canvas.drawPath(
    Path()
      ..addPolygon([for (var i = 0; i < 8; i++) at(2 * pi * i / 8, 0.3)], true),
    blur..color = const Color(0xFFB8C6D8).withValues(alpha: 0.07),
  );
}

/// The living part of a Shiny card, over its frame: sparkles twinkling along a
/// leucistic frame, or magma pulsing through a melanistic card's veins. [above]: the
/// layer over the face (sparkles); otherwise the one under it (veins).
class ShinyLife extends StatefulWidget {
  const ShinyLife({
    required this.kind,
    required this.inset,
    required this.above,
    super.key,
  });
  final String? kind;
  final double inset;
  final bool above;

  @override
  State<ShinyLife> createState() => _ShinyLifeState();
}

class _ShinyLifeState extends State<ShinyLife>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: isMelanistic(widget.kind)
            ? (widget.above ? null : _MagmaPainter(_c))
            : (widget.above ? _SparklePainter(_c, widget.inset) : null),
      ),
    ),
  );
}

/// Magma running through the veins: each one pulses on its own rhythm, and a bright
/// molten bead travels along it.
class _MagmaPainter extends CustomPainter {
  _MagmaPainter(this.t) : super(repaint: t);
  final Animation<double> t;
  static final _metrics = <Size, List<(Path, ui.PathMetric)>>{};

  @override
  void paint(Canvas canvas, Size size) {
    final veins = _metrics.putIfAbsent(
      size,
      () => [
        for (final v in magmaVeins(size))
          for (final m in v.computeMetrics()) (v, m),
      ],
    );
    canvas
      ..save()
      ..clipRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(radius),
        ),
      );
    for (final (i, (path, m)) in veins.indexed) {
      final pulse = 0.5 + 0.5 * sin(2 * pi * (t.value * 2 + i * 0.37));
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF8A3BE0)
              .withValues(alpha: 0.25 + 0.45 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      final at = ((t.value * (1 + i % 3 * 0.5) + i * 0.29) % 1) * m.length;
      canvas.drawPath(
        m.extractPath(at, at + 18),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFE2A6FF).withValues(alpha: 0.9),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MagmaPainter old) => false;
}

/// Diamond sparkles: four-pointed stars that flare and fade at random spots of the frame,
/// each with a soft halo.
class _SparklePainter extends CustomPainter {
  _SparklePainter(this.t, this.inset) : super(repaint: t);
  final Animation<double> t;
  final double inset;
  static final _spots = <Size, List<(Offset, double, double)>>{};

  @override
  void paint(Canvas canvas, Size size) {
    final spots = _spots.putIfAbsent(size, () {
      final r = Random(37);
      return [
        for (var i = 0; i < 34; i++)
          (
            // On the frame band, all the way round.
            _onBand(size, r.nextDouble(), r.nextDouble() * inset),
            r.nextDouble(), // phase
            2.5 + r.nextDouble() * 4, // size
          ),
      ];
    });
    for (final (c, phase, s) in spots) {
      // Each flares briefly, twice per cycle, at its own moment.
      final x = (t.value * 2 + phase) % 1;
      if (x > 0.18) continue;
      final k = sin(pi * x / 0.18);
      canvas
        ..drawCircle(
          c,
          s * 2.2 * k,
          Paint()
            ..color = const Color(0xFFDDEEFF).withValues(alpha: 0.5 * k)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        )
        ..drawPath(
          starPath(c, s * 1.6 * k),
          Paint()..color = Colors.white.withValues(alpha: k),
        );
    }
  }

  static Offset _onBand(Size size, double p, double depth) {
    final (w, h) = (size.width, size.height);
    final d = p * 2 * (w + h);
    if (d < w) return Offset(d, depth);
    if (d < w + h) return Offset(w - depth, d - w);
    if (d < 2 * w + h) return Offset(w - (d - w - h), h - depth);
    return Offset(depth, h - (d - 2 * w - h));
  }

  @override
  bool shouldRepaint(_SparklePainter old) => false;
}
