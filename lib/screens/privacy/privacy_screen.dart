import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';

const _texts = <String, List<String>>{
  "tr": [
    "Gizlilik ve Hakkında",
    "Elifbe.nl · Kur’an Okuma Rehberi",
    "Dil, okuma ayarları, oyuncu profilleri ve oyun ilerlemesi bu cihazda saklanır. Tarayıcı verilerini temizlemek bu yerel kayıtları silebilir.",
    "Çevrimiçi sıralama Google Firebase kullanır. Anonim bir hesap kimliği, takma ad, oyun puanları ve zaman bilgileri sunucuya gönderilir. Takma ad ve en iyi puanlar diğer oyunculara gösterilebilir. Gerçek adını veya iletişim bilgilerini takma ad olarak kullanma.",
    "Öğrenme ilerlemesinin bir kopyası Firebase üzerinden saklanabilir. Uygulamada Firebase Analytics veya reklam izleme aracı kurulmamıştır. İçerik ve meal kaynakları ana ekrandaki Kaynaklar bölümündedir. Veriyle ilgili sorular için Bize Ulaşın bölümünü kullan.",
  ],
  "en": [
    "Privacy and About",
    "Elifbe.nl · Quran Reading Guide",
    "Language, reading settings, player profiles and game progress are stored on this device. Clearing browser data may remove these local records.",
    "The online leaderboard uses Google Firebase. An anonymous account identifier, nickname, game scores and timestamps are sent to the server. Nicknames and best scores may be visible to other players. Do not use your real name or contact details as a nickname.",
    "A copy of learning progress may be stored through Firebase. The app does not include Firebase Analytics or advertising trackers. Content and translation credits are in Sources on the home screen. For data questions, use Contact Us.",
  ],
  "nl": [
    "Privacy en over deze app",
    "Elifbe.nl · Koran leren lezen",
    "Taal, leesinstellingen, spelersprofielen en spelvoortgang worden op dit apparaat opgeslagen. Het wissen van browsergegevens kan deze lokale gegevens verwijderen.",
    "Het online klassement gebruikt Google Firebase. Een anonieme accountcode, bijnaam, scores en tijdstippen worden naar de server verstuurd. Bijnamen en beste scores kunnen zichtbaar zijn voor andere spelers. Gebruik geen echte naam of contactgegevens als bijnaam.",
    "Een kopie van de leervoortgang kan via Firebase worden opgeslagen. De app bevat geen Firebase Analytics of advertentietrackers. Bronnen en vertaalgegevens staan onder Bronnen op het startscherm. Gebruik Neem contact op voor vragen over gegevens.",
  ],
  "de": [
    "Datenschutz und Über diese App",
    "Elifbe.nl · Koran lesen lernen",
    "Sprache, Leseeinstellungen, Spielerprofile und Spielfortschritt werden auf diesem Gerät gespeichert. Das Löschen von Browserdaten kann diese lokalen Daten entfernen.",
    "Die Online-Rangliste verwendet Google Firebase. Eine anonyme Kontokennung, Spitzname, Spielpunkte und Zeitangaben werden an den Server gesendet. Spitznamen und Bestwerte können anderen Spielern angezeigt werden. Verwende keinen echten Namen oder Kontaktdaten als Spitznamen.",
    "Eine Kopie des Lernfortschritts kann über Firebase gespeichert werden. Die App enthält weder Firebase Analytics noch Werbetracker. Inhalts- und Übersetzungsquellen stehen unter Quellen auf der Startseite. Bei Fragen zu Daten nutze Kontakt.",
  ],
  "fr": [
    "Confidentialité et à propos",
    "Elifbe.nl · Apprendre à lire le Coran",
    "La langue, les réglages de lecture, les profils et la progression sont conservés sur cet appareil. Effacer les données du navigateur peut supprimer ces données locales.",
    "Le classement en ligne utilise Google Firebase. Un identifiant de compte anonyme, un pseudonyme, des scores et des dates sont envoyés au serveur. Les pseudonymes et meilleurs scores peuvent être visibles par les autres joueurs. Ne choisis pas ton vrai nom ou tes coordonnées comme pseudonyme.",
    "Une copie de la progression peut être conservée via Firebase. L’application ne contient ni Firebase Analytics ni outils de suivi publicitaire. Les références sont dans Sources sur l’accueil. Pour toute question sur les données, utilise Nous contacter.",
  ],
  "es": [
    "Privacidad y acerca de",
    "Elifbe.nl · Guía de lectura del Corán",
    "El idioma, los ajustes de lectura, los perfiles y el progreso se guardan en este dispositivo. Borrar los datos del navegador puede eliminar estos registros locales.",
    "La clasificación en línea utiliza Google Firebase. Se envían al servidor un identificador anónimo, un apodo, las puntuaciones y las fechas. Los apodos y mejores puntuaciones pueden ser visibles para otros jugadores. No uses tu nombre real ni datos de contacto como apodo.",
    "Una copia del progreso puede guardarse mediante Firebase. La aplicación no incluye Firebase Analytics ni rastreadores publicitarios. Las referencias están en Fuentes en la pantalla de inicio. Para preguntas sobre tus datos, utiliza Contacto.",
  ],
  "bs": [
    "Privatnost i o aplikaciji",
    "Elifbe.nl · Vodič za učenje Kur’ana",
    "Jezik, postavke čitanja, profili igrača i napredak čuvaju se na ovom uređaju. Brisanje podataka preglednika može ukloniti ove lokalne zapise.",
    "Online rang-lista koristi Google Firebase. Anonimni identifikator računa, nadimak, bodovi i vrijeme šalju se na server. Nadimci i najbolji rezultati mogu biti vidljivi drugim igračima. Ne koristi pravo ime ili kontakt podatke kao nadimak.",
    "Kopija napretka može se čuvati putem Firebasea. Aplikacija ne sadrži Firebase Analytics ni alate za praćenje oglasa. Izvori sadržaja i prijevoda nalaze se u odjeljku Izvori na početnom ekranu. Za pitanja o podacima koristi Kontakt.",
  ],
};

class PrivacyEntry extends StatelessWidget {
  const PrivacyEntry({super.key});
  @override
  Widget build(BuildContext context) => TextButton.icon(
    key: const ValueKey('home-privacy'),
    icon: const Icon(Icons.privacy_tip_outlined),
    label: Text(_texts[context.language.code]!.first),
    onPressed:
        () => Navigator.of(context).push(
          MaterialPageRoute(
            settings: const RouteSettings(name: '/gizlilik'),
            builder: (_) => const PrivacyScreen(),
          ),
        ),
  );
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final text = _texts[context.language.code]!;
    return Scaffold(
      appBar: AppBar(title: Text(text.first)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(text[1], style: Theme.of(context).textTheme.titleLarge),
              for (final paragraph in text.skip(2))
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    paragraph,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
