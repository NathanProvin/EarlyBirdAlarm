import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../birds.dart';
import '../cards.dart';
import '../content.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../store.dart';
import 'card.dart';
import 'collection.dart';
import 'theme.dart';

/// Where the birds, songs, photos and card stats come from, their licenses, and the privacy policy.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // privacy-fr.html, privacy-de.html… (site-static); English is privacy.html.
    final lang = l.localeName.split('_').first;
    final page = lang == 'en' ? 'privacy.html' : 'privacy-$lang.html';
    return Scaffold(
      appBar: AppBar(title: Text(l.credits)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(l.creditsBody, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  launchUrl(Uri.parse(baseUrl.replaceFirst('v1/', page))),
              child: Text(l.privacyPolicy),
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder(
            future: const MethodChannel('early_bird/version')
                .invokeMethod<String>('get'),
            builder: (context, v) => Text(
              v.hasData ? l.version(v.data!) : '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          // Test builds only: see the reveal of each rarity (nothing is saved).
          if (devTools) ...[
            const SizedBox(height: 32),
            Text(
              'Dev: preview a card reveal',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final (t, kind) in [
                  for (final t in tiers) (t, null),
                  ('shiny', 'leucistic'),
                  ('shiny', 'melanistic'),
                ])
                  ActionChip(
                    label: Text(
                      kind == null
                          ? rarityName(l, t)
                          : '${l.shiny} · ${shinyKindName(l, kind)}',
                    ),
                    labelStyle: TextStyle(color: rarityColor[t]),
                    onPressed: () => _preview(context, t, kind),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const _DevDraw(),
          ],
        ],
      ),
    );
  }
}

/// Test builds only: wins [count] Twitch cards in a row through the real path (the bird
/// the deck offers, a correct answer, the deck refilled with real downloads), to measure
/// species diversity and rarities on the phone. It writes to the real collection: back
/// the saved data up first (adb) and restore it after. Leaving the screen stops it.
class _DevDraw extends StatefulWidget {
  const _DevDraw();

  @override
  State<_DevDraw> createState() => _DevDrawState();
}

class _DevDrawState extends State<_DevDraw> {
  static const count = 1000;
  int? _done;

  Future<void> _run() async {
    for (var i = 0; i < count && mounted; i++) {
      final (bird, rec) = store.pickNext(DateTime.now());
      await store.answered(null, bird, rec, true, '');
      await store.sync();
      if (mounted) setState(() => _done = i + 1);
    }
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: ActionChip(
      label: Text(
        _done == null
            ? 'Dev: draw $count Twitch cards'
            : 'Dev: drawn $_done / $count',
      ),
      onPressed: _done == null ? _run : null,
    ),
  );
}

/// A card of [rarity] for a random bird of the region, revealed as if just won; not saved.
/// Opens a reveal of [rarity]. A Shiny one needs a bird with a photo of that [kind]: one of
/// the region if there is one, else any (a random region bird mostly has none, and then
/// rollCard falls back to Legendary: the bug seen on 2026-11-11).
void _preview(BuildContext context, String rarity, String? kind) {
  bool fits(Bird b) =>
      b.shiny.isNotEmpty && b.shiny.every((s) => s.kind == kind);
  final pool = kind == null
      ? birds
      : [
          ...birds.where(fits),
          if (!birds.any(fits)) ...species.values.where(fits),
        ];
  if (pool.isEmpty) return;
  final bird = pool[Random().nextInt(pool.length)];
  final card = rollCard(bird, store.region, rarity: rarity);
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => _Preview(bird, card)));
}

class _Preview extends StatelessWidget {
  const _Preview(this.bird, this.card);
  final Bird bird;
  final CardData card; // rolled once: a rebuild must not show another card

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: CardDetail(
            bird: bird,
            card: card,
            flipIn: true,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
