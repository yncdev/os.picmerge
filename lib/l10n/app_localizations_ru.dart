// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Pic Merge';

  @override
  String get appSubtitle => 'Объединение изображений';

  @override
  String get ok => 'ОК';

  @override
  String get cancel => 'Отмена';

  @override
  String get clearList => 'Очистить';

  @override
  String get recentHistory => 'Недавние записи';

  @override
  String get errorLoadPhotos =>
      'Не удалось загрузить фотографии. Повторите попытку.';

  @override
  String get errorCameraUnavailable => 'Не удаётся использовать камеру.';

  @override
  String get errorLoadPdfs => 'Не удалось загрузить PDF. Повторите попытку.';

  @override
  String maxImagesReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$max изображений',
      one: '$max изображения',
    );
    return 'Можно добавить не более $_temp0.';
  }

  @override
  String unsupportedFilesExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Исключено $count файла неподдерживаемого формата.',
      many: 'Исключено $count файлов неподдерживаемого формата.',
      few: 'Исключено $count файла неподдерживаемого формата.',
      one: 'Исключён $count файл неподдерживаемого формата.',
    );
    return '$_temp0';
  }

  @override
  String overLimitAdded(int max, int added) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$max изображений',
      one: '$max изображения',
    );
    return 'Можно добавить не более $_temp0, поэтому добавлено только $added.';
  }

  @override
  String get clearConfirm =>
      'Убрать все выбранные изображения из списка?\nИсходные фотографии не будут удалены.';

  @override
  String get folderDialogTitle => 'Выбор папки для сохранения';

  @override
  String get folderDialogBodyAndroid =>
      'Выберите папку, например Documents, или новую папку.\n\nНельзя выбрать корень внутреннего хранилища, саму папку Download и папку Android/data.';

  @override
  String get pickFolder => 'Выбрать папку';

  @override
  String useDefaultFolder(String name) {
    return 'Использовать папку по умолчанию ($name)';
  }

  @override
  String get pickOtherFolder => 'Выбрать другую папку';

  @override
  String get errorPickFolder => 'Не удалось выбрать папку. Повторите попытку.';

  @override
  String savedTo(String folder, String file) {
    return 'Сохранено: $folder/$file';
  }

  @override
  String get saveCancelled => 'Сохранение отменено.';

  @override
  String get saveFailedTitle => 'Не удалось сохранить';

  @override
  String get shareFormatPrompt =>
      'Выберите формат файла для отправки по почте, через мессенджеры и другими способами.';

  @override
  String shareAs(String format) {
    return 'Поделиться в формате $format';
  }

  @override
  String get shareCancelled => 'Отправка отменена.';

  @override
  String get shareFailedTitle => 'Не удалось поделиться';

  @override
  String get crashTitle => 'Прошлое сохранение не завершено';

  @override
  String get crashBody =>
      'Прошлое сохранение прервалось. Не закрывайте приложение до окончания сохранения, а если это повторится, уменьшите число изображений.';

  @override
  String emptyTitle(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: '$min изображений или PDF',
      one: '$min изображения или PDF',
    );
    return 'Выберите не менее $_temp0 для объединения';
  }

  @override
  String get emptyHint =>
      'Направление расположения определяется автоматически.';

  @override
  String get pickImages => 'Выбрать изображения';

  @override
  String get pickPdf => 'Выбрать PDF';

  @override
  String get takePhoto => 'Сделать снимок';

  @override
  String get autoDirectionVertical => 'Авто: вертикально (сверху → вниз)';

  @override
  String get autoDirectionHorizontal => 'Авто: горизонтально (слева → направо)';

  @override
  String get previewNoteOriginal =>
      'Это предпросмотр PNG. В PNG между изображениями есть серые линии. PDF сохраняет каждый элемент на отдельной странице, без линий.';

  @override
  String previewSummary(int pages, int perPaper) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pages страницы',
      many: '$pages страниц',
      few: '$pages страницы',
      one: '$pages страница',
    );
    return 'Всего $_temp0 · $perPaper на лист';
  }

  @override
  String get previewNoteHorizontal =>
      'PNG соединяет страницы в ряд, с серыми линиями между изображениями. PDF сохраняет каждую страницу отдельно, без линий.';

  @override
  String get previewNoteVertical =>
      'PNG соединяет страницы сверху вниз, с серыми линиями между изображениями. PDF сохраняет каждую страницу отдельно, без линий.';

  @override
  String get paperOriginal => 'Оригинал';

  @override
  String get orientationPortrait => 'Книжная';

  @override
  String get orientationLandscape => 'Альбомная';

  @override
  String get colorMode => 'Цвет';

  @override
  String get grayscaleMode => 'Ч/б';

  @override
  String get imagesPerPaper => 'Изображений на лист';

  @override
  String get imageSize => 'Масштаб';

  @override
  String get margin => 'Поля';

  @override
  String selectedCount(int count, int max) {
    return 'Выбрано $count/$max';
  }

  @override
  String get addItems => 'Добавить';

  @override
  String get pickPhotos => 'Выбрать фото';

  @override
  String get pickPdfFiles => 'Выбрать файлы PDF';

  @override
  String get camera => 'Камера';

  @override
  String get folderNotChosen => 'Папка: при первом сохранении';

  @override
  String folderCurrent(String name) {
    return 'Папка: $name';
  }

  @override
  String get changeFolder => 'Изменить';

  @override
  String needMinImages(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: '$min изображений',
      one: '$min изображения',
    );
    return 'Для сохранения выберите не менее $_temp0.';
  }

  @override
  String saveAs(String format) {
    return 'Сохранить $format';
  }

  @override
  String get share => 'Поделиться';

  @override
  String shareTitle(String format) {
    return 'Поделиться: $format';
  }

  @override
  String processingImages(int current, int total) {
    return 'Обработка изображений $current/$total';
  }

  @override
  String get buildingFile => 'Создание файла';

  @override
  String get openingShare => 'Открытие окна отправки';

  @override
  String get saving => 'Сохранение';

  @override
  String get cancelling => 'Отмена…';

  @override
  String get mayTakeLong =>
      'Большие изображения могут обрабатываться несколько десятков секунд.';

  @override
  String get keepAppOpen => 'Не закрывайте приложение до завершения.';

  @override
  String get errorApplyCrop =>
      'Не удалось применить обрезку. Повторите попытку.';

  @override
  String get cropTitle => 'Обрезка';

  @override
  String get cropApply => 'Применить';

  @override
  String get cropSelectAll => 'Выбрать всё';

  @override
  String get errorOpenImage => 'Не удаётся открыть изображение.';

  @override
  String croppedSize(int width, int height) {
    return '$width×$height (обрезано)';
  }

  @override
  String get removeFromList => 'Убрать из списка';

  @override
  String get errorLoadHistory => 'Не удалось загрузить записи.';

  @override
  String historyRateEmpty(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return 'За последние $_temp0 сохранений не было.';
  }

  @override
  String historyRate(int days, int percent, int success, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return 'Успешность за последние $_temp0: $percent% ($success/$total)';
  }

  @override
  String get historyEmpty => 'Вы ещё ничего не сохраняли.';

  @override
  String imageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count изображения',
      many: '$count изображений',
      few: '$count изображения',
      one: '$count изображение',
    );
    return '$_temp0';
  }

  @override
  String get statusRunning => 'Выполняется';

  @override
  String get statusSuccess => 'Успешно';

  @override
  String get statusFailed => 'Ошибка';

  @override
  String get statusCancelled => 'Отменено';

  @override
  String get statusCrashed => 'Аварийное завершение';

  @override
  String get errorUnsupportedFormat =>
      'Есть изображение неподдерживаемого формата.';

  @override
  String errorUnsupportedFormatAt(int n) {
    return 'Изображение $n имеет неподдерживаемый формат.';
  }

  @override
  String get errorCorruptFile => 'Есть повреждённый файл изображения.';

  @override
  String errorCorruptFileAt(int n) {
    return 'Файл изображения $n повреждён.';
  }

  @override
  String get errorSourceUnavailable =>
      'Не удаётся открыть изображение. Выберите его ещё раз.';

  @override
  String errorSourceUnavailableAt(int n) {
    return 'Не удаётся открыть изображение $n. Выберите его ещё раз.';
  }

  @override
  String get errorOutOfSpace => 'Недостаточно места в хранилище.';

  @override
  String get errorFolderUnavailable =>
      'Нет доступа к папке для сохранения. Выберите папку ещё раз.';

  @override
  String get errorOutputTooLarge =>
      'Готовый файл слишком большой. Уменьшите число изображений.';

  @override
  String get errorOutOfMemory =>
      'Недостаточно памяти. Уменьшите число изображений.';

  @override
  String get errorUnknown => 'Произошла неизвестная ошибка.';

  @override
  String get aboutTitle => 'О программе';

  @override
  String get sendFeedback => 'Отправить отзыв';

  @override
  String get termsTitle => 'Условия использования';

  @override
  String get version => 'Версия';

  @override
  String get noMailAppTitle => 'Не удаётся открыть почтовое приложение';

  @override
  String get noMailAppBody => 'Отправьте отзыв на этот адрес.';

  @override
  String get copyAddress => 'Скопировать адрес';

  @override
  String get addressCopied => 'Адрес скопирован.';

  @override
  String get termsBody =>
      'Последнее обновление: 5 ноября 2026 г.\n\n1. Принятие условий\nУстанавливая или используя Pic Merge (далее «Приложение»), вы соглашаетесь с настоящими Условиями. Если вы не согласны, не используйте Приложение.\n\n2. Лицензия\nПриложение является программным обеспечением с открытым исходным кодом, выпущенным под лицензией MIT License, и вы можете использовать его в соответствии с этой лицензией. На сторонние компоненты распространяются их собственные лицензии.\n\n3. Ваша ответственность\nТолько вы несёте ответственность за файлы, которые обрабатываете, сохраняете и отправляете с помощью Приложения, за наличие прав на их использование и за соблюдение применимого законодательства. Самостоятельно создавайте резервные копии важных файлов.\n\n4. Ваши данные\nПриложение обрабатывает файлы на вашем устройстве и не отправляет их ни на какие серверы. Если вы используете функцию «Отправить отзыв», сообщение создаёт почтовое приложение на вашем устройстве, а отправленное вами обрабатывает ваш поставщик услуг электронной почты.\n\n5. Отказ от гарантий\nПриложение предоставляется «КАК ЕСТЬ» и «ПО МЕРЕ ДОСТУПНОСТИ», без каких-либо гарантий, явных или подразумеваемых, включая товарную пригодность, пригодность для определённой цели и ненарушение прав. Нет гарантии, что оно будет работать без ошибок и перебоев или что его результаты будут точными.\n\n6. Ограничение ответственности\nВ максимальной степени, разрешённой применимым законодательством, авторы, правообладатели и распространители не несут ответственности по каким-либо претензиям, за убытки или иную ответственность, включая потерю данных, упущенную выгоду, косвенные и последующие убытки, возникающие в связи с Приложением или его использованием.\n\n7. Отсутствие обязательств по поддержке\nАвторы не обязаны предоставлять поддержку, обновления или обслуживание либо отвечать на отзывы и могут в любое время изменить или прекратить работу Приложения.\n\n8. Магазины приложений и платформы\nЕсли вы получили Приложение через магазин приложений, к вашему использованию Приложения также применяются условия этого магазина.\n\n9. Изменения\nНастоящие Условия могут меняться. Продолжая использовать Приложение после изменения, вы принимаете это изменение.\n\n10. Язык\nПереводы предоставляются для удобства. При расхождениях преимущественную силу имеет версия на английском языке.\n\nКонтакты: yncdev@gmail.com';

  @override
  String get privacyTitle => 'Политика конфиденциальности';

  @override
  String get openSourceLicenses => 'Лицензии открытого ПО';

  @override
  String get privacyBody =>
      'Последнее обновление: 6 ноября 2026 г.\n\nНастоящая политика распространяется на Pic Merge для Android и iOS и расширение Chrome Pic Merge (далее «Приложение»).\n\nЧто Приложение делает с вашими файлами\nПриложение читает выбранные вами изображения и PDF и объединяет их в один файл на вашем устройстве. Ваши файлы никогда не отправляются на сервер, а в Приложении нет учётной записи, рекламы и аналитики.\n\nЧто хранится и где\nВсё перечисленное ниже остаётся на вашем устройстве или в браузере:\n\n- Сохраняемые вами файлы — в используемой вами папке: папке по умолчанию или выбранной вами.\n- Недавние записи: для каждого сохранения — время, формат, количество элементов, имя, размер и разрешение итогового файла, имя папки сохранения, направление расположения и результат. Мобильное приложение также хранит имя, размер в пикселях и размер файла каждого элемента и применённый масштаб и хранит всё это в локальной базе данных до удаления Приложения. Расширение хранит последние 50 сохранений в хранилище браузера.\n- Выбранная вами папка сохранения, если вы выбрали её вместо папки по умолчанию.\n- Временные файлы, создаваемые при обработке. Они удаляются по окончании обработки, когда вы убираете элемент из списка, при следующем использовании функции «Поделиться» или при следующем запуске Приложения.\n\nИсходные изображения и пути к ним в Приложении не хранятся. Приложение не собирает, не продаёт и не передаёт эти данные, и разработчик не имеет к ним доступа. При удалении Приложения удаляются его сохранённые данные, кроме файлов, сохранённых вами в папке вне Приложения.\n\nРезервное копирование приложений Android для Приложения отключено. На iOS собственная резервная копия вашего устройства, например резервная копия iCloud, может включать данные Приложения и файлы в его папке в зависимости от настроек устройства.\n\nРазрешения\n- Android: разрешения на доступ к интернету, хранилищу и камере не запрашиваются. Файлы выбираются через системные средства выбора, а фотографии снимаются системным приложением камеры.\n- iOS: система запрашивает ваше разрешение при первом использовании камеры.\n- Расширение Chrome: разрешения не объявлены. Если вы выберете папку сохранения, браузер запросит доступ к этой папке.\n\nОтправка отзыва\nФункция «Отправить отзыв» в мобильном приложении открывает почтовое приложение на вашем устройстве с уже заполненными адресом и темой. Тема содержит версию приложения, модель устройства и версию ОС, и вы можете её изменить. Ничего не отправляется, пока вы не отправите это сами. Затем ваше сообщение обрабатывает ваш поставщик услуг электронной почты, а разработчик получает то, что вы отправили.\n\nДругие сервисы\nЕсли вы делитесь файлом, этим занимается системное меню «Поделиться» вашего устройства или выбранное вами приложение. Если вы получили Приложение в магазине приложений, к этому магазину применяются его собственные условия конфиденциальности.\n\nИзменения\nНастоящая политика может меняться. Изменения публикуются в этом документе.\n\nКонтакты\nyncdev@gmail.com';
}
