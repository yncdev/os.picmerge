import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

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
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// Program name. "Pic Merge" in every language.
  ///
  /// In en, this message translates to:
  /// **'Pic Merge'**
  String get appName;

  /// Small subtitle next to the program name in the title bar. Empty means no subtitle.
  ///
  /// In en, this message translates to:
  /// **''**
  String get appSubtitle;

  /// Dialog confirmation button.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button that empties the selection list.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearList;

  /// Recent history sheet title and its app bar icon tooltip.
  ///
  /// In en, this message translates to:
  /// **'Recent history'**
  String get recentHistory;

  /// The photo picker failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the photos. Please try again.'**
  String get errorLoadPhotos;

  /// No camera, or the camera was refused.
  ///
  /// In en, this message translates to:
  /// **'The camera isn\'t available.'**
  String get errorCameraUnavailable;

  /// The document picker failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the PDF. Please try again.'**
  String get errorLoadPdfs;

  /// The list is already full.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {max, plural, one{{max} image} other{{max} images}}.'**
  String maxImagesReached(int max);

  /// Files left out of the list while picking.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} file was left out because its format isn\'t supported.} other{{count} files were left out because their format isn\'t supported.}}'**
  String unsupportedFilesExcluded(int count);

  /// More files were picked than the list can hold.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {max, plural, one{{max} image} other{{max} images}}, so only {added} {added, plural, one{was} other{were}} added.'**
  String overLimitAdded(int max, int added);

  /// Asked before emptying the list. Line break between the two sentences.
  ///
  /// In en, this message translates to:
  /// **'Remove all selected images from the list?\nThe original photos will not be deleted.'**
  String get clearConfirm;

  /// Title of the dialog that changes the save folder.
  ///
  /// In en, this message translates to:
  /// **'Choose a save folder'**
  String get folderDialogTitle;

  /// Body of that dialog on Android. Keep the folder names Documents, Download and Android/data as they are.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder such as Documents, or a newly created one.\n\nThe top level of internal storage, the Download folder itself and the Android/data folder can\'t be chosen.'**
  String get folderDialogBodyAndroid;

  /// Button that opens the system folder picker when no folder is in use yet.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get pickFolder;

  /// Folder dialog button that goes back to the default save folder. name is the folder name.
  ///
  /// In en, this message translates to:
  /// **'Use default folder ({name})'**
  String useDefaultFolder(String name);

  /// Folder dialog button that opens the system folder picker when a folder is already in use.
  ///
  /// In en, this message translates to:
  /// **'Choose another folder'**
  String get pickOtherFolder;

  /// The system folder picker failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t choose a folder. Please try again.'**
  String get errorPickFolder;

  /// Snack bar after saving.
  ///
  /// In en, this message translates to:
  /// **'Saved: {folder}/{file}'**
  String savedTo(String folder, String file);

  /// Snack bar after the user cancelled a save.
  ///
  /// In en, this message translates to:
  /// **'Save cancelled.'**
  String get saveCancelled;

  /// Error dialog title for a save.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save'**
  String get saveFailedTitle;

  /// Heading of the sheet that asks PNG or PDF before sharing.
  ///
  /// In en, this message translates to:
  /// **'Choose the file format to send by email, messaging apps and more.'**
  String get shareFormatPrompt;

  /// List tile in that sheet. format is PNG or PDF.
  ///
  /// In en, this message translates to:
  /// **'Share as {format}'**
  String shareAs(String format);

  /// Snack bar after the user cancelled sharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing cancelled.'**
  String get shareCancelled;

  /// Error dialog title for sharing.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share'**
  String get shareFailedTitle;

  /// Dialog after the previous save ended abnormally.
  ///
  /// In en, this message translates to:
  /// **'The last save didn\'t finish'**
  String get crashTitle;

  /// Body of that dialog.
  ///
  /// In en, this message translates to:
  /// **'The last save stopped partway. Keep the app open until saving finishes, and if this keeps happening, use fewer images.'**
  String get crashBody;

  /// Main message of the empty screen.
  ///
  /// In en, this message translates to:
  /// **'Choose at least {min, plural, one{{min} image or PDF} other{{min} images or PDFs}} to merge'**
  String emptyTitle(int min);

  /// Second line of the empty screen.
  ///
  /// In en, this message translates to:
  /// **'The layout direction is chosen automatically.'**
  String get emptyHint;

  /// Empty screen button that opens the photo picker.
  ///
  /// In en, this message translates to:
  /// **'Choose images'**
  String get pickImages;

  /// Empty screen button that opens the document picker.
  ///
  /// In en, this message translates to:
  /// **'Choose PDF'**
  String get pickPdf;

  /// Empty screen button that opens the camera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// Preview heading for original size: images stack from top to bottom. Automatic, not selectable.
  ///
  /// In en, this message translates to:
  /// **'Auto: vertical layout (top → bottom)'**
  String get autoDirectionVertical;

  /// Preview heading for original size: images run from left to right. Automatic, not selectable.
  ///
  /// In en, this message translates to:
  /// **'Auto: horizontal layout (left → right)'**
  String get autoDirectionHorizontal;

  /// Preview note for original size.
  ///
  /// In en, this message translates to:
  /// **'This is the PNG preview. The PNG has gray lines between images. The PDF saves one page per item, with no lines.'**
  String get previewNoteOriginal;

  /// Preview heading when a paper is chosen.
  ///
  /// In en, this message translates to:
  /// **'{pages, plural, one{{pages} page} other{{pages} pages}} · {perPaper} per sheet'**
  String previewSummary(int pages, int perPaper);

  /// Preview note when PNG joins pages side by side.
  ///
  /// In en, this message translates to:
  /// **'The PNG joins pages side by side, with gray lines between images. The PDF saves each page separately, with no lines.'**
  String get previewNoteHorizontal;

  /// Preview note when PNG joins pages top to bottom.
  ///
  /// In en, this message translates to:
  /// **'The PNG joins pages from top to bottom, with gray lines between images. The PDF saves each page separately, with no lines.'**
  String get previewNoteVertical;

  /// Paper choice meaning no paper, keep the image size.
  ///
  /// In en, this message translates to:
  /// **'Original size'**
  String get paperOriginal;

  /// Paper orientation. Short label on a segmented button.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get orientationPortrait;

  /// Paper orientation. Short label on a segmented button.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get orientationLandscape;

  /// Output in color. Short label on a segmented button.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorMode;

  /// Output in grayscale. Short label on a segmented button.
  ///
  /// In en, this message translates to:
  /// **'B&W'**
  String get grayscaleMode;

  /// Setting label: how many images go on one sheet of paper.
  ///
  /// In en, this message translates to:
  /// **'Images per sheet'**
  String get imagesPerPaper;

  /// Setting label: image scale within its cell, 100%, 50% or 30%.
  ///
  /// In en, this message translates to:
  /// **'Image size'**
  String get imageSize;

  /// Setting label: size of the white margin around pages and images, 0%, 3%, 5% or 10%. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get margin;

  /// List header, for example 3/30.
  ///
  /// In en, this message translates to:
  /// **'Selected {count}/{max}'**
  String selectedCount(int count, int max);

  /// List header button that opens the add menu.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addItems;

  /// Add menu item.
  ///
  /// In en, this message translates to:
  /// **'Choose photos'**
  String get pickPhotos;

  /// Add menu item.
  ///
  /// In en, this message translates to:
  /// **'Choose PDF files'**
  String get pickPdfFiles;

  /// List header button.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Bottom bar on devices with no default folder (Android 9 and older) when none has been chosen yet.
  ///
  /// In en, this message translates to:
  /// **'Save folder: chosen on first save'**
  String get folderNotChosen;

  /// Bottom bar with the current save folder name.
  ///
  /// In en, this message translates to:
  /// **'Save folder: {name}'**
  String folderCurrent(String name);

  /// Bottom bar link to choose another folder.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeFolder;

  /// Bottom bar hint when only one item is selected.
  ///
  /// In en, this message translates to:
  /// **'Choose at least {min, plural, one{{min} image} other{{min} images}} to save.'**
  String needMinImages(int min);

  /// Bottom bar button and progress title. format is PNG or PDF. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Save {format}'**
  String saveAs(String format);

  /// Bottom bar button, and the place shown for shared sessions in the history. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Progress title while sharing. format is PNG or PDF.
  ///
  /// In en, this message translates to:
  /// **'Share {format}'**
  String shareTitle(String format);

  /// Progress text.
  ///
  /// In en, this message translates to:
  /// **'Processing images {current}/{total}'**
  String processingImages(int current, int total);

  /// Progress text while encoding the file.
  ///
  /// In en, this message translates to:
  /// **'Creating the file'**
  String get buildingFile;

  /// Progress text just before the share sheet opens.
  ///
  /// In en, this message translates to:
  /// **'Opening the share sheet'**
  String get openingShare;

  /// Progress text while copying to the save folder.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get saving;

  /// Progress text after tapping cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get cancelling;

  /// Progress hint while encoding.
  ///
  /// In en, this message translates to:
  /// **'Large images can take tens of seconds.'**
  String get mayTakeLong;

  /// Progress hint.
  ///
  /// In en, this message translates to:
  /// **'Keep the app open until this finishes.'**
  String get keepAppOpen;

  /// Crop could not be applied.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t apply the crop. Please try again.'**
  String get errorApplyCrop;

  /// Crop screen title and the crop button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get cropTitle;

  /// Crop screen confirm button.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get cropApply;

  /// Crop screen button that resets to the whole image.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get cropSelectAll;

  /// Crop screen could not load the image.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the image.'**
  String get errorOpenImage;

  /// List item subtitle after cropping. width and height are pixels.
  ///
  /// In en, this message translates to:
  /// **'{width}×{height} (cropped)'**
  String croppedSize(int width, int height);

  /// List item button tooltip. The source file is not deleted.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get removeFromList;

  /// The history could not be read.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the history.'**
  String get errorLoadHistory;

  /// History heading when no sessions are in the period.
  ///
  /// In en, this message translates to:
  /// **'No saves in the last {days, plural, one{{days} day} other{{days} days}}.'**
  String historyRateEmpty(int days);

  /// History heading with the success rate.
  ///
  /// In en, this message translates to:
  /// **'Success rate in the last {days, plural, one{{days} day} other{{days} days}}: {percent}% ({success}/{total})'**
  String historyRate(int days, int percent, int success, int total);

  /// History with no sessions at all.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t saved anything yet.'**
  String get historyEmpty;

  /// Number of images in a history row.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} image} other{{count} images}}'**
  String imageCount(int count);

  /// Session status.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusRunning;

  /// Session status.
  ///
  /// In en, this message translates to:
  /// **'Succeeded'**
  String get statusSuccess;

  /// Session status.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// Session status.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// Session status: the app ended during a save.
  ///
  /// In en, this message translates to:
  /// **'Ended abnormally'**
  String get statusCrashed;

  /// Error unsupported_format when the image number is unknown.
  ///
  /// In en, this message translates to:
  /// **'There is an image in an unsupported format.'**
  String get errorUnsupportedFormat;

  /// Error unsupported_format. n is the position in the list, from 1.
  ///
  /// In en, this message translates to:
  /// **'Image {n} is in an unsupported format.'**
  String errorUnsupportedFormatAt(int n);

  /// Error corrupt_file when the image number is unknown.
  ///
  /// In en, this message translates to:
  /// **'There is a damaged image file.'**
  String get errorCorruptFile;

  /// Error corrupt_file. n is the position in the list, from 1.
  ///
  /// In en, this message translates to:
  /// **'The file for image {n} is damaged.'**
  String errorCorruptFileAt(int n);

  /// Error source_unavailable when the image number is unknown.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open an image. Please choose it again.'**
  String get errorSourceUnavailable;

  /// Error source_unavailable. n is the position in the list, from 1.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open image {n}. Please choose it again.'**
  String errorSourceUnavailableAt(int n);

  /// Error out_of_space.
  ///
  /// In en, this message translates to:
  /// **'There is not enough storage space.'**
  String get errorOutOfSpace;

  /// Error folder_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t access the save folder. Please choose a folder again.'**
  String get errorFolderUnavailable;

  /// Error output_too_large.
  ///
  /// In en, this message translates to:
  /// **'The result file is too large. Please use fewer images.'**
  String get errorOutputTooLarge;

  /// Error out_of_memory.
  ///
  /// In en, this message translates to:
  /// **'There is not enough memory. Please use fewer images.'**
  String get errorOutOfMemory;

  /// Error unknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get errorUnknown;

  /// Menu item and page title: information about the program.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// Menu item that opens the mail app. The Terms name this item, so keep both the same.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// Terms of use page title and the row that opens it.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsTitle;

  /// Label for the app version on the About page.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Dialog title when no mail app can open.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open a mail app'**
  String get noMailAppTitle;

  /// Dialog body above the address when no mail app can open.
  ///
  /// In en, this message translates to:
  /// **'Please send your feedback to this address.'**
  String get noMailAppBody;

  /// Button that copies the address.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get copyAddress;

  /// Snack bar after copying the address.
  ///
  /// In en, this message translates to:
  /// **'Address copied.'**
  String get addressCopied;

  /// Full terms of use. Translate faithfully: do not add, soften or reorder anything, and never add a sentence that makes the authors, copyright holders or distributors responsible or liable. Keep the numbering.
  ///
  /// In en, this message translates to:
  /// **'Last updated: November 5, 2026\n\n1. Acceptance\nBy installing or using Pic Merge (the \"App\"), you agree to these Terms. If you do not agree, do not use the App.\n\n2. License\nThe App is open-source software released under the MIT License, and you may use it under that license. Third-party components keep their own licenses.\n\n3. Your responsibilities\nYou alone are responsible for the files you process, save and share with the App, for having the rights to use them, and for complying with applicable laws. Keep your own backups of important files.\n\n4. Your data\nThe App processes files on your device and does not send them to any server. If you use Send feedback, your device\'s mail app creates the message, and what you send is handled by your mail provider.\n\n5. No warranty\nThe App is provided \"AS IS\" and \"AS AVAILABLE\", without warranty of any kind, express or implied, including merchantability, fitness for a particular purpose and non-infringement. There is no guarantee that it will be error-free or uninterrupted, or that its results will be accurate.\n\n6. Limitation of liability\nTo the maximum extent permitted by applicable law, the authors, copyright holders and distributors are not liable for any claim, damages or other liability, including loss of data, loss of profits and indirect or consequential damages, arising from or connected with the App or its use.\n\n7. No obligation to support\nThe authors have no obligation to provide support, updates or maintenance or to reply to feedback, and may change or stop the App at any time.\n\n8. App stores and platforms\nIf you obtained the App through an app store, that store\'s terms also apply to your use of the App.\n\n9. Changes\nThese Terms may change. If you keep using the App after a change, you accept the change.\n\n10. Language\nTranslations are provided for convenience. If they differ, the English version prevails.\n\nContact: yncdev@gmail.com'**
  String get termsBody;

  /// Privacy policy page title and the row that opens it.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyTitle;

  /// Row that opens the list of open-source licenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicenses;

  /// Full privacy policy. Translate faithfully: do not add promises or anything that takes on responsibility. Keep the address.
  ///
  /// In en, this message translates to:
  /// **'Last updated: November 6, 2026\n\nThis policy covers Pic Merge for Android and iOS and the Pic Merge Chrome extension (the \"App\").\n\nWhat the App does with your files\nThe App reads the images and PDFs you choose and combines them into a single file on your device. Your files are never sent to a server, and the App has no account, advertising or analytics.\n\nWhat is stored, and where\nEverything below stays on your device or in your browser:\n\n- Files you save, in the folder you use: the default folder or one you choose.\n- Recent history: for each save, the time, format, number of items, the result file\'s name, size and dimensions, the save folder\'s name, the layout direction, and the result. The mobile app also keeps each item\'s name, pixel size and file size and the scale applied, and keeps all of this in a local database until the App is deleted. The extension keeps the last 50 saves in browser storage.\n- Your chosen save folder, if you pick one instead of the default.\n- Temporary files made while processing. They are deleted when processing ends, when you remove the item from the list, at your next share, or the next time you start the App.\n\nOriginal images and their paths are not kept in the App. The App does not collect, sell or share any of this data, and the developer cannot access it. Deleting the App removes its stored data, except files you saved to a folder outside the App.\n\nAndroid app backup is turned off for the App. On iOS, your device\'s own backup, such as iCloud Backup, may include the App\'s data and the files in its folder, depending on your device settings.\n\nPermissions\n- Android: no internet, storage or camera permission is requested. Files are chosen through system pickers and photos are taken with the system camera app.\n- iOS: the system asks for your permission the first time you use the camera.\n- Chrome extension: no permissions are declared. If you choose a save folder, your browser asks for access to that folder.\n\nSending feedback\nThe mobile app\'s Send feedback option opens your device\'s mail app with the address and subject filled in. The subject includes the app version, device model and OS version, and you can edit it. Nothing is sent unless you send it yourself. Your message is then handled by your mail provider, and the developer receives what you send.\n\nOther services\nIf you share a file, your device\'s share sheet or the app you choose handles it. If you obtained the App from an app store, that store\'s own privacy terms apply to the store.\n\nChanges\nThis policy may change. Changes are published in this document.\n\nContact\nyncdev@gmail.com'**
  String get privacyBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'id',
    'ja',
    'ko',
    'pt',
    'ru',
    'th',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

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
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
