import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../content.dart';
import '../l10n/app_localizations.dart';

/// Where the birds, songs, photos and card stats come from, their licenses, and the privacy policy.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final page = l.localeName.startsWith('fr')
        ? 'privacy-fr.html'
        : 'privacy.html';
    return Scaffold(
      appBar: AppBar(title: Text(l.credits)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l.creditsBody, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  launchUrl(Uri.parse(baseUrl.replaceFirst('v1/', page))),
              child: Text(l.privacyPolicy),
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder(
            future: const MethodChannel(
              'early_bird/version',
            ).invokeMethod<String>('get'),
            builder: (context, v) => Text(
              v.hasData ? l.version(v.data!) : '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
