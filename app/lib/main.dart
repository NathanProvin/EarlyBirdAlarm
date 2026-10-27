import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'l10n/app_localizations.dart';
import 'store.dart';
import 'ui/edit.dart';
import 'ui/ring.dart';
import 'ui/theme.dart';

late final Store store;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
  store = await Store.load();
  runApp(
    MaterialApp(
      title: 'Early Bird',
      theme: dawnTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
  int? _ringingId; // guards against pushing the ring screen twice

  @override
  void initState() {
    super.initState();
    Permission.notification.request();
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
          floatingActionButton: FloatingActionButton(
            elevation: 0,
            onPressed: _edit,
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l.streak(store.streak), style: text.titleMedium),
                ),
                if (alarms.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(l.noAlarms, style: text.titleLarge),
                    ),
                  ),
                for (final a in alarms)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    onTap: () => _edit(a),
                    title: Text(
                      TimeOfDay(hour: a.hour, minute: a.minute).format(context),
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
                          store.save(a..enabled = on, l.openToAnswer),
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
