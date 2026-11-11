import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

import '../birds.dart';
import '../cards.dart';
import '../content.dart';
import '../l10n/app_localizations.dart';
import 'shiny.dart';
import 'theme.dart';

String rarityName(AppLocalizations l, String tier) => switch (tier) {
  'common' => l.common,
  'uncommon' => l.uncommon,
  'rare' => l.rare,
  'epic' => l.epic,
  'shiny' => l.shiny,
  _ => l.legendary,
};

/// "Leucistic" / "Melanistic": what a Shiny card's header says instead of its rarity.
String shinyKindName(AppLocalizations l, String? kind) =>
    kind == 'melanistic' ? l.melanistic : l.leucistic;

/// The full trading card. Without [card] the bird is only "heard": a grey, blurred card
/// showing just its name and "Try next time!".
class BirdCardView extends StatelessWidget {
  const BirdCardView({required this.bird, this.card, this.play, super.key});
  final Bird bird;
  final CardData? card;
  final String?
  play; // a heard card's recording: a play button under "Try next time"

  @override
  Widget build(BuildContext context) => Theme(
    data: cardTheme,
    child: Builder(builder: _build),
  );

  Widget _build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final card = this.card;
    final rarity =
        card?.rarity ??
        bird.rarity; // the card keeps the rarity it was won with
    final shiny = card != null && rarity == 'shiny';
    final kind = shiny ? bird.photoOf(card.photo).kind : null;
    final ivory =
        shiny && !isMelanistic(kind); // a light frame: dark header text
    final frame = card == null
        ? unknownColor
        : shiny
        ? shinyAccent(kind)
        : rarityColor[rarity]!;
    // Shiny looks: 5 leucistic (diamond), 6 melanistic (obsidian); see shiny.dart.
    final level = shiny
        ? (isMelanistic(kind) ? 6 : 5)
        : max(0, tiers.indexOf(rarity));
    final label = text.labelLarge?.copyWith(
      color: card == null || ivory ? ink : paper,
      fontWeight: FontWeight.bold,
      // Lifts the light text off the textured (and, on gold, bright) frame.
      shadows: card == null
          ? null
          : [
              Shadow(
                color: ivory ? Colors.white : Color.lerp(frame, ink, 0.7)!,
                offset: const Offset(0, 1),
                blurRadius: ivory ? 3 : 0,
              ),
            ],
    );
    final recording = bird.recordings
        .where((r) => r.file == card?.recording)
        .firstOrNull;
    final face = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(radius - 6),
        // A won card's thickness: a thin dark band where the face meets the frame.
        boxShadow: card == null
            ? null
            : [
                BoxShadow(
                  color: Color.lerp(frame, ink, 0.55)!.withValues(alpha: 0.45),
                  spreadRadius: 1.2,
                ),
              ],
      ),
      // A won card is printed on textured card stock tinted with its rarity.
      child: CustomPaint(
        painter: card == null ? null : _CardStock(frame, level, kind),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(radius - 8),
                      child: BirdPhoto(bird, photo: card?.photo),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bird.nameIn(l.localeName),
                          style: text.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(bird.latin, style: _latin(text)),
                      ],
                    ),
                  ),
                  // The recording this card was won with, to hear it again.
                  if (recording != null)
                    Column(
                      children: [
                        PlayButton(recording.file, color: frame),
                        Text(kindName(l, recording.kind), style: _latin(text)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // The stars of the region where the card was won (older cards: this region's).
              if (card?.level ?? bird.level case final level?)
                _RarityRow(label: l.birdRarity, level: level, color: frame),
              for (final key in statKeys)
                if (bird.stats.containsKey(
                  key,
                )) // unknown for this species: no row
                  _StatRow(
                    label: statName(l, key),
                    value: card?.stats[key],
                    stat: key,
                    bird: bird,
                    color: frame,
                  ),
            ],
          ),
        ),
      ),
    );
    final inset = (rarity == 'legendary' || rarity == 'shiny') && card != null
        ? 14.0
        : 8.0;
    // The card is a fixed-size picture: text grows with the phone's font size, up to 1.3×.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: AspectRatio(
        aspectRatio: 0.68,
        // A won card's frame is made of its rarity's material; a heard one stays plain.
        child: CustomPaint(
          painter: card == null
              ? _PlainFrame(frame)
              : _FrameMaterial(
                  shiny ? shinyFrameColor(kind) : frame,
                  level,
                  inset,
                  MediaQuery.devicePixelRatioOf(context),
                ),
          child: Stack(
            children: [
              // A Shiny card lives: magma under the face, sparkles over it.
              if (shiny)
                Positioned.fill(
                  child: ShinyLife(kind: kind, inset: inset, above: false),
                ),
              Padding(
                padding: EdgeInsets.all(inset),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '#${bird.number.toString().padLeft(3, '0')}',
                              style: label,
                            ),
                          ),
                          // Shrinks rather than squeezing the number and the
                          // quality ("Shiny · Melanistic").
                          Flexible(
                            flex: 2,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                card == null
                                    ? l.heard
                                    : shiny
                                    ? '${l.shiny} · ${shinyKindName(l, kind)}'
                                    : rarityName(l, rarity),
                                style: label,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              card == null ? '' : '${card.quality} %',
                              style: label,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: card != null
                          ? face
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                ImageFiltered(
                                  imageFilter: ui.ImageFilter.blur(
                                    sigmaX: 8,
                                    sigmaY: 8,
                                  ),
                                  child: ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      Colors.grey,
                                      BlendMode.saturation,
                                    ),
                                    child: face,
                                  ),
                                ),
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          bird.nameIn(l.localeName),
                                          style: text.headlineSmall,
                                          textAlign: TextAlign.center,
                                        ),
                                        Text(bird.latin, style: _latin(text)),
                                        const SizedBox(height: 16),
                                        Text(
                                          l.tryNextTime,
                                          style: text.titleMedium,
                                        ),
                                        if (play case final file?) ...[
                                          const SizedBox(height: 12),
                                          PlayButton(file, glass: true),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              if (shiny)
                Positioned.fill(
                  child: ShinyLife(kind: kind, inset: inset, above: true),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The background of a won card: card stock tinted with its rarity [color] and printed
/// with the pattern of its rarity [level] (0 Common … 4 Legendary), all equally faint so
/// the text reads as on plain paper: a guilloche (interlaced waves, as on a banknote) for
/// Common and Uncommon, a coarse paper grain for Rare, the soft shadow of foliage for
/// Epic, and a golden camouflage for Legendary.
class _CardStock extends CustomPainter {
  const _CardStock(this.color, this.level, [this.kind]);
  final Color color;
  final int level; // 5 and 6: Shiny, leucistic and melanistic (shiny.dart)
  final String? kind;

  /// Each pattern is drawn once per size into an image (blurred leaves and thousands of
  /// specks are too slow to redraw), at 2× — enough for patterns this faint.
  // shortcut: never evicted, fine for the few card sizes the app shows.
  static final _images = <(Color, int, Size), ui.Image>{};
  static const _res = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final image = _images.putIfAbsent((color, level, size), () {
      final recorder = ui.PictureRecorder();
      _draw(Canvas(recorder)..scale(_res), size);
      return recorder.endRecording().toImageSync(
        (size.width * _res).ceil(),
        (size.height * _res).ceil(),
      );
    });
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      Offset.zero & Size(image.width / _res, image.height / _res),
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  void _draw(Canvas canvas, Size size) {
    if (level >= 5) return paintShinyStock(canvas, size, kind);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = color.withValues(alpha: 0.05),
    );
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = color.withValues(alpha: 0.12);
    switch (level) {
      case 2:
        paintGrain(canvas, size, Color.lerp(color, ink, 0.5)!, alpha: 0.16);
      case 3:
        _foliage(canvas, size);
      case 4:
        _camouflage(canvas, size);
      default:
        _guilloche(canvas, size, line);
    }
  }

  void _guilloche(Canvas canvas, Size size, Paint line) {
    const gap = 12.0;
    for (var row = -1; row < size.height / gap + 1; row++) {
      for (final phase in [0.0, pi]) {
        final path = Path();
        for (var x = 0.0; x <= size.width; x += 3) {
          final y = row * gap + 7 * sin(x / 20 + phase + row * 0.5);
          x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        canvas.drawPath(path, line);
      }
    }
  }

  /// The blurred shadow of leaves, as if the card lay under a branch.
  void _foliage(Canvas canvas, Size size) {
    final r = Random(7); // the same branch on every Epic card
    final shade = Paint()
      ..color = Color.lerp(color, ink, 0.4)!.withValues(alpha: 0.11)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    for (var i = 0; i < 44; i++) {
      final len = 26 + r.nextDouble() * 34;
      canvas
        ..save()
        ..translate(r.nextDouble() * size.width, r.nextDouble() * size.height)
        ..rotate(r.nextDouble() * 2 * pi)
        ..drawPath(
          // A leaf: two arcs meeting at a point at each end.
          Path()
            ..moveTo(0, -len / 2)
            ..quadraticBezierTo(len * 0.38, 0, 0, len / 2)
            ..quadraticBezierTo(-len * 0.38, 0, 0, -len / 2),
          shade,
        )
        ..restore();
    }
  }

  /// Camouflage: overlapping irregular blobs in three shades of the card's gold, from
  /// light to shadow, the darker ones on top.
  void _camouflage(Canvas canvas, Size size) {
    final r = Random(11); // the same pattern on every Legendary card
    final shades = [
      // Overlapping patches add up: kept lighter than the other patterns' lines.
      Color.lerp(color, Colors.white, 0.3)!.withValues(alpha: 0.09),
      color.withValues(alpha: 0.07),
      Color.lerp(color, ink, 0.55)!.withValues(alpha: 0.06),
    ];
    for (final shade in shades) {
      for (var i = 0; i < 9; i++) {
        final c = Offset(
          r.nextDouble() * size.width,
          r.nextDouble() * size.height,
        );
        final base = 18 + r.nextDouble() * 22;
        final (p1, p2) = (r.nextDouble() * 2 * pi, r.nextDouble() * 2 * pi);
        final blob = Path();
        for (var a = 0.0; a <= 2 * pi + 0.01; a += 0.2) {
          // A wobbly radius gives the irregular, lobed edge of a camouflage patch.
          final rad =
              base * (1 + 0.3 * sin(2 * a + p1) + 0.18 * sin(3 * a + p2));
          final pt = c + Offset(cos(a) * rad * 1.5, sin(a) * rad);
          a == 0 ? blob.moveTo(pt.dx, pt.dy) : blob.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(blob..close(), Paint()..color = shade);
      }
    }
  }

  @override
  bool shouldRepaint(_CardStock oldDelegate) =>
      oldDelegate.color != color || oldDelegate.level != level;
}

/// The frame of a heard (not won) card: plain.
class _PlainFrame extends CustomPainter {
  const _PlainFrame(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(radius)),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_PlainFrame oldDelegate) => oldDelegate.color != color;
}

/// The frame of a won card, made of its rarity's material ([level] 0 Common … 4
/// Legendary): cardboard, pebbled leather, brushed metal, holographic foil,
/// polished gold titanium. An engraved inner frame marks the top tiers (its corners on
/// Rare). It's painted under the
/// whole card (the header row sits on it, the face covers the middle); the face's
/// shadow gives the card its thickness (see BirdCardView).
/// Fast enough for a grid of cards: each material is drawn once into a small seamless
/// tile ([_tiles]), and each frame once into a recording ([_frames]) replayed after.
class _FrameMaterial extends CustomPainter {
  const _FrameMaterial(this.color, this.level, this.inset, this.dpr);
  final Color color;
  final int level;
  final double inset;
  final double
  dpr; // device pixel ratio: the tiles are drawn at screen resolution

  static const _t =
      60.0; // tile side: a multiple of the 2, 3 and 4 px pattern steps
  static final _tiles = <(int, Color, double), ui.Image>{};
  static final _frames = <(int, Color, Size, double, double), ui.Picture>{};

  Color get _light => Color.lerp(color, Colors.white, 0.55)!;
  Color get _dark => Color.lerp(color, ink, 0.55)!;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPicture(
    _frames.putIfAbsent((level, color, size, inset, dpr), () {
      final recorder = ui.PictureRecorder();
      _draw(Canvas(recorder), size);
      return recorder.endRecording();
    }),
  );

  void _draw(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(radius),
    );
    if (level >= 5) {
      // Shiny: its own material and a triple engraving, more worked than the gold.
      paintShinyFrame(canvas, size, level == 6 ? 'melanistic' : 'leucistic');
      for (final at in const [0.22, 0.5, 0.8]) {
        _groove(canvas, size, at: at);
      }
      _rim(canvas, size);
      return;
    }
    canvas.drawRRect(outer, Paint()..color = color);
    if (level == 2) canvas.drawRRect(outer, _brushedLight(size));
    if (level == 3) canvas.drawRRect(outer, _foil(size));
    if (level == 4) canvas.drawRRect(outer, _polishedGold(size));
    if (level == 5) canvas.drawRRect(outer, _holographic(size));
    final tile = _tiles.putIfAbsent((level, color, dpr), _tile);
    canvas.drawRRect(
      outer,
      Paint()
        ..shader = ImageShader(
          tile,
          TileMode.repeated,
          TileMode.repeated,
          Matrix4.diagonal3Values(1 / dpr, 1 / dpr, 1).storage,
        ),
    );
    // An engraved inner frame: its corners on Rare, all the way round on Epic and up.
    if (level >= 2) _groove(canvas, size, cornersOnly: level == 2);
    _rim(canvas, size);
  }

  /// Shiny: a holographic film, rainbow bands swept diagonally over pearl, soft enough for
  /// the light header text (a "treasure" exception to the flat Dawn rules, as gold is).
  Paint _holographic(Size size) => Paint()
    ..shader = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width, size.height),
      const [
        Color(0xFF9C8BC4),
        Color(0xFF7FA8D8),
        Color(0xFF6FC0B8),
        Color(0xFFA9C97A),
        Color(0xFFD9B66E),
        Color(0xFFD48C9E),
        Color(0xFF9C8BC4),
        Color(0xFF7FA8D8),
        Color(0xFF6FC0B8),
      ],
      const [0, 0.12, 0.25, 0.37, 0.5, 0.62, 0.75, 0.88, 1],
    );

  /// Polished gold titanium: smooth, with sharp mirror-like reflections — warm yellow
  /// highlights and gold shadows alternating diagonally, as on a curved polished metal;
  /// a little lighter than the Legendary gold, so the light header text still reads.
  Paint _polishedGold(Size size) => Paint()
    ..shader = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width, size.height * 0.6),
      const [
        Color(0xFFC08A1A),
        Color(0xFFE3B032),
        Color(0xFFF7D560),
        Color(0xFFEDC24A),
        Color(0xFFCF9C25),
        Color(0xFFE6B53A),
        Color(0xFFF5D25E),
        Color(0xFFDDAA30),
        Color(0xFFBE891B),
      ],
      const [0, 0.14, 0.24, 0.32, 0.47, 0.56, 0.7, 0.86, 1],
    );

  /// This rarity's texture on a transparent [_t]-wide tile; each random shape is also
  /// drawn a tile over on each side, so the tile's edges wrap without a seam.
  ui.Image _tile() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    final wraps = [
      for (final dx in [-_t, 0.0, _t])
        for (final dy in [-_t, 0.0, _t]) Offset(dx, dy),
    ];
    final r = Random(level);
    switch (level) {
      case 0: // cardboard: a speckled paper grain crossed by short fibres
        for (var k = 0; k < 140; k++) {
          final c = Offset(r.nextDouble() * _t, r.nextDouble() * _t);
          final a = r.nextDouble() * pi;
          final len = 2 + r.nextDouble() * 5;
          final d = Offset(cos(a), sin(a)) * len / 2;
          final paint = Paint()
            ..strokeWidth = 0.6 + r.nextDouble() * 0.5
            ..strokeCap = StrokeCap.round
            ..color = (r.nextBool() ? _light : _dark).withValues(
              alpha: 0.12 + r.nextDouble() * 0.14,
            );
          for (final w in wraps) {
            canvas.drawLine(c + w - d, c + w + d, paint);
          }
        }
        paintGrain(canvas, const Size(_t, _t), _dark, alpha: 0.14);
      case 1: // leather: soft rounded pebbles, lit upper left, shaded lower right
        final shade = Paint()..color = _dark.withValues(alpha: 0.2);
        final lit = Paint()..color = _light.withValues(alpha: 0.2);
        for (var k = 0; k < _t * _t / 24; k++) {
          final c = Offset(r.nextDouble() * _t, r.nextDouble() * _t);
          final rad = 1.3 + r.nextDouble() * 1.2;
          for (final w in wraps) {
            canvas
              ..drawCircle(c + w + const Offset(0.5, 0.5), rad, shade)
              ..drawCircle(c + w - const Offset(0.4, 0.4), rad * 0.7, lit);
          }
        }
      case 2: // brushed metal: fine horizontal streaks
        for (var k = 0; k < _t * 2.5; k++) {
          final y = r.nextDouble() * _t;
          final x = r.nextDouble() * _t;
          final len = 6 + r.nextDouble() * _t * 0.8;
          final paint = Paint()
            ..strokeWidth = 0.6
            ..color = (r.nextBool() ? _light : _dark).withValues(
              alpha: 0.12 + r.nextDouble() * 0.18,
            );
          for (final dx in [-_t, 0.0, _t]) {
            canvas.drawLine(
              Offset(x + dx - len / 2, y),
              Offset(x + dx + len / 2, y),
              paint,
            );
          }
        }
      case 4: // gold titanium: a whisper of micro-brushing and a few bright glints
        for (var k = 0; k < _t * 1.5; k++) {
          final y = r.nextDouble() * _t;
          final x = r.nextDouble() * _t;
          final len = 8 + r.nextDouble() * _t * 0.6;
          final paint = Paint()
            ..strokeWidth = 0.5
            ..color = (r.nextBool() ? Colors.white : _dark).withValues(
              alpha: 0.05 + r.nextDouble() * 0.07,
            );
          for (final dx in [-_t, 0.0, _t]) {
            canvas.drawLine(
              Offset(x + dx - len / 2, y),
              Offset(x + dx + len / 2, y),
              paint,
            );
          }
        }
        final glint = Paint()..color = Colors.white.withValues(alpha: 0.35);
        for (var k = 0; k < 6; k++) {
          final c = Offset(r.nextDouble() * _t, r.nextDouble() * _t);
          for (final w in wraps) {
            canvas.drawCircle(c + w, 0.6, glint);
          }
        }
      default: // foil: fine diagonal diffraction lines, as pressed into real foil
        final line = Paint()
          ..strokeWidth = 0.6
          ..color = Colors.white.withValues(alpha: 0.14);
        for (var d = -_t; d < _t; d += 3) {
          canvas.drawLine(Offset(d, 0), Offset(d + _t, _t), line);
        }
    }
    final side = (_t * dpr).round();
    return recorder.endRecording().toImageSync(side, side);
  }

  /// Brushed metal's sheen: a bright band across the middle.
  Paint _brushedLight(Size size) => Paint()
    ..shader = ui.Gradient.linear(
      Offset.zero,
      Offset(0, size.height),
      [
        _dark.withValues(alpha: 0.3),
        _light.withValues(alpha: 0.35),
        _dark.withValues(alpha: 0.1),
        _light.withValues(alpha: 0.3),
        _dark.withValues(alpha: 0.35),
      ],
      const [0, 0.3, 0.5, 0.7, 1],
    );

  /// Holographic foil: rainbow bands running diagonally, laid lightly over the colour
  /// (plain blending: soft-light needs an extra GPU pass, slow on modest phones).
  Paint _foil(Size size) {
    const hues = [
      Color(0xFFFF6FD8),
      Color(0xFF7FD3FF),
      Color(0xFF9DFFB0),
      Color(0xFFFFF27F),
      Color(0xFFFF9F7F),
      Color(0xFFB98CFF),
      Color(0xFFFF6FD8),
    ];
    return Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width / 3, size.height / 3),
        [for (final h in hues) h.withValues(alpha: 0.22)],
        [for (var i = 0; i < hues.length; i++) i / (hues.length - 1)],
        TileMode.mirror,
      );
  }

  /// A thin engraved line running round the frame, midway through it; with
  /// [cornersOnly], just its rounded corners.
  void _groove(
    Canvas canvas,
    Size size, {
    bool cornersOnly = false,
    double at =
        0.5, // how far into the frame: 0 its outer edge, 1 its inner edge
  }) {
    final groove = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(inset * at),
      Radius.circular(radius - inset * at),
    );
    canvas.save();
    if (cornersOnly) {
      const arm = radius + 10; // how far each corner runs along the sides
      canvas.clipPath(
        Path()
          ..addRect(const Rect.fromLTWH(0, 0, arm, arm))
          ..addRect(Rect.fromLTWH(size.width - arm, 0, arm, arm))
          ..addRect(Rect.fromLTWH(0, size.height - arm, arm, arm))
          ..addRect(
            Rect.fromLTWH(size.width - arm, size.height - arm, arm, arm),
          ),
      );
    }
    canvas
      ..drawRRect(
        groove.shift(const Offset(0.6, 0.6)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = _light.withValues(alpha: 0.7),
      )
      ..drawRRect(
        groove,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = _dark.withValues(alpha: 0.7),
      )
      ..restore();
  }

  /// A darker rim at the card's edge.
  void _rim(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      const Radius.circular(radius - 0.5),
    ),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _dark.withValues(alpha: 0.5),
  );

  @override
  bool shouldRepaint(_FrameMaterial oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.level != level ||
      oldDelegate.inset != inset ||
      oldDelegate.dpr != dpr;
}

/// Coarse paper grain: specks of three sizes, dark ([color]) and light, at a faint
/// [alpha]; seeded, so every card has the same grain.
void paintGrain(Canvas canvas, Size size, Color color, {double alpha = 0.12}) {
  final r = Random(5);
  final n = (size.width * size.height / 45).round();
  for (final (width, tone, a) in [
    (1.0, color, alpha),
    (1.9, color, alpha * 0.7),
    (1.4, Colors.white, alpha * 1.5),
  ]) {
    final points = Float32List(n ~/ 3 * 2);
    for (var i = 0; i < points.length; i++) {
      points[i] = r.nextDouble() * (i.isEven ? size.width : size.height);
    }
    canvas.drawRawPoints(
      ui.PointMode.points,
      points,
      Paint()
        ..color = tone.withValues(alpha: a)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }
}

TextStyle? _latin(TextTheme text) =>
    text.bodySmall?.copyWith(fontStyle: FontStyle.italic);

String kindName(AppLocalizations l, String kind) => switch (kind) {
  'song' => l.song,
  'call' => l.call,
  _ => l.alarmCall,
};

/// A recording of [bird] to play: one on the phone if any, else the first (streamed).
String? playableFile(Bird bird) =>
    (bird.recordings.where(onPhone).firstOrNull ?? bird.recordings.firstOrNull)
        ?.file;

/// Plays a catalog recording from the start: from the phone, or streamed from the
/// catalog if it's not there.
Future<void> playRecording(AudioPlayer player, String file) async {
  final path = phonePath(file);
  try {
    if (path == null) {
      await player.setUrl('$baseUrl$file');
    } else if (path.startsWith('assets/')) {
      await player.setAsset(path);
    } else {
      await player.setFilePath(path);
    }
    await player.seek(Duration.zero);
    unawaited(player.play());
  } on Exception {
    // Offline and not on the phone: nothing to play.
  }
}

/// Plays [file]; a round filled button in [color], or with [glass] a bigger frosted one
/// (on heard birds' tiles, to train on the songs that were missed).
class PlayButton extends StatefulWidget {
  const PlayButton(
    this.file, {
    this.color,
    this.glass = false,
    this.small = false,
    super.key,
  });
  final String file;
  final Color? color;
  final bool glass;
  final bool small; // a smaller glass button (the collection's small tiles)

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> {
  final _player = AudioPlayer();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_player.playing) return _player.stop();
    await playRecording(_player, widget.file);
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<bool>(
    stream: _player.playingStream,
    builder: (context, snap) {
      final icon = snap.data == true ? Icons.stop : Icons.play_arrow;
      final tooltip = AppLocalizations.of(context).play;
      if (widget.glass) {
        return ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Material(
              color: Colors.white.withValues(alpha: 0.25),
              shape: CircleBorder(
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 1.5,
                ),
              ),
              child: IconButton(
                tooltip: tooltip,
                onPressed: _toggle,
                iconSize: widget.small ? 24 : 36,
                padding: EdgeInsets.all(widget.small ? 6 : 12),
                icon: Icon(icon, color: Colors.white),
              ),
            ),
          ),
        );
      }
      final color = widget.color!;
      return IconButton.filled(
        tooltip: tooltip,
        onPressed: _toggle,
        style: IconButton.styleFrom(
          backgroundColor: color,
          // A discreet outline lifts it off the card stock.
          side: BorderSide(
            color: Color.lerp(color, Colors.white, 0.45)!,
            width: 1.5,
          ),
        ),
        icon: Icon(icon, color: paper),
      );
    },
  );
}

String statName(AppLocalizations l, String key) => switch (key) {
  'weight' => l.weight,
  'wingspan' => l.wingspan,
  'length' => l.length,
  _ => l.flightDistance,
};

String formatStat(String key, double v, AppLocalizations l) {
  // Sedentary birds have no flight distance worth a number.
  if (key == 'distance' && v < 1) return l.resident;
  final locale = l.localeName;
  final (value, unit) = switch (key) {
    'weight' => v >= 1000 ? (v / 1000, 'kg') : (v, 'g'),
    'distance' => (v, 'km'),
    _ => (v, 'cm'),
  };
  final n = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: value < 10 ? 1 : 0,
  );
  return '${n.format(value)} $unit';
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.stat,
    required this.bird,
    required this.color,
  });
  final String label, stat;
  final double? value;
  final Bird bird;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.bodyMedium;
    final value = this.value;
    final l = AppLocalizations.of(context);
    // TalkBack reads the row as one item: "Weight, 18 g".
    return Semantics(
      label: '$label, ${value == null ? '?' : formatStat(stat, value, l)}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(flex: 4, child: Text(label, style: text)),
            Expanded(
              flex: 3,
              child: Text(
                value == null ? '?' : formatStat(stat, value, l),
                style: text?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: 8),
            // Where this roll sits in the species' spread.
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: value == null ? 0 : percentileOf(bird, stat, value),
                  minHeight: 6,
                  color: color,
                  backgroundColor: unknownColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Bird rarity": how rare the species is in the region, level 1-10 as 0.5-5 stars.
class _RarityRow extends StatelessWidget {
  const _RarityRow({
    required this.label,
    required this.level,
    required this.color,
  });
  final String label;
  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.bodyMedium;
    final stars = level.clamp(1, 10) / 2;
    return Semantics(
      label: '$label, $stars / 5',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label, style: text)),
            _Stars(stars: stars, color: color),
          ],
        ),
      ),
    );
  }
}

/// The five stars; from 4 stars a glint: a light sweeping across them now and then and
/// two faint twinkles; at 5 stars brighter, with three sparkles orbiting the row.
class _Stars extends StatefulWidget {
  const _Stars({required this.stars, required this.color});
  final double stars;
  final Color color;

  @override
  State<_Stars> createState() => _StarsState();
}

class _StarsState extends State<_Stars> with SingleTickerProviderStateMixin {
  late final _glint = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.stars >= 5 ? 2600 : 3600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.stars >= 4) _glint.repeat();
  }

  @override
  void dispose() {
    _glint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            widget.stars >= i
                ? Icons.star
                : widget.stars >= i - 0.5
                ? Icons.star_half
                : Icons.star_border,
            size: 22,
            color: widget.color,
          ),
      ],
    );
    if (widget.stars < 4 || MediaQuery.disableAnimationsOf(context)) {
      _glint.stop();
      return row;
    }
    final strong = widget.stars >= 5;
    // Its own layer: the glint repaints only the stars, not the whole card under them.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glint,
        builder: (context, child) {
          // The sweep crosses the stars in the first 40 % of each cycle, then rests.
          final x = (_glint.value / 0.4).clamp(0.0, 1.0) * 5 - 2.5;
          return CustomPaint(
            foregroundPainter: _Sparkles(_glint.value, strong, widget.color),
            child: ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment(x - 1, -1),
                end: Alignment(x + 1, 1),
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: strong ? 0.75 : 0.45),
                  Colors.transparent,
                ],
                stops: const [0.4, 0.5, 0.6],
              ).createShader(rect),
              child: child,
            ),
          );
        },
        child: row,
      ),
    );
  }
}

/// Twinkles over the stars and, when [strong], sparkles orbiting the row; [t] 0-1.
class _Sparkles extends CustomPainter {
  const _Sparkles(this.t, this.strong, this.color);
  final double t;
  final bool strong;
  final Color color;

  // A four-pointed glint of half-size [r] at [c], faded by [a].
  void _glint(Canvas canvas, Offset c, double r, double a) {
    if (a <= 0) return;
    final p = Paint()
      ..color = Color.lerp(color, Colors.white, 0.7)!.withValues(alpha: a);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r),
      p,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final star = size.width / 5;
    // Twinkles above two stars, each a quick fade in and out at its own moment.
    for (final (i, at) in [(1, 0.5), (3, 0.75)]) {
      final f = 1 - ((t - at).abs() / 0.12);
      _glint(
        canvas,
        Offset(star * (i + 0.8), size.height * 0.2),
        strong ? 4.5 : 3.5,
        (strong ? 0.95 : 0.6) * sin(pi * f.clamp(0, 1) / 2),
      );
    }
    if (!strong) return;
    final c = size.center(Offset.zero);
    for (var k = 0; k < 3; k++) {
      final a = 2 * pi * (t + k / 3);
      _glint(
        canvas,
        c +
            Offset(
              cos(a) * (size.width / 2 + 3),
              sin(a) * (size.height / 2 + 2),
            ),
        3,
        0.55 + 0.35 * sin(a * 2),
      );
    }
  }

  @override
  bool shouldRepaint(_Sparkles oldDelegate) => oldDelegate.t != t;
}

/// Grid cell: won and heard birds show the full card scaled down; undiscovered ones
/// are a quiet "?" tile in the app theme's colors.
class CardTile extends StatelessWidget {
  const CardTile({
    required this.bird,
    required this.heard,
    this.card,
    this.copies = 1,
    this.compact = false,
    this.onTap,
    super.key,
  });
  final Bird bird;
  final CardData? card; // the copy shown, null if not won
  final int copies;
  final bool heard;
  final bool compact; // 3 per row: just the photo in its rarity frame
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).colorScheme;
    final number = '#${bird.number.toString().padLeft(3, '0')}';
    final known = card != null || heard;
    return Semantics(
      button: onTap != null,
      label: known
          ? '$number ${bird.nameIn(AppLocalizations.of(context).localeName)}'
          : number,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        // Laid out at full-card size, then shrunk, so it looks exactly like the big card.
        child: known && compact
            ? _photoTile(number)
            : known
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  // Duplicates as a pile: one or two cards peek out from behind.
                  for (final angle in [-0.05, 0.035].take(copies - 1))
                    Positioned.fill(
                      child: Transform.rotate(
                        angle: angle,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: paper,
                            borderRadius: BorderRadius.circular(radius / 2),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  IgnorePointer(
                    child: FittedBox(
                      child: SizedBox(
                        width: 340,
                        height: 340 / 0.68,
                        child: BirdCardView(bird: bird, card: card),
                      ),
                    ),
                  ),
                  // Outside the shrunk card, so it stays readable.
                  if (copies > 1)
                    Positioned(right: 6, top: 6, child: CopiesBadge(copies)),
                  ?_heardPlay(),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  color: app.surface,
                  border: Border.all(color: app.secondaryContainer, width: 4),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: Text(
                        '?',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: app.onSurface.withValues(alpha: 0.5),
                            ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Theme(data: cardTheme, child: _Badge(number)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

extension on CardTile {
  /// The photo in its rarity frame (greyed out if only heard), with its number.
  Widget _photoTile(String number) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: card == null
          ? unknownColor
          : rarityColor[card!.rarity ?? bird.rarity],
      borderRadius: BorderRadius.circular(radius - 6),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(radius - 10),
          child: card != null
              ? BirdPhoto(bird, photo: card!.photo)
              : Opacity(
                  opacity: 0.5,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.grey,
                      BlendMode.saturation,
                    ),
                    child: BirdPhoto(bird),
                  ),
                ),
        ),
        Positioned(
          left: 4,
          bottom: 4,
          child: Theme(data: cardTheme, child: _Badge(number)),
        ),
        if (copies > 1)
          Positioned(right: 4, top: 4, child: CopiesBadge(copies)),
        ?_heardPlay(),
      ],
    ),
  );

  /// A heard (missed) bird's song, to train on: a glass play button, small and low on
  /// the small tiles.
  Widget? _heardPlay() {
    final file = card == null ? playableFile(bird) : null;
    return file == null
        ? null
        : Align(
            alignment: compact ? const Alignment(0, 0.3) : Alignment.center,
            child: PlayButton(file, glass: true, small: compact),
          );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: paper,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Text(text, style: Theme.of(context).textTheme.labelSmall),
  );
}

/// "×3": how many copies of the card the player owns, in the theme's accent or [color]
/// (the card's rarity, above a full-screen card); [large] above a full-screen card.
class CopiesBadge extends StatelessWidget {
  const CopiesBadge(this.copies, {this.large = false, this.color, super.key});
  final int copies;
  final bool large;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 8,
        vertical: large ? 4 : 2,
      ),
      decoration: BoxDecoration(
        color: color ?? scheme.primary,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        '×$copies',
        style: (large ? text.headlineSmall : text.titleMedium)?.copyWith(
          color: color == null ? scheme.onPrimary : paper,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// The bird's photo, never cropped: the whole photo over a blurred, zoomed copy of itself
/// that fills the box. From the phone (downloaded or bundled), or the web if it's missing.
class BirdPhoto extends StatelessWidget {
  const BirdPhoto(this.bird, {this.photo, super.key});
  final Bird bird;
  final String?
  photo; // a card's variant or Shiny photo; null: the catalog photo

  @override
  Widget build(BuildContext context) {
    final file = bird.photoOf(photo).photo;
    final path = phonePath(file);
    final ImageProvider image = path == null
        ? NetworkImage('$baseUrl$file')
        : path.startsWith('assets/')
        ? AssetImage(path)
        : FileImage(File(path));
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Image(
            image: image,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(color: unknownColor),
          ),
        ),
        Image(
          image: image,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox(),
        ),
      ],
    );
  }
}

/// "1st", "2nd", "12th"... in English; "1re", "2e"... in French and "1.ª", "2.ª" in Spanish
/// (espèce / especie are feminine); "1.", "2." in German.
String ordinal(int n, String locale) {
  if (locale.startsWith('fr')) return n == 1 ? '1re' : '${n}e';
  if (locale.startsWith('es')) return '$n.ª';
  if (locale.startsWith('de')) return '$n.';
  final suffix = n % 100 >= 11 && n % 100 <= 13
      ? 'th'
      : switch (n % 10) {
          1 => 'st',
          2 => 'nd',
          3 => 'rd',
          _ => 'th',
        };
  return '$n$suffix';
}
