// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Pic Merge';

  @override
  String get appSubtitle => '이미지 합치기';

  @override
  String get ok => '확인';

  @override
  String get cancel => '취소';

  @override
  String get clearList => '비우기';

  @override
  String get recentHistory => '최근 기록';

  @override
  String get errorLoadPhotos => '사진을 불러오지 못했습니다. 다시 시도해 주세요.';

  @override
  String get errorCameraUnavailable => '카메라를 사용할 수 없습니다.';

  @override
  String get errorLoadPdfs => 'PDF를 불러오지 못했습니다. 다시 시도해 주세요.';

  @override
  String maxImagesReached(int max) {
    return '최대 $max장까지 담을 수 있습니다.';
  }

  @override
  String unsupportedFilesExcluded(int count) {
    return '$count개 파일은 지원하지 않는 형식이라 제외했습니다.';
  }

  @override
  String overLimitAdded(int max, int added) {
    return '최대 $max장까지 담을 수 있어 $added장만 추가했습니다.';
  }

  @override
  String get clearConfirm => '선택한 이미지를 모두 목록에서 뺄까요?\n원본 사진은 지워지지 않습니다.';

  @override
  String get folderDialogTitle => '저장 폴더 고르기';

  @override
  String get folderDialogBodyAndroid =>
      'Documents 같은 폴더나 새로 만든 폴더를 골라 주세요.\n\n내부 저장소 맨 위, Download 폴더 자체, Android/data 폴더는 고를 수 없습니다.';

  @override
  String get pickFolder => '폴더 고르기';

  @override
  String useDefaultFolder(String name) {
    return '기본 폴더 쓰기 ($name)';
  }

  @override
  String get pickOtherFolder => '다른 폴더 고르기';

  @override
  String get errorPickFolder => '폴더를 고를 수 없습니다. 다시 시도해 주세요.';

  @override
  String savedTo(String folder, String file) {
    return '저장했습니다: $folder/$file';
  }

  @override
  String get saveCancelled => '저장을 취소했습니다.';

  @override
  String get saveFailedTitle => '저장하지 못했습니다';

  @override
  String get shareFormatPrompt => '이메일, 카카오톡, 문자 등으로 보낼 파일 형식을 고르세요.';

  @override
  String shareAs(String format) {
    return '$format로 공유';
  }

  @override
  String get shareCancelled => '공유를 취소했습니다.';

  @override
  String get shareFailedTitle => '공유하지 못했습니다';

  @override
  String get crashTitle => '이전 저장이 끝나지 않았습니다';

  @override
  String get crashBody =>
      '이전 저장이 중간에 종료되었습니다. 저장이 끝날 때까지 앱을 켜 두고, 계속되면 이미지 수를 줄여 주세요.';

  @override
  String emptyTitle(int min) {
    return '합칠 이미지나 PDF를 $min장 이상 골라 주세요';
  }

  @override
  String get emptyHint => '배치 방향은 자동으로 정합니다.';

  @override
  String get pickImages => '이미지 선택';

  @override
  String get pickPdf => 'PDF 선택';

  @override
  String get takePhoto => '카메라로 찍기';

  @override
  String get autoDirectionVertical => '자동: 세로 배치 (위 → 아래)';

  @override
  String get autoDirectionHorizontal => '자동: 가로 배치 (왼쪽 → 오른쪽)';

  @override
  String get previewNoteOriginal =>
      'PNG 미리보기입니다. PNG에는 이미지 사이에 회색 선이 들어갑니다. PDF는 항목마다 한 페이지로 저장되고 선이 없습니다.';

  @override
  String previewSummary(int pages, int perPaper) {
    return '총 $pages페이지 · 용지당 $perPaper개';
  }

  @override
  String get previewNoteHorizontal =>
      'PNG는 페이지를 옆으로 이어 붙이고 이미지 사이에 회색 선을 넣습니다. PDF는 페이지별로 저장되고 선이 없습니다.';

  @override
  String get previewNoteVertical =>
      'PNG는 페이지를 위아래로 이어 붙이고 이미지 사이에 회색 선을 넣습니다. PDF는 페이지별로 저장되고 선이 없습니다.';

  @override
  String get paperOriginal => '원본 크기';

  @override
  String get orientationPortrait => '세로';

  @override
  String get orientationLandscape => '가로';

  @override
  String get colorMode => '컬러';

  @override
  String get grayscaleMode => '흑백';

  @override
  String get imagesPerPaper => '용지당 이미지 수';

  @override
  String get imageSize => '이미지 크기';

  @override
  String get margin => '여백';

  @override
  String selectedCount(int count, int max) {
    return '선택 $count/$max';
  }

  @override
  String get addItems => '추가';

  @override
  String get pickPhotos => '사진 선택';

  @override
  String get pickPdfFiles => 'PDF 파일 선택';

  @override
  String get camera => '카메라';

  @override
  String get folderNotChosen => '저장 폴더: 처음 저장할 때 고릅니다';

  @override
  String folderCurrent(String name) {
    return '저장 폴더: $name';
  }

  @override
  String get changeFolder => '변경';

  @override
  String needMinImages(int min) {
    return '$min장 이상 골라야 저장할 수 있습니다.';
  }

  @override
  String saveAs(String format) {
    return '$format 저장';
  }

  @override
  String get share => '공유';

  @override
  String shareTitle(String format) {
    return '$format 공유';
  }

  @override
  String processingImages(int current, int total) {
    return '이미지 처리 중 $current/$total';
  }

  @override
  String get buildingFile => '파일 만드는 중';

  @override
  String get openingShare => '공유 창 여는 중';

  @override
  String get saving => '저장하는 중';

  @override
  String get cancelling => '취소하는 중…';

  @override
  String get mayTakeLong => '이미지가 크면 수십 초 걸릴 수 있습니다.';

  @override
  String get keepAppOpen => '끝날 때까지 앱을 켜 두세요.';

  @override
  String get errorApplyCrop => '영역을 적용하지 못했습니다. 다시 시도해 주세요.';

  @override
  String get cropTitle => '영역 편집';

  @override
  String get cropApply => '적용';

  @override
  String get cropSelectAll => '전체 선택';

  @override
  String get errorOpenImage => '이미지를 열 수 없습니다.';

  @override
  String croppedSize(int width, int height) {
    return '$width×$height (영역 편집됨)';
  }

  @override
  String get removeFromList => '목록에서 빼기';

  @override
  String get errorLoadHistory => '기록을 불러오지 못했습니다.';

  @override
  String historyRateEmpty(int days) {
    return '최근 $days일 저장 기록이 없습니다.';
  }

  @override
  String historyRate(int days, int percent, int success, int total) {
    return '최근 $days일 성공률 $percent% ($success/$total)';
  }

  @override
  String get historyEmpty => '아직 저장한 적이 없습니다.';

  @override
  String imageCount(int count) {
    return '$count장';
  }

  @override
  String get statusRunning => '진행 중';

  @override
  String get statusSuccess => '성공';

  @override
  String get statusFailed => '실패';

  @override
  String get statusCancelled => '취소';

  @override
  String get statusCrashed => '비정상 종료';

  @override
  String get errorUnsupportedFormat => '지원하지 않는 형식의 이미지가 있습니다.';

  @override
  String errorUnsupportedFormatAt(int n) {
    return '$n번째 이미지는 지원하지 않는 형식입니다.';
  }

  @override
  String get errorCorruptFile => '손상된 이미지 파일이 있습니다.';

  @override
  String errorCorruptFileAt(int n) {
    return '$n번째 이미지 파일이 손상되었습니다.';
  }

  @override
  String get errorSourceUnavailable => '이미지를 열 수 없습니다. 다시 선택해 주세요.';

  @override
  String errorSourceUnavailableAt(int n) {
    return '$n번째 이미지를 열 수 없습니다. 다시 선택해 주세요.';
  }

  @override
  String get errorOutOfSpace => '저장 공간이 부족합니다.';

  @override
  String get errorFolderUnavailable => '저장 폴더에 접근할 수 없습니다. 폴더를 다시 골라 주세요.';

  @override
  String get errorOutputTooLarge => '결과 파일이 너무 큽니다. 이미지 수를 줄여 주세요.';

  @override
  String get errorOutOfMemory => '메모리가 부족합니다. 이미지 수를 줄여 주세요.';

  @override
  String get errorUnknown => '알 수 없는 오류가 발생했습니다.';

  @override
  String get aboutTitle => '프로그램 정보';

  @override
  String get sendFeedback => '의견 보내기';

  @override
  String get termsTitle => '이용약관';

  @override
  String get version => '버전';

  @override
  String get noMailAppTitle => '메일 앱을 열 수 없습니다';

  @override
  String get noMailAppBody => '이 주소로 의견을 보내 주세요.';

  @override
  String get copyAddress => '주소 복사';

  @override
  String get addressCopied => '주소를 복사했습니다.';

  @override
  String get termsBody =>
      '최종 수정일: 2026년 11월 5일\n\n1. 동의\nPic Merge(이하 \'앱\')를 설치하거나 사용하면 이 약관에 동의한 것으로 봅니다. 동의하지 않으면 앱을 사용하지 마세요.\n\n2. 라이선스\n앱은 MIT License로 배포되는 오픈소스 소프트웨어이며, 이 라이선스에 따라 사용할 수 있습니다. 제3자 구성 요소는 각자의 라이선스를 따릅니다.\n\n3. 사용자의 책임\n앱으로 처리·저장·공유하는 파일, 그 파일을 사용할 권리, 관련 법령 준수에 대한 책임은 모두 사용자에게 있습니다. 중요한 파일은 직접 백업하세요.\n\n4. 사용자 데이터\n앱은 파일을 기기 안에서 처리하며 어떤 서버로도 보내지 않습니다. \'의견 보내기\'를 사용하면 기기의 메일 앱에서 메시지가 만들어지고, 보낸 내용은 사용하는 메일 서비스가 처리합니다.\n\n5. 보증의 부인\n앱은 \'있는 그대로\', \'제공되는 대로\' 제공되며, 상품성, 특정 목적 적합성, 비침해를 포함해 명시적이든 묵시적이든 어떠한 보증도 하지 않습니다. 오류나 중단이 없다거나 결과가 정확하다고 보장하지 않습니다.\n\n6. 책임의 제한\n관련 법령이 허용하는 최대 범위에서, 저작자, 저작권자, 배포자는 앱 또는 앱의 사용으로 발생하거나 이와 관련된 어떠한 청구, 손해, 기타 책임(데이터 손실, 이익 손실, 간접·결과적 손해 포함)도 지지 않습니다.\n\n7. 지원 의무 없음\n저작자는 지원, 업데이트, 유지보수를 제공하거나 의견에 답변할 의무가 없으며, 언제든지 앱을 변경하거나 중단할 수 있습니다.\n\n8. 앱 스토어와 플랫폼\n앱을 앱 스토어에서 받았다면 해당 스토어의 약관도 함께 적용됩니다.\n\n9. 약관 변경\n이 약관은 변경될 수 있습니다. 변경 후 앱을 계속 사용하면 변경에 동의한 것으로 봅니다.\n\n10. 언어\n번역본은 편의를 위해 제공합니다. 내용이 다르면 영어본이 우선합니다.\n\n문의: yncdev@gmail.com';

  @override
  String get privacyTitle => '개인정보 처리방침';

  @override
  String get openSourceLicenses => '오픈소스 라이선스';

  @override
  String get privacyBody =>
      '최종 수정일: 2026년 11월 6일\n\n이 방침은 Android·iOS용 Pic Merge와 Pic Merge Chrome 확장 프로그램(이하 \'앱\')에 적용됩니다.\n\n파일 처리: 앱은 사용자가 고른 이미지와 PDF를 기기 안에서 하나의 파일로 합칩니다. 파일을 서버로 보내지 않으며, 계정, 광고, 분석 도구가 없습니다.\n\n저장하는 정보: 다음은 모두 기기나 브라우저 안에만 있습니다. 저장한 결과 파일, 최근 기록, 사용자가 고른 저장 폴더, 처리 중의 임시 파일입니다. 최근 기록에는 저장할 때마다 시각, 형식, 항목 수, 결과 파일의 이름·크기·해상도, 저장 폴더 이름, 배치 방향, 결과가 남습니다. 모바일 앱은 항목별 이름, 픽셀 크기, 파일 크기, 적용 비율도 남기고 앱을 삭제할 때까지 기기의 데이터베이스에 보관합니다. 확장 프로그램은 최근 50건을 브라우저 저장소에 보관합니다. 임시 파일은 처리가 끝날 때, 목록에서 항목을 뺄 때, 다음 공유 때, 또는 앱을 다음에 시작할 때 지웁니다. 원본 이미지와 원본 경로는 앱에 보관하지 않습니다. 앱은 이 정보를 수집, 판매, 공유하지 않으며 개발자는 이 정보에 접근할 수 없습니다. 앱을 삭제하면 저장된 정보도 삭제됩니다. 앱 밖의 폴더에 저장한 파일은 남습니다. Android에서는 이 앱의 앱 백업을 껐습니다. iOS에서는 기기 설정에 따라 iCloud 백업 같은 기기 자체 백업에 앱 데이터와 앱 폴더의 파일이 포함될 수 있습니다.\n\n권한: Android는 인터넷, 저장소, 카메라 권한을 요청하지 않습니다. iOS는 카메라를 처음 쓸 때 시스템이 허용을 묻습니다. Chrome 확장은 권한을 선언하지 않으며, 저장 폴더를 직접 고르면 브라우저가 그 폴더의 접근 허용을 묻습니다.\n\n의견 보내기: 모바일 앱의 \'의견 보내기\'는 주소와 제목이 채워진 메일 앱을 엽니다. 제목에는 앱 버전, 기기 모델, OS 버전이 들어가며 수정할 수 있습니다. 사용자가 직접 보내지 않으면 아무것도 전송되지 않습니다. 보낸 메일은 사용자의 메일 서비스가 처리하고 개발자가 받습니다.\n\n다른 서비스: 파일을 공유하면 기기의 공유 창과 사용자가 고른 앱이 처리합니다. 앱 스토어에서 받았다면 스토어에 대해서는 해당 스토어의 개인정보 약관이 적용됩니다.\n\n변경: 이 방침은 변경될 수 있으며, 변경 내용은 이 문서에 게시합니다.\n\n문의: yncdev@gmail.com';
}
