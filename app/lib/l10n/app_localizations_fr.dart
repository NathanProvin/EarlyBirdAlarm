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
  String get language => 'Langue';

  @override
  String get systemLanguage => 'Téléphone';

  @override
  String get region => 'Région';

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
  String get weight => 'Poids';

  @override
  String get wingspan => 'Envergure';

  @override
  String get length => 'Longueur';

  @override
  String get flightDistance => 'Vol';

  @override
  String get share => 'Partager';

  @override
  String progress(int owned, int total) {
    return '$owned / $total cartes';
  }

  @override
  String get useMyLocation => 'Utiliser ma position';

  @override
  String get searchRegion => 'Chercher un pays ou une région';

  @override
  String get offline =>
      'Pas de connexion. Connectez-vous à Internet pour télécharger les oiseaux de votre région.';

  @override
  String get retry => 'Réessayer';

  @override
  String nearCell(String lat, String lon) {
    return 'Autour de $lat $lon';
  }

  @override
  String get locationDenied =>
      'Position indisponible. Choisissez dans la liste.';

  @override
  String get song => 'chant';

  @override
  String get call => 'cri';

  @override
  String get alarmCall => 'cri d\'alarme';

  @override
  String get seasonalBirds => 'Oiseaux de saison';

  @override
  String get credits => 'Crédits';

  @override
  String get creditsBody =>
      'Présence et saisons des oiseaux : données d\'observation de GBIF.org.\n\nNoms et photos : Wikidata et Wikimedia Commons (CC0, domaine public, CC BY, CC BY-SA) ; l\'auteur et la licence de chaque photo sont sur sa carte (ⓘ).\n\nChants et cris : enregistrements de xeno-canto.org (CC0, CC BY, CC BY-SA, et CC BY-NC-SA / BY-NC pour quelques espèces sans enregistrement libre) ; l\'auteur et la licence sont sur la carte (ⓘ).\n\nStatistiques des cartes : AVONET (Tobias et al. 2022, Ecology Letters, CC BY 4.0), Wikipédia et Wikidata.';

  @override
  String get tryNextTime => 'Ce sera pour la prochaine fois !';

  @override
  String speciesCollected(String ordinal) {
    return '$ordinal espèce collectée !';
  }

  @override
  String get streakLost => 'Série perdue';

  @override
  String get viewSpecies => 'Espèces';

  @override
  String get viewAll => 'Toutes';

  @override
  String get viewRegion => 'Région';

  @override
  String get allRarities => 'Toutes raretés';

  @override
  String get theme => 'Thème';

  @override
  String get themeBlackbird => 'Merle';

  @override
  String get themeGreenfinch => 'Verdier';

  @override
  String get themeBlueTit => 'Mésange';

  @override
  String get themeGull => 'Goéland';

  @override
  String get play => 'Écouter';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get easyInfo => 'Chants des oiseaux communs.';

  @override
  String get mediumInfo => 'Chants et cris, jusqu\'aux oiseaux rares.';

  @override
  String get hardInfo =>
      'Tous les sons, cris d\'alarme compris, de tous les oiseaux.';

  @override
  String get seasonalInfo => 'Seulement les oiseaux présents ce mois-ci.';

  @override
  String get allBirdsInfo => 'Les oiseaux de toutes les saisons.';

  @override
  String get creditsSubtitle => 'Sources, licences et confidentialité';

  @override
  String get twitch => 'Cocheur';

  @override
  String get twitchInfo => 'Entraînez-vous et gagnez des cartes';

  @override
  String get twitchZone => 'Zone Cocheur';

  @override
  String get openBooster => 'Ouvrir un booster';

  @override
  String get listenAgain => 'Réécouter';

  @override
  String get series => 'Séries';

  @override
  String get legendaryHunter => 'Chasseur de légendes';

  @override
  String get perfectWeek => 'Semaine parfaite';

  @override
  String get fullSet => 'Toutes les raretés';

  @override
  String get collector => 'Collectionneur';

  @override
  String get localExpert => 'Expert local';

  @override
  String get rareFinds => 'Belles trouvailles';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String ringsInDays(int days, int hours) {
    return 'Sonne dans $days j $hours h';
  }

  @override
  String ringsInHours(int hours, String minutes) {
    return 'Sonne dans $hours h $minutes';
  }

  @override
  String ringsInMinutes(int minutes) {
    return 'Sonne dans $minutes min';
  }
}
