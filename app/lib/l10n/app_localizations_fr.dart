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
  String get guessTheBird => 'Devinez l\'oiseau !';

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

  @override
  String get alarms => 'Alarmes';

  @override
  String get collection => 'Collection';

  @override
  String get common => 'Commune';

  @override
  String get uncommon => 'Peu commune';

  @override
  String get rare => 'Rare';

  @override
  String get epic => 'Épique';

  @override
  String get legendary => 'Légendaire';

  @override
  String get heard => 'Entendu';

  @override
  String get heardHint =>
      'Devinez-le la prochaine fois pour gagner cette carte';

  @override
  String quality(int percent) {
    return 'Qualité $percent %';
  }

  @override
  String get weight => 'Poids';

  @override
  String get wingspan => 'Envergure';

  @override
  String get length => 'Longueur';

  @override
  String get flightDistance => 'Vol';

  @override
  String get newCard => 'Nouvelle carte !';

  @override
  String get share => 'Partager';

  @override
  String progress(int owned, int total) {
    return '$owned / $total cartes';
  }

  @override
  String get dataSources =>
      'Données : GBIF · Wikidata · Wikipédia · AVONET (Tobias et al. 2022, CC BY 4.0) · xeno-canto · Wikimedia Commons';
}
