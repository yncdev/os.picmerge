// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Pic Merge';

  @override
  String get appSubtitle => '';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get clearList => 'Clear';

  @override
  String get recentHistory => 'Recent history';

  @override
  String get errorLoadPhotos => 'Couldn\'t load the photos. Please try again.';

  @override
  String get errorCameraUnavailable => 'The camera isn\'t available.';

  @override
  String get errorLoadPdfs => 'Couldn\'t load the PDF. Please try again.';

  @override
  String maxImagesReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$max images',
      one: '$max image',
    );
    return 'You can add up to $_temp0.';
  }

  @override
  String unsupportedFilesExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count files were left out because their format isn\'t supported.',
      one: '$count file was left out because its format isn\'t supported.',
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
      other: 'were',
      one: 'was',
    );
    return 'You can add up to $_temp0, so only $added $_temp1 added.';
  }

  @override
  String get clearConfirm =>
      'Remove all selected images from the list?\nThe original photos will not be deleted.';

  @override
  String get folderDialogTitle => 'Choose a save folder';

  @override
  String get folderDialogBodyAndroid =>
      'Choose a folder such as Documents, or a newly created one.\n\nThe top level of internal storage, the Download folder itself and the Android/data folder can\'t be chosen.';

  @override
  String get pickFolder => 'Choose folder';

  @override
  String useDefaultFolder(String name) {
    return 'Use default folder ($name)';
  }

  @override
  String get pickOtherFolder => 'Choose another folder';

  @override
  String get errorPickFolder => 'Couldn\'t choose a folder. Please try again.';

  @override
  String savedTo(String folder, String file) {
    return 'Saved: $folder/$file';
  }

  @override
  String get saveCancelled => 'Save cancelled.';

  @override
  String get saveFailedTitle => 'Couldn\'t save';

  @override
  String get shareFormatPrompt =>
      'Choose the file format to send by email, messaging apps and more.';

  @override
  String shareAs(String format) {
    return 'Share as $format';
  }

  @override
  String get shareCancelled => 'Sharing cancelled.';

  @override
  String get shareFailedTitle => 'Couldn\'t share';

  @override
  String get crashTitle => 'The last save didn\'t finish';

  @override
  String get crashBody =>
      'The last save stopped partway. Keep the app open until saving finishes, and if this keeps happening, use fewer images.';

  @override
  String emptyTitle(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: '$min images or PDFs',
      one: '$min image or PDF',
    );
    return 'Choose at least $_temp0 to merge';
  }

  @override
  String get emptyHint => 'The layout direction is chosen automatically.';

  @override
  String get pickImages => 'Choose images';

  @override
  String get pickPdf => 'Choose PDF';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get autoDirectionVertical => 'Auto: vertical layout (top → bottom)';

  @override
  String get autoDirectionHorizontal =>
      'Auto: horizontal layout (left → right)';

  @override
  String get previewNoteOriginal =>
      'This is the PNG preview. The PNG has gray lines between images. The PDF saves one page per item, with no lines.';

  @override
  String previewSummary(int pages, int perPaper) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pages pages',
      one: '$pages page',
    );
    return '$_temp0 · $perPaper per sheet';
  }

  @override
  String get previewNoteHorizontal =>
      'The PNG joins pages side by side, with gray lines between images. The PDF saves each page separately, with no lines.';

  @override
  String get previewNoteVertical =>
      'The PNG joins pages from top to bottom, with gray lines between images. The PDF saves each page separately, with no lines.';

  @override
  String get paperOriginal => 'Original size';

  @override
  String get orientationPortrait => 'Portrait';

  @override
  String get orientationLandscape => 'Landscape';

  @override
  String get colorMode => 'Color';

  @override
  String get grayscaleMode => 'B&W';

  @override
  String get imagesPerPaper => 'Images per sheet';

  @override
  String get imageSize => 'Image size';

  @override
  String get margin => 'Margin';

  @override
  String selectedCount(int count, int max) {
    return 'Selected $count/$max';
  }

  @override
  String get addItems => 'Add';

  @override
  String get pickPhotos => 'Choose photos';

  @override
  String get pickPdfFiles => 'Choose PDF files';

  @override
  String get camera => 'Camera';

  @override
  String get folderNotChosen => 'Save folder: chosen on first save';

  @override
  String folderCurrent(String name) {
    return 'Save folder: $name';
  }

  @override
  String get changeFolder => 'Change';

  @override
  String needMinImages(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: '$min images',
      one: '$min image',
    );
    return 'Choose at least $_temp0 to save.';
  }

  @override
  String saveAs(String format) {
    return 'Save $format';
  }

  @override
  String get share => 'Share';

  @override
  String shareTitle(String format) {
    return 'Share $format';
  }

  @override
  String processingImages(int current, int total) {
    return 'Processing images $current/$total';
  }

  @override
  String get buildingFile => 'Creating the file';

  @override
  String get openingShare => 'Opening the share sheet';

  @override
  String get saving => 'Saving';

  @override
  String get cancelling => 'Cancelling…';

  @override
  String get mayTakeLong => 'Large images can take tens of seconds.';

  @override
  String get keepAppOpen => 'Keep the app open until this finishes.';

  @override
  String get errorApplyCrop => 'Couldn\'t apply the crop. Please try again.';

  @override
  String get cropTitle => 'Crop';

  @override
  String get cropApply => 'Apply';

  @override
  String get cropSelectAll => 'Select all';

  @override
  String get errorOpenImage => 'Couldn\'t open the image.';

  @override
  String croppedSize(int width, int height) {
    return '$width×$height (cropped)';
  }

  @override
  String get removeFromList => 'Remove from list';

  @override
  String get errorLoadHistory => 'Couldn\'t load the history.';

  @override
  String historyRateEmpty(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '$days day',
    );
    return 'No saves in the last $_temp0.';
  }

  @override
  String historyRate(int days, int percent, int success, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '$days day',
    );
    return 'Success rate in the last $_temp0: $percent% ($success/$total)';
  }

  @override
  String get historyEmpty => 'You haven\'t saved anything yet.';

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
  String get statusRunning => 'In progress';

  @override
  String get statusSuccess => 'Succeeded';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusCrashed => 'Ended abnormally';

  @override
  String get errorUnsupportedFormat =>
      'There is an image in an unsupported format.';

  @override
  String errorUnsupportedFormatAt(int n) {
    return 'Image $n is in an unsupported format.';
  }

  @override
  String get errorCorruptFile => 'There is a damaged image file.';

  @override
  String errorCorruptFileAt(int n) {
    return 'The file for image $n is damaged.';
  }

  @override
  String get errorSourceUnavailable =>
      'Couldn\'t open an image. Please choose it again.';

  @override
  String errorSourceUnavailableAt(int n) {
    return 'Couldn\'t open image $n. Please choose it again.';
  }

  @override
  String get errorOutOfSpace => 'There is not enough storage space.';

  @override
  String get errorFolderUnavailable =>
      'Can\'t access the save folder. Please choose a folder again.';

  @override
  String get errorOutputTooLarge =>
      'The result file is too large. Please use fewer images.';

  @override
  String get errorOutOfMemory =>
      'There is not enough memory. Please use fewer images.';

  @override
  String get errorUnknown => 'An unknown error occurred.';

  @override
  String get aboutTitle => 'About';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get termsTitle => 'Terms of Use';

  @override
  String get version => 'Version';

  @override
  String get noMailAppTitle => 'Couldn\'t open a mail app';

  @override
  String get noMailAppBody => 'Please send your feedback to this address.';

  @override
  String get copyAddress => 'Copy address';

  @override
  String get addressCopied => 'Address copied.';

  @override
  String get termsBody =>
      'Last updated: November 5, 2026\n\n1. Acceptance\nBy installing or using Pic Merge (the \"App\"), you agree to these Terms. If you do not agree, do not use the App.\n\n2. License\nThe App is open-source software released under the MIT License, and you may use it under that license. Third-party components keep their own licenses.\n\n3. Your responsibilities\nYou alone are responsible for the files you process, save and share with the App, for having the rights to use them, and for complying with applicable laws. Keep your own backups of important files.\n\n4. Your data\nThe App processes files on your device and does not send them to any server. If you use Send feedback, your device\'s mail app creates the message, and what you send is handled by your mail provider.\n\n5. No warranty\nThe App is provided \"AS IS\" and \"AS AVAILABLE\", without warranty of any kind, express or implied, including merchantability, fitness for a particular purpose and non-infringement. There is no guarantee that it will be error-free or uninterrupted, or that its results will be accurate.\n\n6. Limitation of liability\nTo the maximum extent permitted by applicable law, the authors, copyright holders and distributors are not liable for any claim, damages or other liability, including loss of data, loss of profits and indirect or consequential damages, arising from or connected with the App or its use.\n\n7. No obligation to support\nThe authors have no obligation to provide support, updates or maintenance or to reply to feedback, and may change or stop the App at any time.\n\n8. App stores and platforms\nIf you obtained the App through an app store, that store\'s terms also apply to your use of the App.\n\n9. Changes\nThese Terms may change. If you keep using the App after a change, you accept the change.\n\n10. Language\nTranslations are provided for convenience. If they differ, the English version prevails.\n\nContact: yncdev@gmail.com';

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get openSourceLicenses => 'Open-source licenses';

  @override
  String get privacyBody =>
      'Last updated: November 6, 2026\n\nThis policy covers Pic Merge for Android and iOS and the Pic Merge Chrome extension (the \"App\").\n\nWhat the App does with your files\nThe App reads the images and PDFs you choose and combines them into a single file on your device. Your files are never sent to a server, and the App has no account, advertising or analytics.\n\nWhat is stored, and where\nEverything below stays on your device or in your browser:\n\n- Files you save, in the folder you use: the default folder or one you choose.\n- Recent history: for each save, the time, format, number of items, the result file\'s name, size and dimensions, the save folder\'s name, the layout direction, and the result. The mobile app also keeps each item\'s name, pixel size and file size and the scale applied, and keeps all of this in a local database until the App is deleted. The extension keeps the last 50 saves in browser storage.\n- Your chosen save folder, if you pick one instead of the default.\n- Temporary files made while processing. They are deleted when processing ends, when you remove the item from the list, at your next share, or the next time you start the App.\n\nOriginal images and their paths are not kept in the App. The App does not collect, sell or share any of this data, and the developer cannot access it. Deleting the App removes its stored data, except files you saved to a folder outside the App.\n\nAndroid app backup is turned off for the App. On iOS, your device\'s own backup, such as iCloud Backup, may include the App\'s data and the files in its folder, depending on your device settings.\n\nPermissions\n- Android: no internet, storage or camera permission is requested. Files are chosen through system pickers and photos are taken with the system camera app.\n- iOS: the system asks for your permission the first time you use the camera.\n- Chrome extension: no permissions are declared. If you choose a save folder, your browser asks for access to that folder.\n\nSending feedback\nThe mobile app\'s Send feedback option opens your device\'s mail app with the address and subject filled in. The subject includes the app version, device model and OS version, and you can edit it. Nothing is sent unless you send it yourself. Your message is then handled by your mail provider, and the developer receives what you send.\n\nOther services\nIf you share a file, your device\'s share sheet or the app you choose handles it. If you obtained the App from an app store, that store\'s own privacy terms apply to the store.\n\nChanges\nThis policy may change. Changes are published in this document.\n\nContact\nyncdev@gmail.com';
}
