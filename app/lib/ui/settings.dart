import 'package:flutter/material.dart';

import '../birds.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'credits.dart';
import 'region.dart';
import 'theme.dart';

/// The bird of each theme, drawn in its plumage: colors of the body, belly, wing, cap,
/// cheek (or null), beak, and an eye ring (or null).
typedef _Plumage = ({
  Color body,
  Color belly,
  Color wing,
  Color cap,
  Color? cheek,
  Color beak,
  Color? eyeRing,
});

const _plumage = <String, _Plumage>{
  'blackbird': (
    body: Color(0xFF141618),
    belly: Color(0xFF1B1E21),
    wing: Color(0xFF2A2E33),
    cap: Color(0xFF141618),
    cheek: null,
    beak: Color(0xFFE8A33D),
    eyeRing: Color(0xFFE8A33D),
  ),
  'serin': (
    body: Color(0xFFB8C043),
    belly: Color(0xFFF2D43A),
    wing: Color(0xFF5F7A34),
    cap: Color(0xFFE6D63B),
    cheek: null,
    beak: Color(0xFF8C8A7A),
    eyeRing: null,
  ),
  'bluetit': (
    body: Color(0xFF8DA65A),
    belly: Color(0xFFF2C94C),
    wing: Color(0xFF2F6DB5),
    cap: Color(0xFF2F6DB5),
    cheek: Color(0xFFFFFFFF),
    beak: Color(0xFF2B2B2B),
    eyeRing: null,
  ),
  // The Black-headed Gull (mouette rieuse): chocolate hood, red bill and legs.
  'gull': (
    body: Color(0xFFFFFFFF),
    belly: Color(0xFFFFFFFF),
    wing: Color(0xFFB9BEC4),
    cap: Color(0xFF4A3830), // the whole head: its hood
    cheek: null,
    beak: Color(0xFFB5442E),
    eyeRing: Color(0xFFFFFFFF),
  ),
};

/// A cute round bird facing right, drawn in a 100 × 100 box scaled to the canvas.
class _BirdPainter extends CustomPainter {
  const _BirdPainter(this.p, {required this.gull});
  final _Plumage p;
  final bool gull; // black wingtip, a hood over the whole head, red legs

  @override
  void paint(Canvas canvas, Size size) {
    Paint fill(Color c) => Paint()..color = c;
    canvas
      ..save()
      ..scale(size.width / 100, size.height / 100)
      // Tail, body, belly.
      ..drawPath(
        Path()..addPolygon(const [
          Offset(26, 60),
          Offset(6, 70),
          Offset(10, 78),
          Offset(32, 70),
        ], true),
        fill(p.wing),
      )
      ..drawOval(
        Rect.fromCenter(center: const Offset(48, 62), width: 54, height: 40),
        fill(p.body),
      )
      ..drawOval(
        Rect.fromCenter(center: const Offset(56, 70), width: 36, height: 22),
        fill(p.belly),
      );
    // Wing, a little tilted.
    canvas
      ..save()
      ..translate(42, 60)
      ..rotate(-0.25)
      ..drawOval(
        Rect.fromCenter(center: Offset.zero, width: 36, height: 20),
        fill(p.wing),
      );
    if (gull) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-15, 1), width: 10, height: 12),
        fill(const Color(0xFF1C1B1A)),
      );
    }
    canvas.restore();
    // Head with its cap (the top of the head), cheek, eye, beak, legs.
    const head = Offset(70, 40);
    canvas
      ..drawCircle(head, 17, fill(gull ? p.cap : p.body))
      ..save()
      ..clipPath(Path()..addOval(Rect.fromCircle(center: head, radius: 17)))
      ..drawRect(const Rect.fromLTWH(50, 20, 40, 13), fill(p.cap))
      ..restore();
    if (p.cheek case final c?) {
      canvas.drawCircle(const Offset(72, 45), 8, fill(c));
    }
    if (p.eyeRing case final c?) {
      canvas.drawCircle(const Offset(76, 38), 5.5, fill(c));
    }
    canvas
      ..drawCircle(const Offset(76, 38), 3.8, fill(const Color(0xFF111111)))
      ..drawCircle(const Offset(77.3, 36.8), 1.3, fill(Colors.white))
      ..drawPath(
        Path()..addPolygon(const [
          Offset(85, 37),
          Offset(97, 41.5),
          Offset(85, 46),
        ], true),
        fill(p.beak),
      );
    final leg = Paint()
      ..color = gull ? p.beak : const Color(0xFF6B5E55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(const Offset(44, 80), const Offset(42, 92), leg)
      ..drawLine(const Offset(55, 80), const Offset(55, 92), leg)
      ..restore();
  }

  @override
  bool shouldRepaint(_BirdPainter oldDelegate) => false;
}

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
                          : _BirdPainter(
                              _plumage[value]!,
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
