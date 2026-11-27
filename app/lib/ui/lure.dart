import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../birds.dart';
import '../content.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'card.dart' show playRecording;
import 'collection.dart' show nameMatches, plainText;
import 'twitch.dart' show PlusSheet;

/// The Lure button (Plus, 2026-11-27; FR "Repasse"), bottom left of Training: a bird's
/// call played the way birders call one in, 3 times a day. Without Plus: the Plus sheet.
class LureButton extends StatelessWidget {
  const LureButton({super.key});

  Future<void> _tap(BuildContext context) async {
    final l = AppLocalizations.of(context);
    unawaited(HapticFeedback.selectionClick());
    if (!store.twitchPlus) {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => const PlusSheet(),
      );
      return;
    }
    if (store.lureLeft(DateTime.now()) == 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.lureNone)));
      return;
    }
    final bird = await showModalBottomSheet<Bird>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _LurePicker(),
    );
    if (bird == null || !context.mounted) return;
    await _call(context, bird);
  }

  /// Downloads the bird's first song (the draw takes it from the phone), plays it, then
  /// "Will it answer?". Offline: nothing used.
  Future<void> _call(BuildContext context, Bird bird) async {
    final l = AppLocalizations.of(context);
    final rec = bird.playable(store.difficulty).firstOrNull;
    final ok =
        rec != null &&
        (localFile(rec.file).existsSync() || await download(rec.file));
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.lureOffline)));
      return;
    }
    await store.lure(bird.id, DateTime.now());
    final player = AudioPlayer();
    unawaited(playRecording(player, rec.file));
    if (!context.mounted) return;
    final scheme = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.campaign, size: 44, color: scheme.primary),
        title: Text(
          l.lurePlayed(bird.nameIn(l.localeName)),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton.tonal(
            style: FilledButton.styleFrom(minimumSize: const Size(120, 52)),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
    await player.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _badge(context, l, scheme),
    );
  }

  Widget _badge(BuildContext context, AppLocalizations l, ColorScheme scheme) {
    final left = store.lureLeft(DateTime.now());
    // Faded without Plus: locked, a tap shows the Plus sheet.
    final color = store.twitchPlus
        ? scheme.primary
        : scheme.primary.withValues(alpha: 0.45);
    return IconButton.outlined(
      iconSize: 28,
      style: IconButton.styleFrom(
        minimumSize: const Size(56, 56),
        side: BorderSide(color: color, width: 2),
      ),
      color: color,
      // The same badge as the Training tab's boosters.
      icon: Badge(
        isLabelVisible: store.twitchPlus && left > 0,
        label: Text('$left'),
        backgroundColor: scheme.primary,
        textColor: scheme.onPrimary,
        child: const Icon(Icons.campaign),
      ),
      tooltip: l.lure,
      onPressed: () => _tap(context),
    );
  }
}

/// Which bird to call: the birds that can be drawn now (region, season, difficulty),
/// searched by name like the Collection (the app's language, English, Latin).
class _LurePicker extends StatefulWidget {
  const _LurePicker();

  @override
  State<_LurePicker> createState() => _LurePickerState();
}

class _LurePickerState extends State<_LurePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final q = plainText(_query.trim());
    final candidates =
        pool(store.monthFor(DateTime.now()), store.difficulty).keys
            .where((b) => q.isEmpty || nameMatches(b, q, l.localeName))
            .toList()
          ..sort(
            (a, b) => a.nameIn(l.localeName).compareTo(b.nameIn(l.localeName)),
          );
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Text(l.lure, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(l.lureInfo, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: l.lureSearch,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: candidates.length,
                itemBuilder: (context, i) {
                  final b = candidates[i];
                  return ListTile(
                    title: Text(b.nameIn(l.localeName)),
                    subtitle: Text(
                      b.latin,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    trailing: const Icon(Icons.campaign_outlined),
                    onTap: () => Navigator.of(context).pop(b),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
