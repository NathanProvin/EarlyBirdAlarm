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
  String get comingSoon => 'Coming soon';

  @override
  String get retry => 'Retry';

  @override
  String nearCell(String lat, String lon) {
    return 'Around $lat $lon';
  }

  @override
  String get locationDenied =>
      'Location not available. Search your region or tap it on the map.';

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
  String speciesCollected(String ordinal) {
    return '$ordinal species collected!';
  }

  @override
  String get streakLost => 'Streak lost';

  @override
  String get viewSpecies => 'Species';

  @override
  String get viewAll => 'All';

  @override
  String get viewRegion => 'Region';

  @override
  String get allRarities => 'All rarities';

  @override
  String get theme => 'Theme';

  @override
  String get resident => 'Resident';

  @override
  String get themeBlackbird => 'Blackbird';

  @override
  String get themeSerin => 'Serin';

  @override
  String get themeBlueTit => 'Blue Tit';

  @override
  String get themeGull => 'Gull';

  @override
  String get play => 'Play';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get easyInfo => 'Common birds, songs only';

  @override
  String get mediumInfo => 'Less common birds, songs & calls';

  @override
  String get hardInfo => 'Rarer birds, all vocalizations';

  @override
  String get seasonalInfo => 'Only birds present this month';

  @override
  String get allBirdsInfo => 'All birds in the region';

  @override
  String get creditsSubtitle => 'Sources, licenses and privacy';

  @override
  String get twitch => 'Twitch';

  @override
  String get twitchInfo => 'Train and earn cards';

  @override
  String get twitchZone => 'Twitch Zone';

  @override
  String get openBooster => 'Open a booster';

  @override
  String get listenAgain => 'Listen again';

  @override
  String get series => 'Series';

  @override
  String get legendaryHunter => 'Legendary hunter';

  @override
  String get perfectWeek => 'Perfect week';

  @override
  String get fullSet => 'Full set';

  @override
  String get collector => 'Collector';

  @override
  String get localExpert => 'Local expert';

  @override
  String get rareFinds => 'Rare finds';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String ringsInDays(int days, int hours) {
    return 'Rings in $days d $hours h';
  }

  @override
  String ringsInHours(int hours, String minutes) {
    return 'Rings in $hours h $minutes';
  }

  @override
  String ringsInMinutes(int minutes) {
    return 'Rings in $minutes min';
  }

  @override
  String get trade => 'Trade';

  @override
  String get viewMenu => 'Choose the view';

  @override
  String get rarityMenu => 'Filter by rarity';

  @override
  String get lookingForBirder => 'Looking for a birder nearby…';

  @override
  String get lookingHint =>
      'Ask them to open Trade too, phones close together.';

  @override
  String get checkCode => 'Do you both see these two birds?';

  @override
  String get itMatches => 'It matches';

  @override
  String get cancel => 'Cancel';

  @override
  String get youGive => 'You give';

  @override
  String get youGet => 'You get';

  @override
  String get nothingYet => 'Nothing yet';

  @override
  String get addCards => 'Add cards';

  @override
  String get validate => 'Validate';

  @override
  String get youValidated => 'You validated';

  @override
  String get theyValidated => 'They validated';

  @override
  String get waitingForThem => 'Waiting for the other birder';

  @override
  String get tradeDone => 'Trade done!';

  @override
  String get tradeCancelled => 'Trade cancelled: nothing changed.';

  @override
  String get updateToTrade => 'Update the app to trade with this birder.';

  @override
  String get tradeInvalid => 'These cards can\'t be accepted. Trade cancelled.';

  @override
  String get tradePermissions =>
      'Trading needs Bluetooth and nearby devices. Allow them in the app\'s settings.';

  @override
  String get openSettings => 'Settings';

  @override
  String tradedOn(String date) {
    return 'Traded on $date';
  }

  @override
  String get tradeStartFailed =>
      'Couldn\'t start looking for birders nearby. Check that Bluetooth is on.';
}
