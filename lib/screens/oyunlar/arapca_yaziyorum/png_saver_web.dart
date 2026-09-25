import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'png_saver_base.dart';

/// Tarayıcıda PNG'yi indirir (İndirilenler).
Future<SaveResult> savePng(Uint8List bytes, String fileName) async {
  try {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'image/png'),
    );
    final url = web.URL.createObjectURL(blob);
    final a =
        web.HTMLAnchorElement()
          ..href = url
          ..download = '$fileName.png'
          ..style.display = 'none';
    web.document.body?.append(a);
    a.click();
    a.remove();
    web.URL.revokeObjectURL(url);
    return const SaveResult(SaveOutcome.saved, 'İndirilenler');
  } catch (_) {
    return const SaveResult(SaveOutcome.failed);
  }
}
