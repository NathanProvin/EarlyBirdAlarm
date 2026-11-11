import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Shiny cards (1.1) come in two looks, by the bird's aberration (a "treasure" exception
/// to the flat Dawn rules, like the Legendary gold):
/// - leucistic: diamond and ivory, a faceted brilliant-white frame that sparkles, the face
///   printed with blurred diamond facets;
/// - melanistic: obsidian, a dark card (white text) with blurred dark purple magma veins
///   glowing through the frame and behind the face.
/// Both frames carry a knurled band with a light running round it.
bool isMelanistic(String? kind) => kind == 'melanistic';

/// The frame's material colour.
Color shinyFrameColor(String? kind) =>
    isMelanistic(kind) ? const Color(0xFF15121A) : const Color(0xFFF6F2E9);

/// The accent for stat bars, stars and the play button, readable on the card's face:
/// steel blue on the ivory paper, light violet on the obsidian.
Color shinyAccent(String? kind) =>
    isMelanistic(kind) ? const Color(0xFFB57CFF) : const Color(0xFF8396AE);

/// The melanistic face: obsidian, a little see-through so the veins glow behind it.
const obsidianFace = Color(0xC0141118);

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

/// The band where the frame's knurling and its running light sit, [inset] wide frame.
RRect _band(Size size, double inset) => RRect.fromRectAndRadius(
  (Offset.zero & size).deflate(inset * 0.5),
  Radius.circular(radius - inset * 0.5),
);

/// The frame of a Shiny card, under the whole card (the face covers the middle).
void paintShinyFrame(Canvas canvas, Size size, String? kind, double inset) {
  final card = RRect.fromRectAndRadius(
    Offset.zero & size,
    const Radius.circular(radius),
  );
  canvas
    ..save()
    ..clipRRect(card);
  final dark = isMelanistic(kind);
  dark ? _obsidian(canvas, size) : _diamond(canvas, size);
  _knurl(canvas, size, inset, dark);
  canvas.restore();
}

/// A knurled band: fine slanted ridges all the way round, each lit on one side and
/// shaded on the other, like the milled edge of a coin.
void _knurl(Canvas canvas, Size size, double inset, bool dark) {
  final band = _band(size, inset);
  final w = inset * 0.42;
  final (lit, shade) = dark
      ? (const Color(0x30FFFFFF), const Color(0xCC000000))
      : (const Color(0xFFFFFFFF), const Color(0x55707888));
  // The band's bed, a shade darker than the frame.
  canvas.drawRRect(
    band,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = dark ? const Color(0x66000000) : const Color(0x22808898),
  );
  final ridge = Paint()
    ..color = shade
    ..strokeWidth = 0.7;
  final light = Paint()
    ..color = lit
    ..strokeWidth = 0.5;
  for (final m in (Path()..addRRect(band)).computeMetrics()) {
    for (var d = 0.0; d < m.length; d += 2.4) {
      final t = m.getTangentForOffset(d)!;
      final n = Offset(-t.vector.dy, t.vector.dx); // across the band
      final a = t.position - n * w / 2 - t.vector * w * 0.3;
      final b = t.position + n * w / 2 + t.vector * w * 0.3;
      canvas
        ..drawLine(a, b, ridge)
        ..drawLine(a + t.vector * 0.8, b + t.vector * 0.8, light);
    }
  }
  // Fine edges on both sides of the band.
  for (final e in [-w / 2, w / 2]) {
    canvas.drawRRect(
      band.inflate(e),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = dark ? const Color(0x40FFFFFF) : const Color(0x998894A6),
    );
  }
}

/// Facets: a jittered grid of points, each cell cut in two triangles, each lit, shaded
/// or (rarely) touched with icy fire, with bright facet edges; [strength] scales them.
void _facets(
  Canvas canvas,
  Size size, {
  required int seed,
  required double step,
  required double strength,
}) {
  final r = Random(seed);
  final cols = (size.width / step).ceil() + 1;
  final rows = (size.height / step).ceil() + 1;
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
    ..color = Colors.white.withValues(alpha: 0.75 * strength);
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
            ? const Color(0xFFBFDCF5).withValues(alpha: 0.45 * strength)
            : roll < 0.5
            ? Colors.white.withValues(
                alpha: (0.35 + r.nextDouble() * 0.4) * strength,
              )
            : const Color(0xFFB9BEC9)
                  .withValues(alpha: (0.12 + r.nextDouble() * 0.2) * strength);
        final path = Path()..addPolygon(tri, true);
        canvas
          ..drawPath(path, Paint()..color = fill)
          ..drawPath(path, edge);
      }
    }
  }
}

/// Ivory and diamond: a pearly white base with brilliant bands, cut into small facets,
/// with glints.
void _diamond(Canvas canvas, Size size) {
  canvas.drawRect(
    Offset.zero & size,
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
  _facets(canvas, size, seed: 21, step: 10, strength: 1);
  final r = Random(22);
  final glint = Paint()..color = Colors.white;
  for (var i = 0; i < size.width * size.height / 900; i++) {
    final c = Offset(r.nextDouble() * size.width, r.nextDouble() * size.height);
    canvas.drawPath(starPath(c, 1.2 + r.nextDouble() * 1.8), glint);
  }
}

/// Obsidian: deep glassy black with sharp reflections and the shell-like ripples of
/// volcanic glass (its veins glow in [ShinyLife]).
void _obsidian(Canvas canvas, Size size) {
  canvas.drawRect(
    Offset.zero & size,
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
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 6.0 + k * (4 + r.nextDouble() * 3)),
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
  for (var i = 0; i < size.width * size.height / 120; i++) {
    canvas.drawCircle(
      Offset(r.nextDouble() * size.width, r.nextDouble() * size.height),
      0.4 + r.nextDouble() * 0.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05 + r.nextDouble() * 0.08),
    );
  }
}

final _veins = <Size, List<Path>>{};

/// Branching cracks over the whole card, from its edges and from inside, the same on
/// every melanistic card of a size.
List<Path> magmaVeins(Size size) => _veins.putIfAbsent(size, () {
  final r = Random(29);
  final veins = <Path>[];
  void crack(Offset p, double angle, int steps) {
    final path = Path()..moveTo(p.dx, p.dy);
    for (var i = 0; i < steps; i++) {
      angle += (r.nextDouble() - 0.5) * 0.9;
      p += Offset(cos(angle), sin(angle)) * (7 + r.nextDouble() * 9);
      path.lineTo(p.dx, p.dy);
      if (r.nextDouble() < 0.16 && steps > 4) {
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
  for (var i = 0; i < 10; i++) {
    final t = r.nextDouble();
    final (start, angle) = switch (i % 4) {
      0 => (Offset(t * w, 0), pi / 2),
      1 => (Offset(w, t * h), pi),
      2 => (Offset(t * w, h), -pi / 2),
      _ => (Offset(0, t * h), 0.0),
    };
    crack(start, angle + (r.nextDouble() - 0.5), 10 + r.nextInt(8));
  }
  for (var i = 0; i < 4; i++) {
    // Some open inside the card, behind the face.
    crack(
      Offset(
        w * (0.2 + 0.6 * r.nextDouble()),
        h * (0.2 + 0.6 * r.nextDouble()),
      ),
      r.nextDouble() * 2 * pi,
      10 + r.nextInt(6),
    );
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

/// The face's card stock on a Shiny card: the frame's diamond facets, larger and blurred
/// soft (leucistic), or faint smoky ripples on the obsidian (melanistic).
void paintShinyStock(Canvas canvas, Size size, String? kind) {
  final rect = Offset.zero & size;
  if (isMelanistic(kind)) {
    final r = Random(31);
    final smoke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.white.withValues(alpha: 0.035)
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
  canvas
    ..saveLayer(
      rect,
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
    )
    ..drawRect(rect, Paint()..color = const Color(0xFFF1F0EC));
  _facets(canvas, size, seed: 41, step: 30, strength: 0.75);
  canvas.restore();
}

/// The living part of a Shiny card: [above] the face, diamond sparkles on a leucistic
/// frame; under it, the light running round the knurled band and, on a melanistic card,
/// the magma veins (the see-through obsidian face lets them glow behind the text).
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
  Widget build(BuildContext context) {
    final dark = isMelanistic(widget.kind);
    if (widget.above && dark) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: widget.above
              ? _SparklePainter(_c, widget.inset)
              : _UnderPainter(_c, widget.inset, dark),
        ),
      ),
    );
  }
}

/// Under the face: the band's running light, and on obsidian the magma. Smooth on any
/// phone: the blurred veins are drawn once into two images that pulse out of step (no blur
/// per frame), and the molten beads are plain soft dots placed along the veins.
class _UnderPainter extends CustomPainter {
  _UnderPainter(this.t, this.inset, this.dark) : super(repaint: t);
  final Animation<double> t;
  final double inset;
  final bool dark;
  static final _glow = <Size, (ui.Image, ui.Image)>{};
  static final _metrics = <Size, List<ui.PathMetric>>{};

  static ui.Image _veinImage(Size size, List<Path> veins) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    for (final v in veins) {
      c
        ..drawPath(
          v,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..color = const Color(0xFF5B1FA6).withValues(alpha: 0.7)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
        )
        ..drawPath(
          v,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = const Color(0xFF9A55F0)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
        );
    }
    return rec.endRecording().toImageSync(
      size.width.ceil(),
      size.height.ceil(),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final v = t.value;
    canvas
      ..save()
      ..clipRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(radius),
        ),
      );
    if (dark) {
      final veins = magmaVeins(size);
      final (a, b) = _glow.putIfAbsent(
        size,
        () => (
          _veinImage(size, [
            for (var i = 0; i < veins.length; i += 2) veins[i],
          ]),
          _veinImage(size, [
            for (var i = 1; i < veins.length; i += 2) veins[i],
          ]),
        ),
      );
      final pulse = sin(2 * pi * v * 2);
      for (final (img, p) in [(a, pulse), (b, -pulse)]) {
        canvas.drawImage(
          img,
          Offset.zero,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.55 + 0.45 * p)
            ..filterQuality = FilterQuality.low,
        );
      }
      final metrics = _metrics.putIfAbsent(
        size,
        () => [for (final p in veins) ...p.computeMetrics()],
      );
      final halo = Paint()
        ..color = const Color(0xFFC890FF).withValues(alpha: 0.22);
      final core = Paint()
        ..color = const Color(0xFFF0D8FF).withValues(alpha: 0.75);
      for (final (i, m) in metrics.indexed) {
        final d = ((v * (1 + i % 3 * 0.5) + i * 0.29) % 1) * m.length;
        final at = m.getTangentForOffset(d)?.position;
        if (at == null) continue;
        canvas
          ..drawCircle(at, 6, halo)
          ..drawCircle(at, 3, halo)
          ..drawCircle(at, 1.4, core);
      }
    }
    // Two lights running round the knurled band, opposite each other.
    final rect = Offset.zero & size;
    final hi = dark ? const Color(0xFFC38BFF) : Colors.white;
    final clear = hi.withValues(alpha: 0);
    canvas
      ..drawRRect(
        _band(size, inset),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = inset * 0.42
          ..shader = SweepGradient(
            colors: [clear, hi, clear, clear, hi, clear, clear],
            stops: const [0, 0.05, 0.1, 0.5, 0.55, 0.6, 1],
            transform: GradientRotation(2 * pi * v),
          ).createShader(rect),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_UnderPainter old) =>
      old.dark != dark || old.inset != inset;
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
          Paint()..color = const Color(0xFFDDEEFF).withValues(alpha: 0.35 * k),
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
