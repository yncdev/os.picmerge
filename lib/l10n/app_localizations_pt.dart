// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Pic Merge';

  @override
  String get appSubtitle => 'Juntar imagens';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancelar';

  @override
  String get clearList => 'Limpar';

  @override
  String get recentHistory => 'Histórico recente';

  @override
  String get errorLoadPhotos =>
      'Não foi possível carregar as fotos. Tente novamente.';

  @override
  String get errorCameraUnavailable => 'Não é possível usar a câmera.';

  @override
  String get errorLoadPdfs =>
      'Não foi possível carregar o PDF. Tente novamente.';

  @override
  String maxImagesReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$max imagens',
      one: '$max imagem',
    );
    return 'Você pode adicionar até $_temp0.';
  }

  @override
  String unsupportedFilesExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count arquivos foram excluídos porque o formato não é compatível.',
      one: '$count arquivo foi excluído porque o formato não é compatível.',
    );
    return '$_temp0';
  }

  @override
  String overLimitAdded(int max, int added) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$max imagens',
      one: '$max imagem',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added foram adicionadas',
      one: '$added foi adicionada',
    );
    return 'Você pode adicionar até $_temp0, então só $_temp1.';
  }

  @override
  String get clearConfirm =>
      'Remover todas as imagens selecionadas da lista?\nAs fotos originais não serão apagadas.';

  @override
  String get folderDialogTitle => 'Escolher pasta para salvar';

  @override
  String get folderDialogBodyAndroid =>
      'Escolha uma pasta como Documents ou uma pasta nova.\n\nNão é possível escolher a raiz do armazenamento interno, a própria pasta Download nem a pasta Android/data.';

  @override
  String get pickFolder => 'Escolher pasta';

  @override
  String useDefaultFolder(String name) {
    return 'Usar a pasta padrão ($name)';
  }

  @override
  String get pickOtherFolder => 'Escolher outra pasta';

  @override
  String get errorPickFolder =>
      'Não foi possível escolher a pasta. Tente novamente.';

  @override
  String savedTo(String folder, String file) {
    return 'Salvo: $folder/$file';
  }

  @override
  String get saveCancelled => 'Salvamento cancelado.';

  @override
  String get saveFailedTitle => 'Não foi possível salvar';

  @override
  String get shareFormatPrompt =>
      'Escolha o formato do arquivo para enviar por e-mail, aplicativos de mensagem e outros.';

  @override
  String shareAs(String format) {
    return 'Compartilhar como $format';
  }

  @override
  String get shareCancelled => 'Compartilhamento cancelado.';

  @override
  String get shareFailedTitle => 'Não foi possível compartilhar';

  @override
  String get crashTitle => 'O último salvamento não terminou';

  @override
  String get crashBody =>
      'O último salvamento foi interrompido. Mantenha o app aberto até terminar e, se continuar acontecendo, use menos imagens.';

  @override
  String emptyTitle(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: '$min imagens ou PDFs',
      one: '$min imagem ou PDF',
    );
    return 'Escolha pelo menos $_temp0 para juntar';
  }

  @override
  String get emptyHint => 'A direção do layout é definida automaticamente.';

  @override
  String get pickImages => 'Escolher imagens';

  @override
  String get pickPdf => 'Escolher PDF';

  @override
  String get takePhoto => 'Tirar foto';

  @override
  String get autoDirectionVertical =>
      'Automático: layout vertical (cima → baixo)';

  @override
  String get autoDirectionHorizontal =>
      'Automático: layout horizontal (esquerda → direita)';

  @override
  String get previewNoteOriginal =>
      'Esta é a prévia do PNG. O PNG tem linhas cinza entre as imagens. O PDF salva uma página por item, sem linhas.';

  @override
  String previewSummary(int pages, int perPaper) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pages páginas',
      one: '$pages página',
    );
    return '$_temp0 no total · $perPaper por folha';
  }

  @override
  String get previewNoteHorizontal =>
      'O PNG une as páginas lado a lado, com linhas cinza entre as imagens. O PDF salva cada página separadamente, sem linhas.';

  @override
  String get previewNoteVertical =>
      'O PNG une as páginas de cima para baixo, com linhas cinza entre as imagens. O PDF salva cada página separadamente, sem linhas.';

  @override
  String get paperOriginal => 'Tamanho original';

  @override
  String get orientationPortrait => 'Retrato';

  @override
  String get orientationLandscape => 'Paisagem';

  @override
  String get colorMode => 'Cor';

  @override
  String get grayscaleMode => 'P&B';

  @override
  String get imagesPerPaper => 'Imagens por folha';

  @override
  String get imageSize => 'Tamanho da imagem';

  @override
  String get margin => 'Margem';

  @override
  String selectedCount(int count, int max) {
    return 'Seleção $count/$max';
  }

  @override
  String get addItems => 'Adicionar';

  @override
  String get pickPhotos => 'Escolher fotos';

  @override
  String get pickPdfFiles => 'Escolher arquivos PDF';

  @override
  String get camera => 'Câmera';

  @override
  String get folderNotChosen => 'Pasta: ao salvar pela primeira vez';

  @override
  String folderCurrent(String name) {
    return 'Pasta: $name';
  }

  @override
  String get changeFolder => 'Alterar';

  @override
  String needMinImages(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: '$min imagens',
      one: '$min imagem',
    );
    return 'Escolha pelo menos $_temp0 para salvar.';
  }

  @override
  String saveAs(String format) {
    return 'Salvar $format';
  }

  @override
  String get share => 'Compartilhar';

  @override
  String shareTitle(String format) {
    return 'Compartilhar $format';
  }

  @override
  String processingImages(int current, int total) {
    return 'Processando imagens $current/$total';
  }

  @override
  String get buildingFile => 'Criando o arquivo';

  @override
  String get openingShare => 'Abrindo a janela de compartilhamento';

  @override
  String get saving => 'Salvando';

  @override
  String get cancelling => 'Cancelando…';

  @override
  String get mayTakeLong => 'Imagens grandes podem levar dezenas de segundos.';

  @override
  String get keepAppOpen => 'Mantenha o app aberto até terminar.';

  @override
  String get errorApplyCrop =>
      'Não foi possível aplicar o recorte. Tente novamente.';

  @override
  String get cropTitle => 'Recortar';

  @override
  String get cropApply => 'Aplicar';

  @override
  String get cropSelectAll => 'Selecionar tudo';

  @override
  String get errorOpenImage => 'Não é possível abrir a imagem.';

  @override
  String croppedSize(int width, int height) {
    return '$width×$height (recortada)';
  }

  @override
  String get removeFromList => 'Remover da lista';

  @override
  String get errorLoadHistory => 'Não foi possível carregar o histórico.';

  @override
  String historyRateEmpty(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'nos últimos $days dias',
      one: 'no último dia',
    );
    return 'Nenhum salvamento $_temp0.';
  }

  @override
  String historyRate(int days, int percent, int success, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'nos últimos $days dias',
      one: 'no último dia',
    );
    return 'Taxa de sucesso $_temp0: $percent% ($success/$total)';
  }

  @override
  String get historyEmpty => 'Você ainda não salvou nada.';

  @override
  String imageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imagens',
      one: '$count imagem',
    );
    return '$_temp0';
  }

  @override
  String get statusRunning => 'Em andamento';

  @override
  String get statusSuccess => 'Sucesso';

  @override
  String get statusFailed => 'Falha';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get statusCrashed => 'Encerrado inesperadamente';

  @override
  String get errorUnsupportedFormat =>
      'Há uma imagem em um formato não compatível.';

  @override
  String errorUnsupportedFormatAt(int n) {
    return 'A imagem $n está em um formato não compatível.';
  }

  @override
  String get errorCorruptFile => 'Há um arquivo de imagem danificado.';

  @override
  String errorCorruptFileAt(int n) {
    return 'O arquivo da imagem $n está danificado.';
  }

  @override
  String get errorSourceUnavailable =>
      'Não é possível abrir uma imagem. Escolha-a novamente.';

  @override
  String errorSourceUnavailableAt(int n) {
    return 'Não é possível abrir a imagem $n. Escolha-a novamente.';
  }

  @override
  String get errorOutOfSpace => 'Não há espaço de armazenamento suficiente.';

  @override
  String get errorFolderUnavailable =>
      'Não é possível acessar a pasta para salvar. Escolha uma pasta novamente.';

  @override
  String get errorOutputTooLarge =>
      'O arquivo gerado é grande demais. Use menos imagens.';

  @override
  String get errorOutOfMemory =>
      'Não há memória suficiente. Use menos imagens.';

  @override
  String get errorUnknown => 'Ocorreu um erro desconhecido.';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String get sendFeedback => 'Enviar comentários';

  @override
  String get termsTitle => 'Termos de uso';

  @override
  String get version => 'Versão';

  @override
  String get noMailAppTitle => 'Não é possível abrir um app de e-mail';

  @override
  String get noMailAppBody => 'Envie seus comentários para este endereço.';

  @override
  String get copyAddress => 'Copiar endereço';

  @override
  String get addressCopied => 'Endereço copiado.';

  @override
  String get termsBody =>
      'Última atualização: 5 de novembro de 2026\n\n1. Aceitação\nAo instalar ou usar o Pic Merge (o \"App\"), você concorda com estes Termos. Se não concordar, não use o App.\n\n2. Licença\nO App é um software de código aberto lançado sob a MIT License, e você pode usá-lo de acordo com essa licença. Componentes de terceiros mantêm suas próprias licenças.\n\n3. Suas responsabilidades\nSomente você é responsável pelos arquivos que processa, salva e compartilha com o App, por ter os direitos de usá-los e por cumprir as leis aplicáveis. Mantenha seus próprios backups de arquivos importantes.\n\n4. Seus dados\nO App processa os arquivos no seu dispositivo e não os envia a nenhum servidor. Se você usar Enviar comentários, o app de e-mail do seu dispositivo cria a mensagem, e o que você envia é tratado pelo seu provedor de e-mail.\n\n5. Sem garantia\nO App é fornecido \"NO ESTADO EM QUE SE ENCONTRA\" e \"CONFORME DISPONÍVEL\", sem garantia de qualquer tipo, expressa ou implícita, incluindo comercialização, adequação a uma finalidade específica e não violação. Não há garantia de que ele estará livre de erros ou interrupções, nem de que seus resultados serão precisos.\n\n6. Limitação de responsabilidade\nNa máxima extensão permitida pela lei aplicável, os autores, os detentores dos direitos autorais e os distribuidores não são responsáveis por qualquer reclamação, dano ou outra responsabilidade, incluindo perda de dados, lucros cessantes e danos indiretos ou consequenciais, decorrentes do App ou de seu uso ou relacionados a eles.\n\n7. Sem obrigação de suporte\nOs autores não têm obrigação de fornecer suporte, atualizações ou manutenção nem de responder a comentários, e podem alterar ou encerrar o App a qualquer momento.\n\n8. Lojas de aplicativos e plataformas\nSe você obteve o App por meio de uma loja de aplicativos, os termos dessa loja também se aplicam ao seu uso do App.\n\n9. Alterações\nEstes Termos podem mudar. Se você continuar usando o App após uma alteração, você aceita a alteração.\n\n10. Idioma\nAs traduções são fornecidas por conveniência. Se houver diferença, prevalece a versão em inglês.\n\nContato: yncdev@gmail.com';

  @override
  String get privacyTitle => 'Política de privacidade';

  @override
  String get openSourceLicenses => 'Licenças de código aberto';

  @override
  String get privacyBody =>
      'Última atualização: 6 de novembro de 2026\n\nEsta política abrange o Pic Merge para Android e iOS e a extensão do Chrome Pic Merge (o \"App\").\n\nO que o App faz com seus arquivos\nO App lê as imagens e os PDFs que você escolhe e os combina em um único arquivo no seu dispositivo. Seus arquivos nunca são enviados a um servidor, e o App não tem conta, publicidade nem análises.\n\nO que é armazenado e onde\nTudo o que segue fica no seu dispositivo ou no seu navegador:\n\n- Arquivos que você salva, na pasta que você usa: a pasta padrão ou uma que você escolher.\n- Histórico recente: de cada salvamento, o horário, o formato, o número de itens, o nome, o tamanho e as dimensões do arquivo resultante, o nome da pasta de salvamento, a direção do layout e o resultado. O app móvel também mantém o nome, o tamanho em pixels e o tamanho de arquivo de cada item e a escala aplicada, e mantém tudo isso em um banco de dados local até que o App seja excluído. A extensão mantém os últimos 50 salvamentos no armazenamento do navegador.\n- A pasta de salvamento escolhida, se você escolher uma em vez da padrão.\n- Arquivos temporários criados durante o processamento. Eles são excluídos quando o processamento termina, quando você remove o item da lista, no seu próximo compartilhamento ou na próxima vez que você iniciar o App.\n\nAs imagens originais e seus caminhos não são mantidos no App. O App não coleta, vende nem compartilha nenhum desses dados, e o desenvolvedor não pode acessá-los. Excluir o App remove seus dados armazenados, exceto os arquivos que você salvou em uma pasta fora do App.\n\nO backup de apps do Android está desativado para o App. No iOS, o backup do próprio dispositivo, como o Backup do iCloud, pode incluir os dados do App e os arquivos da pasta dele, dependendo das configurações do seu dispositivo.\n\nPermissões\n- Android: nenhuma permissão de internet, armazenamento ou câmera é solicitada. Os arquivos são escolhidos pelos seletores do sistema e as fotos são tiradas com o app de câmera do sistema.\n- iOS: o sistema pede sua permissão na primeira vez que você usa a câmera.\n- Extensão do Chrome: nenhuma permissão é declarada. Se você escolher uma pasta de salvamento, seu navegador pede acesso a essa pasta.\n\nEnvio de comentários\nA opção Enviar comentários do app móvel abre o app de e-mail do seu dispositivo com o endereço e o assunto preenchidos. O assunto inclui a versão do app, o modelo do dispositivo e a versão do sistema operacional, e você pode editá-lo. Nada é enviado a menos que você mesmo envie. Sua mensagem é então tratada pelo seu provedor de e-mail, e o desenvolvedor recebe o que você envia.\n\nOutros serviços\nSe você compartilhar um arquivo, a planilha de compartilhamento do seu dispositivo ou o app que você escolher cuida disso. Se você obteve o App em uma loja de aplicativos, os termos de privacidade dessa loja se aplicam à loja.\n\nAlterações\nEsta política pode mudar. As alterações são publicadas neste documento.\n\nContato\nyncdev@gmail.com';
}
