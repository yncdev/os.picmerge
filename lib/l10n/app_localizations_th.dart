// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appName => 'Pic Merge';

  @override
  String get appSubtitle => 'รวมรูปภาพ';

  @override
  String get ok => 'ตกลง';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get clearList => 'ล้าง';

  @override
  String get recentHistory => 'ประวัติล่าสุด';

  @override
  String get errorLoadPhotos => 'โหลดรูปถ่ายไม่ได้ โปรดลองอีกครั้ง';

  @override
  String get errorCameraUnavailable => 'ใช้กล้องไม่ได้';

  @override
  String get errorLoadPdfs => 'โหลด PDF ไม่ได้ โปรดลองอีกครั้ง';

  @override
  String maxImagesReached(int max) {
    return 'เพิ่มได้สูงสุด $max รูป';
  }

  @override
  String unsupportedFilesExcluded(int count) {
    return 'ไม่ได้รวม $count ไฟล์เนื่องจากไม่รองรับรูปแบบไฟล์';
  }

  @override
  String overLimitAdded(int max, int added) {
    return 'เพิ่มได้สูงสุด $max รูป จึงเพิ่มได้เพียง $added รูป';
  }

  @override
  String get clearConfirm =>
      'นำรูปภาพที่เลือกทั้งหมดออกจากรายการหรือไม่\nรูปถ่ายต้นฉบับจะไม่ถูกลบ';

  @override
  String get folderDialogTitle => 'เลือกโฟลเดอร์บันทึก';

  @override
  String get folderDialogBodyAndroid =>
      'โปรดเลือกโฟลเดอร์ เช่น Documents หรือโฟลเดอร์ที่สร้างใหม่\n\nเลือกระดับบนสุดของที่เก็บข้อมูลภายใน โฟลเดอร์ Download เอง และโฟลเดอร์ Android/data ไม่ได้';

  @override
  String get pickFolder => 'เลือกโฟลเดอร์';

  @override
  String useDefaultFolder(String name) {
    return 'ใช้โฟลเดอร์เริ่มต้น ($name)';
  }

  @override
  String get pickOtherFolder => 'เลือกโฟลเดอร์อื่น';

  @override
  String get errorPickFolder => 'เลือกโฟลเดอร์ไม่ได้ โปรดลองอีกครั้ง';

  @override
  String savedTo(String folder, String file) {
    return 'บันทึกแล้ว: $folder/$file';
  }

  @override
  String get saveCancelled => 'ยกเลิกการบันทึกแล้ว';

  @override
  String get saveFailedTitle => 'บันทึกไม่สำเร็จ';

  @override
  String get shareFormatPrompt =>
      'เลือกรูปแบบไฟล์ที่จะส่งทางอีเมล แอปแชต และอื่นๆ';

  @override
  String shareAs(String format) {
    return 'แชร์เป็น $format';
  }

  @override
  String get shareCancelled => 'ยกเลิกการแชร์แล้ว';

  @override
  String get shareFailedTitle => 'แชร์ไม่สำเร็จ';

  @override
  String get crashTitle => 'การบันทึกครั้งก่อนไม่เสร็จสิ้น';

  @override
  String get crashBody =>
      'การบันทึกครั้งก่อนหยุดกลางคัน โปรดเปิดแอปไว้จนกว่าจะบันทึกเสร็จ และหากยังเกิดขึ้นอีก โปรดลดจำนวนรูปภาพ';

  @override
  String emptyTitle(int min) {
    return 'โปรดเลือกรูปภาพหรือ PDF ที่จะรวมอย่างน้อย $min รายการ';
  }

  @override
  String get emptyHint => 'ทิศทางการจัดวางจะกำหนดโดยอัตโนมัติ';

  @override
  String get pickImages => 'เลือกรูปภาพ';

  @override
  String get pickPdf => 'เลือก PDF';

  @override
  String get takePhoto => 'ถ่ายด้วยกล้อง';

  @override
  String get autoDirectionVertical => 'อัตโนมัติ: จัดแนวตั้ง (บน → ล่าง)';

  @override
  String get autoDirectionHorizontal => 'อัตโนมัติ: จัดแนวนอน (ซ้าย → ขวา)';

  @override
  String get previewNoteOriginal =>
      'นี่คือตัวอย่าง PNG ใน PNG จะมีเส้นสีเทาระหว่างรูปภาพ ส่วน PDF จะบันทึกรายการละหนึ่งหน้าโดยไม่มีเส้น';

  @override
  String previewSummary(int pages, int perPaper) {
    return 'ทั้งหมด $pages หน้า · $perPaper รูปต่อแผ่น';
  }

  @override
  String get previewNoteHorizontal =>
      'PNG จะต่อหน้าเรียงกันในแนวนอนและมีเส้นสีเทาระหว่างรูปภาพ ส่วน PDF จะบันทึกแยกทีละหน้าโดยไม่มีเส้น';

  @override
  String get previewNoteVertical =>
      'PNG จะต่อหน้าจากบนลงล่างและมีเส้นสีเทาระหว่างรูปภาพ ส่วน PDF จะบันทึกแยกทีละหน้าโดยไม่มีเส้น';

  @override
  String get paperOriginal => 'ขนาดต้นฉบับ';

  @override
  String get orientationPortrait => 'แนวตั้ง';

  @override
  String get orientationLandscape => 'แนวนอน';

  @override
  String get colorMode => 'สี';

  @override
  String get grayscaleMode => 'ขาวดำ';

  @override
  String get imagesPerPaper => 'จำนวนรูปต่อแผ่น';

  @override
  String get imageSize => 'ขนาดรูปภาพ';

  @override
  String get margin => 'ระยะขอบ';

  @override
  String selectedCount(int count, int max) {
    return 'เลือกแล้ว $count/$max';
  }

  @override
  String get addItems => 'เพิ่ม';

  @override
  String get pickPhotos => 'เลือกรูปถ่าย';

  @override
  String get pickPdfFiles => 'เลือกไฟล์ PDF';

  @override
  String get camera => 'กล้อง';

  @override
  String get folderNotChosen => 'โฟลเดอร์บันทึก: เลือกเมื่อบันทึกครั้งแรก';

  @override
  String folderCurrent(String name) {
    return 'โฟลเดอร์บันทึก: $name';
  }

  @override
  String get changeFolder => 'เปลี่ยน';

  @override
  String needMinImages(int min) {
    return 'ต้องเลือกอย่างน้อย $min รูปจึงจะบันทึกได้';
  }

  @override
  String saveAs(String format) {
    return 'บันทึก $format';
  }

  @override
  String get share => 'แชร์';

  @override
  String shareTitle(String format) {
    return 'แชร์ $format';
  }

  @override
  String processingImages(int current, int total) {
    return 'กำลังประมวลผลรูปภาพ $current/$total';
  }

  @override
  String get buildingFile => 'กำลังสร้างไฟล์';

  @override
  String get openingShare => 'กำลังเปิดหน้าต่างแชร์';

  @override
  String get saving => 'กำลังบันทึก';

  @override
  String get cancelling => 'กำลังยกเลิก…';

  @override
  String get mayTakeLong => 'รูปภาพขนาดใหญ่อาจใช้เวลาหลายสิบวินาที';

  @override
  String get keepAppOpen => 'โปรดเปิดแอปไว้จนกว่าจะเสร็จ';

  @override
  String get errorApplyCrop => 'ใช้การครอบตัดไม่ได้ โปรดลองอีกครั้ง';

  @override
  String get cropTitle => 'ครอบตัด';

  @override
  String get cropApply => 'ใช้';

  @override
  String get cropSelectAll => 'เลือกทั้งหมด';

  @override
  String get errorOpenImage => 'เปิดรูปภาพไม่ได้';

  @override
  String croppedSize(int width, int height) {
    return '$width×$height (ครอบตัดแล้ว)';
  }

  @override
  String get removeFromList => 'นำออกจากรายการ';

  @override
  String get errorLoadHistory => 'โหลดประวัติไม่ได้';

  @override
  String historyRateEmpty(int days) {
    return 'ไม่มีการบันทึกใน $days วันที่ผ่านมา';
  }

  @override
  String historyRate(int days, int percent, int success, int total) {
    return 'อัตราสำเร็จใน $days วันที่ผ่านมา $percent% ($success/$total)';
  }

  @override
  String get historyEmpty => 'ยังไม่เคยบันทึก';

  @override
  String imageCount(int count) {
    return '$count รูป';
  }

  @override
  String get statusRunning => 'กำลังดำเนินการ';

  @override
  String get statusSuccess => 'สำเร็จ';

  @override
  String get statusFailed => 'ไม่สำเร็จ';

  @override
  String get statusCancelled => 'ยกเลิกแล้ว';

  @override
  String get statusCrashed => 'สิ้นสุดผิดปกติ';

  @override
  String get errorUnsupportedFormat => 'มีรูปภาพในรูปแบบที่ไม่รองรับ';

  @override
  String errorUnsupportedFormatAt(int n) {
    return 'รูปภาพที่ $n อยู่ในรูปแบบที่ไม่รองรับ';
  }

  @override
  String get errorCorruptFile => 'มีไฟล์รูปภาพที่เสียหาย';

  @override
  String errorCorruptFileAt(int n) {
    return 'ไฟล์ของรูปภาพที่ $n เสียหาย';
  }

  @override
  String get errorSourceUnavailable => 'เปิดรูปภาพไม่ได้ โปรดเลือกอีกครั้ง';

  @override
  String errorSourceUnavailableAt(int n) {
    return 'เปิดรูปภาพที่ $n ไม่ได้ โปรดเลือกอีกครั้ง';
  }

  @override
  String get errorOutOfSpace => 'พื้นที่เก็บข้อมูลไม่เพียงพอ';

  @override
  String get errorFolderUnavailable =>
      'เข้าถึงโฟลเดอร์บันทึกไม่ได้ โปรดเลือกโฟลเดอร์อีกครั้ง';

  @override
  String get errorOutputTooLarge => 'ไฟล์ผลลัพธ์ใหญ่เกินไป โปรดลดจำนวนรูปภาพ';

  @override
  String get errorOutOfMemory => 'หน่วยความจำไม่เพียงพอ โปรดลดจำนวนรูปภาพ';

  @override
  String get errorUnknown => 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';

  @override
  String get aboutTitle => 'เกี่ยวกับ';

  @override
  String get sendFeedback => 'ส่งความคิดเห็น';

  @override
  String get termsTitle => 'ข้อกำหนดการใช้งาน';

  @override
  String get version => 'เวอร์ชัน';

  @override
  String get noMailAppTitle => 'เปิดแอปอีเมลไม่ได้';

  @override
  String get noMailAppBody => 'โปรดส่งความคิดเห็นไปยังที่อยู่นี้';

  @override
  String get copyAddress => 'คัดลอกที่อยู่';

  @override
  String get addressCopied => 'คัดลอกที่อยู่แล้ว';

  @override
  String get termsBody =>
      'อัปเดตล่าสุด: 5 พฤศจิกายน 2026\n\n1. การยอมรับ\nเมื่อคุณติดตั้งหรือใช้ Pic Merge (\"แอป\") แสดงว่าคุณยอมรับข้อกำหนดนี้ หากไม่ยอมรับ โปรดอย่าใช้แอป\n\n2. สัญญาอนุญาต\nแอปเป็นซอฟต์แวร์โอเพนซอร์สที่เผยแพร่ภายใต้ MIT License และคุณใช้แอปได้ตามสัญญาอนุญาตนั้น ส่วนประกอบของบุคคลที่สามเป็นไปตามสัญญาอนุญาตของตนเอง\n\n3. ความรับผิดชอบของคุณ\nคุณเพียงผู้เดียวเป็นผู้รับผิดชอบต่อไฟล์ที่คุณประมวลผล บันทึก และแชร์ด้วยแอป ต่อการมีสิทธิ์ใช้ไฟล์เหล่านั้น และต่อการปฏิบัติตามกฎหมายที่เกี่ยวข้อง โปรดสำรองไฟล์สำคัญด้วยตนเอง\n\n4. ข้อมูลของคุณ\nแอปประมวลผลไฟล์บนอุปกรณ์ของคุณและไม่ส่งไฟล์ไปยังเซิร์ฟเวอร์ใด หากคุณใช้ ส่งความคิดเห็น แอปอีเมลในอุปกรณ์ของคุณจะสร้างข้อความ และสิ่งที่คุณส่งจะได้รับการจัดการโดยผู้ให้บริการอีเมลของคุณ\n\n5. ไม่มีการรับประกัน\nแอปนี้ให้บริการ \"ตามสภาพ\" และ \"ตามที่มีให้\" โดยไม่มีการรับประกันใด ๆ ไม่ว่าโดยชัดแจ้งหรือโดยนัย รวมถึงความสามารถในการจำหน่าย ความเหมาะสมกับวัตถุประสงค์เฉพาะ และการไม่ละเมิดสิทธิ ไม่มีการรับประกันว่าแอปจะปราศจากข้อผิดพลาดหรือการหยุดชะงัก หรือว่าผลลัพธ์จะถูกต้อง\n\n6. การจำกัดความรับผิด\nภายในขอบเขตสูงสุดที่กฎหมายที่เกี่ยวข้องอนุญาต ผู้เขียน ผู้ถือลิขสิทธิ์ และผู้จัดจำหน่ายไม่ต้องรับผิดต่อการเรียกร้อง ความเสียหาย หรือความรับผิดอื่นใด รวมถึงการสูญเสียข้อมูล การสูญเสียกำไร และความเสียหายทางอ้อมหรือที่เป็นผลสืบเนื่อง ซึ่งเกิดจากหรือเกี่ยวข้องกับแอปหรือการใช้แอป\n\n7. ไม่มีภาระผูกพันในการสนับสนุน\nผู้เขียนไม่มีภาระผูกพันในการให้การสนับสนุน การอัปเดต หรือการบำรุงรักษา หรือในการตอบความคิดเห็น และอาจเปลี่ยนแปลงหรือหยุดแอปได้ทุกเมื่อ\n\n8. ร้านแอปและแพลตฟอร์ม\nหากคุณได้รับแอปผ่านร้านแอป ข้อกำหนดของร้านนั้นจะมีผลกับการใช้แอปของคุณด้วย\n\n9. การเปลี่ยนแปลง\nข้อกำหนดนี้อาจเปลี่ยนแปลงได้ หากคุณใช้แอปต่อหลังการเปลี่ยนแปลง แสดงว่าคุณยอมรับการเปลี่ยนแปลงนั้น\n\n10. ภาษา\nคำแปลจัดทำขึ้นเพื่อความสะดวก หากมีความแตกต่าง ให้ถือฉบับภาษาอังกฤษเป็นหลัก\n\nติดต่อ: yncdev@gmail.com';

  @override
  String get privacyTitle => 'นโยบายความเป็นส่วนตัว';

  @override
  String get openSourceLicenses => 'สัญญาอนุญาตโอเพนซอร์ส';

  @override
  String get privacyBody =>
      'อัปเดตล่าสุด: 6 พฤศจิกายน 2026\n\nนโยบายนี้ครอบคลุม Pic Merge สำหรับ Android และ iOS และส่วนขยาย Chrome ของ Pic Merge (\"แอป\")\n\nสิ่งที่แอปทำกับไฟล์ของคุณ\nแอปอ่านรูปภาพและ PDF ที่คุณเลือกและรวมเป็นไฟล์เดียวบนอุปกรณ์ของคุณ ไฟล์ของคุณจะไม่ถูกส่งไปยังเซิร์ฟเวอร์ และแอปไม่มีบัญชี โฆษณา หรือการวิเคราะห์\n\nสิ่งที่จัดเก็บและที่จัดเก็บ\nทุกอย่างด้านล่างนี้อยู่บนอุปกรณ์หรือในเบราว์เซอร์ของคุณ:\n\n- ไฟล์ที่คุณบันทึก ในโฟลเดอร์ที่คุณใช้: โฟลเดอร์เริ่มต้นหรือโฟลเดอร์ที่คุณเลือก\n- ประวัติล่าสุด: สำหรับการบันทึกแต่ละครั้ง ได้แก่ เวลา รูปแบบ จำนวนรายการ ชื่อ ขนาด และมิติของไฟล์ผลลัพธ์ ชื่อโฟลเดอร์บันทึก ทิศทางการจัดวาง และผลลัพธ์ แอปมือถือยังเก็บชื่อ ขนาดพิกเซล และขนาดไฟล์ของแต่ละรายการ รวมถึงอัตราส่วนที่ใช้ และเก็บทั้งหมดนี้ไว้ในฐานข้อมูลภายในเครื่องจนกว่าจะลบแอป ส่วนส่วนขยายเก็บการบันทึก 50 ครั้งล่าสุดไว้ในพื้นที่จัดเก็บของเบราว์เซอร์\n- โฟลเดอร์บันทึกที่คุณเลือก หากคุณเลือกโฟลเดอร์อื่นแทนโฟลเดอร์เริ่มต้น\n- ไฟล์ชั่วคราวที่สร้างขึ้นระหว่างการประมวลผล ไฟล์เหล่านี้จะถูกลบเมื่อการประมวลผลสิ้นสุด เมื่อคุณนำรายการออกจากรายการ เมื่อคุณแชร์ครั้งถัดไป หรือเมื่อคุณเริ่มแอปครั้งถัดไป\n\nรูปภาพต้นฉบับและเส้นทางของรูปภาพจะไม่ถูกเก็บไว้ในแอป แอปไม่เก็บรวบรวม ขาย หรือแชร์ข้อมูลเหล่านี้ และผู้พัฒนาไม่สามารถเข้าถึงข้อมูลเหล่านี้ได้ การลบแอปจะลบข้อมูลที่แอปจัดเก็บไว้ ยกเว้นไฟล์ที่คุณบันทึกไว้ในโฟลเดอร์ภายนอกแอป\n\nการสำรองข้อมูลแอปของ Android ถูกปิดไว้สำหรับแอปนี้ บน iOS การสำรองข้อมูลของอุปกรณ์เอง เช่น การสำรองข้อมูล iCloud อาจรวมข้อมูลของแอปและไฟล์ในโฟลเดอร์ของแอป ขึ้นอยู่กับการตั้งค่าอุปกรณ์ของคุณ\n\nสิทธิ์\n- Android: ไม่มีการขอสิทธิ์อินเทอร์เน็ต พื้นที่จัดเก็บ หรือกล้อง ไฟล์จะถูกเลือกผ่านตัวเลือกของระบบ และถ่ายภาพด้วยแอปกล้องของระบบ\n- iOS: ระบบจะขออนุญาตจากคุณเมื่อคุณใช้กล้องครั้งแรก\n- ส่วนขยาย Chrome: ไม่มีการประกาศสิทธิ์ใด ๆ หากคุณเลือกโฟลเดอร์บันทึก เบราว์เซอร์จะขอการเข้าถึงโฟลเดอร์นั้น\n\nการส่งความคิดเห็น\nตัวเลือก ส่งความคิดเห็น ของแอปมือถือจะเปิดแอปอีเมลในอุปกรณ์ของคุณพร้อมกรอกที่อยู่และหัวเรื่องไว้แล้ว หัวเรื่องมีเวอร์ชันของแอป รุ่นอุปกรณ์ และเวอร์ชันระบบปฏิบัติการ และคุณแก้ไขได้ จะไม่มีการส่งสิ่งใดเว้นแต่คุณจะส่งเอง จากนั้นข้อความของคุณจะได้รับการจัดการโดยผู้ให้บริการอีเมลของคุณ และผู้พัฒนาจะได้รับสิ่งที่คุณส่ง\n\nบริการอื่น ๆ\nหากคุณแชร์ไฟล์ แผ่นแชร์ของอุปกรณ์หรือแอปที่คุณเลือกจะจัดการไฟล์นั้น หากคุณได้รับแอปจากร้านแอป ข้อกำหนดด้านความเป็นส่วนตัวของร้านนั้นจะมีผลกับร้านนั้น\n\nการเปลี่ยนแปลง\nนโยบายนี้อาจเปลี่ยนแปลงได้ การเปลี่ยนแปลงจะเผยแพร่ในเอกสารนี้\n\nติดต่อ\nyncdev@gmail.com';
}
