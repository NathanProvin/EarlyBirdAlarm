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
    return 'Streak: $count';
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
  String get birdRarity => 'Bird rarity';

  @override
  String get wikipedia => 'Wikipedia';

  @override
  String get expert => 'Expert';

  @override
  String get expertInfo => 'All birds, all vocalizations, no choices';

  @override
  String get typeTheBird => 'Type the bird\'s name';

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
      'Bird presence and seasons: GBIF.org occurrence data.\n\nNames and photos: Wikidata and Wikimedia Commons (CC0, public domain, CC BY, CC BY-SA); each photo\'s author and license are on its card (ⓘ).\n\nSongs and calls: xeno-canto.org and iNaturalist recordings (CC0, CC BY, CC BY-SA); each recordist and license are on the card (ⓘ). Backup alarm rooster: Kalvin Chan, iNaturalist (CC0).\n\nCard stats: AVONET (Tobias et al. 2022, Ecology Letters, CC BY 4.0), Wikipedia and Wikidata.';

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
  String get viewAll => 'Collected';

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
  String get twitch => 'Training';

  @override
  String get twitchZone => 'Training';

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
      'Trading needs Bluetooth, nearby devices and precise location (it never leaves your phone). Allow them in the app\'s settings.';

  @override
  String get openSettings => 'Settings';

  @override
  String tradedOn(String date) {
    return 'Traded on $date';
  }

  @override
  String get tradeStartFailed =>
      'Couldn\'t start looking for birders nearby. Check that Bluetooth is on.';

  @override
  String get fiveOfAKind => 'Five of a kind';

  @override
  String get dawnChorus => 'Dawn chorus';

  @override
  String get globetrotter => 'Globetrotter';

  @override
  String get fullHouse => 'Full house';

  @override
  String get perfectSpecimen => 'Perfect specimen';

  @override
  String get ironStreak => 'Iron streak';

  @override
  String get goalLegendaryHunter => '5 Legendary cards';

  @override
  String get goalPerfectWeek => 'A 7-day wake-up streak';

  @override
  String get goalFullSet => 'A card of each rarity';

  @override
  String get goalCollector => '100 cards';

  @override
  String get goalLocalExpert => '50 species of your region';

  @override
  String get goalRareFinds => '5 cards Rare or better';

  @override
  String get goalFiveOfAKind => '5 copies of one species';

  @override
  String get goalDawnChorus => '10 cards won before 7:00';

  @override
  String get goalGlobetrotter => 'Cards from 3 regions';

  @override
  String get goalFullHouse => '3 series completed';

  @override
  String get goalPerfectSpecimen => 'A card of 95 % quality or more';

  @override
  String get goalIronStreak => 'A 30-day wake-up streak';

  @override
  String get seriesComplete => 'Series complete!';

  @override
  String get achievementUnlocked => 'Achievement unlocked!';

  @override
  String rewardRarity(String rarity) {
    return '$rarity reward';
  }

  @override
  String get tapToCollect => 'Tap to collect';

  @override
  String get tradeLocationOff =>
      'Turn on Location to find birders nearby. Your position is never used or sent.';

  @override
  String get tradeNeedsLocation =>
      'Trading needs the location permission (Android requires it for Bluetooth searches; your position is never used). Allow it in the app\'s settings.';

  @override
  String get tradeNeedsPrecise =>
      'Trading needs precise location: in the app\'s settings, under Location, turn on \"Use precise location\".';

  @override
  String get tradeNeedsBluetooth =>
      'Trading needs the Bluetooth and nearby devices permissions. Allow them in the app\'s settings.';

  @override
  String get searchCollection => 'Search your collection';

  @override
  String get noSpeciesFound => 'No species found';

  @override
  String get introWelcome =>
      'Tired of not progressing at learning bird songs? Every morning, wake up to a new bird: guess it right, win its card, and learn its song.';

  @override
  String get introRegionTitle => 'Choose a region';

  @override
  String get introRegion =>
      'You\'ll hear local birds: select a region on the map, or use your current position.';

  @override
  String get introGameTitle => 'Gameplay';

  @override
  String get introLater =>
      'Harder settings give better rewards; you can change them later in Settings.';

  @override
  String get introCollectionTitle => 'Collect cards';

  @override
  String get introTwitch =>
      'Training: a free booster every 15 minutes to train your ear.';

  @override
  String get introSeries =>
      'Series and achievements: complete them to collect guaranteed rare cards.';

  @override
  String get introTrade =>
      'Trade: meet another birder and swap cards face to face.';

  @override
  String get introExamineTitle => 'Examine cards';

  @override
  String get introExamine => 'Tap and hold the card to examine it!';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get introAgain => 'See the introduction again';

  @override
  String get introRarityTitle => 'Rarity and stats';

  @override
  String get introRarity =>
      'Card rarity goes from Common to Legendary: rare species are more likely to give rare cards. Each card also carries real statistics of its species: aim for a 100% bird!';

  @override
  String get start => 'Start';

  @override
  String get support => 'Support Early Bird';

  @override
  String get tipsTile => 'Buy me a coffee';

  @override
  String get tipsNote =>
      'Early Bird has no ads, no trackers, and is kept going by a solo dev. If the app is useful to you, thank me with a coffee!';

  @override
  String get tipEspresso => 'Espresso';

  @override
  String get tipCappuccino => 'Cappuccino';

  @override
  String get tipBreakfast => 'Breakfast';

  @override
  String get tipBinoculars => 'Stabilized binoculars';

  @override
  String get tipsPayments =>
      'Payments by Google Play. Nothing changes in the game.';

  @override
  String get thankYou => 'Thank you!';

  @override
  String get thankYouBody => 'Your support keeps Early Bird singing.';

  @override
  String get purchasesUnavailable =>
      'Purchases are not available on this phone.';

  @override
  String get twitchPlus => 'Early Bird Plus';

  @override
  String get twitchPlusPitch =>
      'Unlimited mode: a booster every minute! One purchase, for life.';

  @override
  String get paymentsGoogle => 'Payments by Google Play.';

  @override
  String shareTitle(String rarity) {
    return '$rarity card!';
  }

  @override
  String get shareTagline => 'The birders’ alarm · Free on Google Play';

  @override
  String shareText(String bird, String rarity, String link) {
    return 'I knew that song: $bird! $rarity card won. $link';
  }

  @override
  String get shareCopied =>
      'Link copied: paste it in your message if the app leaves it out';

  @override
  String get gyro => 'Gyro';

  @override
  String get gyroHint => 'Cards tilt as you move the phone';

  @override
  String backupMinutes(int minutes) {
    return 'Backup alarm after $minutes min';
  }

  @override
  String get backupOff => 'No backup alarm';

  @override
  String get wakeNotifications => 'Notifications';

  @override
  String get wakeFullScreen => 'Quiz over the lock screen';

  @override
  String get wakeBattery => 'Battery: unrestricted';

  @override
  String get wakeFix => 'Fix';

  @override
  String get wakeMissing =>
      'Without these, an alarm can ring without showing the quiz.';

  @override
  String get wakeOk => 'OK';

  @override
  String get wakeNotOk => 'Missing';

  @override
  String get alarmPermissions => 'Alarm permissions';

  @override
  String get addAlarm => 'Add an alarm';

  @override
  String get supportNudge => 'Enjoying Early Bird? Buy me a coffee';

  @override
  String get viewWorld => 'All birds of the world';

  @override
  String get sortMenu => 'Sort and filter';

  @override
  String get sortNumber => 'Number';

  @override
  String get sortRarity => 'Rarity';

  @override
  String get sortName => 'Name';

  @override
  String get coveredArea => 'Red: covered area';

  @override
  String get confirmRegion => 'Confirm';

  @override
  String get notCovered => 'Not covered yet';
}
