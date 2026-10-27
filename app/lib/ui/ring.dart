import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../birds.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'theme.dart';

// See MainActivity.kt: true keeps the app over the lock screen after the alarm stops.
const _lockScreen = MethodChannel('early_bird/lock_screen');

class RingScreen extends StatefulWidget {
  const RingScreen({required this.alarm, super.key});
  final AlarmSettings alarm;

  @override
  State<RingScreen> createState() => _RingScreenState();
}

class _RingScreenState extends State<RingScreen> {
  // An alarm set before an app update may name a bird that's gone; ask about any bird then.
  late final Bird _bird = birdById(widget.alarm.payload ?? '') ?? birds.first;
  late final List<Bird> _choices = choicesFor(
    _bird,
    store.monthFor(widget.alarm.dateTime),
    store.difficulty,
  );
  late final int _oldStreak = store.streak;
  bool? _correct;

  Future<void> _guess(Bird bird) async {
    if (_correct != null) return;
    await _lockScreen.invokeMethod<void>('hold', true);
    await Alarm.stop(widget.alarm.id);
    final correct = bird == _bird;
    if (!mounted) return;
    await store.answered(
      widget.alarm.id,
      _bird.id,
      correct,
      AppLocalizations.of(context).openToAnswer,
    );
    setState(() => _correct = correct);
    HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => RevealScreen(bird: _bird)),
    );
  }

  Future<void> _snooze() async {
    final minutes = store.byId(widget.alarm.id)?.snoozeMinutes ?? 10;
    await Alarm.stop(widget.alarm.id);
    // Same settings, so the same bird plays again.
    await Alarm.set(
      alarmSettings: widget.alarm.copyWith(
        dateTime: DateTime.now().add(Duration(minutes: minutes)),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final correct = _correct;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: correct != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          builder: (_, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: CircleAvatar(
                            radius: 80,
                            backgroundColor: correct ? moss : brick,
                            child: Icon(
                              correct ? Icons.check : Icons.close,
                              size: 96,
                              color: paper,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: _oldStreak, end: store.streak),
                          duration: const Duration(milliseconds: 600),
                          builder: (_, n, _) =>
                              Text(l.streak(n), style: text.headlineSmall),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Text(l.whoIsSinging, style: text.headlineMedium),
                      const SizedBox(height: 24),
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
                                      onTap: () => _guess(bird),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _snooze, child: Text(l.snooze)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.bird, required this.name, required this.onTap});
  final Bird bird;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: name,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image.asset(
                bird.photo,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

class RevealScreen extends StatelessWidget {
  const RevealScreen({required this.bird, super.key});
  final Bird bird;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final name = bird.nameIn(l.localeName);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _lockScreen.invokeMethod<void>('hold', false);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Image.asset(
                    bird.photo,
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  name,
                  style: text.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                Text(
                  bird.latin,
                  style: text.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                for (final credit in [bird.audioCredit, bird.photoCredit])
                  Text(
                    credit,
                    style: text.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.done),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
