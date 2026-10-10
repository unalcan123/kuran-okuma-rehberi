import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:kuran_okuma_rehberi/services/sound_cache.dart';
import 'package:kuran_okuma_rehberi/services/web_audio/web_audio_engine.dart';
import 'package:kuran_okuma_rehberi/services/web_audio/web_audio_port.dart';

// The web engine's behaviour (docs/SES.md, "Web ses motoru") with the real
// AudioService and WebAudioEngine; only the browser is a fake that records
// what would have sounded.

const elif = 'audio/elifba/ders_1_harfler/01_elif.mp3';
const be = 'audio/elifba/ders_1_harfler/02_be.mp3';
const te = 'audio/elifba/ders_1_harfler/03_te.mp3';
const se = 'audio/elifba/ders_1_harfler/04_se.mp3';
const dogru = 'audio/oyunlar/dogru.mp3';
const fatiha1 = 'audio/sureler/01_fatiha/01.mp3';
const fatiha2 = 'audio/sureler/01_fatiha/02.mp3';
const turkce = 'audio/tr/s001_01.mp3';

class FakeSound implements DecodedSound {
  FakeSound(this.name, this.memorySize);
  final String name;
  @override
  final int memorySize;
  @override
  double get duration => 1.0;
}

class FakeVoice implements SoundVoice {
  FakeVoice(this.sound, this.offset, this._onEnded);
  final FakeSound sound;
  final double offset;
  final void Function() _onEnded;
  bool stopped = false;
  @override
  double position = 0;

  String get name => sound.name;

  /// The browser's "ended" — also after stop(), as Safari may send it.
  void end() => _onEnded();

  @override
  void stop() => stopped = true;
}

class FakeMedia implements MediaChannel {
  String? source;
  double rate = 1.0;
  bool playing = false;
  bool refuse = false;
  void Function()? _onEnded;
  Completer<void>? _pending;
  bool holdPlay = false;

  /// (source, speed when play() was called) for every play().
  final plays = <(String, double)>[];

  @override
  void setSource({
    required Uint8List? bytes,
    required String url,
    required String mimeType,
    required double rate,
    required void Function() onEnded,
    required void Function(Object error) onError,
  }) {
    _abortPending();
    source = url;
    this.rate = rate;
    playing = false;
    _onEnded = onEnded;
  }

  /// The element's "ended" for what it holds now.
  void Function() get endNow => _onEnded!;

  @override
  Future<void> play() {
    plays.add((source!, rate));
    if (refuse) return Future.error('NotAllowedError');
    playing = true;
    if (!holdPlay) return Future.value();
    return (_pending = Completer<void>()).future;
  }

  void finishPlay() => _pending?.complete();

  void _abortPending() {
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) {
      pending.completeError('AbortError');
    }
  }

  @override
  void pause() {
    playing = false;
    _abortPending();
  }

  @override
  void setRate(double rate) => this.rate = rate;

  @override
  void clear() {
    pause();
    source = null;
    _onEnded = null;
  }

  @override
  void dispose() => clear();
}

class FakePort extends WebAudioPort {
  @override
  AudioContextStatus status = AudioContextStatus.none;
  bool contextRuns = true;
  bool holdDecodes = false;
  int memoryPerSound = 100;

  final decoded = <String>[];
  final _held = <(String, Completer<DecodedSound>)>[];
  final voices = <FakeVoice>[];
  final medias = <FakeMedia>[];
  int resumes = 0;
  late void Function(bool visible) visibility;
  late void Function(AudioContextStatus status) contextStatus;

  List<FakeVoice> get sounding => [
    for (final voice in voices)
      if (!voice.stopped) voice,
  ];

  FakeMedia get media => medias.first;

  @override
  void attach({
    required void Function(bool visible) onVisibility,
    required void Function(AudioContextStatus status) onStatus,
  }) {
    visibility = onVisibility;
    contextStatus = onStatus;
  }

  @override
  void ensureContext() {
    if (status == AudioContextStatus.none) {
      status = AudioContextStatus.suspended;
    }
  }

  @override
  Future<bool> resume(Duration timeout) async {
    resumes++;
    if (contextRuns) status = AudioContextStatus.running;
    return contextRuns;
  }

  @override
  Future<DecodedSound> decode(Uint8List bytes) {
    final name = utf8.decode(bytes).replaceFirst('assets/', '');
    decoded.add(name);
    final sound = FakeSound(name, memoryPerSound);
    if (!holdDecodes) return Future.value(sound);
    final completer = Completer<DecodedSound>();
    _held.add((name, completer));
    return completer.future;
  }

  void failDecoding(String name) {
    final i = _held.indexWhere((held) => held.$1 == name);
    _held.removeAt(i).$2.completeError('EncodingError');
  }

  /// Lets the held decoding of [name] finish.
  void finishDecoding(String name) {
    final i = _held.indexWhere((held) => held.$1 == name);
    final (_, completer) = _held.removeAt(i);
    completer.complete(FakeSound(name, memoryPerSound));
  }

  @override
  SoundVoice start(
    DecodedSound sound, {
    double offset = 0,
    required void Function() onEnded,
  }) {
    final voice = FakeVoice(sound as FakeSound, offset, onEnded);
    voices.add(voice);
    return voice;
  }

  @override
  MediaChannel createMediaChannel() {
    final media = FakeMedia();
    medias.add(media);
    return media;
  }

  @override
  String assetUrl(String assetPath) => assetPath;

  @override
  void dispose() {}
}

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

typedef Rig = ({AudioService audio, FakePort port, WebAudioEngine engine});

Rig rig({int memoryBudget = 20 << 20}) {
  final port = FakePort()..status = AudioContextStatus.running;
  late WebAudioEngine engine;
  final audio = AudioService(
    // Each file's bytes are its own name, so the fake can tell them apart.
    cache: SoundCache(
      loader:
          (key) async => ByteData.sublistView(
            Uint8List.fromList(utf8.encode(key)),
          ),
    ),
    engine:
        (cache) =>
            engine = WebAudioEngine(port, cache, memoryBudget: memoryBudget),
  );
  addTearDown(audio.dispose);
  return (audio: audio, port: port, engine: engine);
}

void main() {
  group('which way a sound plays on the web', () {
    test('letters and game sounds are decoded; recitations keep the pitch '
        'in an element', () {
      expect(webSoundRouteFor(elif), WebSoundRoute.decoded);
      expect(webSoundRouteFor(dogru), WebSoundRoute.decoded);
      expect(webSoundRouteFor(fatiha1), WebSoundRoute.element);
      expect(webSoundRouteFor('audio/dualar/01_subhaneke/01.mp3'),
          WebSoundRoute.element);
      expect(webSoundRouteFor(turkce), WebSoundRoute.element);
      // Another speed would change a decoded sound's pitch.
      expect(webSoundRouteFor(elif, rate: 0.75), WebSoundRoute.element);
      // A long file is not decoded into memory.
      expect(webSoundRouteFor(elif, byteLength: 200 * 1024),
          WebSoundRoute.element);
    });
  });

  group('letters (decoded sounds)', () {
    test('a tap plays the letter once and the end is reported', () async {
      final r = rig();
      await r.audio.playAsset(elif);
      expect(r.port.voices.map((v) => v.name), [elif]);
      expect(r.audio.isPlaying, isTrue);
      r.port.voices.single.end();
      expect(r.audio.state, AudioPlaybackState.stopped);
      expect(r.audio.currentAsset, isNull);
    });

    test('quick taps: only the last letter sounds, the earlier ones never '
        'start late', () async {
      final r = rig();
      r.port.holdDecodes = true;
      unawaited(r.audio.playAsset(elif));
      unawaited(r.audio.playAsset(be));
      unawaited(r.audio.playAsset(te));
      await settle();
      // Decoding finishes in a mixed-up order.
      r.port.finishDecoding(be);
      r.port.finishDecoding(te);
      r.port.finishDecoding(elif);
      await settle();
      expect(r.port.voices.map((v) => v.name), [te]);
      expect(r.audio.currentAsset, te);
      // The late ones did not take over pause / resume either.
      await r.audio.pause();
      await r.audio.resume();
      expect(r.port.sounding.map((v) => v.name), [te]);
      // The decoded letters are still kept for the next tap.
      expect(r.engine.decodedAssets, containsAll([elif, be, te]));
    });

    test('an old sound\'s late "ended" does not end the new one', () async {
      final r = rig();
      await r.audio.playAsset(elif);
      final old = r.port.voices.single;
      await r.audio.playAsset(be);
      expect(old.stopped, isTrue);
      old.end(); // Safari may still send it after stop()
      expect(r.audio.currentAsset, be);
      expect(r.audio.isPlaying, isTrue);
      expect(r.port.sounding.map((v) => v.name), [be]);
      // The engine still holds the new one: stop silences it.
      await r.audio.stop();
      expect(r.port.sounding, isEmpty);
    });

    test('stop while the letter is still being prepared: nothing sounds '
        'later', () async {
      final r = rig();
      r.port.holdDecodes = true;
      unawaited(r.audio.playAsset(elif));
      await settle();
      await r.audio.stop();
      r.port.finishDecoding(elif);
      await settle();
      expect(r.port.voices, isEmpty);
      expect(r.audio.state, AudioPlaybackState.stopped);
    });

    test('pause and resume go on from where the letter was', () async {
      final r = rig();
      await r.audio.playAsset(elif);
      r.port.voices.single.position = 0.4;
      await r.audio.pause();
      expect(r.port.voices.single.stopped, isTrue);
      expect(r.audio.isPaused, isTrue);
      await r.audio.resume();
      expect(r.port.voices, hasLength(2));
      expect(r.port.voices.last.offset, 0.4);
      expect(r.audio.isPlaying, isTrue);
    });

    test('paused before it could start: starts once, on resume', () async {
      final r = rig();
      r.port.holdDecodes = true;
      unawaited(r.audio.playAsset(elif));
      await settle();
      await r.audio.pause();
      r.port.finishDecoding(elif);
      await settle();
      expect(r.port.voices, isEmpty);
      await r.audio.resume();
      await settle();
      expect(r.port.voices.map((v) => v.offset), [0]);
    });

    test('decoded sounds stay within their memory budget', () async {
      final r = rig(memoryBudget: 250); // two and a half sounds
      for (final letter in [elif, be, te, se]) {
        await r.audio.playAsset(letter);
        r.port.voices.last.end();
        expect(r.engine.memoryUsed, lessThanOrEqualTo(250));
      }
      expect(r.engine.decodedAssets, [te, se]);
      // A forgotten one is simply decoded again.
      await r.audio.playAsset(elif);
      expect(r.port.decoded.where((name) => name == elif), hasLength(2));
    });

    test('a file the browser cannot decode plays from an element', () async {
      final r = rig();
      final port = r.port;
      port.holdDecodes = true;
      unawaited(r.audio.playAsset(elif));
      await settle();
      port.failDecoding(elif);
      await settle();
      expect(port.voices, isEmpty);
      expect(port.media.plays.map((p) => p.$1), [elif]);
      expect(r.audio.isPlaying, isTrue);
    });
  });

  group('the audio context', () {
    test('when it will not run, the sound is dropped — it does not start '
        'by itself later', () async {
      final r = rig();
      r.port
        ..status = AudioContextStatus.suspended
        ..contextRuns = false;
      await r.audio.playAsset(elif);
      expect(r.audio.state, AudioPlaybackState.stopped);
      expect(r.port.voices, isEmpty);
      // The next touch wakes the context: still nothing plays by itself.
      r.port.status = AudioContextStatus.running;
      r.port.contextStatus(AudioContextStatus.running);
      await settle();
      expect(r.port.voices, isEmpty);
    });

    test('going to the background stops a letter; coming back only wakes '
        'the context', () async {
      final r = rig();
      await r.audio.playAsset(elif);
      await r.audio.playEffect(dogru);
      r.port.visibility(false);
      expect(r.port.sounding, isEmpty);
      expect(r.audio.state, AudioPlaybackState.stopped);
      r.port.status = AudioContextStatus.interrupted;
      final voices = r.port.voices.length;
      r.port.visibility(true);
      await settle();
      expect(r.port.resumes, greaterThan(0));
      expect(r.port.voices, hasLength(voices));
    });

    test('an interruption (call, Siri) stops a letter for good', () async {
      final r = rig();
      await r.audio.playPlaylist([dogru, elif]);
      r.port.status = AudioContextStatus.interrupted;
      r.port.contextStatus(AudioContextStatus.interrupted);
      expect(r.port.sounding, isEmpty);
      expect(r.audio.state, AudioPlaybackState.stopped);
      r.port.status = AudioContextStatus.running;
      r.port.contextStatus(AudioContextStatus.running);
      await settle();
      // The rest of the playlist does not go on by itself.
      expect(r.port.voices.map((v) => v.name), [dogru]);
    });

    test('the screen\'s letters are decoded only once the context exists '
        '(it is made on the first touch)', () async {
      final r = rig();
      r.port.status = AudioContextStatus.none;
      r.engine.preload([elif, be, fatiha1]);
      await settle();
      expect(r.port.decoded, isEmpty);
      r.port.status = AudioContextStatus.running;
      r.port.contextStatus(AudioContextStatus.running);
      await settle();
      // Surahs play from an element: never decoded into memory.
      expect(r.port.decoded, [elif, be]);
    });
  });

  group('effects', () {
    test('a game\'s effect sounds over the letter without stopping it; a '
        'new effect replaces the old one', () async {
      final r = rig();
      await r.audio.playAsset(elif);
      await r.audio.playEffect(dogru);
      expect(r.port.sounding.map((v) => v.name), [elif, dogru]);
      await r.audio.playEffect(dogru);
      expect(r.port.sounding.map((v) => v.name), [elif, dogru]);
      expect(r.port.voices.where((v) => v.stopped).single.name, dogru);
      // A new letter leaves the effect alone.
      await r.audio.playAsset(be);
      expect(r.port.sounding.map((v) => v.name), [dogru, be]);
      await r.audio.stopEffect();
      expect(r.port.sounding.map((v) => v.name), [be]);
    });
  });

  group('surahs and prayers (plain element)', () {
    test('the speed is set before the clip plays, every clip; back to 1.0 '
        'while stopped is kept for the next', () async {
      final r = rig();
      await r.audio.setPlaybackRate(0.75);
      await r.audio.playAsset(fatiha1);
      expect(r.port.media.plays.last, (fatiha1, 0.75));
      r.port.media.endNow();
      await r.audio.playAsset(fatiha2);
      expect(r.port.media.plays.last, (fatiha2, 0.75));
      await r.audio.setPlaybackRate(1.25); // while it plays
      expect(r.port.media.rate, 1.25);
      await r.audio.stop();
      // Leaving the reading screen: 1.0 while nothing plays.
      await r.audio.setPlaybackRate(1.0);
      await r.audio.playAsset(fatiha1);
      expect(r.port.media.plays.last, (fatiha1, 1.0));
      expect(r.port.voices, isEmpty);
    });

    test('a letter at another speed keeps its pitch (element, not a '
        'faster decoded sound)', () async {
      final r = rig();
      await r.audio.setPlaybackRate(0.75);
      await r.audio.playAsset(elif);
      expect(r.port.voices, isEmpty);
      expect(r.port.media.plays.single, (elif, 0.75));
    });

    test('Dinle: the playlist goes on at each end; the end of an earlier '
        'clip never moves the new one on', () async {
      final r = rig();
      await r.audio.playPlaylist([fatiha1, fatiha2]);
      final endOfFirst = r.port.media.endNow;
      endOfFirst();
      await settle();
      expect(r.audio.currentAsset, fatiha2);
      endOfFirst(); // late, for the clip before
      expect(r.audio.currentAsset, fatiha2);
      await r.audio.pause();
      expect(r.port.media.playing, isFalse);
      await r.audio.resume();
      expect(r.port.media.playing, isTrue);
      r.port.media.endNow();
      expect(r.audio.state, AudioPlaybackState.stopped);
      // fatiha2 twice: its start and the resume.
      expect(r.port.media.plays.map((p) => p.$1), [fatiha1, fatiha2, fatiha2]);
    });

    test('Ezberle: the same ayet again starts again from its beginning',
        () async {
      final r = rig();
      for (var i = 0; i < 3; i++) {
        await r.audio.playAsset(fatiha1);
        expect(r.audio.isPlaying, isTrue);
        r.port.media.endNow();
        expect(r.audio.state, AudioPlaybackState.stopped);
      }
      expect(r.port.media.plays, List.filled(3, (fatiha1, 1.0)));
    });

    test('pause / resume the same element; a tap on a letter takes '
        'over', () async {
      final r = rig();
      await r.audio.playAsset(fatiha1);
      await r.audio.pause();
      expect(r.port.media.playing, isFalse);
      await r.audio.resume();
      expect(r.port.media.playing, isTrue);
      expect(r.port.media.plays, hasLength(2));
      await r.audio.playAsset(elif);
      expect(r.port.media.source, isNull); // let go of the surah
      expect(r.port.sounding.map((v) => v.name), [elif]);
    });

    test('an element the browser refuses to play leaves the state '
        'stopped', () async {
      final r = rig();
      await r.audio.playAsset(turkce);
      r.port.media
        ..endNow()
        ..refuse = true;
      await r.audio.playAsset(turkce);
      expect(r.audio.state, AudioPlaybackState.stopped);
      expect(r.audio.currentAsset, isNull);
    });

    test('a quick second tap while the first is still starting: the first '
        'one\'s abort is not an error', () async {
      final r = rig();
      await r.audio.playAsset(fatiha1);
      r.port.media.holdPlay = true; // the browser takes its time to start
      final second = r.audio.playAsset(fatiha2);
      final third = r.audio.playAsset(fatiha1);
      r.port.media.finishPlay();
      await Future.wait([second, third]);
      expect(r.audio.currentAsset, fatiha1);
      expect(r.audio.isPlaying, isTrue);
      expect(r.port.media.source, fatiha1);
    });
  });
}
