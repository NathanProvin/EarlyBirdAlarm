import 'dart:async';
import 'dart:ui' as ui;

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'content.dart';
import 'l10n/app_localizations.dart';
import 'store.dart';
import 'ui/collection.dart';
import 'ui/edit.dart';
import 'ui/region.dart';
import 'ui/ring.dart';
import 'ui/settings.dart';
import 'ui/theme.dart';
import 'ui/twitch.dart';

late final Store store;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
  store = await Store.load();
  await initContent(store.region);
  // Catch up with the region in the background; also runs after each guess (see ring.dart).
  unawaited(store.sync());
  unawaited(store.healAlarms());
  runApp(
    ListenableBuilder(
      listenable: store,
      builder: (_, _) => MaterialApp(
        title: 'Early Bird',
        theme: themeFor(store.theme == 'system' ? 'dawn' : store.theme),
        darkTheme: themeFor('dusk'),
        themeMode: store.theme == 'system' ? ThemeMode.system : ThemeMode.light,
        locale: store.language == null ? null : Locale(store.language!),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
      ),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// "Rings in 7 h 05", rounded up to the minute.
String ringsIn(AppLocalizations l, AlarmData a, [DateTime? now]) {
  now ??= DateTime.now();
  final m = (nextRing(a, now).difference(now).inSeconds / 60).ceil();
  final (d, h, min) = (m ~/ 1440, m % 1440 ~/ 60, m % 60);
  if (d > 0) return l.ringsInDays(d, h);
  if (h > 0) return l.ringsInHours(h, min.toString().padLeft(2, '0'));
  return l.ringsInMinutes(min);
}

/// A thin bar that fills over the last 24 h before [alarm] rings, pulsing gently.
class _RingBar extends StatefulWidget {
  const _RingBar(this.alarm);
  final AlarmData alarm;

  @override
  State<_RingBar> createState() => _RingBarState();
}

class _RingBarState extends State<_RingBar>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
    lowerBound: 0.6,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final left = nextRing(widget.alarm, now).difference(now);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: ringsIn(AppLocalizations.of(context), widget.alarm, now),
      excludeSemantics: true,
      child: FadeTransition(
        opacity: _pulse,
        child: LinearProgressIndicator(
          value: (1 - left.inMinutes / (24 * 60)).clamp(0.0, 1.0),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
          color: scheme.primary,
          backgroundColor: scheme.secondaryContainer,
        ),
      ),
    );
  }
}

/// Twitch | Alarms | Collection on frosted glass: the page shows through, blurred.
/// Alarms, the app's purpose, is a big accent circle in the middle; the two others are
/// small and muted until selected.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.tab,
    required this.onSelect,
    required this.ready,
  });
  final int tab;
  final ValueChanged<int> onSelect;
  final int ready; // Twitch quizzes available, shown as a badge

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget side(int i, IconData icon, String label, {int badge = 0}) {
      final on = tab == i;
      final color = on
          ? scheme.primary
          : scheme.onSurface.withValues(alpha: 0.6);
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: label,
          excludeSemantics: true,
          child: InkWell(
            onTap: () => onSelect(i),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // A little lower than centre: lines up with the big circle's middle.
                const SizedBox(height: 10),
                Badge(
                  isLabelVisible: badge > 0,
                  label: Text('$badge'),
                  backgroundColor: scheme.primary,
                  textColor: scheme.onPrimary,
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 4),
                Text(label, style: text.labelSmall?.copyWith(color: color)),
              ],
            ),
          ),
        ),
      );
    }

    final alarmsOn = tab == 1;
    final inset = MediaQuery.paddingOf(context).bottom; // gesture bar
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.65),
            border: Border(
              top: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08)),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: inset),
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  side(0, Icons.music_note, l.twitch, badge: ready),
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: alarmsOn,
                      label: l.alarms,
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () => onSelect(1),
                        child: Center(
                          // A ring around the circle marks the open tab.
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: alarmsOn
                                    ? scheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: scheme.primary,
                              child: Icon(
                                Icons.alarm,
                                size: 28,
                                color: scheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  side(2, Icons.style_outlined, l.collection),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  int? _ringingId; // guards against pushing the ring screen twice
  int _tab = 1; // 0 = Twitch, 1 = alarms, 2 = collection
  late final Timer _tick; // keeps "Rings in …" current

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 20), (_) => setState(() {}));
    Permission.notification.request();
    if (store.region == null) {
      // First launch: where do you live?
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const RegionScreen())),
      );
    }
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

  void _edit([AlarmData? alarm]) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => EditScreen(alarm: alarm)));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final alarms = store.alarms;
        return Scaffold(
          floatingActionButton: _tab != 1
              ? null
              : FloatingActionButton(
                  elevation: 0,
                  onPressed: _edit,
                  child: const Icon(Icons.add),
                ),
          bottomNavigationBar: _BottomBar(
            tab: _tab,
            onSelect: (i) => setState(() => _tab = i),
            ready: twitchCharges(store.twitchStart, DateTime.now()),
          ),
          // The pages run under the glass bar; their lists pad their ends by
          // MediaQuery's bottom padding, which then includes the bar.
          extendBody: true,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Other tabs use the whole screen: no streak / settings row there.
                if (_tab == 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
                    child: Row(
                      children: [
                        Text(l.streak(store.streak), style: text.titleMedium),
                        const Spacer(),
                        IconButton(
                          tooltip: l.settings,
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_tab == 0)
                  const Expanded(child: TwitchScreen())
                else if (_tab == 2)
                  const Expanded(child: CollectionScreen())
                else if (alarms.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(l.noAlarms, style: text.titleLarge),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      children: [
                        for (final a in alarms)
                          InkWell(
                            onTap: () => _edit(a),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                12,
                                16,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Time, days and switch on one row.
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: TimeOfDay(
                                                  hour: a.hour,
                                                  minute: a.minute,
                                                ).format(context),
                                                style: text.displaySmall,
                                              ),
                                              TextSpan(
                                                text:
                                                    '  ${daysText(context, a.days)}',
                                                style: text.bodyLarge,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Semantics(
                                        // TalkBack: "07:00, Mon Tue, on".
                                        label:
                                            '${TimeOfDay(hour: a.hour, minute: a.minute).format(context)}, ${daysText(context, a.days)}',
                                        child: Switch(
                                          value: a.enabled,
                                          onChanged: (on) => store.save(
                                            a..enabled = on,
                                            l.guessTheBird,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (a.label.isNotEmpty)
                                    Text(
                                      a.label,
                                      style: text.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  if (a.enabled) ...[
                                    const SizedBox(height: 8),
                                    _RingBar(a),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
