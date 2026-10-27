import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../birds.dart';
import '../cards.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

String rarityName(AppLocalizations l, String tier) => switch (tier) {
  'common' => l.common,
  'uncommon' => l.uncommon,
  'rare' => l.rare,
  'epic' => l.epic,
  _ => l.legendary,
};

/// The full trading card. Without [card] the bird is only "heard": grey frame, no stats.
class BirdCardView extends StatelessWidget {
  const BirdCardView({required this.bird, this.card, super.key});
  final Bird bird;
  final CardData? card;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final card = this.card;
    final frame = card == null ? unknownColor : rarityColor[bird.rarity]!;
    final label = text.labelLarge?.copyWith(
      color: card == null ? ink : paper,
      fontWeight: FontWeight.bold,
    );
    return AspectRatio(
      aspectRatio: 5 / 7,
      child: Container(
        padding: EdgeInsets.all(bird.rarity == 'legendary' ? 14 : 8),
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
                  Text(
                    '#${bird.number.toString().padLeft(3, '0')}',
                    style: label,
                  ),
                  const Spacer(),
                  Text(
                    card == null ? l.heard : rarityName(l, bird.rarity),
                    style: label,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
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
                        child: Image.asset(bird.photo, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bird.nameIn(l.localeName),
                      style: text.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      bird.latin,
                      style: text.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
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
                    const SizedBox(height: 4),
                    Text(
                      card == null ? l.heardHint : l.quality(card.quality),
                      style: text.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    return Padding(
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
    this.onTap,
    super.key,
  });
  final Bird bird;
  final int owned; // copies earned
  final bool heard;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
            color: owned > 0 ? rarityColor[bird.rarity] : unknownColor,
            borderRadius: BorderRadius.circular(radius - 6),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(radius - 10),
                child: owned > 0
                    ? Image.asset(bird.photo, fit: BoxFit.cover)
                    : heard
                    ? Opacity(
                        opacity: 0.5,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          ),
                          child: Image.asset(bird.photo, fit: BoxFit.cover),
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
