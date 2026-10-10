import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Build label shown by the diagnostics (`--dart-define=KURAN_BUILD=...`);
/// tells which build a home-screen app is really running.
const String kAudioBuildLabel = String.fromEnvironment(
  'KURAN_BUILD',
  defaultValue: 'yerel',
);

/// The web sound options read from the page address (only for trying out,
/// never shown to children):
/// - `?ses=eski`: the old `audioplayers` way, to compare on a device;
/// - `?sesTani=1`: a small log box over the app (copyable).
class WebAudioFlags {
  const WebAudioFlags({this.legacy = false, this.diagnostics = false});

  factory WebAudioFlags.fromAddress(Uri address) {
    final query = address.queryParameters;
    return WebAudioFlags(
      legacy: query['ses'] == 'eski',
      diagnostics: query['sesTani'] == '1',
    );
  }

  final bool legacy;
  final bool diagnostics;
}

/// The `?sesTani=1` log: events of the audio context and the audio
/// elements, kept in `window.__kuranAudioLog` and shown in a box with a
/// "copy" button, so a test on an iPhone needs no Mac.
class AudioDiagnostics {
  AudioDiagnostics({required this.engineName});

  final String engineName;
  final _lines = <String>[];
  final _started = web.window.performance.now();
  web.HTMLElement? _box;
  web.HTMLElement? _text;
  String Function()? status;

  void log(String event, [String? detail]) {
    final ms = (web.window.performance.now() - _started).round();
    final line = '${ms.toString().padLeft(7)} $event${detail == null ? '' : ' $detail'}';
    _lines.add(line);
    if (_lines.length > 400) _lines.removeAt(0);
    web.console.debug('[ses] $line'.toJS);
    _show();
  }

  String get report => [
    'derleme: $kAudioBuildLabel',
    'motor: $engineName',
    'tarayıcı: ${web.window.navigator.userAgent}',
    'ana ekran: ${_standalone()}',
    if (status != null) status!(),
    ..._lines,
  ].join('\n');

  bool _standalone() {
    try {
      return web.window.matchMedia('(display-mode: standalone)').matches;
    } catch (_) {
      return false;
    }
  }

  void _show() {
    final text = _text ?? _build();
    final head = [
      'derleme $kAudioBuildLabel · $engineName',
      if (status != null) status!(),
    ];
    final tail = _lines.length > 9 ? _lines.sublist(_lines.length - 9) : _lines;
    text.textContent = [...head, ...tail].join('\n');
  }

  web.HTMLElement _build() {
    final box = web.document.createElement('div') as web.HTMLElement;
    box.style.cssText =
        // Touches go through to the app (only the two buttons take them).
        'position:fixed;right:4px;top:35%;z-index:99999;max-width:70vw;'
        'background:rgba(0,0,0,.6);color:#fff;font:10px/1.25 monospace;'
        'padding:4px 6px;border-radius:6px;pointer-events:none;';
    final text = web.document.createElement('pre') as web.HTMLElement;
    text.style.cssText = 'margin:0;white-space:pre-wrap;pointer-events:none;';
    final copy = web.document.createElement('button') as web.HTMLElement;
    copy.textContent = 'Günlüğü kopyala';
    copy.style.cssText =
        'margin-top:4px;font:11px sans-serif;pointer-events:auto;';
    copy.addEventListener(
      'click',
      ((web.Event _) {
        unawaited(
          web.window.navigator.clipboard
              .writeText(report)
              .toDart
              .then((_) => log('günlük kopyalandı'))
              .catchError((Object _) => _download()),
        );
      }).toJS,
    );
    final hide = web.document.createElement('button') as web.HTMLElement;
    hide.textContent = 'Küçült';
    hide.style.cssText =
        'margin:4px 0 0 6px;font:11px sans-serif;pointer-events:auto;';
    hide.addEventListener(
      'click',
      ((web.Event _) {
        final hidden = text.style.display == 'none';
        text.style.display = hidden ? 'block' : 'none';
      }).toJS,
    );
    box
      ..append(text)
      ..append(copy)
      ..append(hide);
    web.document.body?.append(box);
    _box = box;
    _text = text;
    (web.window as JSObject)['__kuranAudioReport'] = (() => report.toJS).toJS;
    return text;
  }

  /// No clipboard (a plain `http://` address on the phone): a text file.
  void _download() {
    final url = web.URL.createObjectURL(
      web.Blob([report.toJS].toJS, web.BlobPropertyBag(type: 'text/plain')),
    );
    (web.document.createElement('a') as web.HTMLAnchorElement)
      ..href = url
      ..download = 'ses-gunlugu.txt'
      ..click();
    Timer(const Duration(seconds: 10), () => web.URL.revokeObjectURL(url));
    log('panoya yazılamadı, dosya indirildi');
  }

  bool get attached => _box != null;
}
