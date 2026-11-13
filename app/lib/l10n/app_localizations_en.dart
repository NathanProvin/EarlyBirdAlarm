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
  String get comingSoon => 'To be added';

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
  String get rarityMenu => 'Rarity';

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
  String get youGive => 'Give';

  @override
  String get youGet => 'Receive';

  @override
  String get nothingYet => 'Empty';

  @override
  String get addCards => 'Add';

  @override
  String get validate => 'Agree';

  @override
  String get youValidated => 'Agreed';

  @override
  String get theyValidated => 'They agreed';

  @override
  String get waitingForThem => 'Waiting validation';

  @override
  String get tradeDone => 'Trade done!';

  @override
  String get tradeCancelled => 'Trade cancelled.';

  @override
  String get updateToTrade => 'Update the app to trade with this birder.';

  @override
  String get tradeInvalid => 'Invalid cards. Trade cancelled.';

  @override
  String get openSettings => 'Settings';

  @override
  String tradedOn(String date) {
    return 'Traded on $date';
  }

  @override
  String get globetrotter => 'Globetrotter';

  @override
  String get fullHouse => 'Full house';

  @override
  String get perfectSpecimen => 'Perfect specimen';

  @override
  String goalLegendaryHunter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Legendary cards',
      one: '1 Legendary card',
    );
    return '$_temp0';
  }

  @override
  String goalFullSet(int count) {
    return 'Cards of $count rarities (the 6th: Shiny)';
  }

  @override
  String goalCollector(int count) {
    return '$count cards';
  }

  @override
  String goalLocalExpert(int count) {
    return '$count species of your region';
  }

  @override
  String goalRareFinds(int count) {
    return '$count cards Rare or better';
  }

  @override
  String goalGlobetrotter(int count) {
    return 'Cards from $count regions';
  }

  @override
  String goalFullHouse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series completed',
      one: '1 series completed',
    );
    return '$_temp0';
  }

  @override
  String goalPerfectSpecimen(int count) {
    return 'A card of $count % quality or more';
  }

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
  String get viewWorld => 'World';

  @override
  String get sortMenu => 'Sort';

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

  @override
  String get supportShort => 'Free, no ads, no trackers';

  @override
  String get account => 'Account';

  @override
  String get accountPitch =>
      'Sign in with Google to keep your collection on every phone.';

  @override
  String get signInGoogle => 'Sign in with Google';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountBody =>
      'This deletes your account and its cloud backup. Your cards stay on this phone.';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get accountError =>
      'Something went wrong. Check your connection and try again.';

  @override
  String get orEmail => 'or with an email';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetSent => 'Reset link sent, check your inbox.';

  @override
  String get wrongPassword => 'Wrong email or password.';

  @override
  String get emailInUse => 'This email already has an account: sign in.';

  @override
  String get weakPassword => 'Password: at least 6 characters.';

  @override
  String get invalidEmail => 'Check the email address.';

  @override
  String get introAccountTitle => 'Keep your collection';

  @override
  String get shiny => 'Shiny';

  @override
  String get leucistic => 'Leucistic';

  @override
  String get melanistic => 'Melanistic';

  @override
  String get inviteFriends => 'Invite friends';

  @override
  String inviteText(String link) {
    return 'I wake up to bird songs and collect their cards on Early Bird 🐦 Can you guess them? It\'s free: $link';
  }

  @override
  String friendsJoined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count friends joined',
      one: '1 friend joined',
      zero: 'No friend joined yet',
    );
    return '$_temp0';
  }

  @override
  String get enterCode => 'Enter a code';

  @override
  String get redeem => 'Redeem';

  @override
  String get codeUnknown => 'This code doesn\'t exist.';

  @override
  String get codeExpired => 'This code has expired.';

  @override
  String get codeUsed => 'You already used this code.';

  @override
  String get codeDone => 'Code redeemed!';

  @override
  String get codeGift => 'A gift for you!';

  @override
  String get welcomeGift => 'Welcome! A gift from your friend';

  @override
  String get achievements => 'Achievements';

  @override
  String get twitcher => 'Twitcher';

  @override
  String get duplicates => 'Duplicates';

  @override
  String get epicFinds => 'Epic finds';

  @override
  String get sharpEar => 'Sharp ear';

  @override
  String get wakeUpStreak => 'Wake-up streak';

  @override
  String get earlyRiser => 'Early riser';

  @override
  String get dailyBirder => 'Daily birder';

  @override
  String get fidelity => 'Loyalty';

  @override
  String get trader => 'Trader';

  @override
  String get influencer => 'Influencer';

  @override
  String goalTwitcher(int count) {
    return '$count species in all';
  }

  @override
  String goalDuplicates(int count) {
    return '$count copies of one species';
  }

  @override
  String goalEpicFinds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards Epic or better',
      one: '1 card Epic or better',
    );
    return '$_temp0';
  }

  @override
  String goalSharpEar(int count) {
    return '$count right answers in a row';
  }

  @override
  String goalWakeUpStreak(int count) {
    return 'A $count-day wake-up streak';
  }

  @override
  String goalEarlyRiser(int count) {
    return '$count cards won before 7:00';
  }

  @override
  String goalDailyBirder(int count) {
    return 'Cards won on $count different days';
  }

  @override
  String goalFidelity(int count) {
    return 'Cards won in $count different months';
  }

  @override
  String goalTrader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards traded away',
      one: '1 card traded away',
    );
    return '$_temp0';
  }

  @override
  String goalInfluencer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count friends joined through your link',
      one: '1 friend joined through your link',
    );
    return '$_temp0';
  }

  @override
  String get songOffline => 'No connection: this song isn\'t on the phone';

  @override
  String get hallOfFame => 'Hall of fame';

  @override
  String get friends => 'Friends';

  @override
  String get chooseCard => 'Choose a card';

  @override
  String get frameAvatar => 'Frame your picture';

  @override
  String get changeAvatar => 'Change your picture';

  @override
  String get signInToKeep => 'Sign in to keep your collection';

  @override
  String get renameTitle => 'Your @name';

  @override
  String get nameRules =>
      '3 to 20 letters, digits or _, once a week. Be respectful: offensive names are removed.';

  @override
  String get nameLength => '3 to 20 characters.';

  @override
  String get nameCharacters => 'Letters, digits and _ only.';

  @override
  String get nameBanned => 'This name isn\'t allowed.';

  @override
  String get nameTaken => 'This name is taken.';

  @override
  String renameTooSoon(String date) {
    return 'Next change possible on $date.';
  }

  @override
  String get addFriend => 'Add a friend';

  @override
  String get friendNameHint => 'their name';

  @override
  String get sendRequest => 'Send';

  @override
  String get requestSent => 'Request sent!';

  @override
  String get friendNotFound => 'No player with this name.';

  @override
  String get friendSelf => 'That\'s you!';

  @override
  String get friendAlready => 'Already your friend.';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get noFriendsYet => 'No friends yet: add one by their @name.';

  @override
  String get removeFriend => 'Remove from friends';

  @override
  String get blockPlayer => 'Block';

  @override
  String get reportPlayer => 'Report';

  @override
  String get challenge => 'Challenge';

  @override
  String get bonusCodes => 'Bonus codes';

  @override
  String get statCards => 'Cards';

  @override
  String get statSpecies => 'Species';

  @override
  String get statRegions => 'Regions';

  @override
  String seeAllFriends(int count) {
    return 'See all ($count)';
  }

  @override
  String get tradeWith => 'Trade with…';

  @override
  String get tradeOpen => 'In progress';

  @override
  String get tradeBothOffer => '1 card each minimum';

  @override
  String get cancelTrade => 'Cancel';
}
