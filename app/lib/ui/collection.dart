import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../birds.dart';
import '../cards.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'card.dart';
import 'theme.dart';

/// The best copy of each owned bird, by bird id.
Map<String, CardData> bestCards(List<CardData> cards) {
  final best = <String, CardData>{};
  for (final c in cards) {
    if ((best[c.birdId]?.quality ?? -1) < c.quality) best[c.birdId] = c;
  }
  return best;
}

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  String? _tier; // rarity filter, null = all

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final cards = store.cards;
    final best = bestCards(cards);
    final heard = store.heard;
    // The region's birds, plus cards won in another region.
    final regionIds = {for (final b in birds) b.id};
    final all = [
      ...birds,
      for (final id in best.keys)
        if (!regionIds.contains(id) && species[id] != null) species[id]!,
    ]..sort((a, b) => a.number.compareTo(b.number));
    String rarityOf(Bird b) => best[b.id]?.rarity ?? b.rarity;
    final shown = [
      for (final b in all)
        if (_tier == null || rarityOf(b) == _tier) b,
    ];
    final openable = [
      for (final b in shown)
        if (best.containsKey(b.id) || heard.contains(b.id)) b,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Text(
            l.progress(
              best.keys.where(regionIds.contains).length,
              birds.length,
            ),
            style: text.titleMedium,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              for (final t in tiers)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(rarityName(l, t)),
                    showCheckmark: false,
                    selected: _tier == t,
                    selectedColor: rarityColor[t],
                    onSelected: (on) => setState(() => _tier = on ? t : null),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 5 / 7,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: shown.length,
            itemBuilder: (context, i) {
              final b = shown[i];
              final open = openable.indexOf(b);
              return CardTile(
                bird: b,
                owned: cards.where((c) => c.birdId == b.id).length,
                rarity: best[b.id]?.rarity,
                heard: heard.contains(b.id),
                onTap: open < 0
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CardPager(birds: openable, initial: open),
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

/// Full cards, swipe left/right between them.
class CardPager extends StatelessWidget {
  const CardPager({required this.birds, required this.initial, super.key});
  final List<Bird> birds;
  final int initial;

  @override
  Widget build(BuildContext context) {
    final cards = store.cards;
    final best = bestCards(cards);
    return Scaffold(
      appBar: AppBar(),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: birds.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: CardDetail(
            bird: birds[i],
            card: best[birds[i].id],
            copies: cards.where((c) => c.birdId == birds[i].id).length,
          ),
        ),
      ),
    );
  }
}

/// A card with its copy count and a share button.
class CardDetail extends StatefulWidget {
  const CardDetail({
    required this.bird,
    this.card,
    this.copies = 0,
    this.isNew = false,
    super.key,
  });
  final Bird bird;
  final CardData? card;
  final int copies;
  final bool isNew;

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final CardDetail(:bird, :card, :copies, :isNew) = widget;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: RepaintBoundary(
              key: _boundary,
              child: BirdCardView(bird: bird, card: card),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isNew)
                Text(
                  l.newCard,
                  style: text.titleMedium?.copyWith(color: coral),
                ),
              if (copies > 1) Text('×$copies', style: text.titleMedium),
              if (card != null) ...[
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => _share(bird.id),
                  icon: const Icon(Icons.share_outlined),
                  label: Text(l.share),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
