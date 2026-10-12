import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import 'audio_service.dart';
import 'turkish_audio_catalog.dart';

/// Oyunlardaki sesli öğretmenin konuşmaları — merkezi liste.
///
/// * Kimlik kalıcıdır; ses `assets/audio/<dil>/<id>.mp3` (her aktif dilde).
/// * Metinler ve çevirileri: `tool/i18n/teacher_lines.json`; ses üretimi
///   `tool/i18n/teacher_audio_<dil>.json` + üretici (`docs/OGRETMEN_SESI.md`).
/// * Yapay zekâ öğretmen sesidir; hocamızın orijinal kayıtları (harf, ders)
///   ayrı sistemdir ve hiç değişmez. Konuşmalarda Arapça yok.
/// * Aynı anlamdaki cümle tek kayıttır; var olan oyun kaydı yeniden
///   kullanılabilir ([doingWell]).
enum TeacherLine {
  newLetters(
    'v_new_letters',
    'Şimdi yeni harfler öğreneceğiz. Harfi dinle ve doğru kutuya sürükle.',
  ),
  reviewOld('v_review_old', 'Şimdi eski harfleri de tekrar edeceğiz.'),
  reinforce('v_reinforce', 'Zorlandığın harflere birlikte bakalım.'),
  dailyStart('v_daily_start', 'Önce eski harfleri kısaca tekrar edelim.'),
  mastery('v_mastery', 'Bütün harflerle karışık oynuyoruz.'),
  tryAgain('v_try_again', 'Tekrar deneyelim.', polite: true),
  lookDots('v_look_dots', 'Bu harfin noktalarına dikkat et.', polite: true),
  hint('v_hint', 'Parlayan harfe bir bak.', polite: true),
  correct('v_correct', 'Aferin, doğru cevap!', polite: true),
  perfect('v_perfect', 'Harika! Hepsini ilk denemede bildin.'),

  /// Var olan oyun kaydı (game_narrations): yeni ses üretilmez.
  doingWell('game_3c3e8f3bf784b2a4', 'Güzel gidiyorsun!', reused: true),
  learned(
    'v_learned',
    'Aferin! Yeni harfleri öğrendin. Şimdi eskilerle karışık tekrar yapalım.',
  ),
  levelUp(
    'v_level_up',
    'Tebrikler! Yeni seviyeye geçtin, yeni harfler açıldı.',
  ),
  reinforcePass(
    'v_reinforce_pass',
    'Testi geçtin! Önce zorlandığın harflere kısa bir bakış.',
  ),
  keepPracticing(
    'v_keep_practicing',
    'Biraz daha çalışalım. Birlikte yapabiliriz.',
  ),
  retest('v_retest', 'Şimdi karışık tekrarı bir daha deneyelim.'),
  allLearned(
    'v_all_learned',
    'Harika! Bütün harfleri öğrendin. Ustalık turları seni bekliyor.',
  ),
  dailyDone('v_daily_done', 'Günlük tekrarı bitirdin, aferin!'),
  gameDone('v_game_done', 'Tebrikler! Oyunu tamamladın.'),

  // "Nasıl oynanır?" — oyunun kimliğiyle ([howToGame]).
  howToDragDrop(
    'v_howto_drag_drop',
    'Sesli kartlara dokun ve sesi dinle. Sonra aynı sesi veren harfi tutup karta sürükle. İstersen önce harfe, sonra karta da dokunabilirsin.',
    howToGame: 'drag_drop',
  ),
  howToListenPick(
    'v_howto_listen_pick',
    'Önce sesi dinle. Sonra o sesi veren harfe dokun. Sesi tekrar duymak için hoparlöre bas.',
    howToGame: 'listen_pick',
  ),
  howToMemory(
    'v_howto_memory',
    'Önce kartlara iyi bak ve harfleri aklında tut. Kartlar kapanınca iki karta dokun. Aynı harfleri bulursan kartlar açık kalır.',
    howToGame: 'memory',
  ),
  howToBulPatlat(
    'v_howto_bul_patlat',
    'Sesi dinle. O harfin yazılı olduğu balonu bul ve dokunarak patlat. Balonlar uçup gitmeden yakala!',
    howToGame: 'bul_patlat',
  ),
  howToHarfArabalari(
    'v_howto_harf_arabalari',
    'Sesi dinle. O harfi taşıyan arabayı bul ve dokunarak yakala.',
    howToGame: 'harf_arabalari',
  ),
  howToHarfDedektifi(
    'v_howto_harf_dedektifi',
    'Büyük harfe bak ve sesini dinle. Sonra kartlarda aynı harfi bul ve dokun. Birden fazla olabilir, hepsini bul!',
    howToGame: 'harf_dedektifi',
  ),
  howToHarfTreni(
    'v_howto_harf_treni',
    'Üstteki harfe bak. Aynı harfi gösteren kartlara dokun, vagonlara yerleşsinler. Bütün vagonları doldur!',
    howToGame: 'harf_treni',
  ),
  howToHarfCiziyorum(
    'v_howto_harf_ciziyorum',
    'Önce harfin nasıl çizildiğini izle. Sonra yeşil noktadan başla ve parmağınla çizginin üstünden git.',
    howToGame: 'harf_ciziyorum',
  ),
  howToArapcaYaziyorum(
    'v_howto_arapca_yaziyorum',
    'Ekrandaki Arapça klavyede harflere dokun. Harfler kendiliğinden birleşir. Önce adını yazmayı dene!',
    howToGame: 'arapca_yaziyorum',
  );

  const TeacherLine(
    this.id,
    this.turkish, {
    this.polite = false,
    this.reused = false,
    this.howToGame,
  });

  /// Bu satır bir oyunun "Nasıl oynanır?" açıklamasıysa oyunun kimliği.
  final String? howToGame;

  /// [gameId] oyununun "Nasıl oynanır?" açıklaması (yoksa null).
  static TeacherLine? howToFor(String gameId) {
    for (final line in values) {
      if (line.howToGame == gameId) return line;
    }
    return null;
  }

  final String id;

  /// Türkçe metin (kaynak; çeviriler tool/i18n/teacher_lines.json).
  final String turkish;

  /// Nazik konuşma: bir ses çalarken söylenmez, sık tekrarlanmaz. Olay
  /// konuşmaları (tur başı, aşama, oyun sonu) çalanı keser.
  final bool polite;

  /// Başka bir sistemin var olan kaydı (yeni ses üretilmez).
  final bool reused;
}

/// Sesli öğretmen: olay konuşmalarını uygulamanın TEK oynatıcısında
/// ([AudioService]) çalar — iki konuşma asla üst üste binmez.
///
/// * Kapatılabilir (cihazda hatırlanır, `teacher_voice.enabled`).
/// * Dosyası olmayan konuşma sessizce atlanır (hata yok).
/// * Nazik konuşmalar: ses çalarken susar; aynı konuşma [repeatGap], herhangi
///   bir nazik konuşma [politeGap] içinde tekrar edilmez (hızlı cevaplarda
///   üst üste binmez).
/// * [repeatLast] son konuşmayı yeniden çalar.
class TeacherVoice extends ChangeNotifier {
  TeacherVoice({
    DateTime Function()? clock,
    this.repeatGap = const Duration(seconds: 6),
    this.politeGap = const Duration(milliseconds: 2500),
  }) : _clock = clock ?? DateTime.now;

  static const String prefsKey = 'teacher_voice.enabled';

  final DateTime Function() _clock;
  final Duration repeatGap;
  final Duration politeGap;

  bool _enabled = true;
  bool _loaded = false;
  String? _lastAsset;
  DateTime? _lastPolite;
  final _lastByLine = <TeacherLine, DateTime>{};

  bool get enabled => _enabled;
  bool get hasLast => _lastAsset != null;

  /// Ağaçta varsa servis (testlerde/ön izlemede olmayabilir: sessiz).
  static TeacherVoice? maybeOf(BuildContext context) {
    try {
      return Provider.of<TeacherVoice>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
  }

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(prefsKey) ?? true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setEnabled(bool value, {AudioService? audio}) async {
    if (_enabled == value) return;
    _enabled = value;
    if (!value && audio != null && _isTeacherAsset(audio.currentAsset)) {
      await audio.stop();
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefsKey, value);
    } catch (_) {}
  }

  static String assetFor(TeacherLine line, AppLanguage language) =>
      'audio/${language.code}/${line.id}.mp3';

  bool _isTeacherAsset(String? asset) =>
      asset != null && TeacherLine.values.any((l) => asset.endsWith('/${l.id}.mp3'));

  /// [line]'ı [language]'de söyler; [after] verilirse önce onlar çalar
  /// (ör. doğru sesi, sonra "Aferin"). Söylendiyse `true`.
  bool say(
    AudioService audio,
    AppLanguage language,
    TeacherLine line, {
    List<String> after = const [],
  }) {
    if (!_enabled) return false;
    final asset = assetFor(line, language);
    TurkishAudioCatalog.ensureLoaded();
    if (!TurkishAudioCatalog.available.value.contains(asset)) return false;
    final now = _clock();
    if (line.polite) {
      if (after.isEmpty && audio.isPlaying) return false;
      final last = _lastByLine[line];
      if (last != null && now.difference(last) < repeatGap) return false;
      if (_lastPolite != null && now.difference(_lastPolite!) < politeGap) {
        return false;
      }
      _lastPolite = now;
    }
    _lastByLine[line] = now;
    _lastAsset = asset;
    notifyListeners();
    if (after.isEmpty) {
      unawaited(audio.playAsset(asset));
    } else {
      unawaited(audio.playPlaylist([...after, asset]));
    }
    return true;
  }

  /// Çalan ses (ör. son harfin kaydı) bitince söyler; en çok [maxWait] bekler.
  void sayWhenQuiet(
    AudioService audio,
    AppLanguage language,
    TeacherLine line, {
    Duration maxWait = const Duration(seconds: 3),
  }) {
    if (!audio.isPlaying) {
      say(audio, language, line);
      return;
    }
    var done = false;
    Timer? timer;
    late final VoidCallback listener;
    void go() {
      if (done) return;
      done = true;
      audio.removeListener(listener);
      timer?.cancel();
      say(audio, language, line);
    }

    listener = () {
      if (!audio.isPlaying) go();
    };
    audio.addListener(listener);
    timer = Timer(maxWait, go);
  }

  /// Çocuk istedi (ör. "Nasıl oynanır?" düğmesi): kapalı olsa da çalar.
  bool play(AudioService audio, AppLanguage language, TeacherLine line) {
    final asset = assetFor(line, language);
    TurkishAudioCatalog.ensureLoaded();
    if (!TurkishAudioCatalog.available.value.contains(asset)) return false;
    _lastAsset = asset;
    notifyListeners();
    unawaited(audio.playAsset(asset));
    return true;
  }

  /// Oyunun ilk [introTimes] açılışında "Nasıl oynanır?" açıklamasını
  /// kendiliğinden okur (sonra yalnızca düğmeyle).
  static const int introTimes = 3;

  Future<bool> introduce(
    AudioService audio,
    AppLanguage language,
    String gameId,
  ) async {
    final line = TeacherLine.howToFor(gameId);
    if (line == null || !_enabled) return false;
    final key = 'teacher_voice.intro.$gameId';
    var count = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      count = prefs.getInt(key) ?? 0;
      if (count >= introTimes) return false;
      await prefs.setInt(key, count + 1);
    } catch (_) {}
    sayWhenQuiet(audio, language, line);
    return true;
  }

  /// Son konuşmayı yeniden çalar (kapalıyken de: çocuk kendisi istedi).
  void repeatLast(AudioService audio) {
    final asset = _lastAsset;
    if (asset != null) unawaited(audio.playAsset(asset));
  }

  @visibleForTesting
  void debugReset() {
    _lastAsset = null;
    _lastPolite = null;
    _lastByLine.clear();
  }
}

/// [context]'in dilinde söyler (servis yoksa sessiz).
bool teacherSay(
  BuildContext context,
  TeacherLine line, {
  List<String> after = const [],
}) {
  final voice = TeacherVoice.maybeOf(context);
  if (voice == null) return false;
  return voice.say(
    context.read<AudioService>(),
    context.language,
    line,
    after: after,
  );
}

/// [teacherSay] gibi, ama çalan ses bitince.
void teacherSayWhenQuiet(BuildContext context, TeacherLine line) {
  final voice = TeacherVoice.maybeOf(context);
  if (voice == null) return;
  voice.sayWhenQuiet(context.read<AudioService>(), context.language, line);
}

/// Oyun açılınca (ilk birkaç kez) nasıl oynandığını anlatır.
void teacherIntroduce(BuildContext context, String gameId) {
  final voice = TeacherVoice.maybeOf(context);
  if (voice == null) return;
  unawaited(
    voice.introduce(context.read<AudioService>(), context.language, gameId),
  );
}
