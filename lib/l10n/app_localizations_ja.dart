// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Pic Merge';

  @override
  String get appSubtitle => '画像結合';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'キャンセル';

  @override
  String get clearList => 'クリア';

  @override
  String get recentHistory => '最近の履歴';

  @override
  String get errorLoadPhotos => '写真を読み込めませんでした。もう一度お試しください。';

  @override
  String get errorCameraUnavailable => 'カメラを使用できません。';

  @override
  String get errorLoadPdfs => 'PDFを読み込めませんでした。もう一度お試しください。';

  @override
  String maxImagesReached(int max) {
    return '最大$max枚まで追加できます。';
  }

  @override
  String unsupportedFilesExcluded(int count) {
    return '$count個のファイルは対応していない形式のため除外しました。';
  }

  @override
  String overLimitAdded(int max, int added) {
    return '追加できるのは最大$max枚のため、$added枚だけ追加しました。';
  }

  @override
  String get clearConfirm => '選択した画像をすべてリストから外しますか？\n元の写真は削除されません。';

  @override
  String get folderDialogTitle => '保存先フォルダの選択';

  @override
  String get folderDialogBodyAndroid =>
      'Documents などのフォルダか、新しく作成したフォルダを選んでください。\n\n内部ストレージの最上位、Download フォルダ自体、Android/data フォルダは選択できません。';

  @override
  String get pickFolder => 'フォルダを選択';

  @override
  String useDefaultFolder(String name) {
    return '既定のフォルダを使う ($name)';
  }

  @override
  String get pickOtherFolder => '別のフォルダを選択';

  @override
  String get errorPickFolder => 'フォルダを選択できません。もう一度お試しください。';

  @override
  String savedTo(String folder, String file) {
    return '保存しました: $folder/$file';
  }

  @override
  String get saveCancelled => '保存をキャンセルしました。';

  @override
  String get saveFailedTitle => '保存できませんでした';

  @override
  String get shareFormatPrompt => 'メールやメッセージアプリなどで送るファイル形式を選んでください。';

  @override
  String shareAs(String format) {
    return '$formatで共有';
  }

  @override
  String get shareCancelled => '共有をキャンセルしました。';

  @override
  String get shareFailedTitle => '共有できませんでした';

  @override
  String get crashTitle => '前回の保存が完了していません';

  @override
  String get crashBody =>
      '前回の保存が途中で終了しました。保存が終わるまでアプリを開いたままにし、繰り返す場合は画像の数を減らしてください。';

  @override
  String emptyTitle(int min) {
    return '結合する画像またはPDFを$min枚以上選んでください';
  }

  @override
  String get emptyHint => '配置方向は自動で決まります。';

  @override
  String get pickImages => '画像を選択';

  @override
  String get pickPdf => 'PDFを選択';

  @override
  String get takePhoto => 'カメラで撮影';

  @override
  String get autoDirectionVertical => '自動: 縦に配置 (上 → 下)';

  @override
  String get autoDirectionHorizontal => '自動: 横に配置 (左 → 右)';

  @override
  String get previewNoteOriginal =>
      'PNGのプレビューです。PNGでは画像の間に灰色の線が入ります。PDFは項目ごとに1ページで保存され、線は入りません。';

  @override
  String previewSummary(int pages, int perPaper) {
    return '全$pagesページ · 用紙1枚に$perPaper枚';
  }

  @override
  String get previewNoteHorizontal =>
      'PNGはページを横につなげ、画像の間に灰色の線を入れます。PDFはページごとに保存され、線は入りません。';

  @override
  String get previewNoteVertical =>
      'PNGはページを縦につなげ、画像の間に灰色の線を入れます。PDFはページごとに保存され、線は入りません。';

  @override
  String get paperOriginal => '元のサイズ';

  @override
  String get orientationPortrait => '縦';

  @override
  String get orientationLandscape => '横';

  @override
  String get colorMode => 'カラー';

  @override
  String get grayscaleMode => '白黒';

  @override
  String get imagesPerPaper => '用紙1枚の画像数';

  @override
  String get imageSize => '画像サイズ';

  @override
  String get margin => '余白';

  @override
  String selectedCount(int count, int max) {
    return '選択 $count/$max';
  }

  @override
  String get addItems => '追加';

  @override
  String get pickPhotos => '写真を選択';

  @override
  String get pickPdfFiles => 'PDFファイルを選択';

  @override
  String get camera => 'カメラ';

  @override
  String get folderNotChosen => '保存先フォルダ: 初回保存時に選びます';

  @override
  String folderCurrent(String name) {
    return '保存先フォルダ: $name';
  }

  @override
  String get changeFolder => '変更';

  @override
  String needMinImages(int min) {
    return '保存するには$min枚以上選んでください。';
  }

  @override
  String saveAs(String format) {
    return '$formatで保存';
  }

  @override
  String get share => '共有';

  @override
  String shareTitle(String format) {
    return '$formatを共有';
  }

  @override
  String processingImages(int current, int total) {
    return '画像を処理中 $current/$total';
  }

  @override
  String get buildingFile => 'ファイルを作成中';

  @override
  String get openingShare => '共有画面を開いています';

  @override
  String get saving => '保存中';

  @override
  String get cancelling => 'キャンセル中…';

  @override
  String get mayTakeLong => '画像が大きいと数十秒かかることがあります。';

  @override
  String get keepAppOpen => '終わるまでアプリを開いたままにしてください。';

  @override
  String get errorApplyCrop => 'トリミングを適用できませんでした。もう一度お試しください。';

  @override
  String get cropTitle => 'トリミング';

  @override
  String get cropApply => '適用';

  @override
  String get cropSelectAll => 'すべて選択';

  @override
  String get errorOpenImage => '画像を開けません。';

  @override
  String croppedSize(int width, int height) {
    return '$width×$height (トリミング済み)';
  }

  @override
  String get removeFromList => 'リストから外す';

  @override
  String get errorLoadHistory => '履歴を読み込めませんでした。';

  @override
  String historyRateEmpty(int days) {
    return '過去$days日間の保存履歴はありません。';
  }

  @override
  String historyRate(int days, int percent, int success, int total) {
    return '過去$days日間の成功率 $percent% ($success/$total)';
  }

  @override
  String get historyEmpty => 'まだ保存したことがありません。';

  @override
  String imageCount(int count) {
    return '$count枚';
  }

  @override
  String get statusRunning => '実行中';

  @override
  String get statusSuccess => '成功';

  @override
  String get statusFailed => '失敗';

  @override
  String get statusCancelled => 'キャンセル';

  @override
  String get statusCrashed => '異常終了';

  @override
  String get errorUnsupportedFormat => '対応していない形式の画像があります。';

  @override
  String errorUnsupportedFormatAt(int n) {
    return '$n番目の画像は対応していない形式です。';
  }

  @override
  String get errorCorruptFile => '破損した画像ファイルがあります。';

  @override
  String errorCorruptFileAt(int n) {
    return '$n番目の画像ファイルが破損しています。';
  }

  @override
  String get errorSourceUnavailable => '画像を開けません。もう一度選んでください。';

  @override
  String errorSourceUnavailableAt(int n) {
    return '$n番目の画像を開けません。もう一度選んでください。';
  }

  @override
  String get errorOutOfSpace => 'ストレージの空き容量が不足しています。';

  @override
  String get errorFolderUnavailable => '保存先フォルダにアクセスできません。フォルダを選び直してください。';

  @override
  String get errorOutputTooLarge => '結果ファイルが大きすぎます。画像の数を減らしてください。';

  @override
  String get errorOutOfMemory => 'メモリが不足しています。画像の数を減らしてください。';

  @override
  String get errorUnknown => '不明なエラーが発生しました。';

  @override
  String get aboutTitle => 'アプリ情報';

  @override
  String get sendFeedback => '意見を送る';

  @override
  String get termsTitle => '利用規約';

  @override
  String get version => 'バージョン';

  @override
  String get noMailAppTitle => 'メールアプリを開けません';

  @override
  String get noMailAppBody => 'このアドレスにご意見をお送りください。';

  @override
  String get copyAddress => 'アドレスをコピー';

  @override
  String get addressCopied => 'アドレスをコピーしました。';

  @override
  String get termsBody =>
      '最終更新日: 2026年11月5日\n\n1. 同意\nPic Merge(以下「本アプリ」)をインストールまたは使用すると、本規約に同意したものとみなされます。同意しない場合は、本アプリを使用しないでください。\n\n2. ライセンス\n本アプリは MIT License で公開されたオープンソースソフトウェアであり、このライセンスに従って使用できます。第三者のコンポーネントにはそれぞれのライセンスが適用されます。\n\n3. 利用者の責任\n本アプリで処理、保存、共有するファイル、それらを使用する権利、および適用される法令の遵守については、利用者のみが責任を負います。重要なファイルはご自身でバックアップしてください。\n\n4. 利用者のデータ\n本アプリはファイルを端末内で処理し、どのサーバーにも送信しません。「意見を送る」を使用すると、端末のメールアプリでメッセージが作成され、送信した内容は利用者のメールサービスが取り扱います。\n\n5. 保証の否認\n本アプリは「現状のまま」「提供可能な範囲で」提供され、商品性、特定目的への適合性、非侵害を含め、明示または黙示を問わず、いかなる保証も行いません。エラーや中断がないこと、または結果が正確であることは保証しません。\n\n6. 責任の制限\n適用される法令で認められる最大限の範囲で、著作者、著作権者および配布者は、本アプリまたはその使用から生じる、またはそれらに関連するいかなる請求、損害その他の責任(データの損失、利益の損失、間接的損害および結果的損害を含む)についても責任を負いません。\n\n7. サポート義務の不存在\n著作者は、サポート、アップデート、保守を提供する義務や、意見に返信する義務を負わず、いつでも本アプリを変更または中止できます。\n\n8. アプリストアとプラットフォーム\n本アプリをアプリストアから入手した場合は、そのストアの規約も本アプリの使用に適用されます。\n\n9. 変更\n本規約は変更されることがあります。変更後も本アプリを使用し続けた場合、その変更に同意したものとみなされます。\n\n10. 言語\n翻訳は便宜のために提供しています。内容が異なる場合は、英語版が優先します。\n\nお問い合わせ: yncdev@gmail.com';

  @override
  String get privacyTitle => 'プライバシーポリシー';

  @override
  String get openSourceLicenses => 'オープンソースライセンス';

  @override
  String get privacyBody =>
      '最終更新日: 2026年11月6日\n\nこのポリシーは、Android および iOS 向けの Pic Merge と Pic Merge Chrome 拡張機能(以下「本アプリ」)を対象とします。\n\n本アプリがファイルに対して行うこと\n本アプリは、利用者が選んだ画像と PDF を読み込み、端末上で 1 つのファイルに結合します。ファイルがサーバーに送信されることはなく、本アプリにはアカウント、広告、分析機能はありません。\n\n保存される情報とその場所\n以下はすべて、利用者の端末またはブラウザ内にとどまります。\n\n- 保存したファイル: 使用するフォルダ(既定のフォルダまたは利用者が選んだフォルダ)に保存されます。\n- 最近の履歴: 保存ごとの日時、形式、項目数、結果ファイルの名前・サイズ・寸法、保存フォルダの名前、配置方向、結果。モバイルアプリは各項目の名前、ピクセルサイズ、ファイルサイズ、適用された倍率も保持し、これらすべてを本アプリが削除されるまでローカルデータベースに保持します。拡張機能は直近 50 件の保存をブラウザのストレージに保持します。\n- 選択した保存フォルダ: 既定のフォルダではなく別のフォルダを選んだ場合。\n- 一時ファイル: 処理中に作成されます。処理が終わったとき、リストから項目を削除したとき、次回の共有時、または次回本アプリを起動したときに削除されます。\n\n元の画像とそのパスは本アプリ内に保持されません。本アプリはこれらのデータを収集、販売、共有せず、開発者がアクセスすることもできません。本アプリを削除すると、保存されたデータも削除されます。ただし、本アプリの外のフォルダに保存したファイルは除きます。\n\n本アプリでは Android のアプリバックアップをオフにしています。iOS では、端末の設定によって、iCloud バックアップなど端末自体のバックアップに本アプリのデータと本アプリのフォルダ内のファイルが含まれることがあります。\n\n権限\n- Android: インターネット、ストレージ、カメラの権限は要求しません。ファイルはシステムの選択画面で選び、写真はシステムのカメラアプリで撮影します。\n- iOS: 初めてカメラを使用するときに、システムが許可を求めます。\n- Chrome 拡張機能: 権限は宣言していません。保存フォルダを選ぶと、ブラウザがそのフォルダへのアクセスの許可を求めます。\n\n意見の送信\nモバイルアプリの「意見を送る」は、宛先と件名が入力された状態で端末のメールアプリを開きます。件名にはアプリのバージョン、端末のモデル、OS のバージョンが含まれ、編集できます。利用者が自分で送信しない限り、何も送信されません。送信したメッセージは利用者のメールサービスが取り扱い、開発者は送信された内容を受け取ります。\n\nその他のサービス\nファイルを共有する場合は、端末の共有シートまたは利用者が選んだアプリがそれを取り扱います。本アプリをアプリストアから入手した場合、そのストアについてはストア独自のプライバシー規約が適用されます。\n\n変更\nこのポリシーは変更されることがあります。変更内容はこの文書に掲載します。\n\nお問い合わせ\nyncdev@gmail.com';
}
