import 'package:flutter/material.dart';

import '../birds.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

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
            const SizedBox(height: 32),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.allBirds),
              subtitle: Text(l.allBirdsHint),
              value: store.allBirds,
              onChanged: (on) => store.allBirds = on,
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
            Text(l.region, style: text.titleMedium),
            const SizedBox(height: 8),
            // shortcut: one bundled region until the region picker in Iteration 3c.
            Text(l.northernFrance, style: text.bodyLarge),
            const SizedBox(height: 48),
            Text(l.dataSources, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
