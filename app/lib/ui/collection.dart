import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../birds.dart';
import '../cards.dart';
import '../content.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'booster.dart';
import 'card.dart';
import 'region.dart';
import 'series.dart';
import 'trade.dart';
import 'theme.dart';

/// A card's rarity; cards from before 3c have none and take their species' tier.
String cardRarity(CardData c) =>
    c.rarity ?? birdById(c.birdId)?.rarity ?? 'common';

/// The best copy of each owned bird, by bird id: the rarest, then the best quality.
Map<String, CardData> bestCards(List<CardData> cards) {
  final best = <String, CardData>{};
  int score(CardData c) => tiers.indexOf(cardRarity(c)) * 1000 + c.quality;
  for (final c in cards) {
    if (best[c.birdId] case final b? when score(b) >= score(c)) continue;
    best[c.birdId] = c;
  }
  return best;
}

// Views: every copy, the best copy of each species, or a region's birds (its id).
const _all = 'all', _species = 'species';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  String _view = _all;
  String? _tier; // rarity filter, null = all
  final _fetching = <String>{}; // other regions' bird lists being downloaded

  /// The bird ids of [region]; for another region, its list is fetched once (to count
  /// "2/500") and meanwhile only the cards won there are known (null).
  Set<String>? _birdsOf(String region) {
    if (region == store.region) return {for (final b in birds) b.id};
    final ids = regionBirdIds(region);
    if (ids == null && _fetching.add(region)) {
      download('regions/$region.json').then((ok) {
        if (ok && mounted) setState(() {});
      });
    }
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cards = store.cards;
    final best = bestCards(cards);
    final heard = store.heard;
    // Region views go by displayed name: GPS cells that share one ("France · South") are a
    // single view. The current region first, then every other one a card was won in, most
    // cards first.
    final names = <String, String>{};
    String nameOf(String r) => names[r] ??= regionName(l, r);
    final groups = <String, Set<String>>{
      if (store.region case final r?) nameOf(r): {r},
    };
    final wonIn = <String, int>{};
    for (final c in cards) {
      if (c.region case final r?) {
        (groups[nameOf(r)] ??= {}).add(r);
        wonIn[nameOf(r)] = (wonIn[nameOf(r)] ?? 0) + 1;
      }
    }
    final current = store.region == null ? null : nameOf(store.region!);
    final regions = [
      ?current,
      ...(groups.keys.where((n) => n != current).toList()
        ..sort((a, b) => wonIn[b]! - wonIn[a]!)),
    ];
    if (_view != _all && _view != _species && !regions.contains(_view)) {
      _view = _all; // that region is gone (e.g. its cards were the only link)
    }
    // Rarity belongs to cards: a bird not won yet has none (the filter hides it).
    String? rarityOf(Bird b, CardData? c) => c == null ? null : cardRarity(c);
    int rank((Bird, CardData?) e) =>
        e.$2 == null ? -1 : tiers.indexOf(cardRarity(e.$2!));
    int rarest((Bird, CardData?) a, (Bird, CardData?) b) {
      final t = rank(b) - rank(a);
      return t != 0 ? t : a.$1.number.compareTo(b.$1.number);
    }

    // A region view's species: each region's whole list when known, else the species won there.
    Set<String> idsOf(String name) => {
      for (final r in groups[name]!)
        ..._birdsOf(r) ??
            {
              for (final c in cards)
                if (c.region == r) c.birdId,
            },
    };
    // (bird, card) entries; a null card is a "?" or "heard" tile (region views only).
    final entries = switch (_view) {
      _all => [
        for (final c in cards)
          if (birdById(c.birdId) case final b?) (b, c as CardData?),
      ]..sort(rarest),
      _species => [
        for (final c in best.values)
          if (birdById(c.birdId) case final b?) (b, c as CardData?),
      ]..sort(rarest),
      final region => [
        for (final id in idsOf(region))
          if (birdById(id) case final b?) (b, best[id]),
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
    final compact = _view != _all && _view != _species;
    // "France (7/353)"; "USA — Northeast (2)" until that region's list has arrived.
    String regionLabel(String name) {
      final known = groups[name]!.every((r) => _birdsOf(r) != null);
      final ids = idsOf(name);
      final owned = ids.where(best.containsKey).length;
      return '$name ($owned${known ? '/${ids.length}' : ''})';
    }

    final views = {
      _all: '${l.viewAll} (${cards.length})',
      _species: '${l.viewSpecies} (${best.length})',
      for (final r in regions) r: regionLabel(r),
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              // The two filters on the left (their menus show the counts), then Trade and Series.
              _Menu<String>(
                value: _view,
                items: views,
                tooltip: l.viewMenu,
                onSelected: (v) => setState(() => _view = v),
                child: const _Round(icon: Icons.expand_more),
              ),
              const SizedBox(width: 6),
              _Menu<String?>(
                value: _tier,
                items: {
                  null: l.allRarities,
                  for (final t in tiers) t: rarityName(l, t),
                },
                colors: rarityColor,
                tooltip: l.rarityMenu,
                onSelected: (t) => setState(() => _tier = t),
                // Every rarity colour around it; the chosen one alone while filtering.
                child: _Round(
                  icon: Icons.arrow_drop_down,
                  ring: _tier == null
                      ? [for (final t in tiers) rarityColor[t]!]
                      : [rarityColor[_tier]!],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const TradeScreen()),
                ),
                icon: const Icon(Icons.swap_horiz),
                label: Text(l.trade),
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
                copies: _view == _all
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

/// A drop-down menu opened by tapping [child].
class _Menu<T> extends StatelessWidget {
  const _Menu({
    required this.value,
    required this.items,
    required this.onSelected,
    required this.tooltip,
    required this.child,
    this.colors = const {},
  });
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onSelected;
  final String tooltip;
  final Widget child;
  final Map<T, Color> colors; // optional text color per item (rarities)

  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
    initialValue: value,
    tooltip: tooltip,
    onSelected: onSelected,
    itemBuilder: (_) => [
      for (final MapEntry(:key, value: label) in items.entries)
        PopupMenuItem(
          value: key,
          child: Text(label, style: TextStyle(color: colors[key])),
        ),
    ],
    child: child,
  );
}

/// A 40 dp round header button: an outline in the theme's colour, or a ring of [ring]
/// colours (the rarity filter).
class _Round extends StatelessWidget {
  const _Round({required this.icon, this.ring});
  final IconData icon;
  final List<Color>? ring;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ring = this.ring;
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ring == null ? scheme.outline : ring.first,
        gradient: ring != null && ring.length > 1
            ? SweepGradient(colors: [...ring, ring.first])
            : null,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surface,
        ),
        child: Icon(icon, size: 22, color: scheme.onSurface),
      ),
    );
  }
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
          final l = AppLocalizations.of(context);
          final header = [
            if (copies > 1) '×$copies',
            if (card?.traded case final d?)
              l.tradedOn(DateFormat.MMMd(l.localeName).format(d)),
          ].join(' · ');
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: CardDetail(
              bird: bird,
              card: card,
              header: header.isEmpty
                  ? null
                  : Text(
                      header,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
      ? CardFlip(rarity: widget.card!.rarity ?? widget.bird.rarity, child: face)
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
          // In 3D like the boosters; the shared picture is taken inside, flat.
          child: Center(
            child: CardTilt(
              // Epic and Legendary cards are glossy; on a reveal, once the flip is done.
              shine:
                  card != null &&
                  tiers.indexOf(cardRarity(card)) >= tiers.indexOf('epic'),
              shineAfter: widget.flipIn
                  ? const Duration(milliseconds: 1100)
                  : Duration.zero,
              child: _flip(
                RepaintBoundary(
                  key: _boundary,
                  child: BirdCardView(bird: bird, card: card),
                ),
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
