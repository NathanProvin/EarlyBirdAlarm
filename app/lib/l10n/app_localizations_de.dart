// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get noAlarms => 'Keine Wecker';

  @override
  String get guessTheBird => 'Welcher Vogel singt?';

  @override
  String get snooze => 'Schlummern';

  @override
  String snoozeMinutes(int minutes) {
    return 'Schlummern: $minutes min';
  }

  @override
  String streak(int count) {
    return 'Serie $count';
  }

  @override
  String get once => 'Einmal';

  @override
  String get label => 'Bezeichnung';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get done => 'Fertig';

  @override
  String get settings => 'Einstellungen';

  @override
  String get difficulty => 'Schwierigkeit';

  @override
  String get easy => 'Leicht';

  @override
  String get medium => 'Mittel';

  @override
  String get hard => 'Schwer';

  @override
  String get allBirds => 'Alle Vögel';

  @override
  String get language => 'Sprache';

  @override
  String get systemLanguage => 'Telefon';

  @override
  String get region => 'Region';

  @override
  String get alarms => 'Wecker';

  @override
  String get collection => 'Sammlung';

  @override
  String get common => 'Häufig';

  @override
  String get uncommon => 'Ungewöhnlich';

  @override
  String get rare => 'Selten';

  @override
  String get epic => 'Episch';

  @override
  String get legendary => 'Legendär';

  @override
  String get heard => 'Gehört';

  @override
  String get weight => 'Gewicht';

  @override
  String get wingspan => 'Spannweite';

  @override
  String get length => 'Länge';

  @override
  String get flightDistance => 'Zug';

  @override
  String get share => 'Teilen';

  @override
  String progress(int owned, int total) {
    return '$owned / $total Karten';
  }

  @override
  String get useMyLocation => 'Meinen Standort verwenden';

  @override
  String get searchRegion => 'Land oder Region suchen';

  @override
  String get offline =>
      'Keine Verbindung. Verbinde dich mit dem Internet, um die Vögel deiner Region zu laden.';

  @override
  String get comingSoon => 'Demnächst';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String nearCell(String lat, String lon) {
    return 'Um $lat $lon';
  }

  @override
  String get locationDenied =>
      'Standort nicht verfügbar. Suche deine Region oder tippe sie auf der Karte an.';

  @override
  String get song => 'Gesang';

  @override
  String get call => 'Ruf';

  @override
  String get alarmCall => 'Warnruf';

  @override
  String get seasonalBirds => 'Vögel der Saison';

  @override
  String get credits => 'Quellen';

  @override
  String get creditsBody =>
      'Vorkommen und Jahreszeiten der Vögel: Beobachtungsdaten von GBIF.org.\n\nNamen und Fotos: Wikidata und Wikimedia Commons (CC0, gemeinfrei, CC BY, CC BY-SA); Urheber und Lizenz jedes Fotos stehen auf seiner Karte (ⓘ).\n\nGesänge und Rufe: Aufnahmen von xeno-canto.org (CC0, CC BY, CC BY-SA, und CC BY-NC-SA / BY-NC für einige Arten ohne freie Aufnahme); Urheber und Lizenz stehen auf der Karte (ⓘ).\n\nKartenwerte: AVONET (Tobias et al. 2022, Ecology Letters, CC BY 4.0), Wikipedia und Wikidata.';

  @override
  String get tryNextTime => 'Beim nächsten Mal klappt\'s!';

  @override
  String speciesCollected(String ordinal) {
    return '$ordinal Art gesammelt!';
  }

  @override
  String get streakLost => 'Serie verloren';

  @override
  String get viewSpecies => 'Arten';

  @override
  String get viewAll => 'Alle';

  @override
  String get viewRegion => 'Region';

  @override
  String get allRarities => 'Alle Seltenheiten';

  @override
  String get theme => 'Design';

  @override
  String get resident => 'Standvogel';

  @override
  String get themeBlackbird => 'Amsel';

  @override
  String get themeSerin => 'Girlitz';

  @override
  String get themeBlueTit => 'Blaumeise';

  @override
  String get themeGull => 'Möwe';

  @override
  String get play => 'Anhören';

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get easyInfo => 'Häufige Vögel, nur Gesang';

  @override
  String get mediumInfo => 'Weniger häufige Vögel, Gesang und Rufe';

  @override
  String get hardInfo => 'Seltenere Vögel, alle Laute';

  @override
  String get seasonalInfo => 'Nur Vögel, die diesen Monat da sind';

  @override
  String get allBirdsInfo => 'Alle Vögel der Region';

  @override
  String get creditsSubtitle => 'Quellen, Lizenzen und Datenschutz';

  @override
  String get twitch => 'Twitcher';

  @override
  String get twitchInfo => 'Trainiere und gewinne Karten';

  @override
  String get twitchZone => 'Twitcher-Zone';

  @override
  String get openBooster => 'Booster öffnen';

  @override
  String get listenAgain => 'Nochmal hören';

  @override
  String get series => 'Serien';

  @override
  String get legendaryHunter => 'Legendenjäger';

  @override
  String get perfectWeek => 'Perfekte Woche';

  @override
  String get fullSet => 'Alle Seltenheiten';

  @override
  String get collector => 'Sammler';

  @override
  String get localExpert => 'Lokaler Experte';

  @override
  String get rareFinds => 'Schöne Funde';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String ringsInDays(int days, int hours) {
    return 'Klingelt in $days T $hours h';
  }

  @override
  String ringsInHours(int hours, String minutes) {
    return 'Klingelt in $hours h $minutes';
  }

  @override
  String ringsInMinutes(int minutes) {
    return 'Klingelt in $minutes min';
  }
}
