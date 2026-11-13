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
  String get comingSoon => 'À venir';

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
  String get fullSet => 'Panoplie';

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
  String get rarityMenu => 'Rareté';

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
  String get globetrotter => 'Globe-trotter';

  @override
  String get fullHouse => 'Carton plein';

  @override
  String get perfectSpecimen => 'Spécimen parfait';

  @override
  String goalLegendaryHunter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartes Légendaires',
      one: '1 carte Légendaire',
    );
    return '$_temp0';
  }

  @override
  String goalFullSet(int count) {
    return 'Des cartes de $count raretés (la 6e : Shiny)';
  }

  @override
  String goalCollector(int count) {
    return '$count cartes';
  }

  @override
  String goalLocalExpert(int count) {
    return '$count espèces de ta région';
  }

  @override
  String goalRareFinds(int count) {
    return '$count cartes Rare ou mieux';
  }

  @override
  String goalGlobetrotter(int count) {
    return 'Des cartes de $count régions';
  }

  @override
  String goalFullHouse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séries complétées',
      one: '1 série complétée',
    );
    return '$_temp0';
  }

  @override
  String goalPerfectSpecimen(int count) {
    return 'Une carte de qualité $count % ou plus';
  }

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
  String get sortMenu => 'Trier';

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

  @override
  String get account => 'Compte';

  @override
  String get accountPitch =>
      'Connectez-vous avec Google pour garder votre collection sur tous vos téléphones.';

  @override
  String get signInGoogle => 'Se connecter avec Google';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountBody =>
      'Votre compte et sa sauvegarde en ligne seront supprimés. Vos cartes restent sur ce téléphone.';

  @override
  String get accountDeleted => 'Compte supprimé';

  @override
  String get accountError =>
      'Un problème est survenu. Vérifiez votre connexion et réessayez.';

  @override
  String get orEmail => 'ou avec un e-mail';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get resetSent => 'Lien envoyé, vérifiez votre boîte mail.';

  @override
  String get wrongPassword => 'E-mail ou mot de passe incorrect.';

  @override
  String get emailInUse => 'Cet e-mail a déjà un compte : connectez-vous.';

  @override
  String get weakPassword => 'Mot de passe : 6 caractères minimum.';

  @override
  String get invalidEmail => 'Vérifiez l\'adresse e-mail.';

  @override
  String get introAccountTitle => 'Gardez votre collection';

  @override
  String get shiny => 'Shiny';

  @override
  String get leucistic => 'Leucique';

  @override
  String get melanistic => 'Mélanique';

  @override
  String get inviteFriends => 'Inviter des amis';

  @override
  String inviteText(String link) {
    return 'Je me réveille au chant des oiseaux et je collectionne leurs cartes sur Early Bird 🐦 Sauras-tu les reconnaître ? C’est gratuit : $link';
  }

  @override
  String friendsJoined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amis ont rejoint',
      one: '1 ami a rejoint',
      zero: 'Aucun ami inscrit pour l’instant',
    );
    return '$_temp0';
  }

  @override
  String get enterCode => 'Entrer un code';

  @override
  String get redeem => 'Valider';

  @override
  String get codeUnknown => 'Ce code n’existe pas.';

  @override
  String get codeExpired => 'Ce code a expiré.';

  @override
  String get codeUsed => 'Vous avez déjà utilisé ce code.';

  @override
  String get codeDone => 'Code validé !';

  @override
  String get codeGift => 'Un cadeau pour vous !';

  @override
  String get welcomeGift => 'Bienvenue ! Un cadeau de la part de votre ami';

  @override
  String get achievements => 'Succès';

  @override
  String get twitcher => 'Cocheur';

  @override
  String get duplicates => 'Doublons';

  @override
  String get epicFinds => 'Trouvailles épiques';

  @override
  String get sharpEar => 'Oreille fine';

  @override
  String get wakeUpStreak => 'Série du réveil';

  @override
  String get earlyRiser => 'Lève-tôt';

  @override
  String get dailyBirder => 'Ornitho du quotidien';

  @override
  String get fidelity => 'Fidélité';

  @override
  String get trader => 'Trader';

  @override
  String get influencer => 'Influenceur';

  @override
  String goalTwitcher(int count) {
    return '$count espèces en tout';
  }

  @override
  String goalDuplicates(int count) {
    return '$count exemplaires d’une même espèce';
  }

  @override
  String goalEpicFinds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartes Épique ou mieux',
      one: '1 carte Épique ou mieux',
    );
    return '$_temp0';
  }

  @override
  String goalSharpEar(int count) {
    return '$count bonnes réponses d’affilée';
  }

  @override
  String goalWakeUpStreak(int count) {
    return '$count jours de réveil d’affilée';
  }

  @override
  String goalEarlyRiser(int count) {
    return '$count cartes gagnées avant 7 h';
  }

  @override
  String goalDailyBirder(int count) {
    return 'Des cartes gagnées $count jours différents';
  }

  @override
  String goalFidelity(int count) {
    return 'Des cartes gagnées sur $count mois différents';
  }

  @override
  String goalTrader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartes échangées',
      one: '1 carte échangée',
    );
    return '$_temp0';
  }

  @override
  String goalInfluencer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amis venus par ton lien',
      one: '1 ami venu par ton lien',
    );
    return '$_temp0';
  }

  @override
  String get songOffline =>
      'Pas de connexion : ce chant n’est pas sur le téléphone';

  @override
  String get hallOfFame => 'Panthéon';

  @override
  String get friends => 'Amis';

  @override
  String get chooseCard => 'Choisir une carte';

  @override
  String get frameAvatar => 'Cadre ta photo';

  @override
  String get changeAvatar => 'Changer de photo';

  @override
  String get signInToKeep => 'Connecte-toi pour garder ta collection';

  @override
  String get renameTitle => 'Ton @pseudo';

  @override
  String get nameRules =>
      '3 à 20 lettres, chiffres ou _, une fois par semaine. Sois respectueux : les pseudos offensants sont supprimés.';

  @override
  String get nameLength => 'De 3 à 20 caractères.';

  @override
  String get nameCharacters => 'Lettres, chiffres et _ seulement.';

  @override
  String get nameBanned => 'Ce pseudo n’est pas autorisé.';

  @override
  String get nameTaken => 'Ce pseudo est déjà pris.';

  @override
  String renameTooSoon(String date) {
    return 'Prochain changement possible le $date.';
  }

  @override
  String get addFriend => 'Ajouter un ami';

  @override
  String get friendNameHint => 'son pseudo';

  @override
  String get sendRequest => 'Envoyer';

  @override
  String get requestSent => 'Demande envoyée !';

  @override
  String get friendNotFound => 'Aucun joueur avec ce pseudo.';

  @override
  String get friendSelf => 'C’est toi !';

  @override
  String get friendAlready => 'Déjà ton ami.';

  @override
  String get accept => 'Accepter';

  @override
  String get decline => 'Refuser';

  @override
  String get noFriendsYet =>
      'Pas encore d’amis : ajoutes-en un avec son @pseudo.';

  @override
  String get removeFriend => 'Retirer des amis';

  @override
  String get blockPlayer => 'Bloquer';

  @override
  String get reportPlayer => 'Signaler';

  @override
  String get challenge => 'Défier';

  @override
  String get bonusCodes => 'Codes bonus';

  @override
  String get statCards => 'Cartes';

  @override
  String get statSpecies => 'Espèces';

  @override
  String get statRegions => 'Régions';

  @override
  String seeAllFriends(int count) {
    return 'Voir tout ($count)';
  }
}
