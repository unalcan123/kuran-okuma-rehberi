import 'package:web/web.dart' as web;

void updateWebMetadata(String code, String title) {
  web.document.documentElement?.setAttribute('lang', code);
  web.document.documentElement?.setAttribute('dir', 'ltr');
  web.document.title = title;
}
