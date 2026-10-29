import 'dart:async';
import 'dart:io';
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
  Widget build(BuildContext context) =>
      Theme(data: cardTheme, child: Builder(builder: _build));

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(radius - 6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - 8),
              child: BirdPhoto(bird),
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
            if (bird.stats.containsKey(key)) // unknown for this species: no row
              _StatRow(
                label: statName(l, key),
                value: card?.stats[key],
                stat: key,
                bird: bird,
                color: frame,
              ),
        ],
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

TextStyle? _latin(TextTheme text) =>
    text.bodySmall?.copyWith(fontStyle: FontStyle.italic);

String kindName(AppLocalizations l, String kind) => switch (kind) {
  'song' => l.song,
  'call' => l.call,
  _ => l.alarmCall,
};

/// Plays a catalog recording: from the phone, or streamed from the catalog if it's not there.
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
    final path = phonePath(widget.file);
    try {
      if (path == null) {
        await _player.setUrl('$baseUrl${widget.file}');
      } else if (path.startsWith('assets/')) {
        await _player.setAsset(path);
      } else {
        await _player.setFilePath(path);
      }
      await _player.seek(Duration.zero);
      unawaited(_player.play());
    } on Exception {
      // Offline and not on the phone: nothing to play.
    }
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

String formatStat(String key, double v, String locale) {
  final n = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: v < 10 ? 1 : 0,
  );
  return switch (key) {
    'weight' => v >= 1000 ? '${n.format(v / 1000)} kg' : '${n.format(v)} g',
    'distance' => '${n.format(v)} km',
    _ => '${n.format(v)} cm',
  };
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
    final locale = AppLocalizations.of(context).localeName;
    // TalkBack reads the row as one item: "Weight, 18 g".
    return Semantics(
      label: '$label, ${value == null ? '?' : formatStat(stat, value, locale)}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(flex: 4, child: Text(label, style: text)),
            Expanded(
              flex: 3,
              child: Text(
                value == null ? '?' : formatStat(stat, value, locale),
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

/// Small grid tile: owned cards show the photo in the rarity frame, heard birds are
/// greyed out, undiscovered ones are a "?".
class CardTile extends StatelessWidget {
  const CardTile({
    required this.bird,
    required this.owned,
    required this.heard,
    this.rarity,
    this.onTap,
    super.key,
  });
  final Bird bird;
  final String? rarity; // of the best copy owned
  final int owned; // copies earned
  final bool heard;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) =>
      Theme(data: cardTheme, child: Builder(builder: _build));

  Widget _build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final number = '#${bird.number.toString().padLeft(3, '0')}';
    return Semantics(
      button: onTap != null,
      label: owned > 0 || heard
          ? '$number ${bird.nameIn(AppLocalizations.of(context).localeName)}'
          : number,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius - 6),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: owned > 0
                ? rarityColor[rarity ?? bird.rarity]
                : unknownColor,
            borderRadius: BorderRadius.circular(radius - 6),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(radius - 10),
                child: owned > 0
                    ? BirdPhoto(bird)
                    : heard
                    ? Opacity(
                        opacity: 0.5,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          ),
                          child: BirdPhoto(bird),
                        ),
                      )
                    : ColoredBox(
                        color: paper,
                        child: Center(
                          child: Text('?', style: text.headlineMedium),
                        ),
                      ),
              ),
              Positioned(left: 4, bottom: 4, child: _Badge(number)),
              if (owned > 1)
                Positioned(right: 4, top: 4, child: _Badge('×$owned')),
            ],
          ),
        ),
      ),
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

/// "1st", "2nd", "12th"... in English; "1re", "2e"... in French (espèce is feminine).
String ordinal(int n, String locale) {
  if (locale.startsWith('fr')) return n == 1 ? '1re' : '${n}e';
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
