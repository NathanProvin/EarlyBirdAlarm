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

  @override
  String get trade => 'Tauschen';

  @override
  String get viewMenu => 'Ansicht wählen';

  @override
  String get rarityMenu => 'Nach Seltenheit filtern';

  @override
  String get lookingForBirder => 'Suche nach Vogelbeobachtern in der Nähe…';

  @override
  String get lookingHint =>
      'Bitte die andere Person, auch Tauschen zu öffnen, Telefone nah beieinander.';

  @override
  String get checkCode => 'Seht ihr beide diese zwei Vögel?';

  @override
  String get itMatches => 'Stimmt';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get youGive => 'Du gibst';

  @override
  String get youGet => 'Du bekommst';

  @override
  String get nothingYet => 'Noch nichts';

  @override
  String get addCards => 'Karten hinzufügen';

  @override
  String get validate => 'Bestätigen';

  @override
  String get youValidated => 'Du hast bestätigt';

  @override
  String get theyValidated => 'Die andere Person hat bestätigt';

  @override
  String get waitingForThem => 'Warte auf die andere Person';

  @override
  String get tradeDone => 'Tausch abgeschlossen!';

  @override
  String get tradeCancelled => 'Tausch abgebrochen: nichts hat sich geändert.';

  @override
  String get updateToTrade =>
      'Aktualisiere die App, um mit dieser Person zu tauschen.';

  @override
  String get tradeInvalid =>
      'Diese Karten können nicht angenommen werden. Tausch abgebrochen.';

  @override
  String get tradePermissions =>
      'Zum Tauschen braucht die App Bluetooth, Geräte in der Nähe und den genauen Standort (er verlässt nie dein Telefon). Erlaube sie in den App-Einstellungen.';

  @override
  String get openSettings => 'Einstellungen';

  @override
  String tradedOn(String date) {
    return 'Getauscht am $date';
  }

  @override
  String get tradeStartFailed =>
      'Die Suche nach Vogelbeobachtern in der Nähe konnte nicht starten. Ist Bluetooth an?';

  @override
  String get fiveOfAKind => 'Fünf gleiche';

  @override
  String get dawnChorus => 'Morgenchor';

  @override
  String get globetrotter => 'Weltenbummler';

  @override
  String get fullHouse => 'Volles Haus';

  @override
  String get perfectSpecimen => 'Perfektes Exemplar';

  @override
  String get ironStreak => 'Eiserne Serie';

  @override
  String get goalLegendaryHunter => '5 legendäre Karten';

  @override
  String get goalPerfectWeek => '7 Tage Weckserie';

  @override
  String get goalFullSet => 'Eine Karte jeder Seltenheit';

  @override
  String get goalCollector => '100 Karten';

  @override
  String get goalLocalExpert => '50 Arten deiner Region';

  @override
  String get goalRareFinds => '5 Karten Selten oder besser';

  @override
  String get goalFiveOfAKind => '5 Exemplare einer Art';

  @override
  String get goalDawnChorus => '10 Karten vor 7 Uhr gewonnen';

  @override
  String get goalGlobetrotter => 'Karten aus 3 Regionen';

  @override
  String get goalFullHouse => '3 Serien abgeschlossen';

  @override
  String get goalPerfectSpecimen => 'Eine Karte mit 95 % Qualität oder mehr';

  @override
  String get goalIronStreak => '30 Tage Weckserie';

  @override
  String get seriesComplete => 'Serie abgeschlossen!';

  @override
  String get achievementUnlocked => 'Erfolg freigeschaltet!';

  @override
  String rewardRarity(String rarity) {
    return 'Belohnung: $rarity';
  }

  @override
  String get tapToCollect => 'Tippen zum Abholen';

  @override
  String get tradeLocationOff =>
      'Schalte den Standort ein, um Vogelbeobachter in der Nähe zu finden. Deine Position wird weder verwendet noch gesendet.';

  @override
  String get tradeNeedsLocation =>
      'Zum Tauschen braucht die App die Standortberechtigung (Android verlangt sie für die Bluetooth-Suche; deine Position wird nie verwendet). Erlaube sie in den App-Einstellungen.';

  @override
  String get tradeNeedsPrecise =>
      'Zum Tauschen braucht die App den genauen Standort: Aktiviere in den App-Einstellungen unter Standort „Genauen Standort verwenden“.';

  @override
  String get tradeNeedsBluetooth =>
      'Zum Tauschen braucht die App die Berechtigungen für Bluetooth und Geräte in der Nähe. Erlaube sie in den App-Einstellungen.';

  @override
  String get searchCollection => 'Sammlung durchsuchen';

  @override
  String get noSpeciesFound => 'Keine Art gefunden';

  @override
  String get introWelcome =>
      'Wach auf mit echtem Vogelgesang. Errate den Vogel unter 4 Fotos, um den Wecker auszuschalten, und gewinne seine Karte.';

  @override
  String get introRegionTitle => 'Deine Region';

  @override
  String get introRegion =>
      'Deine Wecker spielen die Vögel, die je nach Jahreszeit um dich herum leben. Wähle deine Region auf der Karte oder nutze deinen Standort.';

  @override
  String get introGameTitle => 'Dein Spiel';

  @override
  String get introLater =>
      'Sprache, Design und all das kannst du später in den Einstellungen ändern.';

  @override
  String get introCollectionTitle => 'Deine Sammlung';

  @override
  String get introTwitch =>
      'Twitcher-Zone: alle 15 Minuten ein kostenloser Booster, um dein Gehör zu trainieren.';

  @override
  String get introSeries =>
      'Serien und Erfolge: Schließe sie ab, um garantiert seltene Karten zu erhalten.';

  @override
  String get introTrade =>
      'Tauschen: Triff andere Vogelbeobachter und tausche Karten von Person zu Person.';

  @override
  String get introExamineTitle => 'Betrachte deine Karten';

  @override
  String get introExamine =>
      'Halte eine Karte und bewege den Finger: Sie neigt sich und fängt das Licht ein. Probier es aus!';

  @override
  String get next => 'Weiter';

  @override
  String get skip => 'Überspringen';

  @override
  String get letsGo => 'Los geht\'s!';

  @override
  String get introAgain => 'Einführung erneut ansehen';
}
