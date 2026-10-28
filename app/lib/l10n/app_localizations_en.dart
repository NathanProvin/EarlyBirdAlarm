// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get noAlarms => 'No alarms';

  @override
  String get guessTheBird => 'Guess the bird!';

  @override
  String get snooze => 'Snooze';

  @override
  String snoozeMinutes(int minutes) {
    return 'Snooze $minutes min';
  }

  @override
  String streak(int count) {
    return 'Streak $count';
  }

  @override
  String get once => 'Once';

  @override
  String get label => 'Label';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get done => 'Done';

  @override
  String get settings => 'Settings';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get easy => 'Easy';

  @override
  String get medium => 'Medium';

  @override
  String get hard => 'Hard';

  @override
  String get allBirds => 'All birds';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'Phone';

  @override
  String get region => 'Region';

  @override
  String get alarms => 'Alarms';

  @override
  String get collection => 'Collection';

  @override
  String get common => 'Common';

  @override
  String get uncommon => 'Uncommon';

  @override
  String get rare => 'Rare';

  @override
  String get epic => 'Epic';

  @override
  String get legendary => 'Legendary';

  @override
  String get heard => 'Heard';

  @override
  String get weight => 'Weight';

  @override
  String get wingspan => 'Wingspan';

  @override
  String get length => 'Length';

  @override
  String get flightDistance => 'Flight';

  @override
  String get share => 'Share';

  @override
  String progress(int owned, int total) {
    return '$owned / $total cards';
  }

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get searchRegion => 'Search a country or region';

  @override
  String get offline =>
      'No connection. Connect to the internet to download your region\'s birds.';

  @override
  String get retry => 'Retry';

  @override
  String nearCell(String lat, String lon) {
    return 'Around $lat $lon';
  }

  @override
  String get locationDenied => 'Location not available. Choose from the list.';

  @override
  String get song => 'song';

  @override
  String get call => 'call';

  @override
  String get alarmCall => 'alarm call';

  @override
  String get seasonalBirds => 'Seasonal birds';

  @override
  String get credits => 'Credits';

  @override
  String get creditsBody =>
      'Bird presence and seasons: GBIF.org occurrence data.\n\nNames and photos: Wikidata and Wikimedia Commons (CC0, public domain, CC BY, CC BY-SA); each photo\'s author and license are on its card (ⓘ).\n\nSongs and calls: xeno-canto.org recordings (CC0, CC BY, CC BY-SA, and CC BY-NC-SA / BY-NC for a few species with no free recording); each recordist and license are on the card (ⓘ).\n\nCard stats: AVONET (Tobias et al. 2022, Ecology Letters, CC BY 4.0), Wikipedia and Wikidata.';

  @override
  String get tryNextTime => 'Try next time!';

  @override
  String newRarityCard(String rarity) {
    return 'New $rarity card!';
  }

  @override
  String speciesCollected(String ordinal) {
    return '$ordinal species collected!';
  }

  @override
  String get streakLost => 'Streak lost';

  @override
  String get viewCollected => 'Collected';

  @override
  String get viewCopies => 'All copies';

  @override
  String get viewRegion => 'Region';

  @override
  String get allRarities => 'All rarities';
}
