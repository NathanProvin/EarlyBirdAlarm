import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';

const _wake = MethodChannel('early_bird/wake'); // MainActivity

/// The Wake-up check: what Android needs so a ringing alarm shows the quiz over the lock
/// screen, each with a Fix button, and a test ring. In the onboarding and in Settings.
class WakeCheck extends StatefulWidget {
  const WakeCheck({super.key});

  @override
  State<WakeCheck> createState() => _WakeCheckState();
}

class _WakeCheckState extends State<WakeCheck> with WidgetsBindingObserver {
  bool? _notifications, _fullScreen, _battery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from a system settings screen: read everything again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final notifications = await Permission.notification.isGranted;
    final fullScreen = await _wake.invokeMethod<bool>('fullScreen') ?? true;
    final battery = await _wake.invokeMethod<bool>('battery') ?? true;
    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _fullScreen = fullScreen;
      _battery = battery;
    });
  }

  Future<void> _fixNotifications() async {
    if (await Permission.notification.request().isPermanentlyDenied) {
      await openAppSettings();
    }
    await _refresh();
  }

  Future<void> _test() async {
    final l = AppLocalizations.of(context);
    await store.testRing(l.guessTheBird);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.wakeTestSoon)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Battery is advice only: alarm-clock alarms get through battery optimisation (the
    // S22 passed 7 nights optimised); it matters on brands that kill apps (Xiaomi…).
    final missing = [_notifications, _fullScreen].contains(false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.wakeIntro),
        const SizedBox(height: 12),
        _Row(l.wakeNotifications, _notifications, _fixNotifications),
        _Row(
          l.wakeFullScreen,
          _fullScreen,
          () => _wake.invokeMethod<void>('fixFullScreen'),
        ),
        _Row(
          l.wakeBattery,
          _battery,
          () => _wake.invokeMethod<void>('fixBattery'),
          advice: true,
        ),
        if (missing) ...[
          const SizedBox(height: 8),
          Text(
            l.wakeMissing,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _test,
          icon: const Icon(Icons.alarm),
          label: Text(l.wakeTest),
        ),
      ],
    );
  }
}

/// One requirement: its name, then ✓ when met or a Fix button ([advice]: quieter).
class _Row extends StatelessWidget {
  const _Row(this.label, this.ok, this.onFix, {this.advice = false});
  final String label;
  final bool? ok; // null while reading
  final VoidCallback onFix;
  final bool advice;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // The theme's buttons are full width (Size.fromHeight): not here.
    const size = Size(88, 48);
    final fix = Text(l.wakeFix);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        ok != false
            ? Icons.check_circle
            : advice
            ? Icons.info_outline
            : Icons.error_outline,
        color: ok != false
            ? scheme.primary
            : advice
            ? scheme.onSurfaceVariant
            : scheme.error,
        semanticLabel: ok == false ? l.wakeNotOk : l.wakeOk,
      ),
      title: Text(label, textAlign: TextAlign.start),
      trailing: ok != false
          ? null
          : advice
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: size),
              onPressed: onFix,
              child: fix,
            )
          : FilledButton(
              style: FilledButton.styleFrom(minimumSize: size),
              onPressed: onFix,
              child: fix,
            ),
    );
  }
}

/// The Wake-up check on its own screen, from Settings.
class WakeCheckScreen extends StatelessWidget {
  const WakeCheckScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).wakeTitle)),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: const [WakeCheck()],
    ),
  );
}
