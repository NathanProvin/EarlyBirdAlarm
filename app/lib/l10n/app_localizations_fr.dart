// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get noAlarms => 'Aucune alarme';

  @override
  String get whoIsSinging => 'Qui chante ?';

  @override
  String get openToAnswer => 'Qui chante ? Ouvrez pour répondre.';

  @override
  String get snooze => 'Répéter';

  @override
  String snoozeMinutes(int minutes) {
    return 'Répéter après $minutes min';
  }

  @override
  String streak(int count) {
    return 'Série $count';
  }

  @override
  String get once => 'Une fois';

  @override
  String get label => 'Libellé';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get done => 'Terminé';

  @override
  String get settings => 'Réglages';

  @override
  String get difficulty => 'Difficulté';

  @override
  String get easy => 'Facile';

  @override
  String get medium => 'Moyen';

  @override
  String get hard => 'Difficile';

  @override
  String get allBirds => 'Tous les oiseaux';

  @override
  String get allBirdsHint =>
      'N\'importe quel oiseau de la région, quelle que soit la saison';

  @override
  String get language => 'Langue';

  @override
  String get systemLanguage => 'Téléphone';

  @override
  String get region => 'Région';

  @override
  String get northernFrance => 'Nord de la France';
}
