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
  // Keep songs on the phone for upcoming rings; also runs after each guess (see ring.dart).
  unawaited(topUpDeck(store.monthFor(DateTime.now()), store.difficulty));
  runApp(
    ListenableBuilder(
      listenable: store,
      builder: (_, _) => MaterialApp(
        title: 'Early Bird',
        theme: dawnTheme,
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

class _HomeScreenState extends State<HomeScreen> {
  int? _ringingId; // guards against pushing the ring screen twice
  int _tab = 0; // 0 = alarms, 1 = collection

  @override
  void initState() {
    super.initState();
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
                            subtitle: Text(
                              [
                                if (a.label.isNotEmpty) a.label,
                                daysText(context, a.days),
                              ].join(' · '),
                            ),
                            trailing: Switch(
                              value: a.enabled,
                              onChanged: (on) =>
                                  store.save(a..enabled = on, l.guessTheBird),
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
