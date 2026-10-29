import 'package:flutter/material.dart';

import '../birds.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'credits.dart';
import 'region.dart';
import 'theme.dart';

/// A theme to pick: a disc of its background with its accent in the middle ("Phone":
/// half light theme, half dark theme), its name below, a ring when selected.
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch(this.value, this.label);
  final String value, label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = store.theme == value;
    Widget disc(Palette p) => ColoredBox(
      color: p.background,
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
        ),
      ),
    );
    final face = switch (palettes[value]) {
      final p? => disc(p),
      null => Row(
        children: [
          for (final t in [lightTheme, darkTheme])
            Expanded(child: ColoredBox(color: palettes[t]!.background)),
        ],
      ),
    };
    return Semantics(
      button: true,
      selected: on,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => store.theme = value,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: on ? scheme.primary : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                  child: face,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: on ? scheme.primary : null,
                  fontWeight: on ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            const SizedBox(height: 32),
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
            const SizedBox(height: 8),
            Text(
              '${switch (store.difficulty) {
                Difficulty.easy => l.easyInfo,
                Difficulty.medium => l.mediumInfo,
                Difficulty.hard => l.hardInfo,
              }} ${store.allBirds ? l.allBirdsInfo : l.seasonalInfo}',
              style: text.bodySmall,
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
            Row(
              children: [
                for (final (value, label) in [
                  ('system', l.systemLanguage),
                  ('blackbird', l.themeBlackbird),
                  ('greenfinch', l.themeGreenfinch),
                  ('bluetit', l.themeBlueTit),
                  ('gull', l.themeGull),
                ])
                  Expanded(child: _ThemeSwatch(value, label)),
              ],
            ),
            const SizedBox(height: 32),
            Text(l.credits, style: text.titleMedium),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.creditsSubtitle),
              trailing: const Icon(Icons.chevron_right),
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
