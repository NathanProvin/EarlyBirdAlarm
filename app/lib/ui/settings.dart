import 'package:flutter/material.dart';

import '../birds.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'bird_icon.dart';
import 'credits.dart';
import 'region.dart';
import 'theme.dart';

/// "Phone": a little phone, its left half the light theme with a sun, its right half
/// the dark theme with a crescent moon.
class _PhonePainter extends CustomPainter {
  const _PhonePainter(this.outline);
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final light = palettes[lightTheme]!, dark = palettes[darkTheme]!;
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(30, 14, 40, 72),
      const Radius.circular(9),
    );
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = outline;
    canvas
      ..save()
      ..scale(size.width / 100, size.height / 100)
      ..save()
      ..clipRRect(body)
      ..drawRect(
        const Rect.fromLTWH(30, 14, 20, 72),
        Paint()..color = light.background,
      )
      ..drawRect(
        const Rect.fromLTWH(50, 14, 20, 72),
        Paint()..color = dark.background,
      )
      ..restore()
      ..drawCircle(const Offset(40, 50), 5, Paint()..color = light.accent)
      ..drawCircle(const Offset(60, 50), 5, Paint()..color = dark.accent)
      ..drawCircle(
        const Offset(62.5, 48),
        4.2,
        Paint()..color = dark.background,
      )
      ..drawRRect(body, line)
      ..drawLine(const Offset(45, 21), const Offset(55, 21), line)
      ..restore();
  }

  @override
  bool shouldRepaint(_PhonePainter oldDelegate) =>
      oldDelegate.outline != outline;
}

/// A theme to pick: its bird on the theme's surface color ("Phone": the phone icon), its
/// palette as dots (background · surface · accent), its name; a ring when selected.
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch(this.value, this.label);
  final String value, label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = store.theme == value;
    final p = palettes[value];
    final dots = p == null
        ? [palettes[lightTheme]!.background, palettes[darkTheme]!.background]
        : [p.background, p.surface, p.accent];
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
                width: 58,
                height: 58,
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
                    // The surface, not the background: a black blackbird and a
                    // white gull stand out on it.
                    color: p?.surface ?? scheme.secondaryContainer,
                    border: Border.all(
                      color: scheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: CustomPaint(
                      painter: p == null
                          ? _PhonePainter(scheme.onSurface)
                          : BirdPainter(
                              plumages[value]!,
                              gull: value == 'gull',
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 3,
                children: [
                  for (final c in dots)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.onSurface.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                    ),
                ],
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
            const SizedBox(height: 6),
            Text(switch (store.difficulty) {
              Difficulty.easy => l.easyInfo,
              Difficulty.medium => l.mediumInfo,
              Difficulty.hard => l.hardInfo,
            }, style: text.bodySmall),
            const SizedBox(height: 14),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l.seasonalBirds)),
                ButtonSegment(value: true, label: Text(l.allBirds)),
              ],
              selected: {store.allBirds},
              onSelectionChanged: (s) => store.allBirds = s.single,
            ),
            const SizedBox(height: 6),
            Text(
              store.allBirds ? l.allBirdsInfo : l.seasonalInfo,
              style: text.bodySmall,
            ),
            const SizedBox(height: 32),
            Text(l.language, style: text.titleMedium),
            const SizedBox(height: 8),
            // Each language written in itself; '' follows the phone.
            DropdownMenu<String>(
              expandedInsets: EdgeInsets.zero,
              initialSelection: store.language ?? '',
              dropdownMenuEntries: [
                DropdownMenuEntry(value: '', label: l.systemLanguage),
                for (final (code, name) in const [
                  ('en', 'English'),
                  ('fr', 'Français'),
                  ('de', 'Deutsch'),
                  ('es', 'Español'),
                ])
                  DropdownMenuEntry(value: code, label: name),
              ],
              onSelected: (v) =>
                  store.language = v == null || v.isEmpty ? null : v,
            ),
            const SizedBox(height: 32),
            Text(l.theme, style: text.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final (value, label) in [
                  ('system', l.systemLanguage),
                  ('blackbird', l.themeBlackbird),
                  ('serin', l.themeSerin),
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
