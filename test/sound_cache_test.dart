import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/services/sound_cache.dart';

ByteData bytesOf(String text) =>
    ByteData.sublistView(Uint8List.fromList(text.codeUnits));

void main() {
  test('loads a sound once and serves it from memory afterwards', () async {
    final asked = <String>[];
    final cache = SoundCache(
      loader: (key) async {
        asked.add(key);
        return bytesOf(key);
      },
    );
    expect(cache.peek('audio/a.mp3'), isNull);
    final first = await cache.load('audio/a.mp3');
    expect(String.fromCharCodes(first!), 'assets/audio/a.mp3');
    expect(cache.peek('audio/a.mp3'), same(first));
    expect(await cache.load('audio/a.mp3'), same(first));
    expect(asked, ['assets/audio/a.mp3'], reason: 'fetched a single time');
    expect(cache.length, 1);
  });

  test('two requests for the same sound share one download', () async {
    var calls = 0;
    final gate = Completer<void>();
    final cache = SoundCache(
      loader: (key) async {
        calls++;
        await gate.future;
        return bytesOf('x');
      },
    );
    final a = cache.load('audio/a.mp3');
    final b = cache.load('audio/a.mp3');
    gate.complete();
    expect(await a, await b);
    expect(calls, 1);
  });

  test('preload fetches everything once, skipping repeats and loaded ones', () async {
    final asked = <String>[];
    final cache = SoundCache(
      loader: (key) async {
        asked.add(key);
        return bytesOf(key);
      },
    );
    await cache.load('audio/a.mp3');
    asked.clear();
    await cache.preload([
      'audio/a.mp3',
      'audio/b.mp3',
      'audio/b.mp3',
      'audio/c.mp3',
    ]);
    expect(asked.toSet(), {'assets/audio/b.mp3', 'assets/audio/c.mp3'});
    expect(asked.length, 2);
    expect(cache.length, 3);
    // A second preload of the same list does no work.
    asked.clear();
    await cache.preload(['audio/a.mp3', 'audio/b.mp3', 'audio/c.mp3']);
    expect(asked, isEmpty);
  });

  test('preload never runs more downloads at once than allowed', () async {
    var active = 0;
    var peak = 0;
    final cache = SoundCache(
      concurrency: 3,
      loader: (key) async {
        active++;
        if (active > peak) peak = active;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        active--;
        return bytesOf(key);
      },
    );
    await cache.preload([for (var i = 0; i < 20; i++) 'audio/$i.mp3']);
    expect(cache.length, 20);
    expect(peak, 3);
  });

  test('a sound that fails to load is skipped, and can be retried', () async {
    var failing = true;
    final cache = SoundCache(
      loader: (key) async {
        if (key.endsWith('bad.mp3') && failing) throw Exception('404');
        return bytesOf(key);
      },
    );
    await cache.preload(['audio/ok.mp3', 'audio/bad.mp3', 'audio/ok2.mp3']);
    expect(cache.peek('audio/ok.mp3'), isNotNull);
    expect(cache.peek('audio/ok2.mp3'), isNotNull);
    expect(cache.peek('audio/bad.mp3'), isNull);
    expect(await cache.load('audio/bad.mp3'), isNull);
    failing = false;
    expect(await cache.load('audio/bad.mp3'), isNotNull);
  });

  test('a loader that throws at once does not leave the sound stuck', () async {
    var throwNow = true;
    final cache = SoundCache(
      loader: (key) {
        if (throwNow) throw StateError('sync failure');
        return Future.value(bytesOf(key));
      },
    );
    expect(await cache.load('audio/a.mp3'), isNull);
    throwNow = false;
    expect(await cache.load('audio/a.mp3'), isNotNull);
  });

  test('a tap can jump the queue: loading a queued sound works mid-preload', () async {
    final cache = SoundCache(
      concurrency: 1,
      loader: (key) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return bytesOf(key);
      },
    );
    final preload = cache.preload([for (var i = 0; i < 6; i++) 'audio/$i.mp3']);
    final tapped = await cache.load('audio/5.mp3');
    expect(tapped, isNotNull);
    await preload;
    expect(cache.length, 6);
  });
}
