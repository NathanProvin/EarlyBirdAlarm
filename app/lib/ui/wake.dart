import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/app_localizations.dart';

const _wake = MethodChannel('early_bird/wake'); // MainActivity

/// What Android needs so a ringing alarm shows the quiz over the lock screen, each with
/// a Fix button. On the onboarding's region page.
class AlarmPermissions extends StatefulWidget {
  const AlarmPermissions({super.key});

  @override
  State<AlarmPermissions> createState() => _AlarmPermissionsState();
}

class _AlarmPermissionsState extends State<AlarmPermissions>
    with WidgetsBindingObserver {
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final missing = [_notifications, _fullScreen, _battery].contains(false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.alarmPermissions,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        _Row(l.wakeNotifications, _notifications, _fixNotifications),
        _Row(
          l.wakeFullScreen,
          _fullScreen,
          () => _wake.invokeMethod<void>('fixFullScreen'),
        ),
        // Only on brands that kill apps, while restricted (see MainActivity "battery").
        if (_battery == false)
          _Row(
            l.wakeBattery,
            _battery,
            () => _wake.invokeMethod<void>('fixBattery'),
          ),
        if (missing) ...[
          const SizedBox(height: 8),
          Text(
            l.wakeMissing,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

/// One requirement: its name, then ✓ when met or a Fix button.
class _Row extends StatelessWidget {
  const _Row(this.label, this.ok, this.onFix);
  final String label;
  final bool? ok; // null while reading
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        ok == false ? Icons.error_outline : Icons.check_circle,
        color: ok == false ? scheme.error : scheme.primary,
        semanticLabel: ok == false ? l.wakeNotOk : l.wakeOk,
      ),
      title: Text(label, textAlign: TextAlign.start),
      trailing: ok == false
          ? FilledButton(
              // The theme's buttons are full width (Size.fromHeight): not here.
              style: FilledButton.styleFrom(minimumSize: const Size(88, 48)),
              onPressed: onFix,
              child: Text(l.wakeFix),
            )
          : null,
    );
  }
}
