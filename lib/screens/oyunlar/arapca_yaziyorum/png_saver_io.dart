import 'dart:io';
import 'dart:typed_data';

import 'png_saver_base.dart';

/// Masaüstünde (Windows/macOS/Linux) kullanıcının İndirilenler klasörüne
/// yazar. Android/iOS'ta yeni bir eklenti (galeri/paylaşım) olmadan
/// kullanıcının görebileceği kalıcı bir yere kaydedilemediği için
/// [SaveOutcome.unsupported] döner — başarılı gibi davranılmaz.
Future<SaveResult> savePng(Uint8List bytes, String fileName) async {
  try {
    final String? home;
    if (Platform.isWindows) {
      home = Platform.environment['USERPROFILE'];
    } else if (Platform.isMacOS || Platform.isLinux) {
      home = Platform.environment['HOME'];
    } else {
      return const SaveResult(SaveOutcome.unsupported);
    }
    if (home == null) return const SaveResult(SaveOutcome.failed);
    final dir = Directory('$home${Platform.pathSeparator}Downloads');
    if (!dir.existsSync()) return const SaveResult(SaveOutcome.failed);
    var file = File('${dir.path}${Platform.pathSeparator}$fileName.png');
    for (var i = 2; file.existsSync(); i++) {
      file = File('${dir.path}${Platform.pathSeparator}$fileName ($i).png');
    }
    await file.writeAsBytes(bytes, flush: true);
    return SaveResult(SaveOutcome.saved, file.path);
  } catch (_) {
    return const SaveResult(SaveOutcome.failed);
  }
}
