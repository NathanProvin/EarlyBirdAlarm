import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../birds.dart';
import '../cards.dart';
import '../content.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
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
        padding: const EdgeInsets.all(24),
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
          if (!kReleaseMode) ...[
            const SizedBox(height: 32),
            Text(
              'Dev: preview a card reveal',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final t in tiers)
                  ActionChip(
                    label: Text(rarityName(l, t)),
                    labelStyle: TextStyle(color: rarityColor[t]),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => _Preview(t)),
                    ),
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
class _Preview extends StatelessWidget {
  const _Preview(this.rarity);
  final String rarity;

  @override
  Widget build(BuildContext context) {
    final bird = birds[Random().nextInt(birds.length)];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: CardDetail(
            bird: bird,
            card: rollCard(bird, store.region, rarity: rarity),
            flipIn: true,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
