import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../birds.dart';
import '../cards.dart';
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
      collector => l.collector,
      localExpert => l.localExpert,
      rareFinds => l.rareFinds,
      fiveOfAKind => l.fiveOfAKind,
      dawnChorus => l.dawnChorus,
      globetrotter => l.globetrotter,
      fullHouse => l.fullHouse,
      perfectSpecimen => l.perfectSpecimen,
      ironStreak => l.ironStreak,
      _ => l.fullSet,
    };

/// What an achievement asks for (shown on a tap); null for a bird series.
String? seriesGoal(AppLocalizations l, SeriesState s) => s.series != null
    ? null
    : switch (s.id) {
        legendaryHunter => l.goalLegendaryHunter,
        perfectWeek => l.goalPerfectWeek,
        collector => l.goalCollector,
        localExpert => l.goalLocalExpert,
        rareFinds => l.goalRareFinds,
        fiveOfAKind => l.goalFiveOfAKind,
        dawnChorus => l.goalDawnChorus,
        globetrotter => l.goalGlobetrotter,
        fullHouse => l.goalFullHouse,
        perfectSpecimen => l.goalPerfectSpecimen,
        ironStreak => l.goalIronStreak,
        _ => l.goalFullSet,
      };

/// Series and achievements as badges, 2 columns × 3 rows per page; swipe for more.
class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  int _page = 0;

  /// Collects a completed series or achievement: its guaranteed card flips in.
  Future<void> _collect(SeriesState s) async {
    unawaited(HapticFeedback.mediumImpact());
    final card = await store.claim(s);
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RewardScreen(
          title: s.series == null ? l.achievementUnlocked : l.seriesComplete,
          card: card,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final states = seriesStates(
      birds,
      store.achievementCards,
      store.bestAlarmStreak,
    );
    // One page per group (the families take two), 6 badges at most per page.
    final pages = [
      for (final g in seriesGroups)
        if (states.where((s) => s.group == g).toList() case final group)
          for (var i = 0; i < group.length; i += 6)
            group.skip(i).take(6).toList(),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.series)),
      // Back within the thumb's reach, bottom right.
      // Lifted clear of the navigation bar, which the Scaffold doesn't do for it.
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: FloatingActionButton.small(
          elevation: 0,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  for (final page in pages)
                    LayoutBuilder(
                      // Three rows always fit, even above a 3-button navigation bar.
                      builder: (context, box) => GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: max(
                          0.85,
                          (box.maxWidth - 32) / 2 / ((box.maxHeight - 32) / 3),
                        ),
                        padding: const EdgeInsets.all(16),
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (final s in page)
                            _Badge(
                              s,
                              name: seriesName(l, s),
                              claimable: store.claimable(s),
                              onTap: store.claimable(s)
                                  ? () => _collect(s)
                                  : s.birds.isEmpty
                                  ? null
                                  : () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => _SeriesCards(s),
                                      ),
                                    ),
                            ),
                        ],
                      ),
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
  const _Badge(
    this.s, {
    required this.name,
    this.claimable = false,
    this.onTap,
  });
  final SeriesState s;
  final String name;
  final bool claimable; // complete, not collected yet: glows until tapped
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
      collector => Icons.collections_bookmark,
      localExpert => Icons.place,
      rareFinds => Icons.diamond,
      fiveOfAKind => Icons.filter_5,
      dawnChorus => Icons.wb_twilight,
      globetrotter => Icons.public,
      fullHouse => Icons.emoji_events,
      perfectSpecimen => Icons.workspace_premium,
      ironStreak => Icons.military_tech,
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
    final l = AppLocalizations.of(context);
    final goal = seriesGoal(l, s);
    final reward = rarityName(l, s.reward);
    final ring = SizedBox.square(
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
    );
    final badge = Semantics(
      button: onTap != null,
      label: [
        '$name, ${s.owned}/${s.total}',
        ?goal,
        l.rewardRarity(reward),
        if (claimable) l.tapToCollect,
      ].join('. '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The ring shrinks when large text needs the room (two-line names).
            Flexible(
              child: FittedBox(
                child: claimable
                    ? _Glow(
                        accent: scheme.primary,
                        sparkle: rarityColor[s.reward]!,
                        child: ring,
                      )
                    : ring,
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
            // In the colour of the prize: the rarity of the card collected on completion.
            Text(
              '${s.owned}/${s.total}',
              style: text.labelMedium?.copyWith(
                color: rarityColor[s.reward],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
    // A tap shows an achievement's goal (unless it collects the reward).
    return goal == null
        ? badge
        : Tooltip(
            message: goal,
            triggerMode: onTap == null
                ? TooltipTriggerMode.tap
                : TooltipTriggerMode.longPress,
            showDuration: const Duration(seconds: 4),
            child: badge,
          );
  }
}

/// A completed badge waiting to be collected: a soft pulsing glow in the theme's accent
/// and three sparkles of the reward's rarity orbiting the ring.
class _Glow extends StatefulWidget {
  const _Glow({
    required this.accent,
    required this.sparkle,
    required this.child,
  });
  final Color accent, sparkle;
  final Widget child;

  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _Orbit(_c, accent: widget.accent, sparkle: widget.sparkle),
    child: widget.child,
  );
}

class _Orbit extends CustomPainter {
  _Orbit(this.t, {required this.accent, required this.sparkle})
    : super(repaint: t);
  final Animation<double> t;
  final Color accent, sparkle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final pulse = 0.5 + 0.5 * sin(4 * pi * t.value);
    canvas.drawCircle(
      c,
      r + 4,
      Paint()
        ..color = accent.withValues(alpha: 0.18 + 0.22 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    for (var i = 0; i < 3; i++) {
      final a = 2 * pi * (t.value + i / 3) - pi / 2;
      final p = c + Offset(cos(a), sin(a)) * (r + 2);
      canvas.drawCircle(
        p,
        6,
        Paint()
          ..color = sparkle.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(p, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_Orbit old) =>
      old.accent != accent || old.sparkle != sparkle;
}

/// The card collected for a series or an achievement, flipping in like a won card.
/// A card won outside a quiz (a series, an achievement, a code, the welcome card) flips in.
class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key, required this.title, required this.card});
  final String title;
  final CardData card;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: CardDetail(
        bird: birdById(card.birdId)!,
        card: card,
        flipIn: true,
        header: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        onClose: () => Navigator.of(context).pop(),
      ),
    ),
  );
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
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
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
