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
  String get whoIsSinging => 'Who is singing?';

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
  String get allBirdsHint => 'Any bird of the region, whatever the season';

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
  String get heardHint => 'Guess it right next time to win this card';

  @override
  String quality(int percent) {
    return 'Quality $percent %';
  }

  @override
  String get weight => 'Weight';

  @override
  String get wingspan => 'Wingspan';

  @override
  String get length => 'Length';

  @override
  String get flightDistance => 'Flight';

  @override
  String get newCard => 'New card!';

  @override
  String get share => 'Share';

  @override
  String progress(int owned, int total) {
    return '$owned / $total cards';
  }

  @override
  String get dataSources =>
      'Data: GBIF · Wikidata · Wikipedia · AVONET (Tobias et al. 2022, CC BY 4.0) · xeno-canto · Wikimedia Commons';

  @override
  String get chooseRegion => 'Where do you live?';

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
  String get downloading => 'Downloading your region\'s birds…';

  @override
  String nearCell(String lat, String lon) {
    return 'Around $lat $lon';
  }

  @override
  String get locationDenied => 'Location not available. Choose from the list.';

  @override
  String youHeard(String kind) {
    return 'You heard its $kind';
  }

  @override
  String get song => 'song';

  @override
  String get call => 'call';

  @override
  String get alarmCall => 'alarm call';
}
