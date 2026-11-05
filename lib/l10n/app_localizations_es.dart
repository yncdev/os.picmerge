// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Pic Merge';

  @override
  String get appSubtitle => 'Unir imágenes';

  @override
  String get ok => 'Aceptar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get clearList => 'Vaciar';

  @override
  String get recentHistory => 'Historial reciente';

  @override
  String get errorLoadPhotos =>
      'No se pudieron cargar las fotos. Inténtalo de nuevo.';

  @override
  String get errorCameraUnavailable => 'No se puede usar la cámara.';

  @override
  String get errorLoadPdfs => 'No se pudo cargar el PDF. Inténtalo de nuevo.';

  @override
  String maxImagesReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$max imágenes',
      one: '$max imagen',
    );
    return 'Puedes añadir hasta $_temp0.';
  }

  @override
  String unsupportedFilesExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Se han excluido $count archivos porque su formato no es compatible.',
      one: 'Se ha excluido $count archivo porque su formato no es compatible.',
    );
    return '$_temp0';
  }

  @override
  String overLimitAdded(int max, int added) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$max imágenes',
      one: '$max imagen',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'han añadido $added',
      one: 'ha añadido $added',
    );
    return 'Puedes añadir hasta $_temp0, así que solo se $_temp1.';
  }

  @override
  String get clearConfirm =>
      '¿Quitar todas las imágenes seleccionadas de la lista?\nLas fotos originales no se eliminarán.';

  @override
  String get folderDialogTitle => 'Elegir carpeta de guardado';

  @override
  String get folderDialogBodyAndroid =>
      'Elige una carpeta como Documents o una creada por ti.\n\nNo se puede elegir la raíz del almacenamiento interno, la propia carpeta Download ni la carpeta Android/data.';

  @override
  String get pickFolder => 'Elegir carpeta';

  @override
  String useDefaultFolder(String name) {
    return 'Usar la carpeta predeterminada ($name)';
  }

  @override
  String get pickOtherFolder => 'Elegir otra carpeta';

  @override
  String get errorPickFolder =>
      'No se pudo elegir la carpeta. Inténtalo de nuevo.';

  @override
  String savedTo(String folder, String file) {
    return 'Guardado: $folder/$file';
  }

  @override
  String get saveCancelled => 'Se ha cancelado el guardado.';

  @override
  String get saveFailedTitle => 'No se pudo guardar';

  @override
  String get shareFormatPrompt =>
      'Elige el formato del archivo que quieres enviar por correo, aplicaciones de mensajería y otros medios.';

  @override
  String shareAs(String format) {
    return 'Compartir como $format';
  }

  @override
  String get shareCancelled => 'Se ha cancelado la acción de compartir.';

  @override
  String get shareFailedTitle => 'No se pudo compartir';

  @override
  String get crashTitle => 'El último guardado no terminó';

  @override
  String get crashBody =>
      'El último guardado se interrumpió. Mantén la aplicación abierta hasta que termine y, si vuelve a ocurrir, usa menos imágenes.';

  @override
  String emptyTitle(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: '$min imágenes o PDF',
      one: '$min imagen o PDF',
    );
    return 'Elige al menos $_temp0 para unir';
  }

  @override
  String get emptyHint =>
      'La dirección de la disposición se decide automáticamente.';

  @override
  String get pickImages => 'Elegir imágenes';

  @override
  String get pickPdf => 'Elegir PDF';

  @override
  String get takePhoto => 'Hacer una foto';

  @override
  String get autoDirectionVertical =>
      'Automático: disposición vertical (arriba → abajo)';

  @override
  String get autoDirectionHorizontal =>
      'Automático: disposición horizontal (izquierda → derecha)';

  @override
  String get previewNoteOriginal =>
      'Esta es la vista previa del PNG. El PNG lleva líneas grises entre las imágenes. El PDF guarda una página por elemento, sin líneas.';

  @override
  String previewSummary(int pages, int perPaper) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pages páginas',
      one: '$pages página',
    );
    return '$_temp0 en total · $perPaper por hoja';
  }

  @override
  String get previewNoteHorizontal =>
      'El PNG une las páginas una al lado de otra, con líneas grises entre las imágenes. El PDF guarda cada página por separado, sin líneas.';

  @override
  String get previewNoteVertical =>
      'El PNG une las páginas de arriba abajo, con líneas grises entre las imágenes. El PDF guarda cada página por separado, sin líneas.';

  @override
  String get paperOriginal => 'Tamaño original';

  @override
  String get orientationPortrait => 'Vertical';

  @override
  String get orientationLandscape => 'Horizontal';

  @override
  String get colorMode => 'Color';

  @override
  String get grayscaleMode => 'B/N';

  @override
  String get imagesPerPaper => 'Imágenes por hoja';

  @override
  String get imageSize => 'Tamaño de imagen';

  @override
  String get margin => 'Margen';

  @override
  String selectedCount(int count, int max) {
    return 'Selección $count/$max';
  }

  @override
  String get addItems => 'Añadir';

  @override
  String get pickPhotos => 'Elegir fotos';

  @override
  String get pickPdfFiles => 'Elegir archivos PDF';

  @override
  String get camera => 'Cámara';

  @override
  String get folderNotChosen => 'Carpeta: al guardar por primera vez';

  @override
  String folderCurrent(String name) {
    return 'Carpeta: $name';
  }

  @override
  String get changeFolder => 'Cambiar';

  @override
  String needMinImages(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: '$min imágenes',
      one: '$min imagen',
    );
    return 'Elige al menos $_temp0 para guardar.';
  }

  @override
  String saveAs(String format) {
    return 'Guardar $format';
  }

  @override
  String get share => 'Compartir';

  @override
  String shareTitle(String format) {
    return 'Compartir $format';
  }

  @override
  String processingImages(int current, int total) {
    return 'Procesando imágenes $current/$total';
  }

  @override
  String get buildingFile => 'Creando el archivo';

  @override
  String get openingShare => 'Abriendo la ventana de compartir';

  @override
  String get saving => 'Guardando';

  @override
  String get cancelling => 'Cancelando…';

  @override
  String get mayTakeLong =>
      'Las imágenes grandes pueden tardar decenas de segundos.';

  @override
  String get keepAppOpen => 'Mantén la aplicación abierta hasta que termine.';

  @override
  String get errorApplyCrop =>
      'No se pudo aplicar el recorte. Inténtalo de nuevo.';

  @override
  String get cropTitle => 'Recortar';

  @override
  String get cropApply => 'Aplicar';

  @override
  String get cropSelectAll => 'Seleccionar todo';

  @override
  String get errorOpenImage => 'No se puede abrir la imagen.';

  @override
  String croppedSize(int width, int height) {
    return '$width×$height (recortada)';
  }

  @override
  String get removeFromList => 'Quitar de la lista';

  @override
  String get errorLoadHistory => 'No se pudo cargar el historial.';

  @override
  String historyRateEmpty(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'los últimos $days días',
      one: 'el último día',
    );
    return 'No hay guardados en $_temp0.';
  }

  @override
  String historyRate(int days, int percent, int success, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'los últimos $days días',
      one: 'el último día',
    );
    return 'Tasa de éxito en $_temp0: $percent% ($success/$total)';
  }

  @override
  String get historyEmpty => 'Todavía no has guardado nada.';

  @override
  String imageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imágenes',
      one: '$count imagen',
    );
    return '$_temp0';
  }

  @override
  String get statusRunning => 'En curso';

  @override
  String get statusSuccess => 'Correcto';

  @override
  String get statusFailed => 'Error';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get statusCrashed => 'Cierre inesperado';

  @override
  String get errorUnsupportedFormat =>
      'Hay una imagen con un formato no compatible.';

  @override
  String errorUnsupportedFormatAt(int n) {
    return 'La imagen $n tiene un formato no compatible.';
  }

  @override
  String get errorCorruptFile => 'Hay un archivo de imagen dañado.';

  @override
  String errorCorruptFileAt(int n) {
    return 'El archivo de la imagen $n está dañado.';
  }

  @override
  String get errorSourceUnavailable =>
      'No se puede abrir una imagen. Vuelve a elegirla.';

  @override
  String errorSourceUnavailableAt(int n) {
    return 'No se puede abrir la imagen $n. Vuelve a elegirla.';
  }

  @override
  String get errorOutOfSpace => 'No hay suficiente espacio de almacenamiento.';

  @override
  String get errorFolderUnavailable =>
      'No se puede acceder a la carpeta de guardado. Vuelve a elegir una carpeta.';

  @override
  String get errorOutputTooLarge =>
      'El archivo resultante es demasiado grande. Usa menos imágenes.';

  @override
  String get errorOutOfMemory =>
      'No hay suficiente memoria. Usa menos imágenes.';

  @override
  String get errorUnknown => 'Se ha producido un error desconocido.';

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String get sendFeedback => 'Enviar comentarios';

  @override
  String get termsTitle => 'Términos de uso';

  @override
  String get version => 'Versión';

  @override
  String get noMailAppTitle => 'No se puede abrir una aplicación de correo';

  @override
  String get noMailAppBody => 'Envía tus comentarios a esta dirección.';

  @override
  String get copyAddress => 'Copiar dirección';

  @override
  String get addressCopied => 'Dirección copiada.';

  @override
  String get termsBody =>
      'Última actualización: 5 de noviembre de 2026\n\n1. Aceptación\nAl instalar o usar Pic Merge (la \"Aplicación\"), aceptas estos Términos. Si no estás de acuerdo, no uses la Aplicación.\n\n2. Licencia\nLa Aplicación es software de código abierto publicado bajo la MIT License, y puedes usarla conforme a dicha licencia. Los componentes de terceros conservan sus propias licencias.\n\n3. Tus responsabilidades\nSolo tú eres responsable de los archivos que procesas, guardas y compartes con la Aplicación, de tener los derechos para usarlos y de cumplir la legislación aplicable. Guarda tus propias copias de seguridad de los archivos importantes.\n\n4. Tus datos\nLa Aplicación procesa los archivos en tu dispositivo y no los envía a ningún servidor. Si usas Enviar comentarios, la aplicación de correo de tu dispositivo crea el mensaje y lo que envíes lo gestiona tu proveedor de correo.\n\n5. Sin garantía\nLa Aplicación se proporciona \"TAL CUAL\" y \"SEGÚN DISPONIBILIDAD\", sin garantía de ningún tipo, expresa o implícita, incluidas las de comerciabilidad, idoneidad para un fin determinado y no infracción. No se garantiza que esté libre de errores o interrupciones, ni que sus resultados sean exactos.\n\n6. Limitación de responsabilidad\nEn la máxima medida permitida por la legislación aplicable, los autores, los titulares de los derechos de autor y los distribuidores no son responsables de ninguna reclamación, daño u otra responsabilidad, incluidas la pérdida de datos, la pérdida de beneficios y los daños indirectos o consecuentes, que surja de la Aplicación o de su uso o esté relacionada con ellos.\n\n7. Sin obligación de soporte\nLos autores no tienen obligación de proporcionar soporte, actualizaciones ni mantenimiento ni de responder a los comentarios, y pueden cambiar o interrumpir la Aplicación en cualquier momento.\n\n8. Tiendas de aplicaciones y plataformas\nSi obtuviste la Aplicación a través de una tienda de aplicaciones, las condiciones de esa tienda también se aplican a tu uso de la Aplicación.\n\n9. Cambios\nEstos Términos pueden cambiar. Si sigues usando la Aplicación después de un cambio, aceptas el cambio.\n\n10. Idioma\nLas traducciones se ofrecen por comodidad. Si difieren, prevalece la versión en inglés.\n\nContacto: yncdev@gmail.com';

  @override
  String get privacyTitle => 'Política de privacidad';

  @override
  String get openSourceLicenses => 'Licencias de código abierto';

  @override
  String get privacyBody =>
      'Última actualización: 6 de noviembre de 2026\n\nEsta política se aplica a Pic Merge para Android e iOS y a la extensión de Chrome Pic Merge (la \"Aplicación\").\n\nQué hace la Aplicación con tus archivos\nLa Aplicación lee las imágenes y los PDF que eliges y los combina en un solo archivo en tu dispositivo. Tus archivos nunca se envían a un servidor, y la Aplicación no tiene cuentas, publicidad ni analíticas.\n\nQué se almacena y dónde\nTodo lo siguiente permanece en tu dispositivo o en tu navegador:\n\n- Archivos que guardas, en la carpeta que usas: la carpeta predeterminada o una que elijas.\n- Historial reciente: de cada guardado, la hora, el formato, el número de elementos, el nombre, el tamaño y las dimensiones del archivo resultante, el nombre de la carpeta de guardado, la dirección de la disposición y el resultado. La aplicación móvil también conserva el nombre, el tamaño en píxeles y el tamaño de archivo de cada elemento y la escala aplicada, y conserva todo esto en una base de datos local hasta que se elimina la Aplicación. La extensión conserva los últimos 50 guardados en el almacenamiento del navegador.\n- La carpeta de guardado que elijas, si eliges una en lugar de la predeterminada.\n- Archivos temporales creados durante el procesamiento. Se eliminan cuando termina el procesamiento, cuando quitas el elemento de la lista, la próxima vez que compartes o la próxima vez que inicias la Aplicación.\n\nLas imágenes originales y sus rutas no se conservan en la Aplicación. La Aplicación no recopila, vende ni comparte ninguno de estos datos, y el desarrollador no puede acceder a ellos. Al eliminar la Aplicación se eliminan sus datos almacenados, excepto los archivos que hayas guardado en una carpeta fuera de la Aplicación.\n\nLa copia de seguridad de aplicaciones de Android está desactivada para la Aplicación. En iOS, la copia de seguridad propia de tu dispositivo, como la copia de seguridad de iCloud, puede incluir los datos de la Aplicación y los archivos de su carpeta, según los ajustes de tu dispositivo.\n\nPermisos\n- Android: no se solicita ningún permiso de internet, almacenamiento ni cámara. Los archivos se eligen mediante los selectores del sistema y las fotos se toman con la aplicación de cámara del sistema.\n- iOS: el sistema te pide permiso la primera vez que usas la cámara.\n- Extensión de Chrome: no se declara ningún permiso. Si eliges una carpeta de guardado, tu navegador pide acceso a esa carpeta.\n\nEnvío de comentarios\nLa opción Enviar comentarios de la aplicación móvil abre la aplicación de correo de tu dispositivo con la dirección y el asunto ya rellenados. El asunto incluye la versión de la aplicación, el modelo del dispositivo y la versión del sistema operativo, y puedes editarlo. No se envía nada a menos que lo envíes tú mismo. Tu mensaje lo gestiona después tu proveedor de correo, y el desarrollador recibe lo que envías.\n\nOtros servicios\nSi compartes un archivo, lo gestiona la hoja de compartir de tu dispositivo o la aplicación que elijas. Si obtuviste la Aplicación en una tienda de aplicaciones, las condiciones de privacidad de esa tienda se aplican a la tienda.\n\nCambios\nEsta política puede cambiar. Los cambios se publican en este documento.\n\nContacto\nyncdev@gmail.com';
}
