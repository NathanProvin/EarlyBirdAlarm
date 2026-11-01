import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @noAlarms.
  ///
  /// In en, this message translates to:
  /// **'No alarms'**
  String get noAlarms;

  /// No description provided for @guessTheBird.
  ///
  /// In en, this message translates to:
  /// **'Guess the bird!'**
  String get guessTheBird;

  /// No description provided for @snooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snooze;

  /// No description provided for @snoozeMinutes.
  ///
  /// In en, this message translates to:
  /// **'Snooze {minutes} min'**
  String snoozeMinutes(int minutes);

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak {count}'**
  String streak(int count);

  /// No description provided for @once.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get once;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @allBirds.
  ///
  /// In en, this message translates to:
  /// **'All birds'**
  String get allBirds;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get systemLanguage;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @alarms.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarms;

  /// No description provided for @collection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collection;

  /// No description provided for @common.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get common;

  /// No description provided for @uncommon.
  ///
  /// In en, this message translates to:
  /// **'Uncommon'**
  String get uncommon;

  /// No description provided for @rare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get rare;

  /// No description provided for @epic.
  ///
  /// In en, this message translates to:
  /// **'Epic'**
  String get epic;

  /// No description provided for @legendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary'**
  String get legendary;

  /// No description provided for @heard.
  ///
  /// In en, this message translates to:
  /// **'Heard'**
  String get heard;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @birdRarity.
  ///
  /// In en, this message translates to:
  /// **'Bird rarity'**
  String get birdRarity;

  /// No description provided for @wikipedia.
  ///
  /// In en, this message translates to:
  /// **'Wikipedia'**
  String get wikipedia;

  /// No description provided for @expert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get expert;

  /// No description provided for @expertInfo.
  ///
  /// In en, this message translates to:
  /// **'All birds, all vocalizations, no choices'**
  String get expertInfo;

  /// No description provided for @typeTheBird.
  ///
  /// In en, this message translates to:
  /// **'Type the bird\'s name'**
  String get typeTheBird;

  /// No description provided for @wingspan.
  ///
  /// In en, this message translates to:
  /// **'Wingspan'**
  String get wingspan;

  /// No description provided for @length.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get length;

  /// No description provided for @flightDistance.
  ///
  /// In en, this message translates to:
  /// **'Flight'**
  String get flightDistance;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'{owned} / {total} cards'**
  String progress(int owned, int total);

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @searchRegion.
  ///
  /// In en, this message translates to:
  /// **'Search a country or region'**
  String get searchRegion;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Connect to the internet to download your region\'s birds.'**
  String get offline;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @nearCell.
  ///
  /// In en, this message translates to:
  /// **'Around {lat} {lon}'**
  String nearCell(String lat, String lon);

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location not available. Search your region or tap it on the map.'**
  String get locationDenied;

  /// No description provided for @song.
  ///
  /// In en, this message translates to:
  /// **'song'**
  String get song;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'call'**
  String get call;

  /// No description provided for @alarmCall.
  ///
  /// In en, this message translates to:
  /// **'alarm call'**
  String get alarmCall;

  /// No description provided for @seasonalBirds.
  ///
  /// In en, this message translates to:
  /// **'Seasonal birds'**
  String get seasonalBirds;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @creditsBody.
  ///
  /// In en, this message translates to:
  /// **'Bird presence and seasons: GBIF.org occurrence data.\n\nNames and photos: Wikidata and Wikimedia Commons (CC0, public domain, CC BY, CC BY-SA); each photo\'s author and license are on its card (ⓘ).\n\nSongs and calls: xeno-canto.org recordings (CC0, CC BY, CC BY-SA, and CC BY-NC-SA / BY-NC for a few species with no free recording); each recordist and license are on the card (ⓘ).\n\nCard stats: AVONET (Tobias et al. 2022, Ecology Letters, CC BY 4.0), Wikipedia and Wikidata.'**
  String get creditsBody;

  /// No description provided for @tryNextTime.
  ///
  /// In en, this message translates to:
  /// **'Try next time!'**
  String get tryNextTime;

  /// No description provided for @speciesCollected.
  ///
  /// In en, this message translates to:
  /// **'{ordinal} species collected!'**
  String speciesCollected(String ordinal);

  /// No description provided for @streakLost.
  ///
  /// In en, this message translates to:
  /// **'Streak lost'**
  String get streakLost;

  /// No description provided for @viewSpecies.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get viewSpecies;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get viewAll;

  /// No description provided for @viewRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get viewRegion;

  /// No description provided for @allRarities.
  ///
  /// In en, this message translates to:
  /// **'All rarities'**
  String get allRarities;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @resident.
  ///
  /// In en, this message translates to:
  /// **'Resident'**
  String get resident;

  /// No description provided for @themeBlackbird.
  ///
  /// In en, this message translates to:
  /// **'Blackbird'**
  String get themeBlackbird;

  /// No description provided for @themeSerin.
  ///
  /// In en, this message translates to:
  /// **'Serin'**
  String get themeSerin;

  /// No description provided for @themeBlueTit.
  ///
  /// In en, this message translates to:
  /// **'Blue Tit'**
  String get themeBlueTit;

  /// No description provided for @themeGull.
  ///
  /// In en, this message translates to:
  /// **'Gull'**
  String get themeGull;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @easyInfo.
  ///
  /// In en, this message translates to:
  /// **'Common birds, songs only'**
  String get easyInfo;

  /// No description provided for @mediumInfo.
  ///
  /// In en, this message translates to:
  /// **'Less common birds, songs & calls'**
  String get mediumInfo;

  /// No description provided for @hardInfo.
  ///
  /// In en, this message translates to:
  /// **'Rarer birds, all vocalizations'**
  String get hardInfo;

  /// No description provided for @seasonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Only birds present this month'**
  String get seasonalInfo;

  /// No description provided for @allBirdsInfo.
  ///
  /// In en, this message translates to:
  /// **'All birds in the region'**
  String get allBirdsInfo;

  /// No description provided for @creditsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sources, licenses and privacy'**
  String get creditsSubtitle;

  /// No description provided for @twitch.
  ///
  /// In en, this message translates to:
  /// **'Twitch'**
  String get twitch;

  /// No description provided for @twitchInfo.
  ///
  /// In en, this message translates to:
  /// **'Train and earn cards'**
  String get twitchInfo;

  /// No description provided for @twitchZone.
  ///
  /// In en, this message translates to:
  /// **'Twitch Zone'**
  String get twitchZone;

  /// No description provided for @openBooster.
  ///
  /// In en, this message translates to:
  /// **'Open a booster'**
  String get openBooster;

  /// No description provided for @listenAgain.
  ///
  /// In en, this message translates to:
  /// **'Listen again'**
  String get listenAgain;

  /// No description provided for @series.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get series;

  /// No description provided for @legendaryHunter.
  ///
  /// In en, this message translates to:
  /// **'Legendary hunter'**
  String get legendaryHunter;

  /// No description provided for @perfectWeek.
  ///
  /// In en, this message translates to:
  /// **'Perfect week'**
  String get perfectWeek;

  /// No description provided for @fullSet.
  ///
  /// In en, this message translates to:
  /// **'Full set'**
  String get fullSet;

  /// No description provided for @collector.
  ///
  /// In en, this message translates to:
  /// **'Collector'**
  String get collector;

  /// No description provided for @localExpert.
  ///
  /// In en, this message translates to:
  /// **'Local expert'**
  String get localExpert;

  /// No description provided for @rareFinds.
  ///
  /// In en, this message translates to:
  /// **'Rare finds'**
  String get rareFinds;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @ringsInDays.
  ///
  /// In en, this message translates to:
  /// **'Rings in {days} d {hours} h'**
  String ringsInDays(int days, int hours);

  /// No description provided for @ringsInHours.
  ///
  /// In en, this message translates to:
  /// **'Rings in {hours} h {minutes}'**
  String ringsInHours(int hours, String minutes);

  /// No description provided for @ringsInMinutes.
  ///
  /// In en, this message translates to:
  /// **'Rings in {minutes} min'**
  String ringsInMinutes(int minutes);

  /// No description provided for @trade.
  ///
  /// In en, this message translates to:
  /// **'Trade'**
  String get trade;

  /// No description provided for @viewMenu.
  ///
  /// In en, this message translates to:
  /// **'Choose the view'**
  String get viewMenu;

  /// No description provided for @rarityMenu.
  ///
  /// In en, this message translates to:
  /// **'Filter by rarity'**
  String get rarityMenu;

  /// No description provided for @lookingForBirder.
  ///
  /// In en, this message translates to:
  /// **'Looking for a birder nearby…'**
  String get lookingForBirder;

  /// No description provided for @lookingHint.
  ///
  /// In en, this message translates to:
  /// **'Ask them to open Trade too, phones close together.'**
  String get lookingHint;

  /// No description provided for @checkCode.
  ///
  /// In en, this message translates to:
  /// **'Do you both see these two birds?'**
  String get checkCode;

  /// No description provided for @itMatches.
  ///
  /// In en, this message translates to:
  /// **'It matches'**
  String get itMatches;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @youGive.
  ///
  /// In en, this message translates to:
  /// **'You give'**
  String get youGive;

  /// No description provided for @youGet.
  ///
  /// In en, this message translates to:
  /// **'You get'**
  String get youGet;

  /// No description provided for @nothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get nothingYet;

  /// No description provided for @addCards.
  ///
  /// In en, this message translates to:
  /// **'Add cards'**
  String get addCards;

  /// No description provided for @validate.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get validate;

  /// No description provided for @youValidated.
  ///
  /// In en, this message translates to:
  /// **'You validated'**
  String get youValidated;

  /// No description provided for @theyValidated.
  ///
  /// In en, this message translates to:
  /// **'They validated'**
  String get theyValidated;

  /// No description provided for @waitingForThem.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other birder'**
  String get waitingForThem;

  /// No description provided for @tradeDone.
  ///
  /// In en, this message translates to:
  /// **'Trade done!'**
  String get tradeDone;

  /// No description provided for @tradeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Trade cancelled: nothing changed.'**
  String get tradeCancelled;

  /// No description provided for @updateToTrade.
  ///
  /// In en, this message translates to:
  /// **'Update the app to trade with this birder.'**
  String get updateToTrade;

  /// No description provided for @tradeInvalid.
  ///
  /// In en, this message translates to:
  /// **'These cards can\'t be accepted. Trade cancelled.'**
  String get tradeInvalid;

  /// No description provided for @tradePermissions.
  ///
  /// In en, this message translates to:
  /// **'Trading needs Bluetooth, nearby devices and precise location (it never leaves your phone). Allow them in the app\'s settings.'**
  String get tradePermissions;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openSettings;

  /// No description provided for @tradedOn.
  ///
  /// In en, this message translates to:
  /// **'Traded on {date}'**
  String tradedOn(String date);

  /// No description provided for @tradeStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start looking for birders nearby. Check that Bluetooth is on.'**
  String get tradeStartFailed;

  /// No description provided for @fiveOfAKind.
  ///
  /// In en, this message translates to:
  /// **'Five of a kind'**
  String get fiveOfAKind;

  /// No description provided for @dawnChorus.
  ///
  /// In en, this message translates to:
  /// **'Dawn chorus'**
  String get dawnChorus;

  /// No description provided for @globetrotter.
  ///
  /// In en, this message translates to:
  /// **'Globetrotter'**
  String get globetrotter;

  /// No description provided for @fullHouse.
  ///
  /// In en, this message translates to:
  /// **'Full house'**
  String get fullHouse;

  /// No description provided for @perfectSpecimen.
  ///
  /// In en, this message translates to:
  /// **'Perfect specimen'**
  String get perfectSpecimen;

  /// No description provided for @ironStreak.
  ///
  /// In en, this message translates to:
  /// **'Iron streak'**
  String get ironStreak;

  /// No description provided for @goalLegendaryHunter.
  ///
  /// In en, this message translates to:
  /// **'5 Legendary cards'**
  String get goalLegendaryHunter;

  /// No description provided for @goalPerfectWeek.
  ///
  /// In en, this message translates to:
  /// **'A 7-day wake-up streak'**
  String get goalPerfectWeek;

  /// No description provided for @goalFullSet.
  ///
  /// In en, this message translates to:
  /// **'A card of each rarity'**
  String get goalFullSet;

  /// No description provided for @goalCollector.
  ///
  /// In en, this message translates to:
  /// **'100 cards'**
  String get goalCollector;

  /// No description provided for @goalLocalExpert.
  ///
  /// In en, this message translates to:
  /// **'50 species of your region'**
  String get goalLocalExpert;

  /// No description provided for @goalRareFinds.
  ///
  /// In en, this message translates to:
  /// **'5 cards Rare or better'**
  String get goalRareFinds;

  /// No description provided for @goalFiveOfAKind.
  ///
  /// In en, this message translates to:
  /// **'5 copies of one species'**
  String get goalFiveOfAKind;

  /// No description provided for @goalDawnChorus.
  ///
  /// In en, this message translates to:
  /// **'10 cards won before 7:00'**
  String get goalDawnChorus;

  /// No description provided for @goalGlobetrotter.
  ///
  /// In en, this message translates to:
  /// **'Cards from 3 regions'**
  String get goalGlobetrotter;

  /// No description provided for @goalFullHouse.
  ///
  /// In en, this message translates to:
  /// **'3 series completed'**
  String get goalFullHouse;

  /// No description provided for @goalPerfectSpecimen.
  ///
  /// In en, this message translates to:
  /// **'A card of 95 % quality or more'**
  String get goalPerfectSpecimen;

  /// No description provided for @goalIronStreak.
  ///
  /// In en, this message translates to:
  /// **'A 30-day wake-up streak'**
  String get goalIronStreak;

  /// No description provided for @seriesComplete.
  ///
  /// In en, this message translates to:
  /// **'Series complete!'**
  String get seriesComplete;

  /// No description provided for @achievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked!'**
  String get achievementUnlocked;

  /// No description provided for @rewardRarity.
  ///
  /// In en, this message translates to:
  /// **'{rarity} reward'**
  String rewardRarity(String rarity);

  /// No description provided for @tapToCollect.
  ///
  /// In en, this message translates to:
  /// **'Tap to collect'**
  String get tapToCollect;

  /// No description provided for @tradeLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on Location to find birders nearby. Your position is never used or sent.'**
  String get tradeLocationOff;

  /// No description provided for @tradeNeedsLocation.
  ///
  /// In en, this message translates to:
  /// **'Trading needs the location permission (Android requires it for Bluetooth searches; your position is never used). Allow it in the app\'s settings.'**
  String get tradeNeedsLocation;

  /// No description provided for @tradeNeedsPrecise.
  ///
  /// In en, this message translates to:
  /// **'Trading needs precise location: in the app\'s settings, under Location, turn on \"Use precise location\".'**
  String get tradeNeedsPrecise;

  /// No description provided for @tradeNeedsBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Trading needs the Bluetooth and nearby devices permissions. Allow them in the app\'s settings.'**
  String get tradeNeedsBluetooth;

  /// No description provided for @searchCollection.
  ///
  /// In en, this message translates to:
  /// **'Search your collection'**
  String get searchCollection;

  /// No description provided for @noSpeciesFound.
  ///
  /// In en, this message translates to:
  /// **'No species found'**
  String get noSpeciesFound;

  /// No description provided for @introWelcome.
  ///
  /// In en, this message translates to:
  /// **'Tired of not progressing at learning bird songs? Every morning, wake up to a new bird: guess it right, win its card, and learn its song.'**
  String get introWelcome;

  /// No description provided for @introRegionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a region'**
  String get introRegionTitle;

  /// No description provided for @introRegion.
  ///
  /// In en, this message translates to:
  /// **'You\'ll hear local birds: select a region on the map, or use your current position.'**
  String get introRegion;

  /// No description provided for @introGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Gameplay'**
  String get introGameTitle;

  /// No description provided for @introLater.
  ///
  /// In en, this message translates to:
  /// **'Harder settings give better rewards; you can change them later in Settings.'**
  String get introLater;

  /// No description provided for @introCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Collect cards'**
  String get introCollectionTitle;

  /// No description provided for @introTwitch.
  ///
  /// In en, this message translates to:
  /// **'Twitch Zone: a free booster every 15 minutes to train your ear.'**
  String get introTwitch;

  /// No description provided for @introSeries.
  ///
  /// In en, this message translates to:
  /// **'Series and achievements: complete them to collect guaranteed rare cards.'**
  String get introSeries;

  /// No description provided for @introTrade.
  ///
  /// In en, this message translates to:
  /// **'Trade: meet another birder and swap cards face to face.'**
  String get introTrade;

  /// No description provided for @introExamineTitle.
  ///
  /// In en, this message translates to:
  /// **'Examine cards'**
  String get introExamineTitle;

  /// No description provided for @introExamine.
  ///
  /// In en, this message translates to:
  /// **'Tap and hold the card to examine it!'**
  String get introExamine;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @introAgain.
  ///
  /// In en, this message translates to:
  /// **'See the introduction again'**
  String get introAgain;

  /// No description provided for @introRarityTitle.
  ///
  /// In en, this message translates to:
  /// **'Rarity and stats'**
  String get introRarityTitle;

  /// No description provided for @introRarity.
  ///
  /// In en, this message translates to:
  /// **'Card rarity goes from Common to Legendary: rare species are more likely to give rare cards. Each card also carries real statistics of its species: aim for a 100% bird!'**
  String get introRarity;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
