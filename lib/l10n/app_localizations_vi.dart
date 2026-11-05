// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Pic Merge';

  @override
  String get appSubtitle => 'Ghép ảnh';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Hủy';

  @override
  String get clearList => 'Xóa hết';

  @override
  String get recentHistory => 'Lịch sử gần đây';

  @override
  String get errorLoadPhotos => 'Không thể tải ảnh. Vui lòng thử lại.';

  @override
  String get errorCameraUnavailable => 'Không thể sử dụng máy ảnh.';

  @override
  String get errorLoadPdfs => 'Không thể tải PDF. Vui lòng thử lại.';

  @override
  String maxImagesReached(int max) {
    return 'Bạn có thể thêm tối đa $max ảnh.';
  }

  @override
  String unsupportedFilesExcluded(int count) {
    return 'Đã loại $count tệp vì định dạng không được hỗ trợ.';
  }

  @override
  String overLimitAdded(int max, int added) {
    return 'Chỉ có thể thêm tối đa $max ảnh nên chỉ thêm được $added ảnh.';
  }

  @override
  String get clearConfirm =>
      'Xóa tất cả ảnh đã chọn khỏi danh sách?\nẢnh gốc sẽ không bị xóa.';

  @override
  String get folderDialogTitle => 'Chọn thư mục lưu';

  @override
  String get folderDialogBodyAndroid =>
      'Hãy chọn thư mục như Documents hoặc một thư mục mới tạo.\n\nKhông thể chọn cấp cao nhất của bộ nhớ trong, chính thư mục Download và thư mục Android/data.';

  @override
  String get pickFolder => 'Chọn thư mục';

  @override
  String useDefaultFolder(String name) {
    return 'Dùng thư mục mặc định ($name)';
  }

  @override
  String get pickOtherFolder => 'Chọn thư mục khác';

  @override
  String get errorPickFolder => 'Không thể chọn thư mục. Vui lòng thử lại.';

  @override
  String savedTo(String folder, String file) {
    return 'Đã lưu: $folder/$file';
  }

  @override
  String get saveCancelled => 'Đã hủy lưu.';

  @override
  String get saveFailedTitle => 'Không thể lưu';

  @override
  String get shareFormatPrompt =>
      'Hãy chọn định dạng tệp để gửi qua email, ứng dụng nhắn tin và các cách khác.';

  @override
  String shareAs(String format) {
    return 'Chia sẻ dạng $format';
  }

  @override
  String get shareCancelled => 'Đã hủy chia sẻ.';

  @override
  String get shareFailedTitle => 'Không thể chia sẻ';

  @override
  String get crashTitle => 'Lần lưu trước chưa hoàn tất';

  @override
  String get crashBody =>
      'Lần lưu trước đã dừng giữa chừng. Hãy giữ ứng dụng mở cho đến khi lưu xong, nếu vẫn xảy ra thì hãy giảm số ảnh.';

  @override
  String emptyTitle(int min) {
    return 'Hãy chọn ít nhất $min ảnh hoặc PDF để ghép';
  }

  @override
  String get emptyHint => 'Hướng sắp xếp được tự động xác định.';

  @override
  String get pickImages => 'Chọn ảnh';

  @override
  String get pickPdf => 'Chọn PDF';

  @override
  String get takePhoto => 'Chụp bằng máy ảnh';

  @override
  String get autoDirectionVertical => 'Tự động: xếp dọc (trên → dưới)';

  @override
  String get autoDirectionHorizontal => 'Tự động: xếp ngang (trái → phải)';

  @override
  String get previewNoteOriginal =>
      'Đây là bản xem trước PNG. PNG có đường kẻ xám giữa các ảnh. PDF lưu mỗi mục thành một trang, không có đường kẻ.';

  @override
  String previewSummary(int pages, int perPaper) {
    return 'Tổng $pages trang · $perPaper ảnh mỗi tờ';
  }

  @override
  String get previewNoteHorizontal =>
      'PNG nối các trang theo chiều ngang, có đường kẻ xám giữa các ảnh. PDF lưu từng trang riêng, không có đường kẻ.';

  @override
  String get previewNoteVertical =>
      'PNG nối các trang từ trên xuống dưới, có đường kẻ xám giữa các ảnh. PDF lưu từng trang riêng, không có đường kẻ.';

  @override
  String get paperOriginal => 'Kích thước gốc';

  @override
  String get orientationPortrait => 'Dọc';

  @override
  String get orientationLandscape => 'Ngang';

  @override
  String get colorMode => 'Màu';

  @override
  String get grayscaleMode => 'Đen trắng';

  @override
  String get imagesPerPaper => 'Số ảnh mỗi tờ';

  @override
  String get imageSize => 'Kích thước ảnh';

  @override
  String get margin => 'Lề';

  @override
  String selectedCount(int count, int max) {
    return 'Đã chọn $count/$max';
  }

  @override
  String get addItems => 'Thêm';

  @override
  String get pickPhotos => 'Chọn ảnh chụp';

  @override
  String get pickPdfFiles => 'Chọn tệp PDF';

  @override
  String get camera => 'Máy ảnh';

  @override
  String get folderNotChosen => 'Thư mục lưu: chọn khi lưu lần đầu';

  @override
  String folderCurrent(String name) {
    return 'Thư mục lưu: $name';
  }

  @override
  String get changeFolder => 'Đổi';

  @override
  String needMinImages(int min) {
    return 'Cần chọn ít nhất $min ảnh để lưu.';
  }

  @override
  String saveAs(String format) {
    return 'Lưu $format';
  }

  @override
  String get share => 'Chia sẻ';

  @override
  String shareTitle(String format) {
    return 'Chia sẻ $format';
  }

  @override
  String processingImages(int current, int total) {
    return 'Đang xử lý ảnh $current/$total';
  }

  @override
  String get buildingFile => 'Đang tạo tệp';

  @override
  String get openingShare => 'Đang mở cửa sổ chia sẻ';

  @override
  String get saving => 'Đang lưu';

  @override
  String get cancelling => 'Đang hủy…';

  @override
  String get mayTakeLong => 'Ảnh lớn có thể mất vài chục giây.';

  @override
  String get keepAppOpen => 'Hãy giữ ứng dụng mở cho đến khi hoàn tất.';

  @override
  String get errorApplyCrop => 'Không thể áp dụng vùng cắt. Vui lòng thử lại.';

  @override
  String get cropTitle => 'Cắt ảnh';

  @override
  String get cropApply => 'Áp dụng';

  @override
  String get cropSelectAll => 'Chọn tất cả';

  @override
  String get errorOpenImage => 'Không thể mở ảnh.';

  @override
  String croppedSize(int width, int height) {
    return '$width×$height (đã cắt)';
  }

  @override
  String get removeFromList => 'Xóa khỏi danh sách';

  @override
  String get errorLoadHistory => 'Không thể tải lịch sử.';

  @override
  String historyRateEmpty(int days) {
    return 'Không có lần lưu nào trong $days ngày gần đây.';
  }

  @override
  String historyRate(int days, int percent, int success, int total) {
    return 'Tỷ lệ thành công trong $days ngày gần đây: $percent% ($success/$total)';
  }

  @override
  String get historyEmpty => 'Bạn chưa lưu lần nào.';

  @override
  String imageCount(int count) {
    return '$count ảnh';
  }

  @override
  String get statusRunning => 'Đang chạy';

  @override
  String get statusSuccess => 'Thành công';

  @override
  String get statusFailed => 'Thất bại';

  @override
  String get statusCancelled => 'Đã hủy';

  @override
  String get statusCrashed => 'Kết thúc bất thường';

  @override
  String get errorUnsupportedFormat => 'Có ảnh ở định dạng không được hỗ trợ.';

  @override
  String errorUnsupportedFormatAt(int n) {
    return 'Ảnh thứ $n có định dạng không được hỗ trợ.';
  }

  @override
  String get errorCorruptFile => 'Có tệp ảnh bị hỏng.';

  @override
  String errorCorruptFileAt(int n) {
    return 'Tệp của ảnh thứ $n bị hỏng.';
  }

  @override
  String get errorSourceUnavailable => 'Không thể mở ảnh. Vui lòng chọn lại.';

  @override
  String errorSourceUnavailableAt(int n) {
    return 'Không thể mở ảnh thứ $n. Vui lòng chọn lại.';
  }

  @override
  String get errorOutOfSpace => 'Không đủ dung lượng lưu trữ.';

  @override
  String get errorFolderUnavailable =>
      'Không thể truy cập thư mục lưu. Vui lòng chọn lại thư mục.';

  @override
  String get errorOutputTooLarge =>
      'Tệp kết quả quá lớn. Vui lòng giảm số ảnh.';

  @override
  String get errorOutOfMemory => 'Không đủ bộ nhớ. Vui lòng giảm số ảnh.';

  @override
  String get errorUnknown => 'Đã xảy ra lỗi không xác định.';

  @override
  String get aboutTitle => 'Giới thiệu';

  @override
  String get sendFeedback => 'Gửi ý kiến';

  @override
  String get termsTitle => 'Điều khoản sử dụng';

  @override
  String get version => 'Phiên bản';

  @override
  String get noMailAppTitle => 'Không thể mở ứng dụng thư';

  @override
  String get noMailAppBody => 'Vui lòng gửi ý kiến đến địa chỉ này.';

  @override
  String get copyAddress => 'Sao chép địa chỉ';

  @override
  String get addressCopied => 'Đã sao chép địa chỉ.';

  @override
  String get termsBody =>
      'Cập nhật lần cuối: 5 tháng 11 năm 2026\n\n1. Chấp nhận\nKhi cài đặt hoặc sử dụng Pic Merge (\"Ứng dụng\"), bạn đồng ý với các Điều khoản này. Nếu không đồng ý, vui lòng không sử dụng Ứng dụng.\n\n2. Giấy phép\nỨng dụng là phần mềm nguồn mở được phát hành theo MIT License và bạn có thể sử dụng theo giấy phép đó. Các thành phần của bên thứ ba giữ nguyên giấy phép riêng của chúng.\n\n3. Trách nhiệm của bạn\nChỉ riêng bạn chịu trách nhiệm về các tệp bạn xử lý, lưu và chia sẻ bằng Ứng dụng, về việc có quyền sử dụng các tệp đó và về việc tuân thủ pháp luật hiện hành. Hãy tự sao lưu các tệp quan trọng.\n\n4. Dữ liệu của bạn\nỨng dụng xử lý tệp trên thiết bị của bạn và không gửi chúng đến bất kỳ máy chủ nào. Nếu bạn dùng Gửi ý kiến, ứng dụng thư trên thiết bị của bạn sẽ tạo thư, và nội dung bạn gửi do nhà cung cấp dịch vụ thư của bạn xử lý.\n\n5. Không bảo đảm\nỨng dụng được cung cấp \"NGUYÊN TRẠNG\" và \"TÙY THEO KHẢ NĂNG CUNG CẤP\", không có bất kỳ bảo đảm nào, dù rõ ràng hay ngụ ý, bao gồm khả năng thương mại, sự phù hợp với một mục đích cụ thể và không vi phạm. Không có bảo đảm rằng Ứng dụng không có lỗi hoặc không bị gián đoạn, hay rằng kết quả của Ứng dụng là chính xác.\n\n6. Giới hạn trách nhiệm\nTrong phạm vi tối đa mà pháp luật hiện hành cho phép, các tác giả, chủ sở hữu bản quyền và nhà phân phối không chịu trách nhiệm đối với bất kỳ khiếu nại, thiệt hại hoặc trách nhiệm nào khác, bao gồm mất dữ liệu, mất lợi nhuận và thiệt hại gián tiếp hoặc do hậu quả, phát sinh từ hoặc liên quan đến Ứng dụng hay việc sử dụng Ứng dụng.\n\n7. Không có nghĩa vụ hỗ trợ\nCác tác giả không có nghĩa vụ cung cấp hỗ trợ, bản cập nhật hoặc bảo trì hay trả lời ý kiến, và có thể thay đổi hoặc ngừng Ứng dụng bất kỳ lúc nào.\n\n8. Cửa hàng ứng dụng và nền tảng\nNếu bạn nhận Ứng dụng qua một cửa hàng ứng dụng, các điều khoản của cửa hàng đó cũng áp dụng cho việc bạn sử dụng Ứng dụng.\n\n9. Thay đổi\nCác Điều khoản này có thể thay đổi. Nếu bạn tiếp tục sử dụng Ứng dụng sau khi có thay đổi, bạn chấp nhận thay đổi đó.\n\n10. Ngôn ngữ\nBản dịch được cung cấp để thuận tiện. Nếu có khác biệt, bản tiếng Anh được ưu tiên.\n\nLiên hệ: yncdev@gmail.com';

  @override
  String get privacyTitle => 'Chính sách quyền riêng tư';

  @override
  String get openSourceLicenses => 'Giấy phép nguồn mở';

  @override
  String get privacyBody =>
      'Cập nhật lần cuối: 6 tháng 11 năm 2026\n\nChính sách này áp dụng cho Pic Merge dành cho Android và iOS và tiện ích mở rộng Chrome Pic Merge (\"Ứng dụng\").\n\nỨng dụng làm gì với tệp của bạn\nỨng dụng đọc các hình ảnh và PDF bạn chọn rồi ghép chúng thành một tệp duy nhất trên thiết bị của bạn. Tệp của bạn không bao giờ được gửi đến máy chủ, và Ứng dụng không có tài khoản, quảng cáo hay phân tích.\n\nNhững gì được lưu và ở đâu\nMọi thứ dưới đây đều ở trên thiết bị hoặc trong trình duyệt của bạn:\n\n- Tệp bạn lưu, trong thư mục bạn dùng: thư mục mặc định hoặc thư mục bạn chọn.\n- Lịch sử gần đây: với mỗi lần lưu, gồm thời gian, định dạng, số mục, tên, dung lượng và kích thước của tệp kết quả, tên thư mục lưu, hướng sắp xếp và kết quả. Ứng dụng di động cũng giữ tên, kích thước pixel và dung lượng tệp của từng mục cùng tỷ lệ đã áp dụng, và giữ tất cả thông tin này trong cơ sở dữ liệu cục bộ cho đến khi Ứng dụng bị xóa. Tiện ích mở rộng giữ 50 lần lưu gần nhất trong bộ nhớ của trình duyệt.\n- Thư mục lưu bạn đã chọn, nếu bạn chọn một thư mục thay vì thư mục mặc định.\n- Tệp tạm được tạo trong khi xử lý. Các tệp này bị xóa khi xử lý xong, khi bạn bỏ mục khỏi danh sách, ở lần chia sẻ tiếp theo hoặc vào lần tiếp theo bạn khởi động Ứng dụng.\n\nHình ảnh gốc và đường dẫn của chúng không được giữ trong Ứng dụng. Ứng dụng không thu thập, bán hay chia sẻ bất kỳ dữ liệu nào trong số này, và nhà phát triển không thể truy cập chúng. Xóa Ứng dụng sẽ xóa dữ liệu đã lưu của Ứng dụng, trừ các tệp bạn đã lưu vào thư mục bên ngoài Ứng dụng.\n\nTính năng sao lưu ứng dụng của Android đã được tắt cho Ứng dụng. Trên iOS, bản sao lưu của chính thiết bị, chẳng hạn iCloud Backup, có thể bao gồm dữ liệu của Ứng dụng và các tệp trong thư mục của Ứng dụng, tùy theo cài đặt thiết bị của bạn.\n\nQuyền\n- Android: không yêu cầu quyền internet, bộ nhớ hay máy ảnh. Tệp được chọn qua bộ chọn của hệ thống và ảnh được chụp bằng ứng dụng máy ảnh của hệ thống.\n- iOS: hệ thống sẽ hỏi quyền của bạn vào lần đầu bạn dùng máy ảnh.\n- Tiện ích mở rộng Chrome: không khai báo quyền nào. Nếu bạn chọn thư mục lưu, trình duyệt sẽ hỏi quyền truy cập vào thư mục đó.\n\nGửi ý kiến\nTùy chọn Gửi ý kiến của ứng dụng di động sẽ mở ứng dụng thư trên thiết bị của bạn với địa chỉ và tiêu đề đã được điền sẵn. Tiêu đề bao gồm phiên bản ứng dụng, kiểu thiết bị và phiên bản hệ điều hành, và bạn có thể sửa. Không có gì được gửi trừ khi bạn tự gửi. Sau đó, thư của bạn do nhà cung cấp dịch vụ thư của bạn xử lý, và nhà phát triển nhận được những gì bạn gửi.\n\nDịch vụ khác\nNếu bạn chia sẻ tệp, bảng chia sẻ của thiết bị hoặc ứng dụng bạn chọn sẽ xử lý việc đó. Nếu bạn nhận Ứng dụng từ một cửa hàng ứng dụng, các điều khoản về quyền riêng tư của cửa hàng đó áp dụng cho cửa hàng.\n\nThay đổi\nChính sách này có thể thay đổi. Các thay đổi được đăng trong tài liệu này.\n\nLiên hệ\nyncdev@gmail.com';
}
