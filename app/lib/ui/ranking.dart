import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../ranking.dart';
import 'profile.dart' show Avatar;
import 'series.dart' show ModeSwitch, RewardScreen;
import 'theme.dart';

/// Gold, silver and bronze: the ranking's medals (and the onboarding's podium).
const podiumColors = [Color(0xFFD9A21B), Color(0xFFA7ABB2), Color(0xFFB0793F)];

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

/// The profile's rank, inside the Points tile (2026-11-24): "#12 >", to be tapped.
/// Last month's reward waiting: in the reward's colour, with its card; a tap collects it.
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

  Future<void> _collect(String rarity, int rank) async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    // "You finished #3 in November!" with the card it wins, then the card itself.
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: _MiniCard(rarity, width: 40),
        title: Text(
          l.rankFinished('#$rank', _monthName(l, _last)),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(140, 52)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.tapToCollect),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    setState(() => _busy = true);
    unawaited(HapticFeedback.mediumImpact());
    final card = await store.collectRank(_last, rarity);
    if (!mounted) return;
    setState(() => _busy = false);
    // The region's birds aren't known yet: try again later.
    if (card == null) return;
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
    // Inside the Points tile (2026-11-24): "#12 >", in the reward's colour (its mini
    // card before it) while last month's reward waits.
    Widget button({
      required String rank,
      required String label,
      required VoidCallback onTap,
      String? reward,
    }) {
      final edge = reward == null ? scheme.primary : rarityColor[reward]!;
      return Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
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
          ),
        ),
      );
    }

    return FutureBuilder(
      future: _lastRank,
      builder: (context, last) {
        if (last.data case final r? when rankReward(r.rank) != null) {
          final rarity = rankReward(r.rank)!;
          return button(
            reward: rarity,
            rank: '#${r.rank}',
            label: '${l.rankReward(_monthName(l, _last))}. ${l.tapToCollect}',
            onTap: () => _collect(rarity, r.rank),
          );
        }
        return FutureBuilder(
          future: _mine,
          builder: (context, mine) {
            final r = mine.data;
            return button(
              rank: r == null ? '#–' : '#${r.rank}',
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

/// The month's world ranking as a bar chart (2026-11-23): when it ends, then the top 10
/// live, one horizontal bar per player sized by their points, and the player's own row
/// below when they're further down.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final _month = monthKey(DateTime.now());
  // The month by default; the all-time board on the switch (user, 2026-11-27).
  bool _allTime = false;
  // The friends' board, a third button right of the switch (user, 2026-11-28).
  bool _friends = false;
  late final _tops = {_month: watchTop(_month), allTime: watchTop(allTime)};
  late final _saved = saveRank(store);
  late final _mine = {
    _month: _saved.then((_) => myRank(_month)),
    allTime: _saved.then((_) => myRank(allTime)),
  };
  late final _friendsRows = _saved.then((_) => friendsBoard());

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
    final board = _allTime ? allTime : _month;
    final me = store.username;
    // "NOV" over "-4 d": the month's short name and the days left, on the switch.
    final short = DateFormat.MMM(l.localeName)
        .format(DateTime(k ~/ 100, k % 100))
        .replaceAll('.', '')
        .toUpperCase();
    return Scaffold(
      appBar: AppBar(title: Text(l.rankWorld)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 7,
                  // Faded while the friends' board shows; a tap comes back to it.
                  child: AnimatedOpacity(
                    opacity: _friends ? 0.5 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: ModeSwitch(
                      width: 1,
                      series: _allTime,
                      onChanged: (v) => setState(() {
                        _allTime = v;
                        _friends = false;
                      }),
                      left: '$short\n${l.rankDaysLeft(days)}',
                      right: l.rankAllTime,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _FriendsButton(
                    on: _friends,
                    onTap: () => setState(() => _friends = true),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _friends
                ? _friendsChart(context, me)
                : FutureBuilder(
              key: ValueKey(board),
              future: _mine[board],
              builder: (context, mine) {
                final my = mine.data;
                return StreamBuilder(
                  stream: _tops[board],
                  builder: (context, top) {
                    final rows = top.data ?? const <RankRow>[];
                    final inTop = rows.any((r) => r.name == me);
                    // The longest bar is the leader's (or mine, should the list lag).
                    final most = [
                      1,
                      ...rows.map((r) => r.points),
                      ?my?.points,
                    ].reduce(max);
                    return ListView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        MediaQuery.paddingOf(context).bottom,
                      ),
                      children: [
                        for (final r in rows)
                          _Bar(
                            // Ties share the rank of the first with that score.
                            rank:
                                rows.indexWhere((x) => x.points == r.points) +
                                1,
                            row: r,
                            share: r.points / most,
                            me: r.name == me,
                            rewards: !_allTime,
                          ),
                        if (my != null && !inTop && top.hasData) ...[
                          Icon(
                            Icons.more_vert,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                          _Bar(
                            rank: my.rank,
                            row: (
                              uid: '',
                              name: me ?? '',
                              points: my.points,
                              avatar: store.avatar,
                            ),
                            share: my.points / most,
                            me: true,
                            rewards: !_allTime,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// The friends' board: the all-time chart without the rewards.
  Widget _friendsChart(BuildContext context, String? me) => FutureBuilder(
    future: _friendsRows,
    builder: (context, snap) {
      final l = AppLocalizations.of(context);
      final rows = snap.data;
      if (rows == null) {
        return Center(
          child: snap.hasError
              ? Text(l.accountError)
              : const CircularProgressIndicator(),
        );
      }
      final most = [1, ...rows.map((r) => r.points)].reduce(max);
      return ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          for (final r in rows)
            _Bar(
              rank: rows.indexWhere((x) => x.points == r.points) + 1,
              row: r,
              share: r.points / most,
              me: r.name == me,
              rewards: false,
            ),
          if (rows.length <= 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                l.noFriendsYet,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
        ],
      );
    },
  );
}

/// "Friends", right of the month / all-time switch: the same 56 dp pill, filled with the
/// accent while its board shows.
class _FriendsButton extends StatelessWidget {
  const _FriendsButton({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 56,
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? scheme.primary : scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(28),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context).friends,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: on
                    ? scheme.onPrimary
                    : scheme.onSecondaryContainer.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One player in the chart (2026-11-27): the avatar wearing the rank as a medal at its
/// bottom left (gold, silver, bronze for the podium), then a full-width track filled to
/// [share] of the leader's, the @name and points written over the track (never cropped
/// by a short fill), and on a month's board the card that place wins. The player's own
/// row tinted, its fill in the full accent.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.rank,
    required this.row,
    required this.share,
    required this.me,
    required this.rewards,
  });
  final int rank;
  final RankRow row;
  final double share;
  final bool me, rewards;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final medal = rank <= 3 ? podiumColors[rank - 1] : null;
    final reward = rewards ? rankReward(rank) : null;
    const size = 42.0;
    // Rows written before 1.4.0 carry no avatar: the profile has it.
    final avatar = row.avatar != null || row.uid.isEmpty
        ? Avatar(row.avatar, size: size)
        : FutureBuilder(
            future: profileAvatar(row.uid),
            builder: (_, a) => Avatar(a.data, size: size),
          );
    // A row of 50 dp: 11 fit the S22 without scrolling, with a clear gap between the
    // 30 dp bars. The medal hangs off the avatar's bottom left.
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: me ? scheme.primary.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        spacing: 12,
        children: [
          SizedBox(
            width: size + 6,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(top: 0, right: 0, child: avatar),
                Positioned(
                  left: 0,
                  bottom: -3,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 26),
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: medal ?? scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: scheme.surface, width: 2),
                    ),
                    child: Text(
                      '$rank',
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: medal != null ? ink : scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 30,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The fill grows in when the chart opens.
                  TweenAnimationBuilder(
                    tween: Tween(begin: 0.0, end: share.clamp(0.04, 1.0)),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, f, _) => Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        widthFactor: f,
                        heightFactor: 1,
                        child: ColoredBox(
                          color: scheme.primary.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                  // The @name at the start, the points at the end, centred in height.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: Text(
                            '@${row.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          NumberFormat.decimalPattern(l.localeName)
                              .format(row.points),
                          style: text.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (rewards)
            SizedBox(
              width: 22,
              child: reward == null
                  ? null
                  : Center(child: _MiniCard(reward, width: 18)),
            ),
        ],
      ),
    );
  }
}
