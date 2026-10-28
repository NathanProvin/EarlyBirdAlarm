import 'package:flutter/material.dart';

import '../birds.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'credits.dart';
import 'region.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(l.settings)),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(l.difficulty, style: text.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<Difficulty>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: Difficulty.easy, label: Text(l.easy)),
                ButtonSegment(value: Difficulty.medium, label: Text(l.medium)),
                ButtonSegment(value: Difficulty.hard, label: Text(l.hard)),
              ],
              selected: {store.difficulty},
              onSelectionChanged: (s) => store.difficulty = s.single,
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l.seasonalBirds)),
                ButtonSegment(value: true, label: Text(l.allBirds)),
              ],
              selected: {store.allBirds},
              onSelectionChanged: (s) => store.allBirds = s.single,
            ),
            const SizedBox(height: 32),
            Text(l.language, style: text.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: '', label: Text(l.systemLanguage)),
                const ButtonSegment(value: 'en', label: Text('English')),
                const ButtonSegment(value: 'fr', label: Text('Français')),
              ],
              selected: {store.language ?? ''},
              onSelectionChanged: (s) =>
                  store.language = s.single.isEmpty ? null : s.single,
            ),
            const SizedBox(height: 32),
            Text(l.theme, style: text.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 'system', label: Text(l.systemLanguage)),
                ButtonSegment(value: 'dawn', label: Text(l.themeDawn)),
                ButtonSegment(value: 'dusk', label: Text(l.themeDusk)),
                ButtonSegment(value: 'forest', label: Text(l.themeForest)),
              ],
              selected: {store.theme},
              onSelectionChanged: (s) => store.theme = s.single,
            ),
            const SizedBox(height: 32),
            Text(l.region, style: text.titleMedium),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                store.region == null ? '—' : regionName(l, store.region!),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const RegionScreen()),
              ),
            ),
            const SizedBox(height: 48),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(l.credits, style: text.bodySmall),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CreditsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
