import 'dart:math';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'birds.dart';
import 'ui/theme.dart';

// See MainActivity.kt: true keeps the app over the lock screen after the alarm stops.
const _lockScreen = MethodChannel('early_bird/lock_screen');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
  runApp(
    MaterialApp(
      title: 'Early Bird',
      theme: dawnTheme,
      home: const HomeScreen(),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _next;
  int? _ringingId; // guards against pushing the ring screen twice

  @override
  void initState() {
    super.initState();
    Permission.notification.request();
    Alarm.scheduled.listen((set) {
      if (mounted) setState(() => _next = set.alarms.firstOrNull?.dateTime);
    });
    Alarm.ringing.listen((set) {
      final alarm = set.alarms.firstOrNull;
      if (alarm == null || alarm.id == _ringingId || !mounted) return;
      _ringingId = alarm.id;
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(builder: (_) => RingScreen(alarm: alarm)),
          )
          .then((_) => _ringingId = null);
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    final now = DateTime.now();
    var at = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    final bird = Random().nextInt(birds.length);
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: 1,
        dateTime: at,
        assetAudioPath: birds[bird].audio,
        payload: '$bird',
        volumeSettings: VolumeSettings.fade(
          fadeDuration: const Duration(seconds: 60),
        ),
        notificationSettings: const NotificationSettings(
          title: 'Early Bird',
          body: 'Who is singing? Open to answer.',
          androidStopAlarmOnDismiss: false, // only a guess stops it
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final next = _next;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                next == null
                    ? 'No alarm'
                    : TimeOfDay.fromDateTime(next).format(context),
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _pickTime,
                child: const Text('Set alarm'),
              ),
              if (next != null)
                TextButton(
                  onPressed: () => Alarm.stop(1),
                  child: const Text('Cancel'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class RingScreen extends StatefulWidget {
  const RingScreen({required this.alarm, super.key});
  final AlarmSettings alarm;

  @override
  State<RingScreen> createState() => _RingScreenState();
}

class _RingScreenState extends State<RingScreen> {
  late final Bird _answer =
      birds[int.tryParse(widget.alarm.payload ?? '') ?? 0];
  late final List<Bird> _choices = choicesFor(_answer);
  bool? _correct;

  Future<void> _guess(Bird bird) async {
    if (_correct != null) return;
    await _lockScreen.invokeMethod<void>('hold', true);
    await Alarm.stop(widget.alarm.id);
    setState(() => _correct = bird == _answer);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => RevealScreen(bird: _answer)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final correct = _correct;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: correct != null
                ? Center(
                    child: TweenAnimationBuilder<double>(
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
                  )
                : Column(
                    children: [
                      const Spacer(),
                      Text(
                        'Who is singing?',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Spacer(),
                      for (final bird in _choices)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: FilledButton(
                            onPressed: () => _guess(bird),
                            child: Text(bird.name),
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

class RevealScreen extends StatelessWidget {
  const RevealScreen({required this.bird, super.key});
  final Bird bird;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                  child: Text(
                    bird.name.split(' ').last[0],
                    style: text.displayMedium,
                  ),
                ),
                const SizedBox(height: 24),
                Text(bird.name, style: text.headlineMedium),
                Text(
                  bird.latin,
                  style: text.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                Text('Placeholder audio', style: text.bodySmall),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
