import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/output_settings.dart';

/// 출력 설정 (DESIGN §2.1.5). 저장하지 않으므로 앱을 시작하면 기본값(A4·세로·용지당 1개·100%·여백 5%·컬러)이다.
class OutputSettingsController extends Notifier<OutputSettings> {
  @override
  OutputSettings build() => const OutputSettings();

  void setPaper(PaperSize paper) => state = state.copyWith(paper: paper);

  void setOrientation(PaperOrientation orientation) =>
      state = state.copyWith(orientation: orientation);

  void setImagesPerPaper(int imagesPerPaper) =>
      state = state.copyWith(imagesPerPaper: imagesPerPaper);

  void setImageSizePercent(int percent) => state = state.copyWith(imageSizePercent: percent);

  void setMarginPercent(int percent) => state = state.copyWith(marginPercent: percent);

  void setGrayscale(bool grayscale) => state = state.copyWith(grayscale: grayscale);
}

final outputSettingsProvider =
    NotifierProvider<OutputSettingsController, OutputSettings>(OutputSettingsController.new);
