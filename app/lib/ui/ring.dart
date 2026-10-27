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
  late final int _bird = int.tryParse(widget.alarm.payload ?? '') ?? 0;
  late final List<Bird> _choices = choicesFor(birds[_bird]);
  late final int _oldStreak = store.streak;
  bool? _correct;

  Future<void> _guess(Bird bird) async {
    if (_correct != null) return;
    await _lockScreen.invokeMethod<void>('hold', true);
    await Alarm.stop(widget.alarm.id);
    final correct = bird == birds[_bird];
    if (!mounted) return;
    await store.answered(
      widget.alarm.id,
      _bird,
      correct,
      AppLocalizations.of(context).openToAnswer,
    );
    setState(() => _correct = correct);
    HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => RevealScreen(bird: birds[_bird])),
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
                      const Spacer(),
                      Text(l.whoIsSinging, style: text.headlineMedium),
                      const Spacer(),
                      for (final bird in _choices)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: FilledButton(
                            onPressed: () => _guess(bird),
                            child: Text(bird.nameIn(l.localeName)),
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
                // shortcut: initial in a circle stands in for the photo until Iteration 3.
                CircleAvatar(
                  radius: 80,
                  backgroundColor: coral,
                  child: Text(name[0], style: text.displayMedium),
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
                Text(l.placeholderAudio, style: text.bodySmall),
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
