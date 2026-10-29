import 'dart:math';

import 'package:flutter/material.dart';

import '../birds.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../series.dart';
import 'card.dart';
import 'collection.dart';
import 'theme.dart';

String seriesName(AppLocalizations l, SeriesState s) =>
    s.series?.nameIn(l.localeName) ??
    switch (s.id) {
      legendaryHunter => l.legendaryHunter,
      perfectWeek => l.perfectWeek,
      _ => l.fullSet,
    };

/// Series and achievements as badges, 2 columns × 3 rows per page; swipe for more.
class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final states = seriesStates(birds, store.cards, store.bestStreak);
    final pages = [
      for (var i = 0; i < states.length; i += 6)
        states.skip(i).take(6).toList(),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.series)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  for (final page in pages)
                    GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      padding: const EdgeInsets.all(16),
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final s in page)
                          _Badge(
                            s,
                            name: seriesName(l, s),
                            onTap: s.birds.isEmpty
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => _SeriesCards(s),
                                    ),
                                  ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            // Page dots.
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page
                            ? scheme.primary
                            : scheme.onSurface.withValues(alpha: 0.25),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round badge: the series' bird (greyed until one is won) or the achievement's
/// icon, an accent arc for the progress, a foil ring once complete.
class _Badge extends StatelessWidget {
  const _Badge(this.s, {required this.name, this.onTap});
  final SeriesState s;
  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final face = s.face;
    final icon = switch (s.id) {
      legendaryHunter => Icons.auto_awesome,
      perfectWeek => Icons.local_fire_department,
      fullSet => Icons.style,
      _ => Icons.flutter_dash, // a series whose birds have no photo
    };
    final inner = face != null
        ? (s.owned > 0
              ? BirdPhoto(face)
              : ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.grey,
                    BlendMode.saturation,
                  ),
                  child: Opacity(opacity: 0.5, child: BirdPhoto(face)),
                ))
        : ColoredBox(
            color: scheme.secondaryContainer,
            child: Icon(
              icon,
              size: 44,
              color: s.owned > 0
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.4),
            ),
          );
    return Semantics(
      button: onTap != null,
      label: '$name, ${s.owned}/${s.total}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: 112,
              child: CustomPaint(
                painter: _Ring(
                  s.owned / s.total,
                  track: scheme.onSurface.withValues(alpha: 0.15),
                  accent: scheme.primary,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: ClipOval(child: inner),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: text.titleSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${s.owned}/${s.total}',
              style: text.labelMedium?.copyWith(
                color: s.complete ? scheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The progress ring around a badge: an accent arc, or a full foil ring when done.
class _Ring extends CustomPainter {
  const _Ring(this.progress, {required this.track, required this.accent});
  final double progress;
  final Color track, accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(3);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    if (progress >= 1) {
      // The foil of the boosters, all around.
      const silver = Color(0xFFDADBE0);
      paint
        ..strokeWidth = 6
        ..shader = SweepGradient(
          colors: [silver, accent, silver, accent, silver],
        ).createShader(rect);
      canvas.drawCircle(rect.center, arc.width / 2, paint);
      return;
    }
    canvas.drawCircle(rect.center, arc.width / 2, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(
        arc,
        -pi / 2,
        2 * pi * progress,
        false,
        paint..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(_Ring old) =>
      old.progress != progress || old.accent != accent || old.track != track;
}

/// A series' birds of the region, 3 per row: won cards, "heard" birds and "?".
class _SeriesCards extends StatelessWidget {
  const _SeriesCards(this.s);
  final SeriesState s;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cards = store.cards;
    final best = bestCards(cards);
    final heard = store.heard;
    final entries = [for (final b in s.birds) (b, best[b.id])];
    final openable = [
      for (final e in entries)
        if (e.$2 != null || heard.contains(e.$1.id)) e,
    ];
    return Scaffold(
      appBar: AppBar(title: Text('${seriesName(l, s)}  ${s.owned}/${s.total}')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.68,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final (b, c) = entries[i];
          final open = openable.indexOf(entries[i]);
          return CardTile(
            bird: b,
            card: c,
            copies: cards.where((x) => x.birdId == b.id).length,
            heard: heard.contains(b.id),
            compact: true,
            onTap: open < 0
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
    );
  }
}
