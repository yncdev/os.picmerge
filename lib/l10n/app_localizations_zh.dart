// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Pic Merge';

  @override
  String get appSubtitle => '图片合并';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get clearList => '清空';

  @override
  String get recentHistory => '最近记录';

  @override
  String get errorLoadPhotos => '无法加载照片，请重试。';

  @override
  String get errorCameraUnavailable => '无法使用相机。';

  @override
  String get errorLoadPdfs => '无法加载 PDF，请重试。';

  @override
  String maxImagesReached(int max) {
    return '最多可添加 $max 张。';
  }

  @override
  String unsupportedFilesExcluded(int count) {
    return '$count 个文件的格式不受支持，已排除。';
  }

  @override
  String overLimitAdded(int max, int added) {
    return '最多可添加 $max 张，因此只添加了 $added 张。';
  }

  @override
  String get clearConfirm => '要将所选图片全部从列表中移除吗？\n原始照片不会被删除。';

  @override
  String get folderDialogTitle => '选择保存文件夹';

  @override
  String get folderDialogBodyAndroid =>
      '请选择 Documents 等文件夹或新建的文件夹。\n\n无法选择内部存储根目录、Download 文件夹本身和 Android/data 文件夹。';

  @override
  String get pickFolder => '选择文件夹';

  @override
  String useDefaultFolder(String name) {
    return '使用默认文件夹（$name）';
  }

  @override
  String get pickOtherFolder => '选择其他文件夹';

  @override
  String get errorPickFolder => '无法选择文件夹，请重试。';

  @override
  String savedTo(String folder, String file) {
    return '已保存：$folder/$file';
  }

  @override
  String get saveCancelled => '已取消保存。';

  @override
  String get saveFailedTitle => '保存失败';

  @override
  String get shareFormatPrompt => '请选择要通过电子邮件、聊天应用等发送的文件格式。';

  @override
  String shareAs(String format) {
    return '以 $format 分享';
  }

  @override
  String get shareCancelled => '已取消分享。';

  @override
  String get shareFailedTitle => '分享失败';

  @override
  String get crashTitle => '上次保存未完成';

  @override
  String get crashBody => '上次保存中途结束。请在保存完成前保持应用开启；如果仍然出现，请减少图片数量。';

  @override
  String emptyTitle(int min) {
    return '请选择至少 $min 张要合并的图片或 PDF';
  }

  @override
  String get emptyHint => '排列方向会自动确定。';

  @override
  String get pickImages => '选择图片';

  @override
  String get pickPdf => '选择 PDF';

  @override
  String get takePhoto => '用相机拍摄';

  @override
  String get autoDirectionVertical => '自动：纵向排列（上 → 下）';

  @override
  String get autoDirectionHorizontal => '自动：横向排列（左 → 右）';

  @override
  String get previewNoteOriginal =>
      '这是 PNG 预览。PNG 的图片之间有灰色线条。PDF 每个项目保存为一页，没有线条。';

  @override
  String previewSummary(int pages, int perPaper) {
    return '共 $pages 页 · 每张纸 $perPaper 张';
  }

  @override
  String get previewNoteHorizontal =>
      'PNG 会将页面左右相连，并在图片之间加入灰色线条。PDF 按页保存，没有线条。';

  @override
  String get previewNoteVertical => 'PNG 会将页面上下相连，并在图片之间加入灰色线条。PDF 按页保存，没有线条。';

  @override
  String get paperOriginal => '原始大小';

  @override
  String get orientationPortrait => '纵向';

  @override
  String get orientationLandscape => '横向';

  @override
  String get colorMode => '彩色';

  @override
  String get grayscaleMode => '黑白';

  @override
  String get imagesPerPaper => '每张纸的图片数';

  @override
  String get imageSize => '图片大小';

  @override
  String get margin => '边距';

  @override
  String selectedCount(int count, int max) {
    return '已选 $count/$max';
  }

  @override
  String get addItems => '添加';

  @override
  String get pickPhotos => '选择照片';

  @override
  String get pickPdfFiles => '选择 PDF 文件';

  @override
  String get camera => '相机';

  @override
  String get folderNotChosen => '保存文件夹：首次保存时选择';

  @override
  String folderCurrent(String name) {
    return '保存文件夹：$name';
  }

  @override
  String get changeFolder => '更改';

  @override
  String needMinImages(int min) {
    return '至少选择 $min 张才能保存。';
  }

  @override
  String saveAs(String format) {
    return '保存 $format';
  }

  @override
  String get share => '分享';

  @override
  String shareTitle(String format) {
    return '分享 $format';
  }

  @override
  String processingImages(int current, int total) {
    return '正在处理图片 $current/$total';
  }

  @override
  String get buildingFile => '正在生成文件';

  @override
  String get openingShare => '正在打开分享窗口';

  @override
  String get saving => '正在保存';

  @override
  String get cancelling => '正在取消…';

  @override
  String get mayTakeLong => '图片较大时可能需要几十秒。';

  @override
  String get keepAppOpen => '完成前请保持应用开启。';

  @override
  String get errorApplyCrop => '无法应用裁剪，请重试。';

  @override
  String get cropTitle => '裁剪';

  @override
  String get cropApply => '应用';

  @override
  String get cropSelectAll => '全选';

  @override
  String get errorOpenImage => '无法打开图片。';

  @override
  String croppedSize(int width, int height) {
    return '$width×$height（已裁剪）';
  }

  @override
  String get removeFromList => '从列表中移除';

  @override
  String get errorLoadHistory => '无法加载记录。';

  @override
  String historyRateEmpty(int days) {
    return '最近 $days 天没有保存记录。';
  }

  @override
  String historyRate(int days, int percent, int success, int total) {
    return '最近 $days 天成功率 $percent%（$success/$total）';
  }

  @override
  String get historyEmpty => '还没有保存过。';

  @override
  String imageCount(int count) {
    return '$count 张';
  }

  @override
  String get statusRunning => '进行中';

  @override
  String get statusSuccess => '成功';

  @override
  String get statusFailed => '失败';

  @override
  String get statusCancelled => '已取消';

  @override
  String get statusCrashed => '异常结束';

  @override
  String get errorUnsupportedFormat => '有图片的格式不受支持。';

  @override
  String errorUnsupportedFormatAt(int n) {
    return '第 $n 张图片的格式不受支持。';
  }

  @override
  String get errorCorruptFile => '有已损坏的图片文件。';

  @override
  String errorCorruptFileAt(int n) {
    return '第 $n 张图片的文件已损坏。';
  }

  @override
  String get errorSourceUnavailable => '无法打开图片，请重新选择。';

  @override
  String errorSourceUnavailableAt(int n) {
    return '无法打开第 $n 张图片，请重新选择。';
  }

  @override
  String get errorOutOfSpace => '存储空间不足。';

  @override
  String get errorFolderUnavailable => '无法访问保存文件夹，请重新选择文件夹。';

  @override
  String get errorOutputTooLarge => '结果文件过大，请减少图片数量。';

  @override
  String get errorOutOfMemory => '内存不足，请减少图片数量。';

  @override
  String get errorUnknown => '发生未知错误。';

  @override
  String get aboutTitle => '关于';

  @override
  String get sendFeedback => '发送反馈';

  @override
  String get termsTitle => '使用条款';

  @override
  String get version => '版本';

  @override
  String get noMailAppTitle => '无法打开邮件应用';

  @override
  String get noMailAppBody => '请将反馈发送到此地址。';

  @override
  String get copyAddress => '复制地址';

  @override
  String get addressCopied => '地址已复制。';

  @override
  String get termsBody =>
      '最后更新日期：2026年11月5日\n\n1. 接受\n安装或使用 Pic Merge（以下简称\"本应用\"）即表示您同意本条款。如不同意，请勿使用本应用。\n\n2. 许可\n本应用是依据 MIT License 发布的开源软件，您可按该许可使用。第三方组件适用各自的许可。\n\n3. 您的责任\n对于您使用本应用处理、保存和分享的文件、您使用这些文件的权利以及遵守适用法律，均由您自行负责。请自行备份重要文件。\n\n4. 您的数据\n本应用在您的设备上处理文件，不会将其发送到任何服务器。如果您使用\"发送反馈\"，消息由您设备上的邮件应用创建，您发送的内容由您的邮件服务提供商处理。\n\n5. 不提供保证\n本应用按\"原样\"和\"现有状态\"提供，不提供任何明示或默示的保证，包括适销性、特定用途适用性和不侵权。不保证其没有错误或不会中断，也不保证其结果准确。\n\n6. 责任限制\n在适用法律允许的最大范围内，作者、版权持有人和分发者不对因本应用或其使用而产生或与之相关的任何索赔、损害或其他责任负责，包括数据丢失、利润损失以及间接或后果性损害。\n\n7. 无支持义务\n作者没有义务提供支持、更新或维护，也没有义务回复反馈，并可随时更改或停止本应用。\n\n8. 应用商店和平台\n如果您通过应用商店获得本应用，该商店的条款同样适用于您对本应用的使用。\n\n9. 变更\n本条款可能会变更。如果您在变更后继续使用本应用，即表示您接受该变更。\n\n10. 语言\n译文仅为方便而提供。如有差异，以英文版为准。\n\n联系方式：yncdev@gmail.com';

  @override
  String get privacyTitle => '隐私政策';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get privacyBody =>
      '最后更新日期：2026年11月6日\n\n本政策适用于 Android 和 iOS 版 Pic Merge 以及 Pic Merge Chrome 扩展程序（以下简称\"本应用\"）。\n\n本应用如何处理您的文件\n本应用读取您选择的图片和 PDF，并在您的设备上将它们合并为一个文件。您的文件绝不会发送到服务器，本应用没有账户、广告或分析功能。\n\n存储哪些内容以及存储位置\n以下所有内容都保留在您的设备或浏览器中：\n\n- 您保存的文件：位于您使用的文件夹，即默认文件夹或您选择的文件夹。\n- 最近记录：每次保存的时间、格式、项目数，结果文件的名称、大小和尺寸，保存文件夹的名称，排列方向以及结果。移动应用还会保留每个项目的名称、像素尺寸和文件大小以及所应用的缩放比例，并将所有这些内容保存在本地数据库中，直到本应用被删除。扩展程序将最近 50 次保存记录保存在浏览器存储空间中。\n- 您选择的保存文件夹：如果您选择了其他文件夹而不是默认文件夹。\n- 临时文件：在处理过程中生成。它们会在处理结束时、您从列表中移除该项目时、您下次分享时或您下次启动本应用时被删除。\n\n原始图片及其路径不会保留在本应用中。本应用不收集、出售或分享任何此类数据，开发者也无法访问这些数据。删除本应用会移除其存储的数据，但您保存到本应用之外文件夹的文件除外。\n\n本应用已关闭 Android 应用备份。在 iOS 上，根据您的设备设置，设备自身的备份（如 iCloud 备份）可能包含本应用的数据及其文件夹中的文件。\n\n权限\n- Android：不请求互联网、存储或相机权限。文件通过系统选择器选择，照片通过系统相机应用拍摄。\n- iOS：首次使用相机时，系统会请求您的许可。\n- Chrome 扩展程序：未声明任何权限。如果您选择保存文件夹，浏览器会请求访问该文件夹的权限。\n\n发送反馈\n移动应用的\"发送反馈\"选项会打开您设备上的邮件应用，并填好地址和主题。主题包含应用版本、设备型号和操作系统版本，您可以编辑。除非您自己发送，否则不会发送任何内容。您的邮件随后由您的邮件服务提供商处理，开发者会收到您发送的内容。\n\n其他服务\n如果您分享文件，由您设备的分享面板或您选择的应用处理。如果您从应用商店获得本应用，该商店自身的隐私条款适用于该商店。\n\n变更\n本政策可能会变更。变更内容会在本文档中发布。\n\n联系方式\nyncdev@gmail.com';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appName => 'Pic Merge';

  @override
  String get appSubtitle => '圖片合併';

  @override
  String get ok => '確定';

  @override
  String get cancel => '取消';

  @override
  String get clearList => '清空';

  @override
  String get recentHistory => '最近記錄';

  @override
  String get errorLoadPhotos => '無法載入相片，請再試一次。';

  @override
  String get errorCameraUnavailable => '無法使用相機。';

  @override
  String get errorLoadPdfs => '無法載入 PDF，請再試一次。';

  @override
  String maxImagesReached(int max) {
    return '最多可新增 $max 張。';
  }

  @override
  String unsupportedFilesExcluded(int count) {
    return '$count 個檔案的格式不受支援，已排除。';
  }

  @override
  String overLimitAdded(int max, int added) {
    return '最多可新增 $max 張，因此只新增了 $added 張。';
  }

  @override
  String get clearConfirm => '要將所選圖片全部從清單中移除嗎？\n原始相片不會被刪除。';

  @override
  String get folderDialogTitle => '選擇儲存資料夾';

  @override
  String get folderDialogBodyAndroid =>
      '請選擇 Documents 等資料夾或新建的資料夾。\n\n無法選擇內部儲存空間最上層、Download 資料夾本身和 Android/data 資料夾。';

  @override
  String get pickFolder => '選擇資料夾';

  @override
  String useDefaultFolder(String name) {
    return '使用預設資料夾（$name）';
  }

  @override
  String get pickOtherFolder => '選擇其他資料夾';

  @override
  String get errorPickFolder => '無法選擇資料夾，請再試一次。';

  @override
  String savedTo(String folder, String file) {
    return '已儲存：$folder/$file';
  }

  @override
  String get saveCancelled => '已取消儲存。';

  @override
  String get saveFailedTitle => '儲存失敗';

  @override
  String get shareFormatPrompt => '請選擇要透過電子郵件、通訊應用程式等傳送的檔案格式。';

  @override
  String shareAs(String format) {
    return '以 $format 分享';
  }

  @override
  String get shareCancelled => '已取消分享。';

  @override
  String get shareFailedTitle => '分享失敗';

  @override
  String get crashTitle => '上次儲存未完成';

  @override
  String get crashBody => '上次儲存中途結束。請在儲存完成前保持應用程式開啟；如果仍然發生，請減少圖片數量。';

  @override
  String emptyTitle(int min) {
    return '請選擇至少 $min 張要合併的圖片或 PDF';
  }

  @override
  String get emptyHint => '排列方向會自動決定。';

  @override
  String get pickImages => '選擇圖片';

  @override
  String get pickPdf => '選擇 PDF';

  @override
  String get takePhoto => '用相機拍攝';

  @override
  String get autoDirectionVertical => '自動：縱向排列（上 → 下）';

  @override
  String get autoDirectionHorizontal => '自動：橫向排列（左 → 右）';

  @override
  String get previewNoteOriginal =>
      '這是 PNG 預覽。PNG 的圖片之間有灰色線條。PDF 每個項目儲存為一頁，沒有線條。';

  @override
  String previewSummary(int pages, int perPaper) {
    return '共 $pages 頁 · 每張紙 $perPaper 張';
  }

  @override
  String get previewNoteHorizontal =>
      'PNG 會將頁面左右相連，並在圖片之間加入灰色線條。PDF 按頁儲存，沒有線條。';

  @override
  String get previewNoteVertical => 'PNG 會將頁面上下相連，並在圖片之間加入灰色線條。PDF 按頁儲存，沒有線條。';

  @override
  String get paperOriginal => '原始大小';

  @override
  String get orientationPortrait => '直向';

  @override
  String get orientationLandscape => '橫向';

  @override
  String get colorMode => '彩色';

  @override
  String get grayscaleMode => '黑白';

  @override
  String get imagesPerPaper => '每張紙的圖片數';

  @override
  String get imageSize => '圖片大小';

  @override
  String get margin => '邊距';

  @override
  String selectedCount(int count, int max) {
    return '已選 $count/$max';
  }

  @override
  String get addItems => '新增';

  @override
  String get pickPhotos => '選擇相片';

  @override
  String get pickPdfFiles => '選擇 PDF 檔案';

  @override
  String get camera => '相機';

  @override
  String get folderNotChosen => '儲存資料夾：首次儲存時選擇';

  @override
  String folderCurrent(String name) {
    return '儲存資料夾：$name';
  }

  @override
  String get changeFolder => '變更';

  @override
  String needMinImages(int min) {
    return '至少選擇 $min 張才能儲存。';
  }

  @override
  String saveAs(String format) {
    return '儲存 $format';
  }

  @override
  String get share => '分享';

  @override
  String shareTitle(String format) {
    return '分享 $format';
  }

  @override
  String processingImages(int current, int total) {
    return '正在處理圖片 $current/$total';
  }

  @override
  String get buildingFile => '正在產生檔案';

  @override
  String get openingShare => '正在開啟分享視窗';

  @override
  String get saving => '正在儲存';

  @override
  String get cancelling => '正在取消…';

  @override
  String get mayTakeLong => '圖片較大時可能需要數十秒。';

  @override
  String get keepAppOpen => '完成前請保持應用程式開啟。';

  @override
  String get errorApplyCrop => '無法套用裁剪，請再試一次。';

  @override
  String get cropTitle => '裁剪';

  @override
  String get cropApply => '套用';

  @override
  String get cropSelectAll => '全選';

  @override
  String get errorOpenImage => '無法開啟圖片。';

  @override
  String croppedSize(int width, int height) {
    return '$width×$height（已裁剪）';
  }

  @override
  String get removeFromList => '從清單中移除';

  @override
  String get errorLoadHistory => '無法載入記錄。';

  @override
  String historyRateEmpty(int days) {
    return '最近 $days 天沒有儲存記錄。';
  }

  @override
  String historyRate(int days, int percent, int success, int total) {
    return '最近 $days 天成功率 $percent%（$success/$total）';
  }

  @override
  String get historyEmpty => '尚未儲存過。';

  @override
  String imageCount(int count) {
    return '$count 張';
  }

  @override
  String get statusRunning => '進行中';

  @override
  String get statusSuccess => '成功';

  @override
  String get statusFailed => '失敗';

  @override
  String get statusCancelled => '已取消';

  @override
  String get statusCrashed => '異常結束';

  @override
  String get errorUnsupportedFormat => '有圖片的格式不受支援。';

  @override
  String errorUnsupportedFormatAt(int n) {
    return '第 $n 張圖片的格式不受支援。';
  }

  @override
  String get errorCorruptFile => '有已損毀的圖片檔案。';

  @override
  String errorCorruptFileAt(int n) {
    return '第 $n 張圖片的檔案已損毀。';
  }

  @override
  String get errorSourceUnavailable => '無法開啟圖片，請重新選擇。';

  @override
  String errorSourceUnavailableAt(int n) {
    return '無法開啟第 $n 張圖片，請重新選擇。';
  }

  @override
  String get errorOutOfSpace => '儲存空間不足。';

  @override
  String get errorFolderUnavailable => '無法存取儲存資料夾，請重新選擇資料夾。';

  @override
  String get errorOutputTooLarge => '結果檔案過大，請減少圖片數量。';

  @override
  String get errorOutOfMemory => '記憶體不足，請減少圖片數量。';

  @override
  String get errorUnknown => '發生未知的錯誤。';

  @override
  String get aboutTitle => '關於';

  @override
  String get sendFeedback => '傳送意見';

  @override
  String get termsTitle => '使用條款';

  @override
  String get version => '版本';

  @override
  String get noMailAppTitle => '無法開啟郵件應用程式';

  @override
  String get noMailAppBody => '請將意見傳送到這個地址。';

  @override
  String get copyAddress => '複製地址';

  @override
  String get addressCopied => '地址已複製。';

  @override
  String get termsBody =>
      '最後更新日期：2026年11月5日\n\n1. 接受\n安裝或使用 Pic Merge（以下簡稱「本應用程式」）即表示您同意本條款。如不同意，請勿使用本應用程式。\n\n2. 授權\n本應用程式是依 MIT License 發布的開放原始碼軟體，您可依該授權使用。第三方元件適用各自的授權。\n\n3. 您的責任\n對於您使用本應用程式處理、儲存和分享的檔案、您使用這些檔案的權利以及遵守適用法律，均由您自行負責。請自行備份重要檔案。\n\n4. 您的資料\n本應用程式在您的裝置上處理檔案，不會將其傳送到任何伺服器。如果您使用「傳送意見」，訊息由您裝置上的郵件應用程式建立，您傳送的內容由您的郵件服務供應商處理。\n\n5. 不提供保證\n本應用程式按「現狀」和「現有狀態」提供，不提供任何明示或默示的保證，包括適售性、特定用途適用性和不侵權。不保證其沒有錯誤或不會中斷，也不保證其結果準確。\n\n6. 責任限制\n在適用法律允許的最大範圍內，作者、著作權人和散布者不對因本應用程式或其使用而產生或與之相關的任何索賠、損害或其他責任負責，包括資料遺失、利潤損失以及間接或衍生性損害。\n\n7. 無支援義務\n作者沒有義務提供支援、更新或維護，也沒有義務回覆意見，並可隨時變更或停止本應用程式。\n\n8. 應用程式商店和平台\n如果您透過應用程式商店取得本應用程式，該商店的條款同樣適用於您對本應用程式的使用。\n\n9. 變更\n本條款可能會變更。如果您在變更後繼續使用本應用程式，即表示您接受該變更。\n\n10. 語言\n譯文僅為方便而提供。如有差異，以英文版為準。\n\n聯絡方式：yncdev@gmail.com';

  @override
  String get privacyTitle => '隱私權政策';

  @override
  String get openSourceLicenses => '開放原始碼授權';

  @override
  String get privacyBody =>
      '最後更新日期：2026年11月6日\n\n本政策適用於 Android 和 iOS 版 Pic Merge 以及 Pic Merge Chrome 擴充功能（以下簡稱「本應用程式」）。\n\n本應用程式如何處理您的檔案\n本應用程式讀取您選擇的圖片和 PDF，並在您的裝置上將它們合併為一個檔案。您的檔案絕不會傳送到伺服器，本應用程式沒有帳號、廣告或分析功能。\n\n儲存哪些內容以及儲存位置\n以下所有內容都保留在您的裝置或瀏覽器中：\n\n- 您儲存的檔案：位於您使用的資料夾，即預設資料夾或您選擇的資料夾。\n- 最近記錄：每次儲存的時間、格式、項目數，結果檔案的名稱、大小和尺寸，儲存資料夾的名稱，排列方向以及結果。行動應用程式還會保留每個項目的名稱、像素尺寸和檔案大小以及所套用的縮放比例，並將所有這些內容保存在本機資料庫中，直到本應用程式被刪除。擴充功能將最近 50 次儲存記錄保存在瀏覽器儲存空間中。\n- 您選擇的儲存資料夾：如果您選擇了其他資料夾而不是預設資料夾。\n- 暫存檔案：在處理過程中產生。它們會在處理結束時、您從清單中移除該項目時、您下次分享時或您下次啟動本應用程式時被刪除。\n\n原始圖片及其路徑不會保留在本應用程式中。本應用程式不收集、出售或分享任何此類資料，開發者也無法存取這些資料。刪除本應用程式會移除其儲存的資料，但您儲存到本應用程式之外資料夾的檔案除外。\n\n本應用程式已關閉 Android 應用程式備份。在 iOS 上，依您的裝置設定，裝置本身的備份（如 iCloud 備份）可能包含本應用程式的資料及其資料夾中的檔案。\n\n權限\n- Android：不要求網際網路、儲存空間或相機權限。檔案透過系統選擇器選擇，照片透過系統相機應用程式拍攝。\n- iOS：首次使用相機時，系統會要求您的許可。\n- Chrome 擴充功能：未宣告任何權限。如果您選擇儲存資料夾，瀏覽器會要求存取該資料夾的權限。\n\n傳送意見\n行動應用程式的「傳送意見」選項會開啟您裝置上的郵件應用程式，並填好地址和主旨。主旨包含應用程式版本、裝置型號和作業系統版本，您可以編輯。除非您自己傳送，否則不會傳送任何內容。您的郵件隨後由您的郵件服務供應商處理，開發者會收到您傳送的內容。\n\n其他服務\n如果您分享檔案，由您裝置的分享面板或您選擇的應用程式處理。如果您從應用程式商店取得本應用程式，該商店自身的隱私權條款適用於該商店。\n\n變更\n本政策可能會變更。變更內容會在本文件中發布。\n\n聯絡方式\nyncdev@gmail.com';
}
