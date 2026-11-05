/// 설치된 앱과 기기 정보. 프로그램 정보 화면과 의견 보내기 제목에 쓴다 (DESIGN §2.2).
class AppInfo {
  const AppInfo({
    required this.versionName,
    required this.buildNumber,
    required this.manufacturer,
    required this.model,
    required this.osName,
    required this.osVersion,
  });

  final String versionName;
  final String buildNumber;
  final String manufacturer;
  final String model;
  final String osName;
  final String osVersion;
}
