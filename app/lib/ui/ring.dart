import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:just_audio/just_audio.dart';

import '../birds.dart';
import '../cards.dart';
import '../content.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../store.dart';
import 'card.dart';
import 'collection.dart';
import 'theme.dart';
import 'tips.dart';

// See MainActivity.kt: true keeps the app over the lock screen after the alarm stops.
const _lockScreen = MethodChannel('early_bird/lock_screen');
const _buzz = MethodChannel(
  'early_bird/buzz',
); // full-strength vibration (MainActivity)

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

enum _Mark { none, picked, correct, wrong, faded }

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
  // Picked at the draw, photos fetched with it (else picked now, as before).
  late final List<Bird> _choices =
      store.drawnChoices(_bird, _rec?.file) ??
      choicesFor(
        _bird,
        store.monthFor(widget.alarm?.dateTime ?? DateTime.now()),
        store.difficulty,
      );
  late final int _oldStreak = store.streak;
  // The Twitch quiz's song, then the songs compared after a wrong guess (alarms ring
  // through the plugin).
  final _player = AudioPlayer();
  Bird? _tapped;

  // After a wrong guess (2026-11-12, user): the choices stay on screen to compare their
  // songs, for as long as the player likes; Next opens the reveal.
  VoidCallback? _next; // set while comparing
  Bird? _playing; // the bird whose song plays (or loads)
  bool _loading = false;

  Timer? _buzzTimer, _vibrateTimer;

  @override
  void initState() {
    super.initState();
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && _next != null && mounted) {
        setState(() => _playing = null);
      }
    });
    if (widget.training != null) {
      _player.setLoopMode(LoopMode.one);
      playRecording(_player, _rec!.file);
    }
    if (widget.alarm case final alarm?) {
      // The bird fades up over ringFade (Store._schedule); the phone vibrates from
      // ringVibrate.
      if (alarm.id < backupOffset) {
        final wait = alarm.dateTime.add(ringVibrate).difference(DateTime.now());
        _vibrateTimer = Timer(
          wait.isNegative ? Duration.zero : wait,
          () => _buzz.invokeMethod<void>('start', false),
        );
      }
      // With the backup alarm (the rooster), the phone buzzes at full strength.
      final minutes = store.byId(mainIdOf(alarm.id))?.backupMinutes ?? 0;
      if (minutes > 0) {
        final start = alarm.id >= backupOffset
            ? DateTime.now() // the backup itself opened the screen
            : alarm.dateTime.add(Duration(minutes: minutes));
        final wait = start.difference(DateTime.now());
        _buzzTimer = Timer(
          wait.isNegative ? Duration.zero : wait,
          () => _buzz.invokeMethod<void>('start', true),
        );
      }
    }
  }

  void _stopBuzz() {
    _buzzTimer?.cancel();
    _vibrateTimer?.cancel();
    _buzz.invokeMethod<void>('stop');
  }

  @override
  void dispose() {
    _buzzTimer?.cancel();
    _vibrateTimer?.cancel();
    if (widget.alarm != null) _buzz.invokeMethod<void>('stop');
    _player.dispose();
    super.dispose();
  }

  _Mark _markOf(Bird b) => switch (_tapped) {
    null => _Mark.none,
    _ when b == _bird => _Mark.correct, // the answer is always shown
    final t when b == t => _Mark.wrong,
    _ when _next != null => _Mark.none, // comparing: the others are back
    _ => _Mark.faded,
  };

  /// The birds to compare after a wrong guess: the 4 choices, or with a typed guess
  /// (Expert) the answer and the pick.
  List<Bird> get _board => store.difficulty == Difficulty.expert
      ? {_bird, ?_tapped}.toList()
      : _choices;

  /// The recording to compare for [b]: the one that rang for the answer; for the others
  /// one of the same kind (song / call), from the phone when there is one (no data, works
  /// offline), else streamed.
  Recording? _songOf(Bird b) {
    if (b == _bird && _rec != null) return _rec;
    final playable = b.playable(store.difficulty);
    final recs = playable.isEmpty ? b.recordings : playable;
    if (recs.isEmpty) return null;
    int score(Recording r) =>
        (r.kind == _rec?.kind ? 2 : 0) + (onPhone(r) ? 1 : 0);
    return recs.reduce((a, r) => score(r) > score(a) ? r : a);
  }

  /// Plays [b]'s song, or stops it if it's the one playing; one song at a time.
  Future<void> _listen(Bird b) async {
    if (_playing == b) {
      setState(() => _playing = null);
      return _player.stop();
    }
    final rec = _songOf(b);
    if (rec == null) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _playing = b;
      _loading = true;
    });
    await _player.setLoopMode(LoopMode.off);
    final ok = await playRecording(_player, rec.file);
    if (!mounted || _playing != b) return; // another bird was tapped meanwhile
    setState(() {
      _loading = false;
      if (!ok) _playing = null;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).songOffline)),
      );
    }
  }

  Future<void> _guess(Bird bird) async {
    if (_tapped != null) return;
    setState(() => _tapped = bird);
    // A short tap when right, a longer buzz when wrong.
    bird == _bird ? HapticFeedback.mediumImpact() : HapticFeedback.vibrate();
    // The answer stays on screen for 2 s, while the guess is saved.
    final shown = Future<void>.delayed(const Duration(seconds: 2));
    if (widget.alarm case final alarm?) {
      await _lockScreen.invokeMethod<void>('hold', true);
      _stopBuzz();
      await store.stopRing(alarm.id);
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
    void reveal() {
      unawaited(_player.stop());
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

    // Right: the card at once. Wrong: compare the songs first, as long as wanted.
    correct ? reveal() : setState(() => _next = reveal);
  }

  Future<void> _snooze() async {
    final alarm = widget.alarm!;
    if (_tapped != null) return;
    _stopBuzz();
    await store.snooze(alarm); // the same bird again, and its backup
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
        body: Stack(
          children: [
            // Expert: the bird's photo, blurred past recognition under a veil of the
            // theme: texture only, no hint.
            if (store.difficulty == Difficulty.expert) ...[
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 30,
                    sigmaY: 30,
                    tileMode: TileMode.mirror,
                  ),
                  child: BirdPhoto(_bird),
                ),
              ),
              Positioned.fill(
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface
                      .withValues(alpha: 0.55),
                ),
              ),
            ],
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Column(
                  children: [
                    if (_next != null) ...[
                      Text(
                        l.compareHint,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < _board.length; i += 2)
                        Expanded(
                          child: Row(
                            children: [
                              for (final bird in _board.skip(i).take(2))
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: _Choice(
                                      bird: bird,
                                      name: bird.nameIn(l.localeName),
                                      mark: _markOf(bird),
                                      onTap: () => _listen(bird),
                                      play: _playing != bird
                                          ? _Play.idle
                                          : _loading
                                          ? _Play.loading
                                          : _Play.playing,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      // Who recorded the song playing (CC BY).
                      if (_playing case final b? when _songOf(b) != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '♪ ${_songOf(b)!.credit}',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                            maxLines: 2, // the licence must stay readable
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ]
                    // Expert: no choices, the name is typed.
                    else if (store.difficulty == Difficulty.expert)
                      Expanded(
                        child: _TypedGuess(
                          answer: _bird,
                          tapped: _tapped,
                          onGuess: _guess,
                        ),
                      )
                    else
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
                      child: _next != null
                          ? FilledButton.icon(
                              onPressed: _next,
                              icon: const Icon(Icons.arrow_forward, size: 28),
                              label: Text(l.next),
                              style: FilledButton.styleFrom(
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleLarge,
                              ),
                            )
                          : widget.training == null
                          ? FilledButton.tonalIcon(
                              onPressed: _snooze,
                              icon: const Icon(Icons.snooze, size: 28),
                              label: Text(l.snooze),
                              style: button,
                            )
                          : StreamBuilder<bool>(
                              stream: _player.playingStream,
                              builder: (context, playing) =>
                                  FilledButton.tonalIcon(
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
          ],
        ),
      ),
    );
  }
}

/// Expert: a large field to type the bird's name, a third of the way down, and below it
/// the birds of the region whose name matches (in the app's language, English or Latin).
/// Made for a groggy morning: big text and targets. A tap closes the keyboard and marks
/// the pick; the guess is made 0.7 s later, then marked like the photos (✓ pulse / ✕
/// shake); only the pick and the answer stay.
class _TypedGuess extends StatefulWidget {
  const _TypedGuess({
    required this.answer,
    required this.tapped,
    required this.onGuess,
  });
  final Bird answer;
  final Bird? tapped;
  final ValueChanged<Bird> onGuess;

  @override
  State<_TypedGuess> createState() => _TypedGuessState();
}

class _TypedGuessState extends State<_TypedGuess> {
  String _query = '';
  Bird? _picked;

  Future<void> _pick(Bird bird) async {
    if (_picked != null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    setState(() => _picked = bird);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) widget.onGuess(bird);
  }

  _Mark _markOf(Bird b) => switch (widget.tapped) {
    null when _picked == null => _Mark.none,
    null => b == _picked ? _Mark.picked : _Mark.faded,
    _ when b == widget.answer => _Mark.correct,
    _ => _Mark.wrong, // only the pick and the answer are shown
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final big = Theme.of(context).textTheme.headlineSmall;
    final tapped = widget.tapped;
    final q = plainText(_query.trim());
    final shown = tapped != null
        ? {tapped, widget.answer}.toList()
        : q.isEmpty
        ? <Bird>[]
        : ([
            for (final b in birds)
              if (nameMatches(b, q, l.localeName)) b,
          ]..sort(
            (a, b) => a.nameIn(l.localeName).compareTo(b.nameIn(l.localeName)),
          ));
    const none = OutlineInputBorder(borderSide: BorderSide.none);
    return Column(
      children: [
        const Spacer(),
        // The field: frosted glass over the blurred background, outlined in the accent.
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: scheme.primary, width: 3),
              ),
              child: TextField(
                autofocus: true,
                enabled: tapped == null && _picked == null,
                style: big,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l.typeTheBird,
                  filled: false,
                  border: none,
                  enabledBorder: none,
                  focusedBorder: none,
                  disabledBorder: none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 22,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search, size: 32),
                  ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          flex: 2,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (final b in shown)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: _Marked(
                    mark: _markOf(b),
                    width: 3,
                    child: Material(
                      color: scheme.surfaceContainer.withValues(alpha: 0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radius),
                        side: BorderSide(color: scheme.outline),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(radius),
                        onTap: tapped == null && _picked == null
                            ? () => _pick(b)
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(b.nameIn(l.localeName), style: big),
                              ),
                              _MarkBadge(_markOf(b)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// After a guess: a green (✓, a pulse) or red (✕, a shake) frame, the others fading;
/// [_Mark.picked] frames the Expert pick in the accent while it's being checked.
class _Marked extends StatelessWidget {
  const _Marked({required this.mark, required this.child, this.width = 6});
  final _Mark mark;
  final Widget child;
  final double width; // of the frame

  @override
  Widget build(BuildContext context) {
    final color = switch (mark) {
      _Mark.correct => moss,
      _Mark.wrong => brick,
      _Mark.picked => Theme.of(context).colorScheme.primary,
      _ => Colors.transparent,
    };
    return AnimatedOpacity(
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
            border: Border.all(color: color, width: width),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The ✓ / ✕ badge of a guess, popping in; nothing before.
class _MarkBadge extends StatelessWidget {
  const _MarkBadge(this.mark);
  final _Mark mark;

  @override
  Widget build(BuildContext context) {
    if (mark != _Mark.correct && mark != _Mark.wrong) {
      return const SizedBox.shrink();
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: mark == _Mark.correct ? moss : brick,
        child: Icon(
          mark == _Mark.correct ? Icons.check : Icons.close,
          color: paper,
          size: 32,
        ),
      ),
    );
  }
}

/// A choice: the photo, its name in a frosted box, and after the guess a green / red frame,
/// a ✓ / ✕ badge and a pulse / shake; the other photos fade.
/// A choice's song while comparing: null before (the quiz itself).
enum _Play { idle, loading, playing }

class _Choice extends StatelessWidget {
  const _Choice({
    required this.bird,
    required this.name,
    required this.mark,
    required this.onTap,
    this.play,
  });
  final Bird bird;
  final String name;
  final _Mark mark;
  final VoidCallback onTap;
  final _Play? play;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final play = this.play;
    return Semantics(
      button: true,
      label: play == null ? name : '$name. ${l.play}',
      excludeSemantics: true,
      child: _Marked(
        mark: mark,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: BirdPhoto(bird),
              ),
              // The bird being heard: a ring in the accent around its photo.
              if (play != null && play != _Play.idle)
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: scheme.primary, width: 4),
                  ),
                ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Center(child: _GlassLabel(name)),
              ),
              Positioned(top: 8, right: 8, child: _MarkBadge(mark)),
              if (play != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: play == _Play.idle
                          ? scheme.surface.withValues(alpha: 0.85)
                          : scheme.primary,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: play == _Play.loading
                        ? CircularProgressIndicator(
                            strokeWidth: 3,
                            color: scheme.onPrimary,
                          )
                        : Icon(
                            play == _Play.playing
                                ? Icons.stop
                                : Icons.play_arrow,
                            color: play == _Play.playing
                                ? scheme.onPrimary
                                : scheme.onSurface,
                          ),
                  ),
                ),
            ],
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
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.bold);
    return LayoutBuilder(
      builder: (context, box) {
        // Names wrap between words, never inside one: when a single word is wider than
        // the label ("Mediterranean"), the font shrinks until it fits.
        final room = box.maxWidth - 24;
        var widest = 0.0;
        for (final word in name.split(' ')) {
          final p = TextPainter(
            text: TextSpan(text: word, style: style),
            textDirection: TextDirection.ltr,
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          widest = max(widest, p.width);
          p.dispose();
        }
        final size = style?.fontSize;
        final fitted = widest > room && size != null
            ? style!.copyWith(fontSize: size * room / widest)
            : style;
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius - 4),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Theme.of(context).colorScheme.surface
                  .withValues(alpha: 0.7),
              child: Text(
                name,
                style: fitted,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }
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
    final nudge = card != null && cards.length >= 30 && !store.supportNudged;
    // A natural break: Google decides whether its review sheet shows (never on a
    // sideloaded build). No question of ours first: Play forbids gating reviews.
    void close() {
      if (nudge) store.supportNudged = true;
      if (card != null && cards.length >= 15 && !store.reviewAsked) {
        store.reviewAsked = true;
        unawaited(InAppReview.instance.requestReview());
      }
      Navigator.of(context).pop();
    }

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
              onClose: close,
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
                      CopiesBadge(copies, large: true),
                    Text(
                      streakLost ? l.streakLost : l.streak(store.streak),
                      style: text.bodySmall,
                    ),
                    if (nudge)
                      TextButton.icon(
                        // The theme's buttons are full width (Size.fromHeight): not here.
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        icon: const Icon(Icons.coffee_outlined),
                        label: Text(l.supportNudge),
                        onPressed: () {
                          store.supportNudged = true;
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const TipsScreen(),
                            ),
                          );
                        },
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
