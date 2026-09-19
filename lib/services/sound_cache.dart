import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import 'sound_store.dart';

/// Names the stored copy of the recordings. **Change it whenever a file in
/// `assets/audio/` changes** (`test/audio_assets_test.dart` fails and shows
/// the new value); otherwise visitors keep hearing the old recording.
const String kSoundCacheVersion = '89a425bc';

/// Keeps sound files in memory so a tap never waits on the network.
///
/// On the web every sound is a separate download; asking for the same
/// clip through here fetches it once and later plays start from memory.
/// With a [store], sounds are also kept on the device, so the next visit
/// reads them from there instead of downloading again.
///
/// [assetPath] is the path as `AssetSource` takes it, relative to the
/// `assets/` folder (`audio/elifba/...`).
class SoundCache {
  SoundCache({
    Future<ByteData> Function(String key)? loader,
    this.store,
    this.concurrency = 6,
  }) : _loader = loader ?? rootBundle.load;

  final Future<ByteData> Function(String key) _loader;
  final SoundStore? store;

  /// How many files [preload] fetches at once.
  final int concurrency;

  final _ready = <String, Uint8List>{};
  final _loading = <String, Future<Uint8List?>>{};

  int get length => _ready.length;

  /// The sound if it has already been loaded.
  Uint8List? peek(String assetPath) => _ready[assetPath];

  /// Loads one sound now (or joins the download already under way).
  /// Returns null if it cannot be loaded; a later call tries again.
  Future<Uint8List?> load(String assetPath) {
    final ready = _ready[assetPath];
    if (ready != null) return Future.value(ready);
    return _loading[assetPath] ??= _fetch(assetPath);
  }

  Future<Uint8List?> _fetch(String assetPath) async {
    // Yield first so the caller has registered this download before any
    // failure can clear it.
    await null;
    try {
      final stored = await _readStored(assetPath);
      if (stored != null) {
        _ready[assetPath] = stored;
        return stored;
      }
      final data = await _loader('assets/$assetPath');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      _ready[assetPath] = bytes;
      unawaited(_writeStored(assetPath, bytes));
      return bytes;
    } catch (_) {
      return null;
    } finally {
      _loading.remove(assetPath);
    }
  }

  Future<Uint8List?> _readStored(String assetPath) async {
    try {
      return await store?.read(assetPath);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeStored(String assetPath, Uint8List bytes) async {
    try {
      await store?.write(assetPath, bytes);
    } catch (_) {
      // Not being able to keep it only means downloading again next visit.
    }
  }

  /// Fetches every not-yet-loaded sound in [assetPaths], in order, a few
  /// at a time. Failures are skipped; the sound is then just loaded when
  /// it is played.
  Future<void> preload(Iterable<String> assetPaths) {
    final pending = Queue<String>.of(
      LinkedHashSet<String>.of(assetPaths).where(
        (path) => !_ready.containsKey(path) && !_loading.containsKey(path),
      ),
    );
    Future<void> worker() async {
      while (pending.isNotEmpty) {
        await load(pending.removeFirst());
      }
    }

    final workers = math.min(concurrency, pending.length);
    return Future.wait([for (var i = 0; i < workers; i++) worker()]);
  }
}
