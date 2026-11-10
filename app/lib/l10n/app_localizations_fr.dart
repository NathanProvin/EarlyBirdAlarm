// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get noAlarms => 'Aucune alarme';

  @override
  String get guessTheBird => 'Devinez l\'oiseau !';

  @override
  String get snooze => 'Répéter';

  @override
  String snoozeMinutes(int minutes) {
    return 'Répéter après $minutes min';
  }

  @override
  String streak(int count) {
    return 'Série : $count';
  }

  @override
  String get once => 'Une fois';

  @override
  String get label => 'Libellé';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get done => 'Terminé';

  @override
  String get settings => 'Réglages';

  @override
  String get difficulty => 'Difficulté';

  @override
  String get easy => 'Facile';

  @override
  String get medium => 'Moyen';

  @override
  String get hard => 'Difficile';

  @override
  String get allBirds => 'Tous les oiseaux';

  @override
  String get language => 'Langue';

  @override
  String get systemLanguage => 'Téléphone';

  @override
  String get region => 'Région';

  @override
  String get alarms => 'Alarmes';

  @override
  String get collection => 'Collection';

  @override
  String get common => 'Commune';

  @override
  String get uncommon => 'Peu commune';

  @override
  String get rare => 'Rare';

  @override
  String get epic => 'Épique';

  @override
  String get legendary => 'Légendaire';

  @override
  String get heard => 'Entendu';

  @override
  String get weight => 'Poids';

  @override
  String get birdRarity => 'Rareté';

  @override
  String get wikipedia => 'Wikipédia';

  @override
  String get expert => 'Expert';

  @override
  String get expertInfo => 'Tous les oiseaux, tous les sons, sans choix';

  @override
  String get typeTheBird => 'Tapez le nom de l\'oiseau';

  @override
  String get wingspan => 'Envergure';

  @override
  String get length => 'Longueur';

  @override
  String get flightDistance => 'Vol';

  @override
  String get share => 'Partager';

  @override
  String progress(int owned, int total) {
    return '$owned / $total cartes';
  }

  @override
  String get useMyLocation => 'Utiliser ma position';

  @override
  String get searchRegion => 'Chercher un pays ou une région';

  @override
  String get offline =>
      'Pas de connexion. Connectez-vous à Internet pour télécharger les oiseaux de votre région.';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get retry => 'Réessayer';

  @override
  String nearCell(String lat, String lon) {
    return 'Autour de $lat $lon';
  }

  @override
  String get locationDenied =>
      'Position indisponible. Cherchez votre région ou touchez-la sur la carte.';

  @override
  String get song => 'chant';

  @override
  String get call => 'cri';

  @override
  String get alarmCall => 'cri d\'alarme';

  @override
  String get seasonalBirds => 'Oiseaux de saison';

  @override
  String get credits => 'Crédits';

  @override
  String get creditsBody =>
      'Présence et saisons des oiseaux : données d\'observation de GBIF.org.\n\nNoms et photos : Wikidata et Wikimedia Commons (CC0, domaine public, CC BY, CC BY-SA) ; l\'auteur et la licence de chaque photo sont sur sa carte (ⓘ).\n\nChants et cris : enregistrements de xeno-canto.org et iNaturalist (CC0, CC BY, CC BY-SA) ; l\'auteur et la licence sont sur la carte (ⓘ). Coq du réveil de secours : Kalvin Chan, iNaturalist (CC0).\n\nStatistiques des cartes : AVONET (Tobias et al. 2022, Ecology Letters, CC BY 4.0), Wikipédia et Wikidata.';

  @override
  String get tryNextTime => 'Ce sera pour la prochaine fois !';

  @override
  String speciesCollected(String ordinal) {
    return '$ordinal espèce collectée !';
  }

  @override
  String get streakLost => 'Série perdue';

  @override
  String get viewSpecies => 'Espèces';

  @override
  String get viewAll => 'Collectionnées';

  @override
  String get viewRegion => 'Région';

  @override
  String get allRarities => 'Toutes raretés';

  @override
  String get theme => 'Thème';

  @override
  String get resident => 'Sédentaire';

  @override
  String get themeBlackbird => 'Merle';

  @override
  String get themeSerin => 'Serin';

  @override
  String get themeBlueTit => 'Mésange';

  @override
  String get themeGull => 'Mouette';

  @override
  String get play => 'Écouter';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get easyInfo => 'Oiseaux communs, chants seulement';

  @override
  String get mediumInfo => 'Oiseaux moins communs, chants et cris';

  @override
  String get hardInfo => 'Oiseaux plus rares, tous les sons';

  @override
  String get seasonalInfo => 'Seulement les oiseaux présents ce mois-ci';

  @override
  String get allBirdsInfo => 'Tous les oiseaux de la région';

  @override
  String get creditsSubtitle => 'Sources, licences et confidentialité';

  @override
  String get twitch => 'Entraînement';

  @override
  String get twitchZone => 'Entraînement';

  @override
  String get openBooster => 'Ouvrir un booster';

  @override
  String get listenAgain => 'Réécouter';

  @override
  String get series => 'Séries';

  @override
  String get legendaryHunter => 'Chasseur de légendes';

  @override
  String get perfectWeek => 'Semaine parfaite';

  @override
  String get fullSet => 'Toutes les raretés';

  @override
  String get collector => 'Collectionneur';

  @override
  String get localExpert => 'Expert local';

  @override
  String get rareFinds => 'Belles trouvailles';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String ringsInDays(int days, int hours) {
    return 'Sonne dans $days j $hours h';
  }

  @override
  String ringsInHours(int hours, String minutes) {
    return 'Sonne dans $hours h $minutes';
  }

  @override
  String ringsInMinutes(int minutes) {
    return 'Sonne dans $minutes min';
  }

  @override
  String get trade => 'Échanger';

  @override
  String get viewMenu => 'Choisir la vue';

  @override
  String get rarityMenu => 'Filtrer par rareté';

  @override
  String get lookingForBirder => 'Recherche d\'un ornithologue à proximité…';

  @override
  String get lookingHint =>
      'Demandez-lui d\'ouvrir Échanger aussi, téléphones proches.';

  @override
  String get checkCode => 'Voyez-vous tous les deux ces deux oiseaux ?';

  @override
  String get itMatches => 'C\'est bien ça';

  @override
  String get cancel => 'Annuler';

  @override
  String get youGive => 'Vous donnez';

  @override
  String get youGet => 'Vous recevez';

  @override
  String get nothingYet => 'Rien pour l\'instant';

  @override
  String get addCards => 'Ajouter des cartes';

  @override
  String get validate => 'Valider';

  @override
  String get youValidated => 'Vous avez validé';

  @override
  String get theyValidated => 'L\'autre a validé';

  @override
  String get waitingForThem => 'En attente de l\'autre ornithologue';

  @override
  String get tradeDone => 'Échange conclu !';

  @override
  String get tradeCancelled => 'Échange annulé : rien n\'a changé.';

  @override
  String get updateToTrade =>
      'Mettez l\'application à jour pour échanger avec cet ornithologue.';

  @override
  String get tradeInvalid =>
      'Ces cartes ne peuvent pas être acceptées. Échange annulé.';

  @override
  String get tradePermissions =>
      'L\'échange a besoin du Bluetooth, des appareils à proximité et de la position précise (elle ne quitte jamais votre téléphone). Autorisez-les dans les réglages de l\'application.';

  @override
  String get openSettings => 'Réglages';

  @override
  String tradedOn(String date) {
    return 'Échangée le $date';
  }

  @override
  String get tradeStartFailed =>
      'Impossible de chercher les ornithologues à proximité. Vérifiez que le Bluetooth est activé.';

  @override
  String get fiveOfAKind => 'Carré d\'as';

  @override
  String get dawnChorus => 'Chœur de l\'aube';

  @override
  String get globetrotter => 'Globe-trotter';

  @override
  String get fullHouse => 'Collection complète';

  @override
  String get perfectSpecimen => 'Spécimen parfait';

  @override
  String get ironStreak => 'Série de fer';

  @override
  String get goalLegendaryHunter => '5 cartes légendaires';

  @override
  String get goalPerfectWeek => '7 jours de réveil d\'affilée';

  @override
  String get goalFullSet => 'Une carte de chaque rareté';

  @override
  String get goalCollector => '100 cartes';

  @override
  String get goalLocalExpert => '50 espèces de votre région';

  @override
  String get goalRareFinds => '5 cartes rares ou mieux';

  @override
  String get goalFiveOfAKind => '5 exemplaires d\'une même espèce';

  @override
  String get goalDawnChorus => '10 cartes gagnées avant 7 h';

  @override
  String get goalGlobetrotter => 'Des cartes de 3 régions';

  @override
  String get goalFullHouse => '3 séries complétées';

  @override
  String get goalPerfectSpecimen => 'Une carte de qualité 95 % ou plus';

  @override
  String get goalIronStreak => '30 jours de réveil d\'affilée';

  @override
  String get seriesComplete => 'Série complétée !';

  @override
  String get achievementUnlocked => 'Succès débloqué !';

  @override
  String rewardRarity(String rarity) {
    return 'Récompense : $rarity';
  }

  @override
  String get tapToCollect => 'Touchez pour récupérer';

  @override
  String get tradeLocationOff =>
      'Activez la localisation pour trouver les ornithologues à proximité. Votre position n\'est jamais utilisée ni envoyée.';

  @override
  String get tradeNeedsLocation =>
      'L\'échange a besoin de l\'autorisation de localisation (Android l\'exige pour chercher en Bluetooth ; votre position n\'est jamais utilisée). Autorisez-la dans les réglages de l\'application.';

  @override
  String get tradeNeedsPrecise =>
      'L\'échange a besoin de la position précise : dans les réglages de l\'application, sous Localisation, activez « Utiliser la position exacte ».';

  @override
  String get tradeNeedsBluetooth =>
      'L\'échange a besoin des autorisations Bluetooth et appareils à proximité. Autorisez-les dans les réglages de l\'application.';

  @override
  String get searchCollection => 'Chercher dans la collection';

  @override
  String get noSpeciesFound => 'Aucune espèce trouvée';

  @override
  String get introWelcome =>
      'Vous n\'arrivez pas à progresser dans l\'apprentissage des chants d\'oiseaux ? Chaque matin, réveillez-vous avec un nouvel oiseau : devinez-le, gagnez sa carte, et apprenez son chant.';

  @override
  String get introRegionTitle => 'Choisir une région';

  @override
  String get introRegion =>
      'Vous entendrez des oiseaux locaux : choisissez une région sur la carte, ou utilisez votre position actuelle.';

  @override
  String get introGameTitle => 'Gameplay';

  @override
  String get introLater =>
      'Les réglages plus difficiles donnent de meilleures récompenses ; vous pourrez les changer plus tard dans les Réglages.';

  @override
  String get introCollectionTitle => 'Collectionner des cartes';

  @override
  String get introTwitch =>
      'Entraînement : un booster gratuit toutes les 15 minutes pour entraîner votre oreille.';

  @override
  String get introSeries =>
      'Séries et succès : complétez-les pour récupérer des cartes rares garanties.';

  @override
  String get introTrade =>
      'Échanger : retrouvez un autre ornithologue et échangez des cartes en personne.';

  @override
  String get introExamineTitle => 'Examiner les cartes';

  @override
  String get introExamine => 'Touchez et maintenez la carte pour l\'examiner !';

  @override
  String get next => 'Suivant';

  @override
  String get skip => 'Passer';

  @override
  String get introAgain => 'Revoir l\'introduction';

  @override
  String get introRarityTitle => 'Rareté et statistiques';

  @override
  String get introRarity =>
      'La rareté des cartes va de Commune à Légendaire : les espèces rares ont plus de chances de donner des cartes rares. Chaque carte porte aussi de vraies statistiques de l\'espèce : visez un oiseau à 100 % !';

  @override
  String get start => 'Commencer';

  @override
  String get support => 'Soutenir Early Bird';

  @override
  String get tipsTile => 'M\'offrir un café';

  @override
  String get tipsNote =>
      'Early Bird est sans pub, sans traqueurs, et maintenue par un dev solo. Si l\'app vous est utile, remerciez-moi avec un café !';

  @override
  String get tipEspresso => 'Expresso';

  @override
  String get tipCappuccino => 'Cappuccino';

  @override
  String get tipBreakfast => 'Petit-déjeuner';

  @override
  String get tipBinoculars => 'Jumelles stabilisées';

  @override
  String get tipsPayments =>
      'Paiement par Google Play. Rien ne change dans le jeu.';

  @override
  String get thankYou => 'Merci !';

  @override
  String get thankYouBody => 'Votre soutien fait chanter Early Bird.';

  @override
  String get purchasesUnavailable =>
      'Les achats ne sont pas disponibles sur ce téléphone.';

  @override
  String get twitchPlus => 'Early Bird Plus';

  @override
  String get twitchPlusPitch =>
      'Mode illimité : un booster par minute ! Un achat, à vie.';

  @override
  String get paymentsGoogle => 'Paiement par Google Play.';

  @override
  String shareTitle(String rarity) {
    return 'Carte $rarity !';
  }

  @override
  String get shareTagline => 'Le réveil des ornithos · Gratuit sur Google Play';

  @override
  String shareText(String bird, String rarity, String link) {
    return 'J’ai reconnu le chant : $bird ! Carte $rarity gagnée. $link';
  }

  @override
  String get shareCopied =>
      'Lien copié : colle-le dans ton message si l’app ne l’ajoute pas';

  @override
  String get gyro => 'Gyro';

  @override
  String get gyroHint => 'Les cartes s’inclinent quand tu bouges le téléphone';

  @override
  String backupMinutes(int minutes) {
    return 'Réveil de secours après $minutes min';
  }

  @override
  String get backupOff => 'Pas de réveil de secours';

  @override
  String get wakeNotifications => 'Notifications';

  @override
  String get wakeFullScreen => 'Quiz sur l\'écran verrouillé';

  @override
  String get wakeBattery => 'Batterie : non restreinte';

  @override
  String get wakeFix => 'Corriger';

  @override
  String get wakeMissing =>
      'Sans cela, une alarme peut sonner sans afficher le quiz.';

  @override
  String get wakeOk => 'OK';

  @override
  String get wakeNotOk => 'Manquant';

  @override
  String get alarmPermissions => 'Autorisations du réveil';

  @override
  String get addAlarm => 'Ajouter une alarme';

  @override
  String get supportNudge => 'Early Bird vous plaît ? Offrez-moi un café';

  @override
  String get viewWorld => 'Monde';

  @override
  String get sortMenu => 'Trier et filtrer';

  @override
  String get sortNumber => 'Numéro';

  @override
  String get sortRarity => 'Rareté';

  @override
  String get sortName => 'Nom';

  @override
  String get coveredArea => 'Rouge : zone couverte';

  @override
  String get confirmRegion => 'Valider';

  @override
  String get notCovered => 'Pas encore couvert';

  @override
  String get supportShort => 'Gratuit, sans pub, sans traceurs';
}
