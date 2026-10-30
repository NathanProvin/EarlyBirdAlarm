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
    final page = l.localeName.startsWith('fr')
        ? 'privacy-fr.html'
        : 'privacy.html';
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
          ],
        ],
      ),
    );
  }
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
