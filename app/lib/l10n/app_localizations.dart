import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
    Locale('en'),
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
  /// **'Location not available. Choose from the list.'**
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

  /// No description provided for @newRarityCard.
  ///
  /// In en, this message translates to:
  /// **'New {rarity} card!'**
  String newRarityCard(String rarity);

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

  /// No description provided for @viewCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get viewCollected;

  /// No description provided for @viewCopies.
  ///
  /// In en, this message translates to:
  /// **'All copies'**
  String get viewCopies;

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

  /// No description provided for @themeDawn.
  ///
  /// In en, this message translates to:
  /// **'Dawn'**
  String get themeDawn;

  /// No description provided for @themeDusk.
  ///
  /// In en, this message translates to:
  /// **'Dusk'**
  String get themeDusk;

  /// No description provided for @themeForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get themeForest;

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

  /// No description provided for @birdsSetting.
  ///
  /// In en, this message translates to:
  /// **'Birds'**
  String get birdsSetting;

  /// No description provided for @creditsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sources, licenses and privacy'**
  String get creditsSubtitle;

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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
