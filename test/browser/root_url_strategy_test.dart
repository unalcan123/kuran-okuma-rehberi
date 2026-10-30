@TestOn('browser')
library;

import 'dart:ui_web' as ui_web;
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/core/web_url_web.dart';

class FakeLocation implements ui_web.PlatformLocation {
  String _hash = '#/ders/2';
  Object? _state;
  String? writtenUrl;
  @override
  String get hash => _hash;
  @override
  String get pathname => '/';
  @override
  String get search => '';
  @override
  Object? get state => _state;
  @override
  String getBaseHref() => '/';
  @override
  void pushState(Object? state, String title, String url) {
    _state = state;
    writtenUrl = url;
    _hash = '';
  }

  @override
  void replaceState(Object? state, String title, String url) =>
      pushState(state, title, url);
  @override
  void addPopStateListener(ui_web.EventListener fn) {}
  @override
  void removePopStateListener(ui_web.EventListener fn) {}
  @override
  void go(int count) {}
}

void main() {
  test('Existing lesson links still open while every visible URL is root', () {
    final location = FakeLocation();
    final strategy = RootUrlStrategy(location);
    expect(strategy.getPath(), '/ders/2');
    strategy.replaceState({'origin': true}, 'origin', '');
    expect(location.writtenUrl, '/');
    expect(strategy.getPath(), '/ders/2');
    for (final path in ['/ders/1', '/sure/fatiha', '/dualar', '/gizlilik']) {
      strategy.replaceState({'flutter': true}, 'flutter', path);
      expect(location.writtenUrl, '/');
      expect(strategy.getPath(), path);
      expect(location.state, {'flutter': true});
    }
  });
}
