// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get noAlarms => 'Sin alarmas';

  @override
  String get guessTheBird => '¡Adivina el pájaro!';

  @override
  String get snooze => 'Posponer';

  @override
  String snoozeMinutes(int minutes) {
    return 'Posponer $minutes min';
  }

  @override
  String streak(int count) {
    return 'Racha $count';
  }

  @override
  String get once => 'Una vez';

  @override
  String get label => 'Etiqueta';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get done => 'Listo';

  @override
  String get settings => 'Ajustes';

  @override
  String get difficulty => 'Dificultad';

  @override
  String get easy => 'Fácil';

  @override
  String get medium => 'Media';

  @override
  String get hard => 'Difícil';

  @override
  String get allBirds => 'Todas las aves';

  @override
  String get language => 'Idioma';

  @override
  String get systemLanguage => 'Teléfono';

  @override
  String get region => 'Región';

  @override
  String get alarms => 'Alarmas';

  @override
  String get collection => 'Colección';

  @override
  String get common => 'Común';

  @override
  String get uncommon => 'Poco común';

  @override
  String get rare => 'Rara';

  @override
  String get epic => 'Épica';

  @override
  String get legendary => 'Legendaria';

  @override
  String get heard => 'Oído';

  @override
  String get weight => 'Peso';

  @override
  String get wingspan => 'Envergadura';

  @override
  String get length => 'Longitud';

  @override
  String get flightDistance => 'Vuelo';

  @override
  String get share => 'Compartir';

  @override
  String progress(int owned, int total) {
    return '$owned / $total cartas';
  }

  @override
  String get useMyLocation => 'Usar mi ubicación';

  @override
  String get searchRegion => 'Buscar un país o una región';

  @override
  String get offline =>
      'Sin conexión. Conéctate a Internet para descargar las aves de tu región.';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get retry => 'Reintentar';

  @override
  String nearCell(String lat, String lon) {
    return 'Cerca de $lat $lon';
  }

  @override
  String get locationDenied =>
      'Ubicación no disponible. Busca tu región o tócala en el mapa.';

  @override
  String get song => 'canto';

  @override
  String get call => 'reclamo';

  @override
  String get alarmCall => 'alarma';

  @override
  String get seasonalBirds => 'Aves de temporada';

  @override
  String get credits => 'Créditos';

  @override
  String get creditsBody =>
      'Presencia y temporadas de las aves: datos de observación de GBIF.org.\n\nNombres y fotos: Wikidata y Wikimedia Commons (CC0, dominio público, CC BY, CC BY-SA); el autor y la licencia de cada foto están en su carta (ⓘ).\n\nCantos y reclamos: grabaciones de xeno-canto.org (CC0, CC BY, CC BY-SA, y CC BY-NC-SA / BY-NC para algunas especies sin grabación libre); el autor y la licencia están en la carta (ⓘ).\n\nEstadísticas de las cartas: AVONET (Tobias et al. 2022, Ecology Letters, CC BY 4.0), Wikipedia y Wikidata.';

  @override
  String get tryNextTime => '¡La próxima vez será!';

  @override
  String speciesCollected(String ordinal) {
    return '¡$ordinal especie conseguida!';
  }

  @override
  String get streakLost => 'Racha perdida';

  @override
  String get viewSpecies => 'Especies';

  @override
  String get viewAll => 'Todas';

  @override
  String get viewRegion => 'Región';

  @override
  String get allRarities => 'Todas las rarezas';

  @override
  String get theme => 'Tema';

  @override
  String get resident => 'Sedentaria';

  @override
  String get themeBlackbird => 'Mirlo';

  @override
  String get themeSerin => 'Verdecillo';

  @override
  String get themeBlueTit => 'Herrerillo';

  @override
  String get themeGull => 'Gaviota';

  @override
  String get play => 'Escuchar';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get easyInfo => 'Aves comunes, solo cantos';

  @override
  String get mediumInfo => 'Aves menos comunes, cantos y reclamos';

  @override
  String get hardInfo => 'Aves más raras, todos los sonidos';

  @override
  String get seasonalInfo => 'Solo las aves presentes este mes';

  @override
  String get allBirdsInfo => 'Todas las aves de la región';

  @override
  String get creditsSubtitle => 'Fuentes, licencias y privacidad';

  @override
  String get twitch => 'Pajarero';

  @override
  String get twitchInfo => 'Entrena y gana cartas';

  @override
  String get twitchZone => 'Zona Pajarera';

  @override
  String get openBooster => 'Abrir un sobre';

  @override
  String get listenAgain => 'Escuchar otra vez';

  @override
  String get series => 'Series';

  @override
  String get legendaryHunter => 'Cazador de leyendas';

  @override
  String get perfectWeek => 'Semana perfecta';

  @override
  String get fullSet => 'Todas las rarezas';

  @override
  String get collector => 'Coleccionista';

  @override
  String get localExpert => 'Experto local';

  @override
  String get rareFinds => 'Buenos hallazgos';

  @override
  String version(String version) {
    return 'Versión $version';
  }

  @override
  String ringsInDays(int days, int hours) {
    return 'Suena en $days d $hours h';
  }

  @override
  String ringsInHours(int hours, String minutes) {
    return 'Suena en $hours h $minutes';
  }

  @override
  String ringsInMinutes(int minutes) {
    return 'Suena en $minutes min';
  }
}
