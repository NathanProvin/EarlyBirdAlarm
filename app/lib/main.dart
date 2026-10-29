import 'dart:async';

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

class _HomeScreenState extends State<HomeScreen> {
  int? _ringingId; // guards against pushing the ring screen twice
  int _tab = 0; // 0 = alarms, 1 = collection
  late final Timer _tick; // keeps "Rings in …" current

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(seconds: 20),
      (_) => setState(() {}),
    );
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
        final now = DateTime.now();
        final next = alarms
            .where((a) => a.enabled)
            .map((a) => (a, nextRing(a, now)))
            .fold<(AlarmData, DateTime)?>(
              null,
              (best, e) => best == null || e.$2.isBefore(best.$2) ? e : best,
            )
            ?.$1;
        return Scaffold(
          floatingActionButton: _tab != 0
              ? null
              : FloatingActionButton(
                  elevation: 0,
                  onPressed: _edit,
                  child: const Icon(Icons.add),
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.alarm),
                label: l.alarms,
              ),
              NavigationDestination(
                icon: const Icon(Icons.style_outlined),
                label: l.collection,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // The collection uses the whole screen: no streak / settings row there.
                if (_tab == 0)
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
                if (_tab == 1)
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
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            onTap: () => _edit(a),
                            title: Text(
                              TimeOfDay(
                                hour: a.hour,
                                minute: a.minute,
                              ).format(context),
                              style: text.displaySmall,
                            ),
                            subtitle: Text.rich(
                              TextSpan(
                                children: [
                                  if (a.label.isNotEmpty)
                                    TextSpan(
                                      text: '${a.label} · ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  TextSpan(text: daysText(context, a.days)),
                                  if (a == next)
                                    TextSpan(text: '\n${ringsIn(l, a)}'),
                                ],
                              ),
                            ),
                            trailing: Semantics(
                              // TalkBack: "07:00, Mon Tue, on".
                              label:
                                  '${TimeOfDay(hour: a.hour, minute: a.minute).format(context)}, ${daysText(context, a.days)}',
                              child: Switch(
                                value: a.enabled,
                                onChanged: (on) =>
                                    store.save(a..enabled = on, l.guessTheBird),
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
