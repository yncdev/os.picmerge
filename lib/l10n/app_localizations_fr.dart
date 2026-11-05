// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Pic Merge';

  @override
  String get appSubtitle => 'Fusion d\'images';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annuler';

  @override
  String get clearList => 'Vider';

  @override
  String get recentHistory => 'Historique récent';

  @override
  String get errorLoadPhotos =>
      'Impossible de charger les photos. Veuillez réessayer.';

  @override
  String get errorCameraUnavailable =>
      'Impossible d\'utiliser l\'appareil photo.';

  @override
  String get errorLoadPdfs =>
      'Impossible de charger le PDF. Veuillez réessayer.';

  @override
  String maxImagesReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$max images',
      one: '$max image',
    );
    return 'Vous pouvez ajouter jusqu\'à $_temp0.';
  }

  @override
  String unsupportedFilesExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count fichiers ont été exclus car leur format n\'est pas pris en charge.',
      one:
          '$count fichier a été exclu car son format n\'est pas pris en charge.',
    );
    return '$_temp0';
  }

  @override
  String overLimitAdded(int max, int added) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$max images',
      one: '$max image',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'seules $added ont été ajoutées',
      one: 'seule $added a été ajoutée',
    );
    return 'Vous pouvez ajouter jusqu\'à $_temp0 : $_temp1.';
  }

  @override
  String get clearConfirm =>
      'Retirer toutes les images sélectionnées de la liste ?\nLes photos d\'origine ne seront pas supprimées.';

  @override
  String get folderDialogTitle => 'Choisir un dossier d\'enregistrement';

  @override
  String get folderDialogBodyAndroid =>
      'Choisissez un dossier comme Documents ou un dossier que vous avez créé.\n\nLa racine du stockage interne, le dossier Download lui-même et le dossier Android/data ne peuvent pas être choisis.';

  @override
  String get pickFolder => 'Choisir le dossier';

  @override
  String useDefaultFolder(String name) {
    return 'Utiliser le dossier par défaut ($name)';
  }

  @override
  String get pickOtherFolder => 'Choisir un autre dossier';

  @override
  String get errorPickFolder =>
      'Impossible de choisir le dossier. Veuillez réessayer.';

  @override
  String savedTo(String folder, String file) {
    return 'Enregistré : $folder/$file';
  }

  @override
  String get saveCancelled => 'Enregistrement annulé.';

  @override
  String get saveFailedTitle => 'Échec de l\'enregistrement';

  @override
  String get shareFormatPrompt =>
      'Choisissez le format du fichier à envoyer par e-mail, messagerie, etc.';

  @override
  String shareAs(String format) {
    return 'Partager en $format';
  }

  @override
  String get shareCancelled => 'Partage annulé.';

  @override
  String get shareFailedTitle => 'Échec du partage';

  @override
  String get crashTitle => 'Le dernier enregistrement n\'a pas abouti';

  @override
  String get crashBody =>
      'Le dernier enregistrement s\'est arrêté en cours de route. Laissez l\'application ouverte jusqu\'à la fin et, si le problème persiste, utilisez moins d\'images.';

  @override
  String emptyTitle(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: '$min images ou PDF',
      one: '$min image ou PDF',
    );
    return 'Choisissez au moins $_temp0 à fusionner';
  }

  @override
  String get emptyHint => 'Le sens de disposition est choisi automatiquement.';

  @override
  String get pickImages => 'Choisir des images';

  @override
  String get pickPdf => 'Choisir un PDF';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get autoDirectionVertical =>
      'Auto : disposition verticale (haut → bas)';

  @override
  String get autoDirectionHorizontal =>
      'Auto : disposition horizontale (gauche → droite)';

  @override
  String get previewNoteOriginal =>
      'Ceci est l\'aperçu du PNG. Le PNG comporte des lignes grises entre les images. Le PDF enregistre une page par élément, sans lignes.';

  @override
  String previewSummary(int pages, int perPaper) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pages pages',
      one: '$pages page',
    );
    return '$_temp0 au total · $perPaper par feuille';
  }

  @override
  String get previewNoteHorizontal =>
      'Le PNG relie les pages côte à côte, avec des lignes grises entre les images. Le PDF enregistre chaque page séparément, sans lignes.';

  @override
  String get previewNoteVertical =>
      'Le PNG relie les pages de haut en bas, avec des lignes grises entre les images. Le PDF enregistre chaque page séparément, sans lignes.';

  @override
  String get paperOriginal => 'Taille d\'origine';

  @override
  String get orientationPortrait => 'Portrait';

  @override
  String get orientationLandscape => 'Paysage';

  @override
  String get colorMode => 'Couleur';

  @override
  String get grayscaleMode => 'N&B';

  @override
  String get imagesPerPaper => 'Images par feuille';

  @override
  String get imageSize => 'Taille d\'image';

  @override
  String get margin => 'Marge';

  @override
  String selectedCount(int count, int max) {
    return 'Sélection $count/$max';
  }

  @override
  String get addItems => 'Ajouter';

  @override
  String get pickPhotos => 'Choisir des photos';

  @override
  String get pickPdfFiles => 'Choisir des fichiers PDF';

  @override
  String get camera => 'Appareil photo';

  @override
  String get folderNotChosen => 'Dossier : au premier enregistrement';

  @override
  String folderCurrent(String name) {
    return 'Dossier : $name';
  }

  @override
  String get changeFolder => 'Modifier';

  @override
  String needMinImages(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: '$min images',
      one: '$min image',
    );
    return 'Choisissez au moins $_temp0 pour enregistrer.';
  }

  @override
  String saveAs(String format) {
    return 'Enregistrer $format';
  }

  @override
  String get share => 'Partager';

  @override
  String shareTitle(String format) {
    return 'Partager $format';
  }

  @override
  String processingImages(int current, int total) {
    return 'Traitement des images $current/$total';
  }

  @override
  String get buildingFile => 'Création du fichier';

  @override
  String get openingShare => 'Ouverture de la fenêtre de partage';

  @override
  String get saving => 'Enregistrement';

  @override
  String get cancelling => 'Annulation…';

  @override
  String get mayTakeLong =>
      'Les grandes images peuvent prendre plusieurs dizaines de secondes.';

  @override
  String get keepAppOpen => 'Laissez l\'application ouverte jusqu\'à la fin.';

  @override
  String get errorApplyCrop =>
      'Impossible d\'appliquer le recadrage. Veuillez réessayer.';

  @override
  String get cropTitle => 'Recadrer';

  @override
  String get cropApply => 'Appliquer';

  @override
  String get cropSelectAll => 'Tout sélectionner';

  @override
  String get errorOpenImage => 'Impossible d\'ouvrir l\'image.';

  @override
  String croppedSize(int width, int height) {
    return '$width×$height (recadrée)';
  }

  @override
  String get removeFromList => 'Retirer de la liste';

  @override
  String get errorLoadHistory => 'Impossible de charger l\'historique.';

  @override
  String historyRateEmpty(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'ces $days derniers jours',
      one: 'le dernier jour',
    );
    return 'Aucun enregistrement $_temp0.';
  }

  @override
  String historyRate(int days, int percent, int success, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'des $days derniers jours',
      one: 'du dernier jour',
    );
    return 'Taux de réussite $_temp0 : $percent% ($success/$total)';
  }

  @override
  String get historyEmpty => 'Vous n\'avez encore rien enregistré.';

  @override
  String imageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
      one: '$count image',
    );
    return '$_temp0';
  }

  @override
  String get statusRunning => 'En cours';

  @override
  String get statusSuccess => 'Réussi';

  @override
  String get statusFailed => 'Échec';

  @override
  String get statusCancelled => 'Annulé';

  @override
  String get statusCrashed => 'Arrêt anormal';

  @override
  String get errorUnsupportedFormat =>
      'Une image est dans un format non pris en charge.';

  @override
  String errorUnsupportedFormatAt(int n) {
    return 'L\'image $n est dans un format non pris en charge.';
  }

  @override
  String get errorCorruptFile => 'Un fichier image est endommagé.';

  @override
  String errorCorruptFileAt(int n) {
    return 'Le fichier de l\'image $n est endommagé.';
  }

  @override
  String get errorSourceUnavailable =>
      'Impossible d\'ouvrir une image. Veuillez la choisir à nouveau.';

  @override
  String errorSourceUnavailableAt(int n) {
    return 'Impossible d\'ouvrir l\'image $n. Veuillez la choisir à nouveau.';
  }

  @override
  String get errorOutOfSpace => 'L\'espace de stockage est insuffisant.';

  @override
  String get errorFolderUnavailable =>
      'Impossible d\'accéder au dossier d\'enregistrement. Veuillez choisir à nouveau un dossier.';

  @override
  String get errorOutputTooLarge =>
      'Le fichier obtenu est trop volumineux. Utilisez moins d\'images.';

  @override
  String get errorOutOfMemory =>
      'La mémoire est insuffisante. Utilisez moins d\'images.';

  @override
  String get errorUnknown => 'Une erreur inconnue s\'est produite.';

  @override
  String get aboutTitle => 'À propos';

  @override
  String get sendFeedback => 'Envoyer un avis';

  @override
  String get termsTitle => 'Conditions d\'utilisation';

  @override
  String get version => 'Version';

  @override
  String get noMailAppTitle =>
      'Impossible d\'ouvrir une application de messagerie';

  @override
  String get noMailAppBody => 'Veuillez envoyer votre avis à cette adresse.';

  @override
  String get copyAddress => 'Copier l\'adresse';

  @override
  String get addressCopied => 'Adresse copiée.';

  @override
  String get termsBody =>
      'Dernière mise à jour : 5 novembre 2026\n\n1. Acceptation\nEn installant ou en utilisant Pic Merge (l\'« Application »), vous acceptez les présentes Conditions. Si vous ne les acceptez pas, n\'utilisez pas l\'Application.\n\n2. Licence\nL\'Application est un logiciel open source publié sous la MIT License, et vous pouvez l\'utiliser conformément à cette licence. Les composants tiers conservent leurs propres licences.\n\n3. Vos responsabilités\nVous êtes seul responsable des fichiers que vous traitez, enregistrez et partagez avec l\'Application, de la détention des droits nécessaires pour les utiliser et du respect des lois applicables. Conservez vos propres sauvegardes des fichiers importants.\n\n4. Vos données\nL\'Application traite les fichiers sur votre appareil et ne les envoie à aucun serveur. Si vous utilisez Envoyer un avis, l\'application de messagerie de votre appareil crée le message, et ce que vous envoyez est traité par votre fournisseur de messagerie.\n\n5. Absence de garantie\nL\'Application est fournie « TELLE QUELLE » et « SELON SA DISPONIBILITÉ », sans garantie d\'aucune sorte, expresse ou implicite, notamment de qualité marchande, d\'adéquation à un usage particulier et d\'absence de contrefaçon. Rien ne garantit qu\'elle sera exempte d\'erreurs ou d\'interruptions, ni que ses résultats seront exacts.\n\n6. Limitation de responsabilité\nDans toute la mesure permise par la loi applicable, les auteurs, les titulaires des droits d\'auteur et les distributeurs ne sont responsables d\'aucune réclamation, d\'aucun dommage ni d\'aucune autre responsabilité, y compris la perte de données, la perte de bénéfices et les dommages indirects ou consécutifs, découlant de l\'Application ou de son utilisation ou s\'y rapportant.\n\n7. Aucune obligation d\'assistance\nLes auteurs n\'ont aucune obligation de fournir une assistance, des mises à jour ou une maintenance, ni de répondre aux avis, et peuvent modifier ou arrêter l\'Application à tout moment.\n\n8. Boutiques d\'applications et plateformes\nSi vous avez obtenu l\'Application par l\'intermédiaire d\'une boutique d\'applications, les conditions de cette boutique s\'appliquent également à votre utilisation de l\'Application.\n\n9. Modifications\nLes présentes Conditions peuvent changer. Si vous continuez à utiliser l\'Application après un changement, vous acceptez ce changement.\n\n10. Langue\nLes traductions sont fournies pour plus de commodité. En cas de différence, la version anglaise prévaut.\n\nContact : yncdev@gmail.com';

  @override
  String get privacyTitle => 'Politique de confidentialité';

  @override
  String get openSourceLicenses => 'Licences open source';

  @override
  String get privacyBody =>
      'Dernière mise à jour : 6 novembre 2026\n\nCette politique couvre Pic Merge pour Android et iOS ainsi que l\'extension Chrome Pic Merge (l\'« Application »).\n\nCe que l\'Application fait de vos fichiers\nL\'Application lit les images et les PDF que vous choisissez et les combine en un seul fichier sur votre appareil. Vos fichiers ne sont jamais envoyés à un serveur, et l\'Application n\'a ni compte, ni publicité, ni outil d\'analyse.\n\nCe qui est stocké, et où\nTout ce qui suit reste sur votre appareil ou dans votre navigateur :\n\n- Les fichiers que vous enregistrez, dans le dossier que vous utilisez : le dossier par défaut ou celui que vous choisissez.\n- L\'historique récent : pour chaque enregistrement, l\'heure, le format, le nombre d\'éléments, le nom, la taille et les dimensions du fichier obtenu, le nom du dossier d\'enregistrement, le sens de disposition et le résultat. L\'application mobile conserve aussi le nom, la taille en pixels et la taille de fichier de chaque élément ainsi que l\'échelle appliquée, et conserve tout cela dans une base de données locale jusqu\'à la suppression de l\'Application. L\'extension conserve les 50 derniers enregistrements dans le stockage du navigateur.\n- Le dossier d\'enregistrement que vous avez choisi, si vous en choisissez un autre que celui par défaut.\n- Les fichiers temporaires créés pendant le traitement. Ils sont supprimés à la fin du traitement, lorsque vous retirez l\'élément de la liste, lors de votre prochain partage ou au prochain démarrage de l\'Application.\n\nLes images originales et leurs chemins ne sont pas conservés dans l\'Application. L\'Application ne collecte, ne vend et ne partage aucune de ces données, et le développeur ne peut pas y accéder. La suppression de l\'Application supprime ses données stockées, à l\'exception des fichiers que vous avez enregistrés dans un dossier extérieur à l\'Application.\n\nLa sauvegarde d\'applications Android est désactivée pour l\'Application. Sur iOS, la sauvegarde propre à votre appareil, comme la sauvegarde iCloud, peut inclure les données de l\'Application et les fichiers de son dossier, selon les réglages de votre appareil.\n\nAutorisations\n- Android : aucune autorisation d\'accès à Internet, au stockage ou à l\'appareil photo n\'est demandée. Les fichiers sont choisis via les sélecteurs du système et les photos sont prises avec l\'application appareil photo du système.\n- iOS : le système vous demande votre autorisation la première fois que vous utilisez l\'appareil photo.\n- Extension Chrome : aucune autorisation n\'est déclarée. Si vous choisissez un dossier d\'enregistrement, votre navigateur demande l\'accès à ce dossier.\n\nEnvoi d\'un avis\nL\'option Envoyer un avis de l\'application mobile ouvre l\'application de messagerie de votre appareil avec l\'adresse et l\'objet déjà remplis. L\'objet comprend la version de l\'application, le modèle de l\'appareil et la version du système d\'exploitation, et vous pouvez le modifier. Rien n\'est envoyé à moins que vous ne l\'envoyiez vous-même. Votre message est ensuite traité par votre fournisseur de messagerie, et le développeur reçoit ce que vous envoyez.\n\nAutres services\nSi vous partagez un fichier, la feuille de partage de votre appareil ou l\'application que vous choisissez s\'en charge. Si vous avez obtenu l\'Application dans une boutique d\'applications, les conditions de confidentialité de cette boutique s\'appliquent à la boutique.\n\nModifications\nCette politique peut changer. Les modifications sont publiées dans ce document.\n\nContact\nyncdev@gmail.com';
}
