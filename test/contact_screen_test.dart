// Ana sayfadan "Bize Ulaşın": resimli, açıklamalı sayfa; mesaj e-posta
// uygulamasında fluttercanpolat@gmail.com'a hazır açılır (resim orada eklenir).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/screens/home/home_screen.dart';
import 'package:kuran_okuma_rehberi/screens/iletisim/contact_screen.dart';

void setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  test('e-posta adresi ve mailto bağlantısı', () {
    expect(kContactEmail, 'fluttercanpolat@gmail.com');
    final uri = contactMailUri(
      topic: 'Öneri',
      name: 'Ali',
      message: 'Çok güzel bir uygulama',
    );
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'fluttercanpolat@gmail.com');
    final params = Uri.splitQueryString(uri.query);
    expect(params['subject'], "Kur'an Okuma Rehberi – Öneri");
    expect(params['body'], contains('Çok güzel bir uygulama'));
    expect(params['body'], contains('— Ali'));
    expect(uri.query, isNot(contains('+'))); // boşluklar %20
  });

  testWidgets('ana sayfadan açılır; resimli ve yazılı', (tester) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    final entry = find.byKey(const ValueKey('home-contact'));
    await tester.scrollUntilVisible(
      entry,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(ContactScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('contact-picture')), findsOneWidget);
    expect(find.text(kContactEmail), findsOneWidget);
    expect(find.textContaining('resim veya'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(360, 640), Size(1280, 800)]) {
    testWidgets('$size: form e-postayı hazır açar, taşma yok', (tester) async {
      setSize(tester, size);
      Uri? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: ContactScreen(
            launcher: (uri) async {
              opened = uri;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<Finder> reach(String key) async {
        final f = find.byKey(ValueKey(key));
        await tester.scrollUntilVisible(
          f,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        return f;
      }

      await tester.tap(await reach('contact-topic-Hata bildirimi'));
      await tester.pump();
      await tester.enterText(await reach('contact-name'), 'Ayşe');
      await tester.enterText(await reach('contact-message'), 'Ses gelmiyor');
      final send = find.byKey(const ValueKey('contact-send'));
      await tester.scrollUntilVisible(
        send,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(opened?.path, kContactEmail);
      final params = Uri.splitQueryString(opened!.query);
      expect(params['subject'], contains('Hata bildirimi'));
      expect(params['body'], contains('Ses gelmiyor'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('e-posta uygulaması yoksa adres kopyalanır ve söylenir', (
    tester,
  ) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(home: ContactScreen(launcher: (_) async => false)),
    );
    await tester.pumpAndSettle();
    final send = find.byKey(const ValueKey('contact-send'));
    await tester.scrollUntilVisible(
      send,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(send);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Adres kopyalandı'), findsOneWidget);
  });
}
