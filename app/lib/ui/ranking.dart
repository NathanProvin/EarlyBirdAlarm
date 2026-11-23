import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../ranking.dart';
import 'series.dart' show RewardScreen;
import 'theme.dart';

/// A month key's name in the app's language: "202611" → "November".
String _monthName(AppLocalizations l, String key) {
  final k = int.parse(key);
  return DateFormat.MMMM(l.localeName).format(DateTime(k ~/ 100, k % 100));
}

/// A small card in a rarity's colour (the reward ladder, the tile).
class _MiniCard extends StatelessWidget {
  const _MiniCard(this.rarity, {this.width = 20});
  final String rarity;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: width * 1.4,
    decoration: BoxDecoration(
      color: rarityColor[rarity],
      borderRadius: BorderRadius.circular(width / 6),
      border: Border.all(color: ink, width: 1.5),
    ),
  );
}

/// Opens the month's ranking.
Future<void> openRanking(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const RankingScreen()));

/// "NOV": a month key's first three letters in the app's language, in capitals.
String _monthShort(AppLocalizations l, String key) {
  final k = int.parse(key);
  final s = DateFormat.MMM(l.localeName)
      .format(DateTime(k ~/ 100, k % 100))
      .replaceAll('.', '')
      .toUpperCase();
  return s.length > 3 ? s.substring(0, 3) : s;
}

/// The profile's rank button (1/3 beside the score, 2026-11-23): "#12 ›" over "📅 NOV",
/// outlined in the accent like the map's radar, to be tapped. Last month's reward
/// waiting: outlined and glowing in the reward's colour, with its card; a tap collects it.
class RankButton extends StatefulWidget {
  const RankButton({super.key});

  @override
  State<RankButton> createState() => _RankButtonState();
}

class _RankButtonState extends State<RankButton> {
  final _now = DateTime.now();
  late final _last = lastMonthKey(_now), _month = monthKey(_now);
  late Future<({int rank, int total, int points})?> _lastRank =
      store.rankCollected(_last) ? Future.value() : myRank(_last);
  late Future<({int rank, int total, int points})?> _mine = _load();
  bool _busy = false;

  Future<({int rank, int total, int points})?> _load() async {
    await saveRank(store); // the latest score first: the rank shown is current
    return myRank(_month);
  }

  Future<void> _collect(String rarity) async {
    if (_busy) return;
    setState(() => _busy = true);
    unawaited(HapticFeedback.mediumImpact());
    final card = await store.collectRank(_last, rarity);
    if (!mounted) return;
    setState(() => _busy = false);
    // The region's birds aren't known yet: try again later.
    if (card == null) return;
    final l = AppLocalizations.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            RewardScreen(title: l.rankReward(_monthName(l, _last)), card: card),
      ),
    );
    if (mounted) setState(() => _lastRank = Future.value());
  }

  Future<void> _open() async {
    await openRanking(context);
    if (mounted) setState(() => _mine = myRank(_month));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    Widget button({
      required String rank,
      required String month,
      required String label,
      required VoidCallback onTap,
      String? reward,
    }) {
      final edge = reward == null ? scheme.primary : rarityColor[reward]!;
      return Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              if (reward != null)
                BoxShadow(
                  color: edge.withValues(alpha: 0.6),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Material(
            color: scheme.secondaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: BorderSide(color: edge, width: 2),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 2,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (reward != null) ...[
                            _MiniCard(reward, width: 16),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            rank,
                            style: text.headlineSmall?.copyWith(
                              color: edge,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.chevron_right, color: edge),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 4,
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                          Text(
                            month,
                            style: text.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return FutureBuilder(
      future: _lastRank,
      builder: (context, last) {
        if (last.data case final r?) {
          final rarity = rankReward(r.rank, r.total);
          return button(
            reward: rarity,
            rank: '#${r.rank}',
            month: _monthShort(l, _last),
            label: '${l.rankReward(_monthName(l, _last))}. ${l.tapToCollect}',
            onTap: () => _collect(rarity),
          );
        }
        return FutureBuilder(
          future: _mine,
          builder: (context, mine) {
            final r = mine.data;
            return button(
              rank: r == null ? '#–' : '#${r.rank}',
              month: _monthShort(l, _month),
              label: r == null
                  ? '${l.rankTitle(_monthName(l, _month))}. ${l.rankEnter}'
                  : '${l.rankTitle(_monthName(l, _month))}: #${r.rank}',
              onTap: _open,
            );
          },
        );
      },
    );
  }
}

/// The month's world ranking: when it ends, the reward ladder (your place on it
/// raised), the top 10 live, then your own row if you're further down.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final _month = monthKey(DateTime.now());
  late final _top = watchTop(_month);
  late final _mine = saveRank(store).then((_) => myRank(_month));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final k = int.parse(_month);
    final end = DateTime.utc(k ~/ 100, k % 100 + 1);
    final days = (end.difference(DateTime.now().toUtc()).inMinutes / 1440)
        .ceil()
        .clamp(1, 31);
    final me = store.username;
    return Scaffold(
      appBar: AppBar(title: Text(l.rankTitle(_monthName(l, _month)))),
      body: FutureBuilder(
        future: _mine,
        builder: (context, mine) {
          final my = mine.data;
          final myTier = my == null ? null : rankReward(my.rank, my.total);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Text(
                l.rankEnds(days),
                textAlign: TextAlign.center,
                style: text.titleSmall?.copyWith(color: scheme.primary),
              ),
              const SizedBox(height: 16),
              // The reward ladder: a card per rarity over its top percentile.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final (rarity, pct) in rankLadder)
                    Column(
                      spacing: 6,
                      children: [
                        AnimatedScale(
                          scale: rarity == myTier ? 1.35 : 1,
                          duration: const Duration(milliseconds: 300),
                          child: _MiniCard(rarity, width: 26),
                        ),
                        Text(
                          '$pct%',
                          style: text.labelMedium?.copyWith(
                            fontWeight: rarity == myTier
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l.rankHint,
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
              const SizedBox(height: 20),
              StreamBuilder(
                stream: _top,
                builder: (context, top) {
                  final rows = top.data ?? const <RankRow>[];
                  final inTop = rows.any((r) => r.name == me);
                  return Column(
                    spacing: 6,
                    children: [
                      for (final r in rows)
                        _Row(
                          // Ties share the rank of the first with that score.
                          rank:
                              rows.indexWhere((x) => x.points == r.points) + 1,
                          name: r.name,
                          points: r.points,
                          me: r.name == me,
                        ),
                      if (my != null && !inTop && top.hasData) ...[
                        Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
                        _Row(
                          rank: my.rank,
                          name: me ?? '',
                          points: my.points,
                          me: true,
                        ),
                      ],
                      if (my == null &&
                          mine.connectionState == ConnectionState.done)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            l.rankEnter,
                            textAlign: TextAlign.center,
                            style: text.bodyLarge,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One player in the ranking: the rank (gold, silver, bronze for the podium), the @name,
/// the points; the player's own row in the accent.
class _Row extends StatelessWidget {
  const _Row({
    required this.rank,
    required this.name,
    required this.points,
    required this.me,
  });
  final int rank, points;
  final String name;
  final bool me;

  static const _podium = [
    Color(0xFFD9A21B),
    Color(0xFFA7ABB2),
    Color(0xFFB0793F),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final medal = rank <= 3 ? _podium[rank - 1] : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: me ? scheme.primary : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: medal),
            child: Text(
              '$rank',
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: medal != null
                    ? ink
                    : me
                    ? scheme.onPrimary
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '@$name',
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(
                color: me ? scheme.onPrimary : null,
                fontWeight: me ? FontWeight.bold : null,
              ),
            ),
          ),
          Text(
            NumberFormat.decimalPattern(l.localeName).format(points),
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: me ? scheme.onPrimary : scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
