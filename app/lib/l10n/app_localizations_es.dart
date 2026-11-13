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
    return 'Racha: $count';
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
  String get birdRarity => 'Rareza';

  @override
  String get wikipedia => 'Wikipedia';

  @override
  String get expert => 'Experto';

  @override
  String get expertInfo => 'Todas las aves, todos los sonidos, sin opciones';

  @override
  String get typeTheBird => 'Escribe el nombre del ave';

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
      'Presencia y temporadas de las aves: datos de observación de GBIF.org.\n\nNombres y fotos: Wikidata y Wikimedia Commons (CC0, dominio público, CC BY, CC BY-SA); el autor y la licencia de cada foto están en su carta (ⓘ).\n\nCantos y reclamos: grabaciones de xeno-canto.org e iNaturalist (CC0, CC BY, CC BY-SA); el autor y la licencia están en la carta (ⓘ). Gallo de la alarma de respaldo: Kalvin Chan, iNaturalist (CC0).\n\nEstadísticas de las cartas: AVONET (Tobias et al. 2022, Ecology Letters, CC BY 4.0), Wikipedia y Wikidata.';

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
  String get viewAll => 'Coleccionadas';

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
  String get twitch => 'Entrenamiento';

  @override
  String get twitchZone => 'Entrenamiento';

  @override
  String get openBooster => 'Abrir un sobre';

  @override
  String get listenAgain => 'Escuchar otra vez';

  @override
  String get series => 'Series';

  @override
  String get legendaryHunter => 'Cazador de leyendas';

  @override
  String get fullSet => 'Juego completo';

  @override
  String get collector => 'Coleccionista';

  @override
  String get localExpert => 'Experto local';

  @override
  String get rareFinds => 'Hallazgos raros';

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

  @override
  String get trade => 'Intercambiar';

  @override
  String get viewMenu => 'Elegir la vista';

  @override
  String get rarityMenu => 'Rareza';

  @override
  String get lookingForBirder => 'Buscando pajareros cerca…';

  @override
  String get lookingHint =>
      'Pídele que abra Intercambiar también, con los teléfonos cerca.';

  @override
  String get checkCode => '¿Veis los dos estas dos aves?';

  @override
  String get itMatches => 'Coincide';

  @override
  String get cancel => 'Cancelar';

  @override
  String get youGive => 'Das';

  @override
  String get youGet => 'Recibes';

  @override
  String get nothingYet => 'Nada todavía';

  @override
  String get addCards => 'Añadir cartas';

  @override
  String get validate => 'Confirmar';

  @override
  String get youValidated => 'Has confirmado';

  @override
  String get theyValidated => 'La otra persona ha confirmado';

  @override
  String get waitingForThem => 'Esperando a la otra persona';

  @override
  String get tradeDone => '¡Intercambio hecho!';

  @override
  String get tradeCancelled => 'Intercambio cancelado: no ha cambiado nada.';

  @override
  String get updateToTrade =>
      'Actualiza la app para intercambiar con esta persona.';

  @override
  String get tradeInvalid =>
      'Estas cartas no se pueden aceptar. Intercambio cancelado.';

  @override
  String get tradePermissions =>
      'Para intercambiar, la app necesita el Bluetooth, los dispositivos cercanos y la ubicación precisa (nunca sale de tu teléfono). Permítelos en los ajustes de la app.';

  @override
  String get openSettings => 'Ajustes';

  @override
  String tradedOn(String date) {
    return 'Intercambiada el $date';
  }

  @override
  String get tradeStartFailed =>
      'No se pudo empezar a buscar pajareros cerca. ¿Está activado el Bluetooth?';

  @override
  String get globetrotter => 'Trotamundos';

  @override
  String get fullHouse => 'Pleno';

  @override
  String get perfectSpecimen => 'Ejemplar perfecto';

  @override
  String goalLegendaryHunter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas Legendarias',
      one: '1 carta Legendaria',
    );
    return '$_temp0';
  }

  @override
  String goalFullSet(int count) {
    return 'Cartas de $count rarezas (la 6.ª: Shiny)';
  }

  @override
  String goalCollector(int count) {
    return '$count cartas';
  }

  @override
  String goalLocalExpert(int count) {
    return '$count especies de tu región';
  }

  @override
  String goalRareFinds(int count) {
    return '$count cartas Rara o mejor';
  }

  @override
  String goalGlobetrotter(int count) {
    return 'Cartas de $count regiones';
  }

  @override
  String goalFullHouse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series completadas',
      one: '1 serie completada',
    );
    return '$_temp0';
  }

  @override
  String goalPerfectSpecimen(int count) {
    return 'Una carta de calidad $count % o más';
  }

  @override
  String get seriesComplete => '¡Serie completada!';

  @override
  String get achievementUnlocked => '¡Logro desbloqueado!';

  @override
  String rewardRarity(String rarity) {
    return 'Recompensa: $rarity';
  }

  @override
  String get tapToCollect => 'Toca para recoger';

  @override
  String get tradeLocationOff =>
      'Activa la ubicación para encontrar pajareros cerca. Tu posición nunca se usa ni se envía.';

  @override
  String get tradeNeedsLocation =>
      'Para intercambiar, la app necesita el permiso de ubicación (Android lo exige para buscar por Bluetooth; tu posición nunca se usa). Permítelo en los ajustes de la app.';

  @override
  String get tradeNeedsPrecise =>
      'Para intercambiar, la app necesita la ubicación precisa: en los ajustes de la app, en Ubicación, activa «Usar ubicación precisa».';

  @override
  String get tradeNeedsBluetooth =>
      'Para intercambiar, la app necesita los permisos de Bluetooth y dispositivos cercanos. Permítelos en los ajustes de la app.';

  @override
  String get searchCollection => 'Buscar en tu colección';

  @override
  String get noSpeciesFound => 'Ninguna especie encontrada';

  @override
  String get introWelcome =>
      '¿Te cuesta avanzar aprendiendo cantos de aves? Cada mañana, despierta con un ave nueva: adivínala, gana su carta y aprende su canto.';

  @override
  String get introRegionTitle => 'Elegir región';

  @override
  String get introRegion =>
      'Escucharás aves locales: elige una región en el mapa o usa tu ubicación actual.';

  @override
  String get introGameTitle => 'Modo de juego';

  @override
  String get introLater =>
      'Los ajustes más difíciles dan mejores recompensas; puedes cambiarlos luego en Ajustes.';

  @override
  String get introCollectionTitle => 'Colecciona cartas';

  @override
  String get introTwitch =>
      'Entrenamiento: un sobre gratis cada 15 minutos para entrenar el oído.';

  @override
  String get introSeries =>
      'Series y logros: complétalos para conseguir cartas raras garantizadas.';

  @override
  String get introTrade =>
      'Intercambiar: queda con otro pajarero e intercambiad cartas en persona.';

  @override
  String get introExamineTitle => 'Examinar cartas';

  @override
  String get introExamine => '¡Mantén pulsada la carta para examinarla!';

  @override
  String get next => 'Siguiente';

  @override
  String get skip => 'Saltar';

  @override
  String get introAgain => 'Ver otra vez la introducción';

  @override
  String get introRarityTitle => 'Rareza y estadísticas';

  @override
  String get introRarity =>
      'La rareza de las cartas va de Común a Legendaria: las especies raras tienen más probabilidad de dar cartas raras. Cada carta lleva además estadísticas reales de su especie: ¡busca un ave al 100 %!';

  @override
  String get start => 'Empezar';

  @override
  String get support => 'Apoya Early Bird';

  @override
  String get tipsTile => 'Invítame a un café';

  @override
  String get tipsNote =>
      'Early Bird no tiene anuncios ni rastreadores y lo mantiene un desarrollador en solitario. Si la app te resulta útil, ¡agradécemelo con un café!';

  @override
  String get tipEspresso => 'Expreso';

  @override
  String get tipCappuccino => 'Capuchino';

  @override
  String get tipBreakfast => 'Desayuno';

  @override
  String get tipBinoculars => 'Prismáticos estabilizados';

  @override
  String get tipsPayments => 'Pago con Google Play. Nada cambia en el juego.';

  @override
  String get thankYou => '¡Gracias!';

  @override
  String get thankYouBody => 'Tu apoyo hace que Early Bird siga cantando.';

  @override
  String get purchasesUnavailable =>
      'Las compras no están disponibles en este teléfono.';

  @override
  String get twitchPlus => 'Early Bird Plus';

  @override
  String get twitchPlusPitch =>
      'Modo ilimitado: ¡un sobre por minuto! Una compra, para siempre.';

  @override
  String get paymentsGoogle => 'Pago con Google Play.';

  @override
  String shareTitle(String rarity) {
    return '¡Carta $rarity!';
  }

  @override
  String get shareTagline =>
      'El despertador de los pajareros · Gratis en Google Play';

  @override
  String shareText(String bird, String rarity, String link) {
    return '¡Reconocí el canto: $bird! Carta $rarity ganada. $link';
  }

  @override
  String get shareCopied =>
      'Enlace copiado: pégalo en tu mensaje si la app no lo incluye';

  @override
  String get gyro => 'Giro';

  @override
  String get gyroHint => 'Las cartas se inclinan al mover el teléfono';

  @override
  String backupMinutes(int minutes) {
    return 'Alarma de respaldo a los $minutes min';
  }

  @override
  String get backupOff => 'Sin alarma de respaldo';

  @override
  String get wakeNotifications => 'Notificaciones';

  @override
  String get wakeFullScreen => 'Quiz en la pantalla de bloqueo';

  @override
  String get wakeBattery => 'Batería: sin restricciones';

  @override
  String get wakeFix => 'Arreglar';

  @override
  String get wakeMissing =>
      'Sin esto, una alarma puede sonar sin mostrar el quiz.';

  @override
  String get wakeOk => 'OK';

  @override
  String get wakeNotOk => 'Falta';

  @override
  String get alarmPermissions => 'Permisos del despertador';

  @override
  String get addAlarm => 'Añadir una alarma';

  @override
  String get supportNudge => '¿Te gusta Early Bird? Invítame a un café';

  @override
  String get viewWorld => 'Mundo';

  @override
  String get sortMenu => 'Ordenar';

  @override
  String get sortNumber => 'Número';

  @override
  String get sortRarity => 'Rareza';

  @override
  String get sortName => 'Nombre';

  @override
  String get coveredArea => 'Rojo: zona cubierta';

  @override
  String get confirmRegion => 'Confirmar';

  @override
  String get notCovered => 'Aún no cubierto';

  @override
  String get supportShort => 'Gratis, sin anuncios, sin rastreadores';

  @override
  String get account => 'Cuenta';

  @override
  String get accountPitch =>
      'Inicia sesión con Google para conservar tu colección en todos tus móviles.';

  @override
  String get signInGoogle => 'Iniciar sesión con Google';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountBody =>
      'Se eliminarán tu cuenta y su copia en la nube. Tus cartas se quedan en este móvil.';

  @override
  String get accountDeleted => 'Cuenta eliminada';

  @override
  String get accountError =>
      'Algo salió mal. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get orEmail => 'o con un correo';

  @override
  String get email => 'Correo';

  @override
  String get password => 'Contraseña';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get forgotPassword => '¿Olvidaste la contraseña?';

  @override
  String get resetSent => 'Enlace enviado, revisa tu correo.';

  @override
  String get wrongPassword => 'Correo o contraseña incorrectos.';

  @override
  String get emailInUse => 'Este correo ya tiene cuenta: inicia sesión.';

  @override
  String get weakPassword => 'Contraseña: al menos 6 caracteres.';

  @override
  String get invalidEmail => 'Revisa la dirección de correo.';

  @override
  String get introAccountTitle => 'Conserva tu colección';

  @override
  String get shiny => 'Shiny';

  @override
  String get leucistic => 'Leucístico';

  @override
  String get melanistic => 'Melánico';

  @override
  String get inviteFriends => 'Invitar amigos';

  @override
  String inviteText(String link) {
    return 'Me despierto con cantos de pájaros y colecciono sus cartas en Early Bird 🐦 ¿Sabrás reconocerlos? Es gratis: $link';
  }

  @override
  String friendsJoined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amigos se han unido',
      one: '1 amigo se ha unido',
      zero: 'Aún no se ha unido ningún amigo',
    );
    return '$_temp0';
  }

  @override
  String get enterCode => 'Introducir un código';

  @override
  String get redeem => 'Canjear';

  @override
  String get codeUnknown => 'Este código no existe.';

  @override
  String get codeExpired => 'Este código ha caducado.';

  @override
  String get codeUsed => 'Ya has usado este código.';

  @override
  String get codeDone => '¡Código canjeado!';

  @override
  String get codeGift => '¡Un regalo para ti!';

  @override
  String get welcomeGift => '¡Bienvenido! Un regalo de tu amigo';

  @override
  String get achievements => 'Logros';

  @override
  String get twitcher => 'Twitcher';

  @override
  String get duplicates => 'Duplicados';

  @override
  String get epicFinds => 'Hallazgos épicos';

  @override
  String get sharpEar => 'Oído fino';

  @override
  String get wakeUpStreak => 'Racha de despertares';

  @override
  String get earlyRiser => 'Madrugador';

  @override
  String get dailyBirder => 'Pajarero diario';

  @override
  String get fidelity => 'Fidelidad';

  @override
  String get trader => 'Comerciante';

  @override
  String get influencer => 'Influencer';

  @override
  String goalTwitcher(int count) {
    return '$count especies en total';
  }

  @override
  String goalDuplicates(int count) {
    return '$count copias de una especie';
  }

  @override
  String goalEpicFinds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas Épica o mejor',
      one: '1 carta Épica o mejor',
    );
    return '$_temp0';
  }

  @override
  String goalSharpEar(int count) {
    return '$count respuestas correctas seguidas';
  }

  @override
  String goalWakeUpStreak(int count) {
    return 'Una racha de $count días';
  }

  @override
  String goalEarlyRiser(int count) {
    return '$count cartas ganadas antes de las 7:00';
  }

  @override
  String goalDailyBirder(int count) {
    return 'Cartas ganadas en $count días distintos';
  }

  @override
  String goalFidelity(int count) {
    return 'Cartas ganadas en $count meses distintos';
  }

  @override
  String goalTrader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas intercambiadas',
      one: '1 carta intercambiada',
    );
    return '$_temp0';
  }

  @override
  String goalInfluencer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amigos llegaron por tu enlace',
      one: '1 amigo llegó por tu enlace',
    );
    return '$_temp0';
  }

  @override
  String get songOffline => 'Sin conexión: este canto no está en el teléfono';

  @override
  String get hallOfFame => 'Salón de la fama';

  @override
  String get friends => 'Amigos';

  @override
  String get chooseCard => 'Elegir una carta';

  @override
  String get frameAvatar => 'Encuadra tu foto';

  @override
  String get changeAvatar => 'Cambiar foto';

  @override
  String get signInToKeep => 'Inicia sesión para conservar tu colección';

  @override
  String get renameTitle => 'Tu @nombre';

  @override
  String get nameRules =>
      'De 3 a 20 letras, cifras o _, una vez por semana. Sé respetuoso: los nombres ofensivos se eliminan.';

  @override
  String get nameLength => 'De 3 a 20 caracteres.';

  @override
  String get nameCharacters => 'Solo letras, cifras y _.';

  @override
  String get nameBanned => 'Este nombre no está permitido.';

  @override
  String get nameTaken => 'Este nombre ya está en uso.';

  @override
  String renameTooSoon(String date) {
    return 'Próximo cambio posible el $date.';
  }

  @override
  String get addFriend => 'Añadir un amigo';

  @override
  String get friendNameHint => 'su nombre';

  @override
  String get sendRequest => 'Enviar';

  @override
  String get requestSent => '¡Solicitud enviada!';

  @override
  String get friendNotFound => 'Ningún jugador con este nombre.';

  @override
  String get friendSelf => '¡Eres tú!';

  @override
  String get friendAlready => 'Ya es tu amigo.';

  @override
  String get accept => 'Aceptar';

  @override
  String get decline => 'Rechazar';

  @override
  String get noFriendsYet => 'Aún no tienes amigos: añade uno con su @nombre.';

  @override
  String get removeFriend => 'Quitar de amigos';

  @override
  String get blockPlayer => 'Bloquear';

  @override
  String get reportPlayer => 'Denunciar';

  @override
  String get challenge => 'Desafiar';

  @override
  String get bonusCodes => 'Códigos de bonificación';

  @override
  String get statCards => 'Cartas';

  @override
  String get statSpecies => 'Especies';

  @override
  String get statRegions => 'Regiones';

  @override
  String seeAllFriends(int count) {
    return 'Ver todos ($count)';
  }
}
