import 'dart:ui_web' as ui_web;

/// Keep lesson/surah navigation internal while retaining browser Back.
void configureWebUrl() {
  ui_web.urlStrategy = RootUrlStrategy();
}

class RootUrlStrategy extends ui_web.HashUrlStrategy {
  RootUrlStrategy([super.location = const ui_web.BrowserPlatformLocation()])
    : _location = location {
    _path = super.getPath();
  }

  final ui_web.PlatformLocation _location;
  late String _path;

  @override
  String getPath() {
    // Accept existing shared links, including a hash entered while running.
    final visible = super.getPath();
    return visible == '/' ? _path : visible;
  }

  @override
  String prepareExternalUrl(String internalUrl) =>
      '${_location.pathname}${_location.search}';

  @override
  void pushState(Object? state, String title, String url) {
    if (url.isNotEmpty) _path = url;
    super.pushState(state, title, url);
  }

  @override
  void replaceState(Object? state, String title, String url) {
    // Flutter's origin-entry setup uses an empty URL. Preserve the incoming
    // deep link before the visible hash is removed by that setup.
    if (url.isNotEmpty) _path = url;
    super.replaceState(state, title, url);
  }
}
