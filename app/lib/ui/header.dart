import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'account.dart';
import 'settings.dart';

/// The top row of the Alarms and Training pages: the account on the left, [center] in
/// the middle, Settings on the right.
class PageHeader extends StatelessWidget {
  const PageHeader({required this.center, super.key});
  final Widget center;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    void open(Widget screen) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => screen));
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconButton(
            tooltip: l.account,
            icon: const Icon(Icons.person_outline),
            onPressed: () => open(const AccountScreen()),
          ),
          Expanded(
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: center),
            ),
          ),
          IconButton(
            tooltip: l.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => open(const SettingsScreen()),
          ),
        ],
      ),
    );
  }
}
