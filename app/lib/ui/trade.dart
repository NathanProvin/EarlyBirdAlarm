import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../account.dart';
import '../birds.dart';
import '../cards.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../profile.dart';
import '../remote_trade.dart';
import '../trade.dart';
import 'account.dart';
import 'card.dart';
import 'collection.dart';
import 'profile.dart';
import 'theme.dart';

/// Trading with friends at a distance (2026-11-13): the Collection's ⇄ opens this friend
/// picker, then the trade screen with the friend chosen (also reached from a friend's
/// profile). Face-to-face trades over Nearby were removed (git tag `face-to-face-trade`).
class FriendPickerScreen extends StatelessWidget {
  const FriendPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.tradeWith)),
      body: FutureBuilder(
        future: Future.wait([social(store), myTrades()]),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text(l.accountError));
          final data = snap.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final friends =
              (data[0]
                      as ({
                        List<PlayerProfile> requests,
                        List<PlayerProfile> friends,
                      }))
                  .friends;
          final open = {for (final t in data[1] as List<RemoteTrade>) t.friend};
          if (friends.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l.noFriendsYet, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.person_add_alt_1),
                    label: Text(l.addFriend),
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const AccountScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              for (final f in friends)
                ListTile(
                  leading: Avatar(f.avatar),
                  title: Text('@${f.name}'),
                  subtitle: open.contains(f.uid) ? Text(l.tradeOpen) : null,
                  trailing: const Icon(Icons.swap_horiz),
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(builder: (_) => TradeScreen(f)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The trade with [friend], live: each side's offer, the validations, Validate and
/// Cancel; once both validated, the swap is applied and the cards received flip in.
class TradeScreen extends StatefulWidget {
  const TradeScreen(this.friend, {super.key});
  final PlayerProfile friend;

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  late final Stream<RemoteTrade?> _trade = watchTrade(widget.friend.uid);
  Set<String> _locked = const {}; // cards offered in other trades
  List<CardData>? _received; // the swap applied here: its reveal
  bool _seen = false; // the trade existed (so its end means cancelled)
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    myTrades().then((all) {
      if (!mounted) return;
      final here = all.where((t) => t.friend == widget.friend.uid).firstOrNull;
      setState(() => _locked = lockedCards(all, except: here?.id));
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    unawaited(sweepTrades(store)); // the profile dot, up to date
    super.dispose();
  }

  Future<void> _run(Future<void> Function() job) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await job();
    } catch (e) {
      debugPrint('trade: $e');
      messenger.showSnackBar(SnackBar(content: Text(l.accountError)));
    }
  }

  Future<void> _pick(RemoteTrade t) async {
    final picked = await showModalBottomSheet<List<CardData>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _Picker(initial: t.mine, locked: _locked),
    );
    if (picked != null) await _run(() => setOffer(t, picked));
  }

  void _apply(RemoteTrade t) {
    if (_applying) return;
    _applying = true;
    applyTrade(store, t).then((cards) {
      if (mounted) {
        unawaited(HapticFeedback.mediumImpact());
        setState(() => _received = cards);
      }
    }, onError: (Object e) => debugPrint('trade: $e'));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Avatar(widget.friend.avatar, size: 36),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                '@${widget.friend.name}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: switch (_received) {
          final cards? => _done(l, text, cards),
          null => StreamBuilder<RemoteTrade?>(
            stream: _trade,
            builder: (context, snap) {
              // An error once the trade was there: it was deleted meanwhile.
              if (snap.hasError) {
                return _message(_seen ? l.tradeCancelled : l.accountError);
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final t = snap.data;
              if (t == null) {
                return _message(_seen ? l.tradeCancelled : l.accountError);
              }
              _seen = true;
              if (t.forged) return _message(l.tradeInvalid);
              if (t.swapping) {
                _apply(t);
                return const Center(child: CircularProgressIndicator());
              }
              return _trading(l, text, t);
            },
          ),
        },
      ),
    );
  }

  Widget _message(String m) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(m, textAlign: TextAlign.center),
    ),
  );

  Widget _trading(AppLocalizations l, TextTheme text, RemoteTrade t) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.youGive, style: text.titleMedium),
        const SizedBox(height: 8),
        _Offer(
          cards: t.mine,
          empty: l.nothingYet,
          onAdd: () => _pick(t),
          addLabel: l.addCards,
        ),
        const SizedBox(height: 24),
        Text(l.youGet, style: text.titleMedium),
        const SizedBox(height: 8),
        _Offer(cards: t.theirs, empty: l.nothingYet),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.collections_bookmark_outlined),
          label: Text(l.theirCollection('@${widget.friend.name}')),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _FriendCollection(widget.friend),
            ),
          ),
        ),
        const Spacer(),
        if (!t.bothOffer)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(l.tradeBothOffer, textAlign: TextAlign.center),
          ),
        // The button says whether I agreed; the chip says whether they did.
        Center(
          child: Chip(
            avatar: Icon(
              t.theyValidated ? Icons.check : Icons.hourglass_empty,
              size: 18,
            ),
            label: Text(t.theyValidated ? l.theyValidated : l.waitingForThem),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: t.canValidate ? () => _run(() => validate(t)) : null,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          child: Text(t.iValidated ? l.youValidated : l.validate),
        ),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () => _run(() => cancelTrade(t)),
          child: Text(l.cancelTrade),
        ),
      ],
    ),
  );

  Widget _done(AppLocalizations l, TextTheme text, List<CardData> cards) =>
      Column(
        children: [
          const SizedBox(height: 8),
          Text(l.tradeDone, style: text.titleLarge),
          Expanded(
            // The cards received flip in one by one, like a booster.
            child: PageView(
              children: [
                for (final c in cards)
                  if (birdById(c.birdId) case final b?)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: CardDetail(bird: b, card: c, flipIn: true),
                    ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: Text(l.done),
            ),
          ),
        ],
      );
}

/// One side's offer: small cards in a row, and an "add" tile for this phone's side.
class _Offer extends StatelessWidget {
  const _Offer({
    required this.cards,
    required this.empty,
    this.onAdd,
    this.addLabel,
  });
  final List<CardData> cards;
  final String empty;
  final VoidCallback? onAdd;
  final String? addLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = [
      for (final c in cards)
        if (birdById(c.birdId) case final b?) (b, c as CardData?),
    ];
    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (onAdd != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: addLabel ?? '',
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(radius),
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outline, width: 2),
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: Icon(Icons.add, size: 32, color: scheme.primary),
                  ),
                ),
              ),
            ),
          if (cards.isEmpty && onAdd == null)
            Center(
              child: Text(empty, style: Theme.of(context).textTheme.bodyMedium),
            ),
          for (final (i, (b, c)) in entries.indexed)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 90,
                // A tap shows the card whole: name, stats, quality.
                child: CardTile(
                  bird: b,
                  card: c,
                  heard: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CardPager(entries: entries, initial: i),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cards as full small cards with their names (2026-11-17: photos alone didn't say which
/// bird or how good), 2 per row, with a Collected / Duplicates switch (Duplicates: every
/// copy but each species' best). [chosen] and [onTap]: picking; else a tap opens the card.
class _CardGrid extends StatefulWidget {
  const _CardGrid({required this.cards, this.chosen, this.onTap});
  final List<CardData>
  cards; // in display order, birds known to this phone only
  final Set<String>? chosen;
  final ValueChanged<CardData>? onTap;

  @override
  State<_CardGrid> createState() => _CardGridState();
}

class _CardGridState extends State<_CardGrid> {
  bool _spares = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final best = {for (final c in bestCards(widget.cards).values) c.key};
    final spares = [
      for (final c in widget.cards)
        if (!best.contains(c.key)) c,
    ];
    final shown = _spares ? spares : widget.cards;
    final entries = [
      for (final c in shown) (birdById(c.birdId)!, c as CardData?),
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                label: Text('${l.viewAll} (${widget.cards.length})'),
              ),
              ButtonSegment(
                value: true,
                label: Text('${l.viewDuplicates} (${spares.length})'),
              ),
            ],
            selected: {_spares},
            onSelectionChanged: (s) => setState(() => _spares = s.single),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: shown.length,
            itemBuilder: (context, i) {
              final c = shown[i];
              final on = widget.chosen?.contains(c.key) ?? false;
              return Stack(
                fit: StackFit.expand,
                children: [
                  CardTile(
                    bird: entries[i].$1,
                    card: c,
                    heard: false,
                    onTap: widget.onTap != null
                        ? () => widget.onTap!(c)
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  CardPager(entries: entries, initial: i),
                            ),
                          ),
                  ),
                  if (on)
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(radius),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: 48,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Cards sorted by card number, spare copies before each species' best; unknown birds
/// (a catalog this phone hasn't got yet) left out.
List<CardData> _byNumber(List<CardData> cards) {
  final best = {for (final c in bestCards(cards).values) c.key};
  return [
    for (final c in cards)
      if (birdById(c.birdId) != null) c,
  ]..sort((a, b) {
    final n = birdById(a.birdId)!.number - birdById(b.birdId)!.number;
    if (n != 0) return n;
    return (best.contains(a.key) ? 1 : 0) - (best.contains(b.key) ? 1 : 0);
  });
}

/// The friend's collection, to see what to ask for (read-only; tap a card to see it whole).
class _FriendCollection extends StatelessWidget {
  const _FriendCollection(this.friend);
  final PlayerProfile friend;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.theirCollection('@${friend.name}'))),
      body: FutureBuilder(
        future: friendCards(friend.uid),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text(l.accountError));
          final cards = snap.data;
          if (cards == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: EdgeInsets.only(
              top: 8,
              bottom: MediaQuery.paddingOf(context).bottom,
            ),
            child: _CardGrid(cards: _byNumber(cards)),
          );
        },
      ),
    );
  }
}

/// Choose the cards to give: the whole collection, duplicates first, up to
/// [maxTradeCards].
class _Picker extends StatefulWidget {
  const _Picker({required this.initial, this.locked = const {}});
  final List<CardData> initial;
  final Set<String> locked; // offered in another trade: not available here

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  late final _chosen = {for (final c in widget.initial) c.key};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sorted = _byNumber([
      for (final c in store.cards)
        if (!widget.locked.contains(c.key)) c,
    ]);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          Expanded(
            child: _CardGrid(
              cards: sorted,
              chosen: _chosen,
              onTap: (c) => setState(() {
                if (!_chosen.remove(c.key) && _chosen.length < maxTradeCards) {
                  _chosen.add(c.key);
                }
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop([
                for (final c in sorted)
                  if (_chosen.contains(c.key)) c,
              ]),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: Text('${l.done} (${_chosen.length}/$maxTradeCards)'),
            ),
          ),
        ],
      ),
    );
  }
}
