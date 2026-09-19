import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'sound_store_base.dart';

/// The browser's Cache Storage under a name that carries [version], so
/// changed recordings never meet stale copies (and older versions'
/// caches are deleted). Does not depend on how or where the site is
/// hosted — Flutter's own service worker only caches sites served from
/// the domain root.
SoundStore? createSoundStore(String version) => WebSoundStore(version);

class WebSoundStore implements SoundStore {
  WebSoundStore(String version) : _name = '$_prefix$version';

  static const _prefix = 'kuran-sounds-';

  final String _name;
  Future<web.Cache>? _cache;

  Future<web.Cache> _open() => _cache ??= _openAndClean();

  Future<web.Cache> _openAndClean() async {
    final storage = web.window.caches;
    final cache = await storage.open(_name).toDart;
    try {
      for (final name in (await storage.keys().toDart).toDart) {
        final other = name.toDart;
        if (other.startsWith(_prefix) && other != _name) {
          await storage.delete(other).toDart;
        }
      }
    } catch (_) {
      // Leftover old caches only waste space.
    }
    return cache;
  }

  // Never fetched: only a stable key, resolved against the page's address.
  String _key(String assetPath) => 'kuran-sounds/$assetPath';

  @override
  Future<Uint8List?> read(String assetPath) async {
    try {
      final cache = await _open();
      final hit = await cache.match(_key(assetPath).toJS).toDart;
      if (hit == null) return null;
      final buffer = await hit.arrayBuffer().toDart;
      return buffer.toDart.asUint8List();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String assetPath, Uint8List bytes) async {
    try {
      final cache = await _open();
      await cache.put(_key(assetPath).toJS, web.Response(bytes.toJS)).toDart;
    } catch (_) {
      // Storage full or unavailable (private mode): download again next time.
    }
  }
}
