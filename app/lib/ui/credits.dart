import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Where the birds, songs, photos and card stats come from, and their licenses.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.credits)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l.creditsBody, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
