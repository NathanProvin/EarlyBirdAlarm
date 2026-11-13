import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../birds.dart';
import '../cards.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../names.dart';
import '../profile.dart';
import 'card.dart';
import 'collection.dart';
import 'theme.dart';

/// The profile page's pieces (2026-11-13): the avatar cropped from a card, the @name,
/// the hall of fame, friends. Laid out by AccountScreen (account.dart).

/// The public contact address (privacy page): where reports go.
const contactEmail = 'nanodev009@gmail.com';

/// A player's picture: their chosen card's photo, cropped round, in a ring of the card's
/// rarity colour; a quiet person icon before one is chosen.
class Avatar extends StatelessWidget {
  const Avatar(this.avatar, {this.size = 40, super.key});
  final Map<String, dynamic>? avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final a = avatar;
    final bird = a == null ? null : birdById(a['bird'] as String? ?? '');
    final ring = rarityColor[a?['rarity']] ?? scheme.outlineVariant;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size / 24 + 1),
      decoration: BoxDecoration(shape: BoxShape.circle, color: ring),
      child: ClipOval(
        child: bird == null
            ? ColoredBox(
                color: scheme.secondaryContainer,
                child: Icon(
                  Icons.person,
                  size: size * 0.55,
                  color: scheme.onSecondaryContainer,
                ),
              )
            : LayoutBuilder(
                builder: (context, box) => Transform(
                  // The crop saved as a share of the circle: the same at any size.
                  transform: Matrix4.identity()
                    ..translateByDouble(
                      (a!['dx'] as num? ?? 0) * box.maxWidth,
                      (a['dy'] as num? ?? 0) * box.maxWidth,
                      0,
                      1,
                    )
                    ..scaleByDouble(
                      (a['scale'] as num? ?? 1).toDouble(),
                      (a['scale'] as num? ?? 1).toDouble(),
                      1,
                      1,
                    ),
                  child: BirdPhoto(bird, photo: a['photo'] as String?),
                ),
              ),
      ),
    );
  }
}

/// Picks one card of the collection (the best copy of each species, rarest first).
Future<CardData?> pickCard(BuildContext context) =>
    Navigator.of(context)
        .push<CardData>(MaterialPageRoute(builder: (_) => const _CardPicker()));

class _CardPicker extends StatelessWidget {
  const _CardPicker();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final best = bestCards(store.cards).values.toList()
      ..sort(
        (a, b) => cardTiers
            .indexOf(cardRarity(b))
            .compareTo(cardTiers.indexOf(cardRarity(a))),
      );
    return Scaffold(
      appBar: AppBar(title: Text(l.chooseCard)),
      body: GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 0.72,
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (final c in best)
            if (birdById(c.birdId) case final bird?)
              CardTile(
                bird: bird,
                card: c,
                heard: false,
                compact: true,
                onTap: () => Navigator.of(context).pop(c),
              ),
        ],
      ),
    );
  }
}

/// Frames [card]'s photo in a circle (pinch to zoom, drag to move); the crop as the
/// avatar map, or null when cancelled.
Future<Map<String, dynamic>?> cropAvatar(BuildContext context, CardData card) =>
    Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => _Crop(card)),
    );

class _Crop extends StatefulWidget {
  const _Crop(this.card);
  final CardData card;

  @override
  State<_Crop> createState() => _CropState();
}

class _CropState extends State<_Crop> {
  final _zoom = TransformationController();
  double _side = 1; // the crop square's side, measured

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bird = birdById(widget.card.birdId)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.frameAvatar)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder: (context, box) => Stack(
                        key: ValueKey(_side = box.maxWidth),
                        fit: StackFit.expand,
                        children: [
                          ClipRect(
                            child: InteractiveViewer(
                              transformationController: _zoom,
                              minScale: 1,
                              maxScale: 6,
                              child: BirdPhoto(bird, photo: widget.card.photo),
                            ),
                          ),
                          // The circle that becomes the avatar; outside it, dimmed.
                          IgnorePointer(
                            child: CustomPaint(
                              painter: _Hole(
                                Theme.of(context).colorScheme.surface,
                                rarityColor[cardRarity(widget.card)]!,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(l.frameHint, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final m = _zoom.value;
                  final side = _side;
                  Navigator.of(context).pop({
                    'bird': bird.id,
                    'photo': widget.card.photo,
                    'rarity': cardRarity(widget.card),
                    'scale': m.getMaxScaleOnAxis(),
                    'dx': m.getTranslation().x / side,
                    'dy': m.getTranslation().y / side,
                  });
                },
                child: Text(l.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hole extends CustomPainter {
  const _Hole(this.veil, this.ring);
  final Color veil, ring;

  @override
  void paint(Canvas canvas, Size size) {
    final circle = Path()..addOval(Offset.zero & size);
    canvas
      ..drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Offset.zero & size),
          circle,
        ),
        Paint()..color = veil.withValues(alpha: 0.75),
      )
      ..drawPath(
        circle,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = ring,
      );
  }

  @override
  bool shouldRepaint(_Hole old) => old.veil != veil || old.ring != ring;
}

/// The identity block: the avatar (✎ to change it), the @name (✎ to rename), and under
/// them, small, the email or a sign-in link.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.email, required this.onSignIn, super.key});
  final String? email; // null: anonymous
  final VoidCallback onSignIn;

  Future<void> _changeAvatar(BuildContext context) async {
    final card = await pickCard(context);
    if (card == null || !context.mounted) return;
    final crop = await cropAvatar(context, card);
    if (crop == null) return;
    store.avatar = crop;
    unawaited(saveProfile(store).catchError((Object _) {}));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Semantics(
          button: true,
          label: l.changeAvatar,
          child: GestureDetector(
            onTap: () => _changeAvatar(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Avatar(store.avatar, size: 128),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: _GlassIcon(Icons.edit, color: scheme.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => const _Rename(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shrinks to fit on one line: a 20-character name is shown whole.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '@${store.username ?? '…'}',
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit, size: 18, color: scheme.primary),
              ],
            ),
          ),
        ),
        if (email case final e?)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_done_outlined, size: 14, color: scheme.primary),
              const SizedBox(width: 4),
              Text(
                e,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          )
        else
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: onSignIn,
            child: Text(l.signInToKeep),
          ),
      ],
    );
  }
}

/// A small round frosted button (the avatar's ✎).
class _GlassIcon extends StatelessWidget {
  const _GlassIcon(this.icon, {required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.45),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    ),
  );
}

/// Change the @name: rules shown as they're typed; once a week (the first change free).
class _Rename extends StatefulWidget {
  const _Rename();

  @override
  State<_Rename> createState() => _RenameState();
}

class _RenameState extends State<_Rename> {
  late final _field = TextEditingController(text: store.username ?? '');
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  String _problem(AppLocalizations l, NameProblem p) => switch (p) {
    NameProblem.length => l.nameLength,
    NameProblem.characters => l.nameCharacters,
    NameProblem.banned => l.nameBanned,
  };

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await rename(store, _field.text.trim());
      navigator.pop();
    } on RenameException catch (e) {
      setState(
        () => _error = switch (e.error) {
          RenameError.invalid => _problem(l, e.problem!),
          RenameError.taken => l.nameTaken,
          RenameError.tooSoon => l.renameTooSoon(
            MaterialLocalizations.of(context)
                .formatMediumDate(nextRename(store)!),
          ),
          RenameError.offline => l.accountError,
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final next = nextRename(store);
    return AlertDialog(
      title: Text(l.renameTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _field,
            autofocus: next == null,
            enabled: next == null,
            autocorrect: false,
            maxLength: 20,
            decoration: InputDecoration(
              prefixText: '@',
              errorText: _error,
              helperText: next == null
                  ? l.nameRules
                  : l.renameTooSoon(
                      MaterialLocalizations.of(context).formatMediumDate(next),
                    ),
              helperMaxLines: 2,
              errorMaxLines: 2,
            ),
            onChanged: (v) => setState(
              () => _error = switch (nameProblem(v.trim())) {
                final p? when v.isNotEmpty => _problem(l, p),
                _ => null,
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: _busy || next != null ? null : _save,
          child: Text(l.save),
        ),
      ],
    );
  }
}

/// The hall of fame: 3 cards the player chose to show; tap a slot to choose its card.
class HallOfFame extends StatelessWidget {
  const HallOfFame({super.key});

  Future<void> _choose(BuildContext context, int slot) async {
    final card = await pickCard(context);
    if (card == null) return;
    store.hall = [
      for (var i = 0; i < 3; i++)
        i == slot
            ? card.key
            : (store.hall.elementAtOrNull(i) == card.key
                  ? ''
                  : store.hall.elementAtOrNull(i) ?? ''),
    ];
    unawaited(saveProfile(store).catchError((Object _) {}));
  }

  @override
  // Listens itself: placed as a const widget, a parent's rebuild skips it.
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) =>
        HallRow(cards: hallCards(store), onTap: (i) => _choose(context, i)),
  );
}

/// Three card slots in a row (the player's own, or a friend's to look at).
class HallRow extends StatelessWidget {
  const HallRow({required this.cards, this.onTap, super.key});
  final List<CardData?> cards;
  final void Function(int slot)? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AspectRatio(
              aspectRatio: 0.72,
              child: switch ((cards.elementAtOrNull(i), onTap)) {
                (final CardData c, _) when birdById(c.birdId) != null =>
                  CardTile(
                    bird: birdById(c.birdId)!,
                    card: c,
                    heard: false,
                    onTap: onTap == null ? null : () => onTap!(i),
                  ),
                (_, final tap?) => Semantics(
                  button: true,
                  label: l.chooseCard,
                  child: InkWell(
                    onTap: () => tap(i),
                    borderRadius: BorderRadius.circular(radius),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(
                          color: scheme.onSurface.withValues(alpha: 0.25),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 32,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                _ => const SizedBox.shrink(),
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Friends: Add friend, the requests received (Accept / Decline), then the friends.
class Friends extends StatefulWidget {
  const Friends({super.key});

  @override
  State<Friends> createState() => _FriendsState();
}

class _FriendsState extends State<Friends> {
  late Future<({List<PlayerProfile> requests, List<PlayerProfile> friends})>
  _social = social(store);

  void _reload() => setState(() => _social = social(store));

  Future<void> _run(Future<void> Function() job) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await job();
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l.accountError)));
    }
    if (mounted) _reload();
  }

  Future<void> _add() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        final field = TextEditingController();
        return AlertDialog(
          title: Text(l.addFriend),
          content: TextField(
            controller: field,
            autofocus: true,
            autocorrect: false,
            decoration: InputDecoration(
              prefixText: '@',
              hintText: l.friendNameHint,
            ),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, field.text),
              child: Text(l.sendRequest),
            ),
          ],
        );
      },
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      await sendRequest(name);
      messenger.showSnackBar(SnackBar(content: Text(l.requestSent)));
    } on FriendException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (e.error) {
            FriendError.notFound => l.friendNotFound,
            FriendError.self => l.friendSelf,
            FriendError.already => l.friendAlready,
            FriendError.offline => l.accountError,
          }),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder(
      future: _social,
      builder: (context, snap) {
        final data = snap.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.tonalIcon(
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(l.addFriend),
              onPressed: _add,
            ),
            const SizedBox(height: 8),
            if (data == null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: snap.hasError
                    ? Text(l.accountError, textAlign: TextAlign.center)
                    : const Center(child: CircularProgressIndicator()),
              )
            else ...[
              for (final p in data.requests)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Avatar(p.avatar),
                  title: Text('@${p.name}'),
                  subtitle: Text(l.wantsToBeFriends),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l.decline,
                        icon: const Icon(Icons.close),
                        onPressed: () => _run(() => decline(p.uid)),
                      ),
                      IconButton.filled(
                        tooltip: l.accept,
                        icon: const Icon(Icons.check),
                        onPressed: () => _run(() => accept(p.uid)),
                      ),
                    ],
                  ),
                ),
              for (final p in data.friends)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Avatar(p.avatar),
                  title: Text('@${p.name}'),
                  trailing: Icon(Icons.chevron_right, color: scheme.primary),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => FriendScreen(p)),
                    );
                    if (mounted) _reload();
                  },
                ),
              if (data.requests.isEmpty && data.friends.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l.noFriendsYet,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

/// A friend's profile: their avatar, @name and hall of fame; Challenge and Trade to come;
/// Remove, Block and Report in the menu.
class FriendScreen extends StatelessWidget {
  const FriendScreen(this.friend, {super.key});
  final PlayerProfile friend;

  Future<void> _act(BuildContext context, String action) async {
    final navigator = Navigator.of(context);
    switch (action) {
      case 'remove':
        await removeFriend(friend.uid);
      case 'block':
        await block(store, friend.uid);
      case 'report':
        await launchUrl(
          Uri(
            scheme: 'mailto',
            path: contactEmail,
            query:
                'subject=${Uri.encodeComponent('Report @${friend.name}')}'
                '&body=${Uri.encodeComponent('Player id: ${friend.uid}\n')}',
          ),
        );
        return;
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            onSelected: (a) => _act(context, a),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'remove', child: Text(l.removeFriend)),
              PopupMenuItem(value: 'block', child: Text(l.blockPlayer)),
              PopupMenuItem(value: 'report', child: Text(l.reportPlayer)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Center(child: Avatar(friend.avatar, size: 128)),
          const SizedBox(height: 12),
          Text(
            '@${friend.name}',
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text(
            l.hallOfFame,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          HallRow(cards: friend.hall),
          const SizedBox(height: 24),
          // To come: shown so players know (2026-11-13, user).
          for (final (icon, label) in [
            (Icons.sports_esports_outlined, l.challenge),
            (Icons.swap_horiz, l.trade),
          ]) ...[
            FilledButton.tonalIcon(
              onPressed: null,
              icon: Icon(icon),
              label: Text('$label · ${l.comingSoon}'),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
