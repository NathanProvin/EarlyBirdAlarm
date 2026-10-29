import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../birds.dart';
import '../cards.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'booster.dart';
import 'card.dart';
import 'region.dart';
import 'series.dart';
import 'theme.dart';

/// The best copy of each owned bird, by bird id.
Map<String, CardData> bestCards(List<CardData> cards) {
  final best = <String, CardData>{};
  for (final c in cards) {
    if ((best[c.birdId]?.quality ?? -1) < c.quality) best[c.birdId] = c;
  }
  return best;
}

enum _View { all, species, region }

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  _View _view = _View.all;
  String? _tier; // rarity filter, null = all

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cards = store.cards;
    final best = bestCards(cards);
    final heard = store.heard;
    final regionIds = {for (final b in birds) b.id};
    String rarityOf(Bird b, CardData? c) => c?.rarity ?? b.rarity;
    int rarest((Bird, CardData?) a, (Bird, CardData?) b) {
      final t =
          tiers.indexOf(rarityOf(b.$1, b.$2)) -
          tiers.indexOf(rarityOf(a.$1, a.$2));
      return t != 0 ? t : a.$1.number.compareTo(b.$1.number);
    }

    // (bird, card) entries; a null card is a "?" or "heard" tile (Region view only).
    final entries = switch (_view) {
      _View.all => [
        for (final c in cards)
          if (birdById(c.birdId) case final b?) (b, c as CardData?),
      ]..sort(rarest),
      _View.species => [
        for (final c in best.values)
          if (birdById(c.birdId) case final b?) (b, c as CardData?),
      ]..sort(rarest),
      _View.region => [
        for (final b in birds) (b, best[b.id]),
        // Cards won in another region.
        for (final c in best.values)
          if (!regionIds.contains(c.birdId) && species[c.birdId] != null)
            (species[c.birdId]!, c as CardData?),
      ]..sort((a, b) => a.$1.number.compareTo(b.$1.number)),
    };
    final shown = [
      for (final e in entries)
        if (_tier == null || rarityOf(e.$1, e.$2) == _tier) e,
    ];
    final openable = [
      for (final e in shown)
        if (e.$2 != null || heard.contains(e.$1.id)) e,
    ];
    // The region's many "?" stay 3 per row; won cards are shown whole 2 per row.
    final compact = _view == _View.region;
    final regionLabel = store.region == null
        ? l.viewRegion
        : regionName(l, store.region!);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              // The menus shrink with "…" so Series always fits.
              Expanded(
                child: Row(
                  children: [
                    // Each view shows its count, e.g. "France (7/353)".
                    Flexible(
                      flex: 3,
                      child: _Menu<_View>(
                        value: _view,
                        items: {
                          _View.all: '${l.viewAll} (${cards.length})',
                          _View.species: '${l.viewSpecies} (${best.length})',
                          _View.region:
                              '$regionLabel (${best.keys.where(regionIds.contains).length}/${birds.length})',
                        },
                        onSelected: (v) => setState(() => _view = v),
                      ),
                    ),
                    Flexible(
                      flex: 2,
                      child: _Menu<String?>(
                        value: _tier,
                        items: {
                          null: l.allRarities,
                          for (final t in tiers) t: rarityName(l, t),
                        },
                        colors: rarityColor,
                        onSelected: (t) => setState(() => _tier = t),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SeriesScreen()),
                ),
                icon: const Icon(Icons.collections_bookmark_outlined),
                label: Text(l.series),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            // The last row scrolls clear of the glass bottom bar.
            padding: EdgeInsets.fromLTRB(
              12,
              4,
              12,
              12 + MediaQuery.paddingOf(context).bottom,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: compact ? 3 : 2,
              childAspectRatio: 0.68,
              mainAxisSpacing: compact ? 8 : 12,
              crossAxisSpacing: compact ? 8 : 12,
            ),
            itemCount: shown.length,
            itemBuilder: (context, i) {
              final (b, c) = shown[i];
              final open = openable.indexOf(shown[i]);
              return CardTile(
                bird: b,
                card: c,
                copies: _view == _View.all
                    ? 1
                    : cards.where((x) => x.birdId == b.id).length,
                heard: heard.contains(b.id),
                compact: compact,
                onTap: open < 0
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CardPager(entries: openable, initial: open),
                        ),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A compact "Label ▾" drop-down menu.
class _Menu<T> extends StatelessWidget {
  const _Menu({
    required this.value,
    required this.items,
    required this.onSelected,
    this.colors = const {},
  });
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onSelected;
  final Map<T, Color> colors; // optional text color per item (rarities)

  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
    initialValue: value,
    onSelected: onSelected,
    itemBuilder: (_) => [
      for (final MapEntry(:key, value: label) in items.entries)
        PopupMenuItem(
          value: key,
          child: Text(label, style: TextStyle(color: colors[key])),
        ),
    ],
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              items[value]!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: colors[value]),
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
    ),
  );
}

/// Full cards, swipe left/right between them.
class CardPager extends StatelessWidget {
  const CardPager({required this.entries, required this.initial, super.key});
  final List<(Bird, CardData?)> entries;
  final int initial;

  @override
  Widget build(BuildContext context) {
    final cards = store.cards;
    return Scaffold(
      appBar: AppBar(),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: entries.length,
        itemBuilder: (_, i) {
          final (bird, card) = entries[i];
          final copies = cards.where((c) => c.birdId == bird.id).length;
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: CardDetail(
              bird: bird,
              card: card,
              header: copies > 1
                  ? Text(
                      '×$copies',
                      style: Theme.of(context).textTheme.titleMedium,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

/// A card with centered round buttons below: Share, credits, and an optional close
/// button. [header] goes above the card.
class CardDetail extends StatefulWidget {
  const CardDetail({
    required this.bird,
    this.card,
    this.recording,
    this.header,
    this.onClose,
    this.flipIn = false,
    super.key,
  });
  final Bird bird;
  final CardData? card;
  final bool flipIn; // a card just won flips face up with sparks (see CardFlip)
  final Recording?
  recording; // whose credit to show; defaults to the card's recording
  final Widget? header;
  final VoidCallback? onClose;

  @override
  State<CardDetail> createState() => _CardDetailState();
}

class _CardDetailState extends State<CardDetail> {
  final _boundary = GlobalKey();

  Future<void> _share(String name) async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(png!.buffer.asUint8List(), mimeType: 'image/png'),
        ],
        fileNameOverrides: ['$name.png'],
      ),
    );
  }

  void _credits(Recording? recording) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final credit in [?recording?.credit, widget.bird.photoCredit])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                credit,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    ),
  );

  Widget _flip(Widget face) => widget.flipIn && widget.card != null
      ? CardFlip(
          color: rarityColor[widget.card!.rarity ?? widget.bird.rarity]!,
          child: face,
        )
      : face;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final CardDetail(:bird, :card, :header, :onClose) = widget;
    final recording =
        widget.recording ??
        bird.recordings.where((r) => r.file == card?.recording).firstOrNull;
    return Column(
      children: [
        ?header,
        Expanded(
          child: Center(
            child: _flip(
              RepaintBoundary(
                key: _boundary,
                child: BirdCardView(bird: bird, card: card),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 24,
          children: [
            if (card != null)
              RoundButton(
                icon: Icons.share_outlined,
                tooltip: l.share,
                onPressed: () => _share(bird.id),
              ),
            RoundButton(
              icon: Icons.info_outline,
              tooltip: l.credits,
              onPressed: () => _credits(recording),
            ),
            if (onClose != null)
              RoundButton(
                icon: Icons.close,
                tooltip: l.done,
                onPressed: onClose,
              ),
          ],
        ),
      ],
    );
  }
}

/// A big round button (Share, Close).
class RoundButton extends StatelessWidget {
  const RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: tooltip,
    onPressed: onPressed,
    iconSize: 28,
    style: IconButton.styleFrom(
      fixedSize: const Size(56, 56),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
    ),
    icon: Icon(icon),
  );
}
