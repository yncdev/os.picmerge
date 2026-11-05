// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Pic Merge';

  @override
  String get appSubtitle => 'Bilder zusammenfügen';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get clearList => 'Leeren';

  @override
  String get recentHistory => 'Letzte Vorgänge';

  @override
  String get errorLoadPhotos =>
      'Die Fotos konnten nicht geladen werden. Bitte versuche es erneut.';

  @override
  String get errorCameraUnavailable =>
      'Die Kamera kann nicht verwendet werden.';

  @override
  String get errorLoadPdfs =>
      'Das PDF konnte nicht geladen werden. Bitte versuche es erneut.';

  @override
  String maxImagesReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$max Bilder',
      one: '$max Bild',
    );
    return 'Du kannst bis zu $_temp0 hinzufügen.';
  }

  @override
  String unsupportedFilesExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Dateien wurden ausgelassen, weil ihr Format nicht unterstützt wird.',
      one:
          '$count Datei wurde ausgelassen, weil ihr Format nicht unterstützt wird.',
    );
    return '$_temp0';
  }

  @override
  String overLimitAdded(int max, int added) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$max Bilder',
      one: '$max Bild',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'wurden nur $added hinzugefügt',
      one: 'wurde nur $added hinzugefügt',
    );
    return 'Du kannst bis zu $_temp0 hinzufügen, daher $_temp1.';
  }

  @override
  String get clearConfirm =>
      'Alle ausgewählten Bilder aus der Liste entfernen?\nDie Originalfotos werden nicht gelöscht.';

  @override
  String get folderDialogTitle => 'Speicherordner auswählen';

  @override
  String get folderDialogBodyAndroid =>
      'Wähle einen Ordner wie Documents oder einen neu erstellten Ordner.\n\nDie oberste Ebene des internen Speichers, der Ordner Download selbst und der Ordner Android/data können nicht gewählt werden.';

  @override
  String get pickFolder => 'Ordner auswählen';

  @override
  String useDefaultFolder(String name) {
    return 'Standardordner verwenden ($name)';
  }

  @override
  String get pickOtherFolder => 'Anderen Ordner auswählen';

  @override
  String get errorPickFolder =>
      'Der Ordner konnte nicht ausgewählt werden. Bitte versuche es erneut.';

  @override
  String savedTo(String folder, String file) {
    return 'Gespeichert: $folder/$file';
  }

  @override
  String get saveCancelled => 'Speichern abgebrochen.';

  @override
  String get saveFailedTitle => 'Speichern fehlgeschlagen';

  @override
  String get shareFormatPrompt =>
      'Wähle das Dateiformat zum Senden per E-Mail, Messenger und mehr.';

  @override
  String shareAs(String format) {
    return 'Als $format teilen';
  }

  @override
  String get shareCancelled => 'Teilen abgebrochen.';

  @override
  String get shareFailedTitle => 'Teilen fehlgeschlagen';

  @override
  String get crashTitle => 'Das letzte Speichern wurde nicht abgeschlossen';

  @override
  String get crashBody =>
      'Das letzte Speichern wurde unterbrochen. Lass die App geöffnet, bis das Speichern abgeschlossen ist, und verwende weniger Bilder, falls es wieder passiert.';

  @override
  String emptyTitle(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: '$min Bilder oder PDFs',
      one: '$min Bild oder PDF',
    );
    return 'Wähle mindestens $_temp0 zum Zusammenfügen';
  }

  @override
  String get emptyHint => 'Die Anordnung wird automatisch festgelegt.';

  @override
  String get pickImages => 'Bilder auswählen';

  @override
  String get pickPdf => 'PDF auswählen';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get autoDirectionVertical =>
      'Automatisch: vertikale Anordnung (oben → unten)';

  @override
  String get autoDirectionHorizontal =>
      'Automatisch: horizontale Anordnung (links → rechts)';

  @override
  String get previewNoteOriginal =>
      'Dies ist die PNG-Vorschau. Das PNG enthält graue Linien zwischen den Bildern. Das PDF speichert pro Eintrag eine Seite, ohne Linien.';

  @override
  String previewSummary(int pages, int perPaper) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pages Seiten',
      one: '$pages Seite',
    );
    return '$_temp0 insgesamt · $perPaper pro Blatt';
  }

  @override
  String get previewNoteHorizontal =>
      'Das PNG fügt die Seiten nebeneinander zusammen, mit grauen Linien zwischen den Bildern. Das PDF speichert jede Seite einzeln, ohne Linien.';

  @override
  String get previewNoteVertical =>
      'Das PNG fügt die Seiten untereinander zusammen, mit grauen Linien zwischen den Bildern. Das PDF speichert jede Seite einzeln, ohne Linien.';

  @override
  String get paperOriginal => 'Originalgröße';

  @override
  String get orientationPortrait => 'Hochformat';

  @override
  String get orientationLandscape => 'Querformat';

  @override
  String get colorMode => 'Farbe';

  @override
  String get grayscaleMode => 'S/W';

  @override
  String get imagesPerPaper => 'Bilder pro Blatt';

  @override
  String get imageSize => 'Bildgröße';

  @override
  String get margin => 'Rand';

  @override
  String selectedCount(int count, int max) {
    return 'Auswahl $count/$max';
  }

  @override
  String get addItems => 'Hinzufügen';

  @override
  String get pickPhotos => 'Fotos auswählen';

  @override
  String get pickPdfFiles => 'PDF-Dateien auswählen';

  @override
  String get camera => 'Kamera';

  @override
  String get folderNotChosen => 'Ordner: beim ersten Speichern';

  @override
  String folderCurrent(String name) {
    return 'Ordner: $name';
  }

  @override
  String get changeFolder => 'Ändern';

  @override
  String needMinImages(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: '$min Bilder',
      one: '$min Bild',
    );
    return 'Wähle mindestens $_temp0 zum Speichern.';
  }

  @override
  String saveAs(String format) {
    return '$format speichern';
  }

  @override
  String get share => 'Teilen';

  @override
  String shareTitle(String format) {
    return '$format teilen';
  }

  @override
  String processingImages(int current, int total) {
    return 'Bilder werden verarbeitet $current/$total';
  }

  @override
  String get buildingFile => 'Datei wird erstellt';

  @override
  String get openingShare => 'Teilen-Fenster wird geöffnet';

  @override
  String get saving => 'Wird gespeichert';

  @override
  String get cancelling => 'Wird abgebrochen…';

  @override
  String get mayTakeLong =>
      'Große Bilder können einige Dutzend Sekunden dauern.';

  @override
  String get keepAppOpen =>
      'Lass die App geöffnet, bis der Vorgang abgeschlossen ist.';

  @override
  String get errorApplyCrop =>
      'Der Zuschnitt konnte nicht angewendet werden. Bitte versuche es erneut.';

  @override
  String get cropTitle => 'Zuschneiden';

  @override
  String get cropApply => 'Anwenden';

  @override
  String get cropSelectAll => 'Alles auswählen';

  @override
  String get errorOpenImage => 'Das Bild kann nicht geöffnet werden.';

  @override
  String croppedSize(int width, int height) {
    return '$width×$height (zugeschnitten)';
  }

  @override
  String get removeFromList => 'Aus der Liste entfernen';

  @override
  String get errorLoadHistory => 'Der Verlauf konnte nicht geladen werden.';

  @override
  String historyRateEmpty(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'in den letzten $days Tagen',
      one: 'am letzten Tag',
    );
    return 'Keine Speichervorgänge $_temp0.';
  }

  @override
  String historyRate(int days, int percent, int success, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'der letzten $days Tage',
      one: 'am letzten Tag',
    );
    return 'Erfolgsquote $_temp0: $percent% ($success/$total)';
  }

  @override
  String get historyEmpty => 'Es wurde noch nichts gespeichert.';

  @override
  String imageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bilder',
      one: '$count Bild',
    );
    return '$_temp0';
  }

  @override
  String get statusRunning => 'Läuft';

  @override
  String get statusSuccess => 'Erfolgreich';

  @override
  String get statusFailed => 'Fehlgeschlagen';

  @override
  String get statusCancelled => 'Abgebrochen';

  @override
  String get statusCrashed => 'Unerwartet beendet';

  @override
  String get errorUnsupportedFormat =>
      'Ein Bild hat ein nicht unterstütztes Format.';

  @override
  String errorUnsupportedFormatAt(int n) {
    return 'Bild $n hat ein nicht unterstütztes Format.';
  }

  @override
  String get errorCorruptFile => 'Eine Bilddatei ist beschädigt.';

  @override
  String errorCorruptFileAt(int n) {
    return 'Die Datei von Bild $n ist beschädigt.';
  }

  @override
  String get errorSourceUnavailable =>
      'Ein Bild kann nicht geöffnet werden. Bitte wähle es erneut aus.';

  @override
  String errorSourceUnavailableAt(int n) {
    return 'Bild $n kann nicht geöffnet werden. Bitte wähle es erneut aus.';
  }

  @override
  String get errorOutOfSpace => 'Nicht genügend Speicherplatz.';

  @override
  String get errorFolderUnavailable =>
      'Auf den Speicherordner kann nicht zugegriffen werden. Bitte wähle erneut einen Ordner aus.';

  @override
  String get errorOutputTooLarge =>
      'Die Ergebnisdatei ist zu groß. Bitte verwende weniger Bilder.';

  @override
  String get errorOutOfMemory =>
      'Nicht genügend Arbeitsspeicher. Bitte verwende weniger Bilder.';

  @override
  String get errorUnknown => 'Ein unbekannter Fehler ist aufgetreten.';

  @override
  String get aboutTitle => 'Über die App';

  @override
  String get sendFeedback => 'Feedback senden';

  @override
  String get termsTitle => 'Nutzungsbedingungen';

  @override
  String get version => 'Version';

  @override
  String get noMailAppTitle => 'Mail-App kann nicht geöffnet werden';

  @override
  String get noMailAppBody => 'Bitte sende dein Feedback an diese Adresse.';

  @override
  String get copyAddress => 'Adresse kopieren';

  @override
  String get addressCopied => 'Adresse kopiert.';

  @override
  String get termsBody =>
      'Zuletzt aktualisiert: 5. November 2026\n\n1. Zustimmung\nMit der Installation oder Nutzung von Pic Merge (die „App“) stimmst du diesen Bedingungen zu. Wenn du nicht zustimmst, nutze die App nicht.\n\n2. Lizenz\nDie App ist Open-Source-Software, die unter der MIT License veröffentlicht wird, und du darfst sie gemäß dieser Lizenz nutzen. Komponenten Dritter unterliegen ihren eigenen Lizenzen.\n\n3. Deine Verantwortung\nDu allein bist verantwortlich für die Dateien, die du mit der App verarbeitest, speicherst und teilst, dafür, dass du die Rechte zu ihrer Nutzung hast, und für die Einhaltung der geltenden Gesetze. Erstelle eigene Sicherungen wichtiger Dateien.\n\n4. Deine Daten\nDie App verarbeitet Dateien auf deinem Gerät und sendet sie an keinen Server. Wenn du Feedback senden verwendest, erstellt die Mail-App deines Geräts die Nachricht, und was du sendest, wird von deinem E-Mail-Anbieter verarbeitet.\n\n5. Keine Gewährleistung\nDie App wird „WIE BESEHEN“ und „WIE VERFÜGBAR“ bereitgestellt, ohne Gewährleistung jeglicher Art, weder ausdrücklich noch stillschweigend, einschließlich Marktgängigkeit, Eignung für einen bestimmten Zweck und Nichtverletzung von Rechten. Es gibt keine Garantie, dass sie fehlerfrei oder ununterbrochen funktioniert oder dass ihre Ergebnisse korrekt sind.\n\n6. Haftungsbeschränkung\nSoweit nach geltendem Recht maximal zulässig, haften die Autoren, Urheberrechtsinhaber und Vertreiber nicht für Ansprüche, Schäden oder sonstige Haftung, einschließlich Datenverlust, entgangenem Gewinn sowie indirekter Schäden und Folgeschäden, die aus der App oder ihrer Nutzung entstehen oder damit zusammenhängen.\n\n7. Keine Supportpflicht\nDie Autoren sind nicht verpflichtet, Support, Updates oder Wartung bereitzustellen oder auf Feedback zu antworten, und können die App jederzeit ändern oder einstellen.\n\n8. App-Stores und Plattformen\nWenn du die App über einen App-Store erhalten hast, gelten für deine Nutzung der App auch die Bedingungen dieses Stores.\n\n9. Änderungen\nDiese Bedingungen können sich ändern. Wenn du die App nach einer Änderung weiter nutzt, akzeptierst du die Änderung.\n\n10. Sprache\nÜbersetzungen werden der Einfachheit halber bereitgestellt. Bei Abweichungen gilt die englische Fassung.\n\nKontakt: yncdev@gmail.com';

  @override
  String get privacyTitle => 'Datenschutzerklärung';

  @override
  String get openSourceLicenses => 'Open-Source-Lizenzen';

  @override
  String get privacyBody =>
      'Zuletzt aktualisiert: 6. November 2026\n\nDiese Richtlinie gilt für Pic Merge für Android und iOS und die Chrome-Erweiterung Pic Merge (die „App“).\n\nWas die App mit deinen Dateien macht\nDie App liest die Bilder und PDFs, die du auswählst, und fügt sie auf deinem Gerät zu einer einzigen Datei zusammen. Deine Dateien werden nie an einen Server gesendet, und die App hat kein Konto, keine Werbung und keine Analyse.\n\nWas gespeichert wird und wo\nAlles Folgende bleibt auf deinem Gerät oder in deinem Browser:\n\n- Dateien, die du speicherst, in dem von dir verwendeten Ordner: dem Standardordner oder einem von dir gewählten.\n- Letzte Vorgänge: für jedes Speichern Zeit, Format, Anzahl der Elemente, Name, Größe und Abmessungen der Ergebnisdatei, Name des Speicherordners, Anordnungsrichtung und Ergebnis. Die mobile App speichert außerdem Name, Pixelgröße und Dateigröße jedes Elements sowie die angewendete Skalierung und bewahrt all dies in einer lokalen Datenbank auf, bis die App gelöscht wird. Die Erweiterung bewahrt die letzten 50 Speichervorgänge im Browserspeicher auf.\n- Dein gewählter Speicherordner, wenn du einen anstelle des Standardordners auswählst.\n- Temporäre Dateien, die während der Verarbeitung entstehen. Sie werden gelöscht, wenn die Verarbeitung endet, wenn du das Element aus der Liste entfernst, beim nächsten Teilen oder beim nächsten Start der App.\n\nOriginalbilder und ihre Pfade werden nicht in der App aufbewahrt. Die App erfasst, verkauft oder teilt keine dieser Daten, und der Entwickler kann nicht darauf zugreifen. Beim Löschen der App werden ihre gespeicherten Daten entfernt, außer Dateien, die du in einem Ordner außerhalb der App gespeichert hast.\n\nDie Android-App-Sicherung ist für die App deaktiviert. Unter iOS kann die eigene Sicherung deines Geräts, z. B. die iCloud-Sicherung, je nach Geräteeinstellungen die Daten der App und die Dateien in ihrem Ordner enthalten.\n\nBerechtigungen\n- Android: Es werden keine Internet-, Speicher- oder Kameraberechtigungen angefordert. Dateien werden über die Systemauswahl ausgewählt und Fotos mit der Kamera-App des Systems aufgenommen.\n- iOS: Das System fragt dich bei der ersten Verwendung der Kamera um Erlaubnis.\n- Chrome-Erweiterung: Es sind keine Berechtigungen deklariert. Wenn du einen Speicherordner auswählst, fragt dein Browser nach dem Zugriff auf diesen Ordner.\n\nFeedback senden\nDie Option Feedback senden der mobilen App öffnet die Mail-App deines Geräts mit bereits eingetragener Adresse und eingetragenem Betreff. Der Betreff enthält die App-Version, das Gerätemodell und die Betriebssystemversion, und du kannst ihn bearbeiten. Es wird nichts gesendet, solange du es nicht selbst sendest. Deine Nachricht wird dann von deinem E-Mail-Anbieter verarbeitet, und der Entwickler erhält, was du sendest.\n\nAndere Dienste\nWenn du eine Datei teilst, übernimmt dies das Teilen-Menü deines Geräts oder die von dir gewählte App. Wenn du die App aus einem App-Store bezogen hast, gelten für den Store dessen eigene Datenschutzbedingungen.\n\nÄnderungen\nDiese Richtlinie kann sich ändern. Änderungen werden in diesem Dokument veröffentlicht.\n\nKontakt\nyncdev@gmail.com';
}
