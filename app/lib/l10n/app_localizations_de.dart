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
    return 'Serie: $count';
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
  String get birdRarity => 'Seltenheit';

  @override
  String get wikipedia => 'Wikipedia';

  @override
  String get expert => 'Experte';

  @override
  String get expertInfo => 'Alle Vögel, alle Laute, keine Auswahl';

  @override
  String get typeTheBird => 'Vogelnamen eintippen';

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
      'Vorkommen und Jahreszeiten der Vögel: Beobachtungsdaten von GBIF.org.\n\nNamen und Fotos: Wikidata und Wikimedia Commons (CC0, gemeinfrei, CC BY, CC BY-SA); Urheber und Lizenz jedes Fotos stehen auf seiner Karte (ⓘ).\n\nGesänge und Rufe: Aufnahmen von xeno-canto.org und iNaturalist (CC0, CC BY, CC BY-SA); Urheber und Lizenz stehen auf der Karte (ⓘ). Hahn des Notfallweckers: Kalvin Chan, iNaturalist (CC0).\n\nKartenwerte: AVONET (Tobias et al. 2022, Ecology Letters, CC BY 4.0), Wikipedia und Wikidata.';

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
  String get viewAll => 'Gesammelt';

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
  String get twitch => 'Training';

  @override
  String get twitchZone => 'Training';

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
  String get rarityMenu => 'Seltenheit';

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
      'Kommst du beim Lernen von Vogelstimmen nicht voran? Wach jeden Morgen mit einem neuen Vogel auf: Errate ihn, gewinne seine Karte und lerne seinen Gesang.';

  @override
  String get introRegionTitle => 'Region wählen';

  @override
  String get introRegion =>
      'Du hörst Vögel aus deiner Umgebung: Wähle eine Region auf der Karte oder nutze deinen aktuellen Standort.';

  @override
  String get introGameTitle => 'Spielweise';

  @override
  String get introLater =>
      'Schwierigere Einstellungen bringen bessere Belohnungen; du kannst sie später in den Einstellungen ändern.';

  @override
  String get introCollectionTitle => 'Karten sammeln';

  @override
  String get introTwitch =>
      'Training: alle 15 Minuten ein kostenloser Booster, um dein Gehör zu trainieren.';

  @override
  String get introSeries =>
      'Serien und Erfolge: Schließe sie ab, um garantiert seltene Karten zu erhalten.';

  @override
  String get introTrade =>
      'Tauschen: Triff andere Vogelbeobachter und tausche Karten von Person zu Person.';

  @override
  String get introExamineTitle => 'Karten betrachten';

  @override
  String get introExamine => 'Halte die Karte gedrückt, um sie zu betrachten!';

  @override
  String get next => 'Weiter';

  @override
  String get skip => 'Überspringen';

  @override
  String get introAgain => 'Einführung erneut ansehen';

  @override
  String get introRarityTitle => 'Seltenheit und Werte';

  @override
  String get introRarity =>
      'Die Seltenheit reicht von Häufig bis Legendär: Seltene Arten geben öfter seltene Karten. Jede Karte trägt außerdem echte Werte ihrer Art: Ziel ist ein 100-%-Vogel!';

  @override
  String get start => 'Starten';

  @override
  String get support => 'Early Bird unterstützen';

  @override
  String get tipsTile => 'Spendier mir einen Kaffee';

  @override
  String get tipsNote =>
      'Early Bird ist ohne Werbung, ohne Tracker und wird von einem Solo-Entwickler gepflegt. Wenn dir die App nützt, bedank dich mit einem Kaffee!';

  @override
  String get tipEspresso => 'Espresso';

  @override
  String get tipCappuccino => 'Cappuccino';

  @override
  String get tipBreakfast => 'Frühstück';

  @override
  String get tipBinoculars => 'Stabilisiertes Fernglas';

  @override
  String get tipsPayments =>
      'Bezahlung über Google Play. Im Spiel ändert sich nichts.';

  @override
  String get thankYou => 'Danke!';

  @override
  String get thankYouBody =>
      'Deine Unterstützung lässt Early Bird weitersingen.';

  @override
  String get purchasesUnavailable =>
      'Käufe sind auf diesem Telefon nicht verfügbar.';

  @override
  String get twitchPlus => 'Early Bird Plus';

  @override
  String get twitchPlusPitch =>
      'Unbegrenzter Modus: ein Booster pro Minute! Einmal kaufen, für immer.';

  @override
  String get paymentsGoogle => 'Bezahlung über Google Play.';

  @override
  String shareTitle(String rarity) {
    return 'Karte „$rarity“!';
  }

  @override
  String get shareTagline =>
      'Der Wecker für Vogelfreunde · Gratis bei Google Play';

  @override
  String shareText(String bird, String rarity, String link) {
    return 'Ich hab den Gesang erkannt: $bird! Karte „$rarity“ gewonnen. $link';
  }

  @override
  String get shareCopied =>
      'Link kopiert: füge ihn in deine Nachricht ein, falls die App ihn weglässt';

  @override
  String get gyro => 'Gyro';

  @override
  String get gyroHint => 'Karten neigen sich, wenn du das Handy bewegst';

  @override
  String backupMinutes(int minutes) {
    return 'Notfallwecker nach $minutes Min.';
  }

  @override
  String get backupOff => 'Kein Notfallwecker';

  @override
  String get wakeNotifications => 'Benachrichtigungen';

  @override
  String get wakeFullScreen => 'Quiz auf dem Sperrbildschirm';

  @override
  String get wakeBattery => 'Akku: nicht eingeschränkt';

  @override
  String get wakeFix => 'Beheben';

  @override
  String get wakeMissing =>
      'Ohne das kann ein Alarm klingeln, ohne das Quiz zu zeigen.';

  @override
  String get wakeOk => 'OK';

  @override
  String get wakeNotOk => 'Fehlt';

  @override
  String get alarmPermissions => 'Weck-Berechtigungen';

  @override
  String get addAlarm => 'Wecker hinzufügen';

  @override
  String get supportNudge =>
      'Gefällt dir Early Bird? Spendier mir einen Kaffee';

  @override
  String get viewWorld => 'Welt';

  @override
  String get sortMenu => 'Sortieren';

  @override
  String get sortNumber => 'Nummer';

  @override
  String get sortRarity => 'Seltenheit';

  @override
  String get sortName => 'Name';

  @override
  String get coveredArea => 'Rot: abgedeckter Bereich';

  @override
  String get confirmRegion => 'Bestätigen';

  @override
  String get notCovered => 'Noch nicht abgedeckt';

  @override
  String get supportShort => 'Kostenlos, ohne Werbung, ohne Tracker';
}
