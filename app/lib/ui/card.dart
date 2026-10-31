import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

import '../birds.dart';
import '../cards.dart';
import '../content.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

String rarityName(AppLocalizations l, String tier) => switch (tier) {
  'common' => l.common,
  'uncommon' => l.uncommon,
  'rare' => l.rare,
  'epic' => l.epic,
  _ => l.legendary,
};

/// The full trading card. Without [card] the bird is only "heard": a grey, blurred card
/// showing just its name and "Try next time!".
class BirdCardView extends StatelessWidget {
  const BirdCardView({required this.bird, this.card, super.key});
  final Bird bird;
  final CardData? card;

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
    final frame = card == null ? unknownColor : rarityColor[rarity]!;
    final label = text.labelLarge?.copyWith(
      color: card == null ? ink : paper,
      fontWeight: FontWeight.bold,
    );
    final recording = bird.recordings
        .where((r) => r.file == card?.recording)
        .firstOrNull;
    final face = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(radius - 6),
      ),
      // A won card is printed on textured card stock tinted with its rarity.
      child: CustomPaint(
        painter: card == null
            ? null
            : _CardStock(frame, max(0, tiers.indexOf(rarity))),
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
                      child: BirdPhoto(bird),
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
    // The card is a fixed-size picture: text grows with the phone's font size, up to 1.3×.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: AspectRatio(
        aspectRatio: 0.68,
        child: Container(
          padding: EdgeInsets.all(
            rarity == 'legendary' && card != null ? 14 : 8,
          ),
          decoration: BoxDecoration(
            color: frame,
            borderRadius: BorderRadius.circular(radius),
          ),
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
                    Text(
                      card == null ? l.heard : rarityName(l, rarity),
                      style: label,
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
                                  Text(l.tryNextTime, style: text.titleMedium),
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
      ),
    );
  }
}

/// The background of a won card: card stock tinted with its rarity [color] and printed
/// with the pattern of its rarity [level] (0 Common … 4 Legendary), all equally faint so
/// the text reads as on plain paper: a guilloche (interlaced waves, as on a banknote) for
/// Common and Uncommon, a wide diamond lattice for Rare, the soft shadow of foliage for
/// Epic, and a golden camouflage for Legendary.
class _CardStock extends CustomPainter {
  const _CardStock(this.color, this.level);
  final Color color;
  final int level;

  @override
  void paint(Canvas canvas, Size size) {
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
        _lattice(canvas, size, line);
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

  void _lattice(Canvas canvas, Size size, Paint line) {
    for (var d = -size.height; d < size.width; d += 18) {
      canvas
        ..drawLine(Offset(d, 0), Offset(d + size.height, size.height), line)
        ..drawLine(Offset(d, size.height), Offset(d + size.height, 0), line);
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

TextStyle? _latin(TextTheme text) =>
    text.bodySmall?.copyWith(fontStyle: FontStyle.italic);

String kindName(AppLocalizations l, String kind) => switch (kind) {
  'song' => l.song,
  'call' => l.call,
  _ => l.alarmCall,
};

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

class PlayButton extends StatefulWidget {
  const PlayButton(this.file, {required this.color, super.key});
  final String file;
  final Color color;

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
    builder: (context, snap) => IconButton.filled(
      tooltip: AppLocalizations.of(context).play,
      onPressed: _toggle,
      style: IconButton.styleFrom(backgroundColor: widget.color),
      icon: Icon(
        snap.data == true ? Icons.stop : Icons.play_arrow,
        color: paper,
      ),
    ),
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
                children: [
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
                    Positioned(right: 6, top: 6, child: _CopiesBadge(copies)),
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
              ? BirdPhoto(bird)
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
          Positioned(right: 4, top: 4, child: _CopiesBadge(copies)),
      ],
    ),
  );
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

/// "×3" on a collection tile: how many copies of the card the player owns, in the
/// theme's accent.
class _CopiesBadge extends StatelessWidget {
  const _CopiesBadge(this.copies);
  final int copies;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        '×$copies',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// The bird's photo, never cropped: the whole photo over a blurred, zoomed copy of itself
/// that fills the box. From the phone (downloaded or bundled), or the web if it's missing.
class BirdPhoto extends StatelessWidget {
  const BirdPhoto(this.bird, {super.key});
  final Bird bird;

  @override
  Widget build(BuildContext context) {
    final path = phonePath(bird.photo);
    final ImageProvider image = path == null
        ? NetworkImage('$baseUrl${bird.photo}')
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
