// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'Pic Merge';

  @override
  String get appSubtitle => 'Gabung Gambar';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Batal';

  @override
  String get clearList => 'Kosongkan';

  @override
  String get recentHistory => 'Riwayat terbaru';

  @override
  String get errorLoadPhotos => 'Foto tidak dapat dimuat. Coba lagi.';

  @override
  String get errorCameraUnavailable => 'Kamera tidak dapat digunakan.';

  @override
  String get errorLoadPdfs => 'PDF tidak dapat dimuat. Coba lagi.';

  @override
  String maxImagesReached(int max) {
    return 'Anda dapat menambahkan hingga $max gambar.';
  }

  @override
  String unsupportedFilesExcluded(int count) {
    return '$count file tidak disertakan karena formatnya tidak didukung.';
  }

  @override
  String overLimitAdded(int max, int added) {
    return 'Anda dapat menambahkan hingga $max gambar, jadi hanya $added gambar yang ditambahkan.';
  }

  @override
  String get clearConfirm =>
      'Hapus semua gambar yang dipilih dari daftar?\nFoto asli tidak akan dihapus.';

  @override
  String get folderDialogTitle => 'Pilih folder penyimpanan';

  @override
  String get folderDialogBodyAndroid =>
      'Pilih folder seperti Documents atau folder yang baru dibuat.\n\nTingkat teratas penyimpanan internal, folder Download itu sendiri, dan folder Android/data tidak dapat dipilih.';

  @override
  String get pickFolder => 'Pilih folder';

  @override
  String useDefaultFolder(String name) {
    return 'Gunakan folder default ($name)';
  }

  @override
  String get pickOtherFolder => 'Pilih folder lain';

  @override
  String get errorPickFolder => 'Folder tidak dapat dipilih. Coba lagi.';

  @override
  String savedTo(String folder, String file) {
    return 'Tersimpan: $folder/$file';
  }

  @override
  String get saveCancelled => 'Penyimpanan dibatalkan.';

  @override
  String get saveFailedTitle => 'Tidak dapat menyimpan';

  @override
  String get shareFormatPrompt =>
      'Pilih format file yang akan dikirim lewat email, aplikasi pesan, dan lainnya.';

  @override
  String shareAs(String format) {
    return 'Bagikan sebagai $format';
  }

  @override
  String get shareCancelled => 'Berbagi dibatalkan.';

  @override
  String get shareFailedTitle => 'Tidak dapat membagikan';

  @override
  String get crashTitle => 'Penyimpanan terakhir belum selesai';

  @override
  String get crashBody =>
      'Penyimpanan terakhir terhenti di tengah jalan. Biarkan aplikasi tetap terbuka hingga penyimpanan selesai, dan jika terus terjadi, kurangi jumlah gambar.';

  @override
  String emptyTitle(int min) {
    return 'Pilih minimal $min gambar atau PDF untuk digabungkan';
  }

  @override
  String get emptyHint => 'Arah tata letak ditentukan secara otomatis.';

  @override
  String get pickImages => 'Pilih gambar';

  @override
  String get pickPdf => 'Pilih PDF';

  @override
  String get takePhoto => 'Ambil foto';

  @override
  String get autoDirectionVertical =>
      'Otomatis: tata letak vertikal (atas → bawah)';

  @override
  String get autoDirectionHorizontal =>
      'Otomatis: tata letak horizontal (kiri → kanan)';

  @override
  String get previewNoteOriginal =>
      'Ini pratinjau PNG. PNG memiliki garis abu-abu di antara gambar. PDF menyimpan satu halaman per item, tanpa garis.';

  @override
  String previewSummary(int pages, int perPaper) {
    return 'Total $pages halaman · $perPaper per lembar';
  }

  @override
  String get previewNoteHorizontal =>
      'PNG menyambung halaman berdampingan, dengan garis abu-abu di antara gambar. PDF menyimpan setiap halaman secara terpisah, tanpa garis.';

  @override
  String get previewNoteVertical =>
      'PNG menyambung halaman dari atas ke bawah, dengan garis abu-abu di antara gambar. PDF menyimpan setiap halaman secara terpisah, tanpa garis.';

  @override
  String get paperOriginal => 'Ukuran asli';

  @override
  String get orientationPortrait => 'Potret';

  @override
  String get orientationLandscape => 'Lanskap';

  @override
  String get colorMode => 'Warna';

  @override
  String get grayscaleMode => 'Hitam putih';

  @override
  String get imagesPerPaper => 'Gambar per lembar';

  @override
  String get imageSize => 'Ukuran gambar';

  @override
  String get margin => 'Margin';

  @override
  String selectedCount(int count, int max) {
    return 'Dipilih $count/$max';
  }

  @override
  String get addItems => 'Tambah';

  @override
  String get pickPhotos => 'Pilih foto';

  @override
  String get pickPdfFiles => 'Pilih file PDF';

  @override
  String get camera => 'Kamera';

  @override
  String get folderNotChosen => 'Folder: saat pertama menyimpan';

  @override
  String folderCurrent(String name) {
    return 'Folder: $name';
  }

  @override
  String get changeFolder => 'Ubah';

  @override
  String needMinImages(int min) {
    return 'Pilih minimal $min gambar untuk menyimpan.';
  }

  @override
  String saveAs(String format) {
    return 'Simpan $format';
  }

  @override
  String get share => 'Bagikan';

  @override
  String shareTitle(String format) {
    return 'Bagikan $format';
  }

  @override
  String processingImages(int current, int total) {
    return 'Memproses gambar $current/$total';
  }

  @override
  String get buildingFile => 'Membuat file';

  @override
  String get openingShare => 'Membuka jendela berbagi';

  @override
  String get saving => 'Menyimpan';

  @override
  String get cancelling => 'Membatalkan…';

  @override
  String get mayTakeLong => 'Gambar besar bisa memerlukan puluhan detik.';

  @override
  String get keepAppOpen => 'Biarkan aplikasi tetap terbuka hingga selesai.';

  @override
  String get errorApplyCrop => 'Pangkasan tidak dapat diterapkan. Coba lagi.';

  @override
  String get cropTitle => 'Pangkas';

  @override
  String get cropApply => 'Terapkan';

  @override
  String get cropSelectAll => 'Pilih semua';

  @override
  String get errorOpenImage => 'Gambar tidak dapat dibuka.';

  @override
  String croppedSize(int width, int height) {
    return '$width×$height (dipangkas)';
  }

  @override
  String get removeFromList => 'Hapus dari daftar';

  @override
  String get errorLoadHistory => 'Riwayat tidak dapat dimuat.';

  @override
  String historyRateEmpty(int days) {
    return 'Tidak ada penyimpanan dalam $days hari terakhir.';
  }

  @override
  String historyRate(int days, int percent, int success, int total) {
    return 'Tingkat keberhasilan $days hari terakhir: $percent% ($success/$total)';
  }

  @override
  String get historyEmpty => 'Anda belum pernah menyimpan.';

  @override
  String imageCount(int count) {
    return '$count gambar';
  }

  @override
  String get statusRunning => 'Berjalan';

  @override
  String get statusSuccess => 'Berhasil';

  @override
  String get statusFailed => 'Gagal';

  @override
  String get statusCancelled => 'Dibatalkan';

  @override
  String get statusCrashed => 'Berhenti tidak normal';

  @override
  String get errorUnsupportedFormat =>
      'Ada gambar dengan format yang tidak didukung.';

  @override
  String errorUnsupportedFormatAt(int n) {
    return 'Gambar ke-$n memiliki format yang tidak didukung.';
  }

  @override
  String get errorCorruptFile => 'Ada file gambar yang rusak.';

  @override
  String errorCorruptFileAt(int n) {
    return 'File gambar ke-$n rusak.';
  }

  @override
  String get errorSourceUnavailable => 'Gambar tidak dapat dibuka. Pilih lagi.';

  @override
  String errorSourceUnavailableAt(int n) {
    return 'Gambar ke-$n tidak dapat dibuka. Pilih lagi.';
  }

  @override
  String get errorOutOfSpace => 'Ruang penyimpanan tidak cukup.';

  @override
  String get errorFolderUnavailable =>
      'Folder penyimpanan tidak dapat diakses. Pilih folder lagi.';

  @override
  String get errorOutputTooLarge =>
      'File hasil terlalu besar. Kurangi jumlah gambar.';

  @override
  String get errorOutOfMemory => 'Memori tidak cukup. Kurangi jumlah gambar.';

  @override
  String get errorUnknown => 'Terjadi kesalahan yang tidak diketahui.';

  @override
  String get aboutTitle => 'Tentang';

  @override
  String get sendFeedback => 'Kirim masukan';

  @override
  String get termsTitle => 'Ketentuan penggunaan';

  @override
  String get version => 'Versi';

  @override
  String get noMailAppTitle => 'Aplikasi email tidak dapat dibuka';

  @override
  String get noMailAppBody => 'Kirim masukan Anda ke alamat ini.';

  @override
  String get copyAddress => 'Salin alamat';

  @override
  String get addressCopied => 'Alamat disalin.';

  @override
  String get termsBody =>
      'Terakhir diperbarui: 5 November 2026\n\n1. Penerimaan\nDengan memasang atau menggunakan Pic Merge (\"Aplikasi\"), Anda menyetujui Ketentuan ini. Jika Anda tidak setuju, jangan gunakan Aplikasi.\n\n2. Lisensi\nAplikasi adalah perangkat lunak sumber terbuka yang dirilis di bawah MIT License, dan Anda dapat menggunakannya sesuai lisensi tersebut. Komponen pihak ketiga tetap memakai lisensinya masing-masing.\n\n3. Tanggung jawab Anda\nHanya Anda yang bertanggung jawab atas file yang Anda proses, simpan, dan bagikan dengan Aplikasi, atas kepemilikan hak untuk menggunakannya, dan atas kepatuhan terhadap hukum yang berlaku. Simpan cadangan file penting Anda sendiri.\n\n4. Data Anda\nAplikasi memproses file di perangkat Anda dan tidak mengirimkannya ke server mana pun. Jika Anda menggunakan Kirim masukan, aplikasi email di perangkat Anda membuat pesan, dan apa yang Anda kirim ditangani oleh penyedia email Anda.\n\n5. Tanpa jaminan\nAplikasi disediakan \"SEBAGAIMANA ADANYA\" dan \"SEBAGAIMANA TERSEDIA\", tanpa jaminan apa pun, baik tersurat maupun tersirat, termasuk kelayakan untuk diperdagangkan, kesesuaian untuk tujuan tertentu, dan tidak adanya pelanggaran. Tidak ada jaminan bahwa Aplikasi bebas dari kesalahan atau gangguan, atau bahwa hasilnya akurat.\n\n6. Batasan tanggung jawab\nSejauh diizinkan secara maksimal oleh hukum yang berlaku, para penulis, pemegang hak cipta, dan distributor tidak bertanggung jawab atas klaim, kerugian, atau tanggung jawab lain apa pun, termasuk kehilangan data, kehilangan keuntungan, serta kerugian tidak langsung atau konsekuensial, yang timbul dari atau berkaitan dengan Aplikasi atau penggunaannya.\n\n7. Tidak ada kewajiban dukungan\nPara penulis tidak berkewajiban menyediakan dukungan, pembaruan, atau pemeliharaan maupun membalas masukan, dan dapat mengubah atau menghentikan Aplikasi kapan saja.\n\n8. Toko aplikasi dan platform\nJika Anda memperoleh Aplikasi melalui toko aplikasi, ketentuan toko tersebut juga berlaku untuk penggunaan Aplikasi oleh Anda.\n\n9. Perubahan\nKetentuan ini dapat berubah. Jika Anda terus menggunakan Aplikasi setelah perubahan, Anda menerima perubahan tersebut.\n\n10. Bahasa\nTerjemahan disediakan untuk kemudahan. Jika terdapat perbedaan, versi bahasa Inggris yang berlaku.\n\nKontak: yncdev@gmail.com';

  @override
  String get privacyTitle => 'Kebijakan privasi';

  @override
  String get openSourceLicenses => 'Lisensi sumber terbuka';

  @override
  String get privacyBody =>
      'Terakhir diperbarui: 6 November 2026\n\nKebijakan ini mencakup Pic Merge untuk Android dan iOS serta ekstensi Chrome Pic Merge (\"Aplikasi\").\n\nApa yang dilakukan Aplikasi terhadap file Anda\nAplikasi membaca gambar dan PDF yang Anda pilih lalu menggabungkannya menjadi satu file di perangkat Anda. File Anda tidak pernah dikirim ke server, dan Aplikasi tidak memiliki akun, iklan, atau analitik.\n\nApa yang disimpan, dan di mana\nSemua yang berikut tetap berada di perangkat atau browser Anda:\n\n- File yang Anda simpan, di folder yang Anda gunakan: folder default atau folder yang Anda pilih.\n- Riwayat terbaru: untuk setiap penyimpanan, waktu, format, jumlah item, nama, ukuran, dan dimensi file hasil, nama folder penyimpanan, arah tata letak, serta hasilnya. Aplikasi seluler juga menyimpan nama, ukuran piksel, dan ukuran file setiap item serta skala yang diterapkan, dan menyimpan semua ini di database lokal hingga Aplikasi dihapus. Ekstensi menyimpan 50 penyimpanan terakhir di penyimpanan browser.\n- Folder penyimpanan pilihan Anda, jika Anda memilih satu sebagai pengganti folder default.\n- File sementara yang dibuat saat pemrosesan. File ini dihapus saat pemrosesan selesai, saat Anda menghapus item dari daftar, saat Anda berbagi berikutnya, atau saat Anda memulai Aplikasi berikutnya.\n\nGambar asli dan jalurnya tidak disimpan di Aplikasi. Aplikasi tidak mengumpulkan, menjual, atau membagikan data ini, dan pengembang tidak dapat mengaksesnya. Menghapus Aplikasi akan menghapus data yang disimpannya, kecuali file yang Anda simpan ke folder di luar Aplikasi.\n\nPencadangan aplikasi Android dinonaktifkan untuk Aplikasi. Di iOS, cadangan perangkat Anda sendiri, seperti Cadangan iCloud, dapat menyertakan data Aplikasi dan file di foldernya, tergantung pada pengaturan perangkat Anda.\n\nIzin\n- Android: tidak ada izin internet, penyimpanan, atau kamera yang diminta. File dipilih melalui pemilih sistem dan foto diambil dengan aplikasi kamera sistem.\n- iOS: sistem meminta izin Anda saat pertama kali Anda menggunakan kamera.\n- Ekstensi Chrome: tidak ada izin yang dideklarasikan. Jika Anda memilih folder penyimpanan, browser Anda meminta akses ke folder tersebut.\n\nMengirim masukan\nOpsi Kirim masukan di aplikasi seluler membuka aplikasi email di perangkat Anda dengan alamat dan subjek yang sudah terisi. Subjek mencakup versi aplikasi, model perangkat, dan versi OS, dan Anda dapat mengubahnya. Tidak ada yang dikirim kecuali Anda sendiri yang mengirimnya. Pesan Anda kemudian ditangani oleh penyedia email Anda, dan pengembang menerima apa yang Anda kirim.\n\nLayanan lain\nJika Anda membagikan file, lembar berbagi perangkat Anda atau aplikasi yang Anda pilih yang menanganinya. Jika Anda memperoleh Aplikasi dari toko aplikasi, ketentuan privasi toko tersebut berlaku untuk toko itu.\n\nPerubahan\nKebijakan ini dapat berubah. Perubahan dipublikasikan dalam dokumen ini.\n\nKontak\nyncdev@gmail.com';
}
