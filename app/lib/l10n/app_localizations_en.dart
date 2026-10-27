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
  String get openToAnswer => 'Who is singing? Open to answer.';

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
  String get northernFrance => 'Northern France';
}
