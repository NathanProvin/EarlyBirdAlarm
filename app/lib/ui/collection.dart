import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../birds.dart';
import '../cards.dart';
import '../content.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../remote_trade.dart' show myTrades;
import '../trade.dart' show lockedCards;
import 'booster.dart';
import 'card.dart';
import 'region.dart';
import 'series.dart';
import 'share.dart';
import 'trade.dart';
import 'theme.dart';
import 'twitch.dart' show PlusSheet;

/// A card's rarity; cards from before 3c have none and take their species' tier.
String cardRarity(CardData c) =>
    c.rarity ?? birdById(c.birdId)?.rarity ?? 'common';

/// Spare copies (2026-11-17): a duplicate is the same bird, rarity and art; of each set
/// of identical cards the best quality one is kept, the others are spares.
List<CardData> spareCards(List<CardData> cards) {
  final kept = <String, CardData>{};
  final spares = <CardData>[];
  for (final c in cards) {
    final art = birdById(c.birdId)?.artOf(c.photo)?.$1 ?? c.photo;
    final k = '${c.birdId}|${cardRarity(c)}|$art';
    switch (kept[k]) {
      case null:
        kept[k] = c;
      case final had when c.quality > had.quality:
        spares.add(had);
        kept[k] = c;
      default:
        spares.add(c);
    }
  }
  return spares;
}

/// The best copy of each owned bird, by bird id: the rarest, then the best quality.
Map<String, CardData> bestCards(List<CardData> cards) {
  final best = <String, CardData>{};
  for (final c in cards) {
    if (best[c.birdId] case final b? when _score(b) >= _score(c)) continue;
    best[c.birdId] = c;
  }
  return best;
}

// Views: the current region (default; a region view is its displayed name), every copy,
// the best copy of each species (shown as stacks), the species owned more than once, or
// every bird of the world.
const _all = 'all', _species = 'species', _duplicates = 'duplicates';
const _world = 'world';

enum _Sort { number, rarity, name, newest, quality }

/// Rarity, then quality: the best copy scores highest.
int _score(CardData c) => cardTiers.indexOf(cardRarity(c)) * 1000 + c.quality;

/// The Hero tag of a species' pile, flying from the grid to the opened pile.
String _pileHero(Bird b) => 'pile-${b.id}';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  // Opens on Collected by rarity (user, 2026-11-13); null is the current region.
  String? _view = _all;
  _Sort _sort = _Sort.rarity;
  String? _tier; // rarity filter, null = all
  final _fetching = <String>{}; // other regions' bird lists being downloaded
  // Crafting (Plus): the forge pill open (crafting mode with Plus), the cards picked.
  bool _craftMenu = false;
  bool get _crafting => _craftMenu && store.twitchPlus;
  final _picked = <String>{};

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  /// Forges [picked] into [result] (a rarity, or 'booster'), then plays the forge.
  Future<void> _forge(List<CardData> picked, String result) async {
    final l = AppLocalizations.of(context);
    // Cards offered in a trade stay put: the friend would still receive them.
    final Set<String> locked;
    try {
      locked = lockedCards(await myTrades());
    } on Exception {
      return _snack(l.accountError);
    }
    if (!mounted) return;
    if (picked.any((c) => locked.contains(c.key))) return _snack(l.craftLocked);
    final best = picked.reduce((a, b) => b.quality > a.quality ? b : a);
    final forged = result == 'booster'
        ? null
        : forgeCard(best, birdById(best.birdId), result);
    await store.craft(picked, forged);
    if (!mounted) return;
    setState(_picked.clear);
    unawaited(
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          opaque: false,
          pageBuilder: (_, _, _) => _ForgeScreen(picked, forged),
          transitionsBuilder: (_, a, _, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      ),
    );
  }

  /// What each recipe gives, in pictures only: any language reads it.
  void _recipes(AppLocalizations l) => showDialog<void>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      // Fixed widths, centred: the arrows line up on the dialog's middle.
      Widget row(int n, String? from, String to) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '$n×',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            _miniCard(from),
            Icon(Icons.arrow_forward, color: scheme.primary),
            _miniCard(to),
            const SizedBox(width: 32), // balances the count on the left
          ],
        ),
      );
      return AlertDialog(
        icon: Icon(Icons.hardware, color: scheme.primary),
        title: Text(l.craftRecipes),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row(2, null, 'booster'),
            for (final MapEntry(key: t, value: n) in craftCost.entries)
              row(n, t, tiers[tiers.indexOf(t) + 1]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      );
    },
  );

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

  /// The view, sort order and rarity filter, in one sheet (the header's first button).
  void _optionsSheet(
    AppLocalizations l,
    Map<String, String> views,
    String Function() view,
  ) => showModalBottomSheet<void>(
    isScrollControlled: true,
    context: context,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheet) {
        void set(VoidCallback change) {
          setState(change);
          setSheet(() {});
        }

        final title = Theme.of(context).textTheme.titleMedium;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.viewMenu, style: title),
              // Choosing a view closes the sheet: the collection shows at once.
              DropdownButton<String>(
                isExpanded: true,
                value: view(),
                items: [
                  for (final MapEntry(:key, value: label) in views.entries)
                    DropdownMenuItem(
                      value: key,
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) {
                  setState(() => _view = v);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 16),
              Text(l.sortMenu, style: title),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final (s, label) in [
                    (_Sort.number, l.sortNumber),
                    (_Sort.rarity, l.sortRarity),
                    (_Sort.name, l.sortName),
                    (_Sort.newest, l.sortNewest),
                    (_Sort.quality, l.sortQuality),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: _sort == s,
                      onSelected: (_) => set(() => _sort = s),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l.rarityMenu, style: title),
              const SizedBox(height: 8),
              // Six circles: all (empty), then each rarity; the choice named below.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final t in [null, ...cardTiers])
                    _RarityDot(
                      color: t == null ? null : rarityColor[t],
                      label: t == null ? l.allRarities : rarityName(l, t),
                      selected: _tier == t,
                      onTap: () => set(() => _tier = t),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _tier == null ? l.allRarities : rarityName(l, _tier!),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
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
    final others = groups.keys.where((n) => n != current).toList()
      ..sort((a, b) => wonIn[b]! - wonIn[a]!);
    var view = _view ?? current ?? _all;
    if (!{_all, _species, _duplicates, _world, ...groups.keys}.contains(view)) {
      view =
          current ??
          _all; // that region is gone (e.g. its cards were the only link)
    }
    // Rarity belongs to cards: a bird not won yet has none (the filter hides it).
    String? rarityOf(Bird b, CardData? c) => c == null ? null : cardRarity(c);
    int rank((Bird, CardData?) e) =>
        e.$2 == null ? -1 : cardTiers.indexOf(cardRarity(e.$2!));
    int byNumber((Bird, CardData?) a, (Bird, CardData?) b) =>
        a.$1.number.compareTo(b.$1.number);
    final plain = <String, String>{};
    String nameKey(Bird b) => plain[b.id] ??= plainText(b.nameIn(l.localeName));
    final int Function((Bird, CardData?), (Bird, CardData?)) order =
        switch (_sort) {
          _Sort.number => byNumber,
          _Sort.rarity => (a, b) {
            final t = rank(b) - rank(a);
            return t != 0 ? t : byNumber(a, b);
          },
          _Sort.name => (a, b) => nameKey(a.$1).compareTo(nameKey(b.$1)),
          // Birds not won yet go last.
          _Sort.newest =>
            (a, b) =>
                (b.$2?.earned.millisecondsSinceEpoch ?? 0) -
                (a.$2?.earned.millisecondsSinceEpoch ?? 0),
          _Sort.quality => (
            a,
            b,
          ) => (b.$2?.quality ?? -1) - (a.$2?.quality ?? -1),
        };
    final spares = spareCards(cards);
    final spareSpecies = {for (final c in spares) c.birdId};
    final copiesOf = <String, int>{};
    for (final c in cards) {
      copiesOf[c.birdId] = (copiesOf[c.birdId] ?? 0) + 1;
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
    // (bird, card) entries; a null card is a "?" or "heard" tile (region and world views).
    final entries = switch (view) {
      _all => [
        for (final c in cards)
          if (birdById(c.birdId) case final b?) (b, c as CardData?),
      ],
      _species => [
        for (final c in best.values)
          if (birdById(c.birdId) case final b?) (b, c as CardData?),
      ],
      // Crafting: every spare copy on its own, ready to pick (the best copies stay out).
      _duplicates when _crafting => [
        for (final c in spares)
          if (birdById(c.birdId) case final b?) (b, c as CardData?),
      ],
      _duplicates => [
        for (final c in best.values)
          if (spareSpecies.contains(c.birdId))
            if (birdById(c.birdId) case final b?) (b, c as CardData?),
      ],
      _world => [for (final b in species.values) (b, best[b.id])],
      final region => [
        for (final id in idsOf(region))
          if (birdById(id) case final b?) (b, best[id]),
      ],
    }..sort(order);
    final shown = [
      for (final e in entries)
        if (_tier == null || rarityOf(e.$1, e.$2) == _tier) e,
    ];
    final openable = [
      for (final e in shown)
        if (e.$2 != null || heard.contains(e.$1.id)) e,
    ];
    // Region and world views' many "?" stay 3 per row; won cards are shown whole 2 per row.
    final compact = view != _all && view != _species && view != _duplicates;
    // "France (7/353)"; "USA — Northeast (2)" until that region's list has arrived.
    String regionLabel(String name) {
      final known = groups[name]!.every((r) => _birdsOf(r) != null);
      final ids = idsOf(name);
      final owned = ids.where(best.containsKey).length;
      return '$name ($owned${known ? '/${ids.length}' : ''})';
    }

    final views = {
      for (final r in [?current]) r: regionLabel(r),
      _all: '${l.viewAll} (${cards.length})',
      _species: '${l.viewSpecies} (${best.length})',
      _duplicates: '${l.viewDuplicates} (${spares.length})',
      for (final r in others) r: regionLabel(r),
      _world:
          '${l.viewWorld} '
          '(${species.keys.where(best.containsKey).length}/${species.length})',
    };
    // The view names alone, for the pill.
    final viewNames = {
      for (final r in [?current, ...others]) r: r,
      _all: l.viewAll,
      _species: l.viewSpecies,
      _duplicates: l.viewDuplicates,
      _world: l.viewWorld,
    };
    Widget round(String tip, VoidCallback onTap, Widget child) => Tooltip(
      message: tip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: child,
      ),
    );
    final picked = [
      for (final c in cards)
        if (_picked.contains(c.key)) c,
    ];
    final result = craftResult(
      [for (final c in picked) cardRarity(c)],
      [for (final c in picked) c.birdId],
    );
    void open(Widget screen) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => screen));
    final grid = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          // The view (its name, as wide as the row allows), sort and filter, search; Trade
          // and Series on the right.
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // The view's name at a fixed width; view, sort and filter in one sheet.
              Tooltip(
                message: l.viewMenu,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () =>
                      _optionsSheet(l, views, () => _view ?? current ?? _all),
                  child: _Pill(
                    viewNames[view]!,
                    // The chosen rarity's colour while filtering.
                    ring: _tier == null ? null : rarityColor[_tier],
                  ),
                ),
              ),
              round(
                l.searchCollection,
                () => showSearch(
                  context: context,
                  delegate: _CollectionSearch(l.searchCollection),
                ),
                const _Round(icon: Icons.search),
              ),
              round(
                l.trade,
                () => open(const FriendPickerScreen()),
                const _Round(icon: Icons.swap_horiz),
              ),
              round(
                l.series,
                () => open(const SeriesScreen()),
                // A dot while a completed series or achievement waits to be collected.
                Badge(
                  isLabelVisible: store.anyClaimable,
                  smallSize: 8,
                  backgroundColor: scheme.primary,
                  child: _Round(
                    icon: Icons.military_tech,
                    color: scheme.primary,
                  ),
                ),
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
              final copies = view == _all || _crafting
                  ? 1
                  : copiesOf[b.id] ?? 0;
              // Species and Duplicates: a pile opens into its copies.
              final pile = !compact && copies > 1;
              if (_crafting) {
                final on = c != null && _picked.contains(c.key);
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CardTile(
                        bird: b,
                        card: c,
                        heard: heard.contains(b.id),
                        compact: compact,
                        onTap: c == null
                            ? null
                            : () {
                                unawaited(HapticFeedback.selectionClick());
                                setState(() {
                                  if (!_picked.remove(c.key)) {
                                    _picked.add(c.key);
                                  }
                                });
                              },
                      ),
                    ),
                    if (on)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radius),
                              border: Border.all(
                                color: scheme.primary,
                                width: 4,
                              ),
                            ),
                            child: Align(
                              alignment: const Alignment(0.9, -0.95),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: scheme.primary,
                                child: Icon(
                                  Icons.check,
                                  size: 18,
                                  color: scheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }
              return CardTile(
                bird: b,
                card: c,
                copies: copies,
                heard: heard.contains(b.id),
                compact: compact,
                heroTag: pile ? _pileHero(b) : null,
                onTap: pile
                    ? () {
                        unawaited(HapticFeedback.selectionClick());
                        Navigator.of(context).push(
                          PageRouteBuilder<void>(
                            transitionDuration: const Duration(
                              milliseconds: 350,
                            ),
                            pageBuilder: (_, _, _) => _PileScreen(b),
                            transitionsBuilder: (_, a, _, child) =>
                                FadeTransition(opacity: a, child: child),
                          ),
                        );
                      }
                    : open < 0
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
    // Crafting, in the thumb's reach: the hammer, and its pill sliding out to the left.
    final plus = store.twitchPlus;
    final small = Theme.of(context).textTheme.bodySmall;
    final pill = Material(
      key: const ValueKey('forge'),
      elevation: 3,
      color: scheme.surfaceContainerHigh,
      shape: StadiumBorder(side: BorderSide(color: scheme.primary, width: 2)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 56,
          maxWidth: MediaQuery.sizeOf(context).width - 32 - 56 - 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l.craftRecipes,
              icon: Icon(Icons.info_outline, color: scheme.primary),
              onPressed: () => _recipes(l),
            ),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.craftTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Without Plus: say it's paid; nothing picked: the pitch; else what
                  // the picked cards give, in pictures.
                  if (!plus || picked.isEmpty)
                    Text(
                      plus ? l.craftPitch : l.craftPlusOnly,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: small,
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Text('${picked.length}×', style: small),
                        const Icon(Icons.arrow_forward, size: 14),
                        if (result == null)
                          const Icon(Icons.block, size: 14)
                        else
                          _miniCard(result, width: 12),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 6, 0),
              child: !plus
                  ? FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      icon: const Icon(Icons.bolt),
                      label: const Text('Plus'),
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        builder: (_) => const PlusSheet(),
                      ),
                    )
                  : picked.isEmpty
                  ? const SizedBox(width: 8)
                  : FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: result == null
                          ? null
                          : () => _forge(picked, result),
                      child: Text(l.craftAction),
                    ),
            ),
          ],
        ),
      ),
    );
    return Stack(
      children: [
        grid,
        Positioned(
          right: 16,
          bottom: 16 + MediaQuery.paddingOf(context).bottom,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              // Grows out of the hammer, right to left, and folds back into it.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SizeTransition(
                    sizeFactor: a,
                    axis: Axis.horizontal,
                    alignment: AlignmentDirectional.centerEnd,
                    child: child,
                  ),
                ),
                child: _craftMenu ? pill : const SizedBox.shrink(),
              ),
              _Hammer(
                tooltip: l.craftTitle,
                on: _craftMenu,
                onTap: () {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() {
                    _craftMenu = !_craftMenu;
                    _picked.clear();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A small card in a rarity's colour; null is "any card" (every rarity's colour) and
/// 'booster' a booster: the recipes and the forge pill, readable in any language.
Widget _miniCard(String? rarity, {double width = 22}) {
  final size = Size(width, width * 1.4);
  if (rarity == 'booster') {
    return SizedBox.fromSize(size: size, child: const BoosterFace());
  }
  return Container(
    width: size.width,
    height: size.height,
    decoration: BoxDecoration(
      color: rarityColor[rarity],
      gradient: rarity == null
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [for (final t in tiers) rarityColor[t]!],
            )
          : null,
      borderRadius: BorderRadius.circular(width / 6),
      border: Border.all(color: ink, width: 1.5),
    ),
  );
}

/// The crafting button: a round hammer in the Plus bolt's and the radar's colours,
/// beating slowly to be noticed; filled with the accent while crafting is on.
class _Hammer extends StatefulWidget {
  const _Hammer({required this.tooltip, required this.on, required this.onTap});
  final String tooltip;
  final bool on;
  final VoidCallback onTap;

  @override
  State<_Hammer> createState() => _HammerState();
}

class _HammerState extends State<_Hammer> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  bool _started = false;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 10 beats (30 s) each time the Collection opens, then rest: seen, never nagging.
    if (!_started && !MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _pulse.repeat(count: 10);
    }
    if (widget.on && _pulse.isAnimating) _pulse.reset();
    return Tooltip(
      message: widget.tooltip,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            // A beat in the first half of each cycle, then rest (as PulseButton).
            final beat = sin((_pulse.value / 0.5).clamp(0.0, 1.0) * pi);
            return DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.25 + 0.6 * beat),
                    blurRadius: 8 + 16 * beat,
                    spreadRadius: 1 + 6 * beat,
                  ),
                ],
              ),
              child: Material(
                shape: const CircleBorder(),
                color: widget.on ? scheme.primary : scheme.secondaryContainer,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.onTap,
                  child: SizedBox.square(
                    dimension: 56,
                    child: Transform.scale(
                      scale: 1 + 0.35 * beat,
                      child: Icon(
                        Icons.hardware,
                        color: widget.on ? scheme.onPrimary : scheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The forge (2026-11-23): the used cards gather from a ring into one pile (the pile
/// screen's deal, backward), the pile shakes under three hammer blows, flashes in the new
/// rarity's colour, and the forged card flips in (or a booster appears).
class _ForgeScreen extends StatefulWidget {
  const _ForgeScreen(this.used, this.forged);
  final List<CardData> used;
  final CardData? forged; // null: a booster

  @override
  State<_ForgeScreen> createState() => _ForgeScreenState();
}

class _ForgeScreenState extends State<_ForgeScreen>
    with SingleTickerProviderStateMixin {
  late final _forge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    _forge.forward().whenComplete(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _forge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final forged = widget.forged;
    final glow = forged == null
        ? Theme.of(context).colorScheme.primary
        : rarityColor[forged.rarity]!;
    void close() => Navigator.of(context).pop();
    final Widget body;
    if (_forge.isCompleted && forged != null) {
      body = CardDetail(
        bird: birdById(forged.birdId)!,
        card: forged,
        flipIn: true,
        onClose: close,
      );
    } else if (_forge.isCompleted) {
      body = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 24,
        children: [
          TweenAnimationBuilder(
            tween: Tween(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (_, s, child) => Transform.scale(scale: s, child: child),
            child: const SizedBox(
              width: 140,
              height: 196,
              child: BoosterFace(),
            ),
          ),
          Text(
            l.craftBooster,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: Colors.white),
          ),
          RoundButton(icon: Icons.close, tooltip: l.done, onPressed: close),
        ],
      );
    } else {
      final used = [
        for (final c in widget.used)
          if (birdById(c.birdId) case final b?) (b, c),
      ];
      body = LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth * 0.32, h = w / 0.68;
          final reach = box.maxWidth * 0.3;
          return AnimatedBuilder(
            animation: _forge,
            builder: (context, _) {
              final v = _forge.value;
              final gather = Curves.easeInCubic.transform(
                (v / 0.45).clamp(0.0, 1.0),
              );
              // Three hammer blows, then the flash.
              final shake = v < 0.45 || v > 0.75
                  ? 0.0
                  : sin((v - 0.45) / 0.3 * 6 * pi);
              final flash = v < 0.7 ? 0.0 : sin((v - 0.7) / 0.3 * pi);
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (final (i, (b, c)) in used.indexed)
                    Transform.translate(
                      offset:
                          Offset.fromDirection(
                            2 * pi * i / used.length - pi / 2,
                            reach,
                          ) *
                          (1 - gather),
                      child: Transform.rotate(
                        angle:
                            (i.isOdd ? -1 : 1) * 0.06 * gather + 0.05 * shake,
                        child: SizedBox(
                          width: w,
                          height: h,
                          child: CardTile(bird: b, card: c, heard: false),
                        ),
                      ),
                    ),
                  IgnorePointer(
                    child: Container(
                      width: w * (1 + 3 * flash),
                      height: w * (1 + 3 * flash),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: flash),
                            glow.withValues(alpha: 0.7 * flash),
                            glow.withValues(alpha: 0),
                          ],
                        ),
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
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(12), child: body),
      ),
    );
  }
}

/// The view button: the current view's name in an outlined pill of fixed width, the
/// options icon after it; [ring] colours the outline while a rarity filter is on.
class _Pill extends StatelessWidget {
  const _Pill(this.label, {this.ring});
  final String label;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A 40 dp pill in a 48 dp touch target, like the round buttons.
    return SizedBox(
      height: 48,
      child: Center(
        child: Container(
          width: 120,
          height: 40,
          padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
          decoration: BoxDecoration(
            border: Border.all(color: ring ?? scheme.outline, width: 2.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.tune, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lower case without accents, to match what the user types: "eider a duvet" finds
/// "Eider à duvet", "kohlmeise" finds "Kohlmeise".
String plainText(String s) {
  const from = 'àáâäãåçèéêëìíîïñòóôöõùúûüýÿœæß';
  const to = 'aaaaaaceeeeiiiinooooouuuuyyoas';
  final out = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    final i = from.indexOf(c);
    out.write(i < 0 ? c : to[i]);
  }
  return out.toString();
}

/// Whether [bird] matches the typed [query] (already [plainText]): a word of its name in
/// [locale], in English or in Latin starts with it ("tit" finds Coal Tit, not Actitis).
/// Shared by the collection search and the Expert quiz.
bool nameMatches(Bird bird, String query, String locale) =>
    [bird.nameIn(locale), bird.name, bird.latin].any(
      (n) => RegExp('(^|[ \'-])${RegExp.escape(query)}').hasMatch(plainText(n)),
    );

/// Search the species of the collection by name, in the app's language, English or Latin;
/// the matches update as the user types. A match opens its best card.
class _CollectionSearch extends SearchDelegate<void> {
  _CollectionSearch(String hint) : super(searchFieldLabel: hint);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cards = store.cards;
    final q = plainText(query.trim());
    final matches =
        [
          for (final MapEntry(key: id, value: card) in bestCards(cards).entries)
            if (birdById(id) case final b?)
              if (q.isEmpty || nameMatches(b, q, l.localeName))
                (b, card as CardData?),
        ]..sort(
          (a, b) =>
              a.$1.nameIn(l.localeName).compareTo(b.$1.nameIn(l.localeName)),
        );
    if (matches.isEmpty) {
      return Center(
        child: Text(
          l.noSpeciesFound,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, i) {
        final (bird, card) = matches[i];
        final rarity = card?.rarity ?? bird.rarity;
        final copies = cards.where((c) => c.birdId == bird.id).length;
        return ListTile(
          leading: SizedBox.square(
            dimension: 48,
            child: ClipOval(child: BirdPhoto(bird)),
          ),
          title: Text(bird.nameIn(l.localeName)),
          subtitle: Text(
            bird.latin,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
          trailing: Text(
            copies > 1
                ? '${rarityName(l, rarity)} ×$copies'
                : rarityName(l, rarity),
            style: TextStyle(
              color: rarityColor[rarity],
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CardPager(entries: matches, initial: i),
            ),
          ),
        );
      },
    );
  }
}

/// One rarity choice in the filter: a filled circle in [color], or an empty one for
/// all; the chosen one gets a ring.
class _RarityDot extends StatelessWidget {
  const _RarityDot({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final Color? color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? scheme.onSurface : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: color == null
                  ? Border.all(color: scheme.outline, width: 2.5)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// A 40 dp round header button: an outline in the theme's colour around [icon].
class _Round extends StatelessWidget {
  const _Round({required this.icon, this.color});
  final IconData icon;
  final Color? color; // the icon's, else the text colour

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final circle = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outline, width: 2.5),
      ),
      child: Icon(icon, size: 22, color: color ?? scheme.onSurface),
    );
    // A 40 dp circle in a 48 dp touch target (Android's minimum).
    return SizedBox.square(dimension: 48, child: Center(child: circle));
  }
}

/// Full cards, swipe left/right between them.
class CardPager extends StatelessWidget {
  const CardPager({required this.entries, required this.initial, super.key});
  final List<(Bird, CardData?)> entries;
  final int initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: entries.length,
        itemBuilder: (_, i) {
          final (bird, card) = entries[i];
          final l = AppLocalizations.of(context);
          final traded = card?.traded;
          return Padding(
            // Clear of the navigation bar (3-button mode is 48 dp, opaque).
            padding: EdgeInsets.fromLTRB(
              12,
              0,
              12,
              12 + MediaQuery.paddingOf(context).bottom,
            ),
            child: CardDetail(
              bird: bird,
              card: card,
              // No ×N here: it read as this copy's own count (user, 2026-11-17).
              header: traded == null
                  ? null
                  : Text(
                      l.tradedOn(DateFormat.MMMd(l.localeName).format(traded)),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
            ),
          );
        },
      ),
    );
  }
}

/// A species' pile opened (2026-11-17): every copy, best first. The top card flies in
/// from the grid (Hero); the others are dealt from under it to their places.
class _PileScreen extends StatefulWidget {
  const _PileScreen(this.bird);
  final Bird bird;

  @override
  State<_PileScreen> createState() => _PileScreenState();
}

class _PileScreenState extends State<_PileScreen>
    with SingleTickerProviderStateMixin {
  late final _deal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..forward();

  @override
  void dispose() {
    _deal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bird = widget.bird;
    final copies = [
      for (final c in store.cards)
        if (c.birdId == bird.id) c,
    ]..sort((a, b) => _score(b) - _score(a));
    final entries = [for (final c in copies) (bird, c as CardData?)];
    const pad = 12.0, gap = 12.0;
    return Scaffold(
      appBar: AppBar(
        title: Text('${bird.nameIn(l.localeName)} ×${copies.length}'),
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          final w = (box.maxWidth - 2 * pad - gap) / 2, h = w / 0.68;
          // From copy i's place back to the top card's.
          Offset toTop(int i) =>
              Offset(-(i % 2) * (w + gap), -(i ~/ 2) * (h + gap));
          return GridView.builder(
            padding: EdgeInsets.fromLTRB(
              pad,
              4,
              pad,
              pad + MediaQuery.paddingOf(context).bottom,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
            ),
            itemCount: copies.length,
            itemBuilder: (context, i) {
              final tile = CardTile(
                bird: bird,
                card: copies[i],
                heard: false,
                heroTag: i == 0 ? _pileHero(bird) : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CardPager(entries: entries, initial: i),
                  ),
                ),
              );
              if (i == 0) return tile;
              // Once the top card has landed, one card every 60 ms, tilted as in a pile.
              final begin = min(0.25 + 0.06 * i, 0.65);
              final t = CurvedAnimation(
                parent: _deal,
                curve: Interval(
                  begin,
                  begin + 0.35,
                  curve: Curves.easeOutCubic,
                ),
              );
              final tilt = (i.isOdd ? -1 : 1) * (0.04 + 0.02 * (i % 3));
              return AnimatedBuilder(
                animation: t,
                builder: (_, child) => Transform.translate(
                  offset: toTop(i) * (1 - t.value),
                  child: Transform.rotate(
                    angle: tilt * (1 - t.value),
                    child: child,
                  ),
                ),
                child: tile,
              );
            },
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

  /// The species' Wikipedia article in the app's language, found by its Latin name ("go"
  /// opens the article directly when the name is a title or redirect).
  void _wikipedia(String lang) => launchUrl(
    Uri.https('$lang.wikipedia.org', '/w/index.php', {
      'search': widget.bird.latin,
      'go': 'Go',
    }),
    mode: LaunchMode.externalApplication,
  );

  Future<void> _share() => shareCard(
    context,
    _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary,
    widget.bird,
    widget.card!,
  );

  void _credits(Recording? recording) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final credit in [
            ?recording?.credit,
            widget.bird.photoOf(widget.card?.photo).credit,
          ])
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
          rarity: widget.card!.rarity ?? widget.bird.rarity,
          kind: widget.bird.photoOf(widget.card!.photo).kind,
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
    final face = _flip(
      RepaintBoundary(
        key: _boundary,
        child: BirdCardView(
          bird: bird,
          card: card,
          play: card == null
              ? widget.recording?.file ?? playableFile(bird)
              : null,
        ),
      ),
    );
    return Column(
      children: [
        Expanded(
          // The card centered, leaving at least 48 dp above and below; the header midway
          // in the space above it. The header never moves the card, so cards line up.
          child: LayoutBuilder(
            builder: (context, box) {
              final height = min(box.maxHeight - 96, box.maxWidth / 0.68);
              final above = (box.maxHeight - height) / 2;
              return Stack(
                children: [
                  if (header != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: above,
                      // Shrinks to fit there (two lines at a large font size).
                      child: FittedBox(fit: BoxFit.scaleDown, child: header),
                    ),
                  Center(
                    child: SizedBox(
                      height: height,
                      // In 3D like the boosters; the shared picture is taken inside, flat.
                      // A heard card stays still: its blurs would be redrawn at every tilt
                      // step (~60 a second), which dropped frames on the wrong-guess reveal.
                      child: card == null
                          ? face
                          : CardTilt(
                              // Epic and Legendary cards are glossy; on a reveal, once the flip is done.
                              shine:
                                  cardTiers.indexOf(cardRarity(card)) >=
                                  cardTiers.indexOf('epic'),
                              shineAfter: widget.flipIn
                                  ? const Duration(milliseconds: 1100)
                                  : Duration.zero,
                              child: face,
                            ),
                    ),
                  ),
                ],
              );
            },
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
                onPressed: _share,
              ),
            RoundButton(
              icon: Icons.info_outline,
              tooltip: l.credits,
              onPressed: () => _credits(recording),
            ),
            // In the collection (not on the reveal, which has Close instead).
            if (onClose == null) ...[
              RoundButton(
                tooltip: l.wikipedia,
                onPressed: () => _wikipedia(l.localeName.split('_').first),
                // Wikipedia's serif "W".
                child: Text(
                  'W',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 28,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
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

/// A big round button (Share, Close) showing [icon], or [child] instead.
class RoundButton extends StatelessWidget {
  const RoundButton({
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.child,
    super.key,
  });
  final IconData? icon;
  final Widget? child;
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
    icon: child ?? Icon(icon),
  );
}
