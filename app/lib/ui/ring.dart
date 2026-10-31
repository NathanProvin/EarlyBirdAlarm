import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../birds.dart';
import '../cards.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'card.dart';
import 'collection.dart';
import 'theme.dart';

// See MainActivity.kt: true keeps the app over the lock screen after the alarm stops.
const _lockScreen = MethodChannel('early_bird/lock_screen');

/// The quiz: a ringing [alarm], or a Twitch [training] quiz that plays its song in the
/// app, can be left (the quiz is lost) and doesn't touch the streak.
class RingScreen extends StatefulWidget {
  const RingScreen({required AlarmSettings this.alarm, super.key})
    : training = null;
  const RingScreen.training(this.training, {super.key}) : alarm = null;
  final AlarmSettings? alarm;
  final (Bird, Recording)? training;

  @override
  State<RingScreen> createState() => _RingScreenState();
}

enum _Mark { none, correct, wrong, faded }

class _RingScreenState extends State<RingScreen> {
  late final Map<String, dynamic> _payload = _parsePayload(
    widget.alarm?.payload,
  );
  // An alarm set before an app update may name a bird that's gone; ask about any bird then.
  late final Bird _bird =
      widget.training?.$1 ??
      birdById(_payload['bird'] as String? ?? '') ??
      birds.first;
  late final Recording? _rec =
      widget.training?.$2 ??
      _bird.recordings.where((r) => r.file == _payload['rec']).firstOrNull;
  late final List<Bird> _choices = choicesFor(
    _bird,
    store.monthFor(widget.alarm?.dateTime ?? DateTime.now()),
    store.difficulty,
  );
  late final int _oldStreak = store.streak;
  final _player = AudioPlayer(); // Twitch only: alarms play through the plugin
  Bird? _tapped;

  @override
  void initState() {
    super.initState();
    if (widget.training != null) {
      _player.setLoopMode(LoopMode.one);
      playRecording(_player, _rec!.file);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  _Mark _markOf(Bird b) => switch (_tapped) {
    null => _Mark.none,
    _ when b == _bird => _Mark.correct, // the answer is always shown
    final t when b == t => _Mark.wrong,
    _ => _Mark.faded,
  };

  Future<void> _guess(Bird bird) async {
    if (_tapped != null) return;
    setState(() => _tapped = bird);
    // A short tap when right, a longer buzz when wrong.
    bird == _bird ? HapticFeedback.mediumImpact() : HapticFeedback.vibrate();
    // The answer stays on screen for 2 s, while the guess is saved.
    final shown = Future<void>.delayed(const Duration(seconds: 2));
    if (widget.alarm case final alarm?) {
      await _lockScreen.invokeMethod<void>('hold', true);
      await Alarm.stop(alarm.id);
    } else {
      await _player.stop();
    }
    final correct = bird == _bird;
    if (!mounted) return;
    final firstOfSpecies =
        correct && !store.cards.any((c) => c.birdId == _bird.id);
    final card = await store.answered(
      widget.alarm?.id,
      _bird,
      _rec,
      correct,
      AppLocalizations.of(context).guessTheBird,
    );
    // The app is open every morning: a good time to fetch songs for the next rings.
    unawaited(store.sync());
    await shown;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RevealScreen(
          bird: _bird,
          recording: _rec,
          card: card,
          firstOfSpecies: firstOfSpecies,
          streakLost: !correct && _oldStreak > 0,
          training: widget.training != null,
        ),
      ),
    );
  }

  Future<void> _snooze() async {
    final alarm = widget.alarm!;
    if (_tapped != null) return;
    final minutes = store.byId(alarm.id)?.snoozeMinutes ?? 10;
    await Alarm.stop(alarm.id);
    // Same settings, so the same bird plays again.
    await Alarm.set(
      alarmSettings: alarm.copyWith(
        dateTime: DateTime.now().add(Duration(minutes: minutes)),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final button = FilledButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
      textStyle: Theme.of(context).textTheme.titleLarge,
    );
    return PopScope(
      canPop: widget.training != null,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Column(
              children: [
                // 2×2 photos: easier to read than text when half asleep.
                for (final row in [_choices.take(2), _choices.skip(2)])
                  Expanded(
                    child: Row(
                      children: [
                        for (final bird in row)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: _Choice(
                                bird: bird,
                                name: bird.nameIn(l.localeName),
                                mark: _markOf(bird),
                                onTap: () => _guess(bird),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: widget.training == null
                      ? FilledButton.tonalIcon(
                          onPressed: _snooze,
                          icon: const Icon(Icons.snooze, size: 28),
                          label: Text(l.snooze),
                          style: button,
                        )
                      : StreamBuilder<bool>(
                          stream: _player.playingStream,
                          builder: (context, playing) => FilledButton.tonalIcon(
                            onPressed: _tapped != null
                                ? null
                                : () => playing.data == true
                                      ? _player.pause()
                                      : _player.play(),
                            icon: Icon(
                              playing.data == true
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 28,
                            ),
                            label: Text(l.listenAgain),
                            style: button,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A choice: the photo, its name in a frosted box, and after the guess a green / red frame,
/// a ✓ / ✕ badge and a pulse / shake; the other photos fade.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.bird,
    required this.name,
    required this.mark,
    required this.onTap,
  });
  final Bird bird;
  final String name;
  final _Mark mark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (mark) {
      _Mark.correct => moss,
      _Mark.wrong => brick,
      _ => Colors.transparent,
    };
    final tile = Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BirdPhoto(bird),
        ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 8,
          child: Center(child: _GlassLabel(name)),
        ),
        if (mark == _Mark.correct || mark == _Mark.wrong)
          Positioned(
            top: 8,
            right: 8,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (_, s, child) => Transform.scale(scale: s, child: child),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: color,
                child: Icon(
                  mark == _Mark.correct ? Icons.check : Icons.close,
                  color: paper,
                  size: 32,
                ),
              ),
            ),
          ),
      ],
    );
    return Semantics(
      button: true,
      label: name,
      excludeSemantics: true,
      child: AnimatedOpacity(
        opacity: mark == _Mark.faded ? 0.15 : 1,
        duration: const Duration(milliseconds: 300),
        child: TweenAnimationBuilder<double>(
          key: ValueKey(mark),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          builder: (_, t, child) => switch (mark) {
            _Mark.correct => Transform.scale(
              scale: 1 + 0.06 * sin(pi * t),
              child: child,
            ),
            _Mark.wrong => Transform.translate(
              offset: Offset(12 * sin(t * pi * 6) * (1 - t), 0),
              child: child,
            ),
            _ => child!,
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: color, width: 6),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: tile,
            ),
          ),
        ),
      ),
    );
  }
}

/// The bird's name in a frosted-glass box over its photo.
class _GlassLabel extends StatelessWidget {
  const _GlassLabel(this.name);
  final String name;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius - 4),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        child: Text(
          name,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );
}

/// After the guess: a won card flips face up in place (with sparks of its rarity), a
/// wrong guess shows the blurred "heard" card with its name.
class RevealScreen extends StatelessWidget {
  const RevealScreen({
    required this.bird,
    this.recording,
    this.card,
    this.firstOfSpecies = false,
    this.streakLost = false,
    this.training = false,
    super.key,
  });
  final Bird bird;
  final Recording?
  recording; // the one that rang; null for alarms set before 3c
  final CardData? card; // null after a wrong guess
  final bool firstOfSpecies, streakLost;
  final bool training; // Twitch quiz: no streak line

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final card = this.card;
    final cards = store.cards;
    final copies = cards.where((c) => c.birdId == bird.id).length;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _lockScreen.invokeMethod<void>('hold', false);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: CardDetail(
              bird: bird,
              card: card,
              recording: recording,
              onClose: () => Navigator.of(context).pop(),
              flipIn: card != null,
              header: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    if (firstOfSpecies)
                      Text(
                        l.speciesCollected(
                          ordinal(bestCards(cards).length, l.localeName),
                        ),
                        style: text.titleMedium,
                      )
                    else if (card != null && copies > 1)
                      Text('×$copies', style: text.titleMedium),
                    if (!training)
                      Text(
                        streakLost ? l.streakLost : l.streak(store.streak),
                        style: text.bodySmall,
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
}

/// Alarm payload: {"bird": id, "rec": file}; before 3c it was just the bird id.
Map<String, dynamic> _parsePayload(String? payload) {
  try {
    return jsonDecode(payload ?? '') as Map<String, dynamic>;
  } on FormatException {
    return {'bird': payload};
  }
}
