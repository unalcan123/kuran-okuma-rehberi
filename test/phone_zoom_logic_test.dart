import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/core/phone_zoom_logic.dart';

double zoom(num lw, num lh, num sw, num sh) => phoneZoomFor(
  layoutWidth: lw,
  layoutHeight: lh,
  screenWidth: sw,
  screenHeight: sh,
);

void main() {
  group('a normal phone is left alone', () {
    test('portrait', () => expect(zoom(393, 852, 393, 852), 1));

    test('landscape, screen size reported rotated', () {
      expect(zoom(852, 393, 852, 393), 1);
    });

    test('landscape, screen size reported UNROTATED (the reported bug)', () {
      // Some browsers keep screen.width = 393 even when held sideways.
      expect(zoom(852, 393, 393, 852), 1);
    });

    test('portrait, screen size reported rotated', () {
      expect(zoom(393, 852, 852, 393), 1);
    });

    test('small windows and address-bar changes', () {
      expect(zoom(393, 700, 393, 852), 1);
      expect(zoom(360, 640, 360, 800), 1);
      expect(zoom(412, 300, 412, 915), 1, reason: 'keyboard open');
    });

    test('a slightly shrunk page is not worth correcting', () {
      expect(zoom(980, 450, 852, 393), 1, reason: 'landscape desktop-site mode');
      expect(zoom(460, 900, 393, 852), 1);
    });
  });

  group('a phone showing a much too wide page is corrected', () {
    test('portrait, 880 px layout on a 393 px phone', () {
      expect(zoom(880, 1908, 393, 852), closeTo(880 / 393, 1e-9));
    });

    test('portrait "desktop site" (980 px)', () {
      expect(zoom(980, 2124, 393, 852), closeTo(980 / 393, 1e-9));
    });

    test('works whichever way the browser reports the screen', () {
      expect(zoom(880, 1908, 852, 393), closeTo(880 / 393, 1e-9));
    });

    test('landscape but laid out far too wide for a phone held sideways', () {
      // 1600 px for a 852 px-wide screen: ratio 1.88
      expect(zoom(1600, 720, 393, 852), closeTo(1600 / 852, 1e-9));
    });
  });

  group('never touches tablets and desktops', () {
    test('tablet', () {
      expect(zoom(820, 1180, 820, 1180), 1);
      expect(zoom(1180, 820, 820, 1180), 1);
      expect(zoom(1600, 2400, 820, 1180), 1, reason: 'short side >= 600');
    });

    test('desktop', () {
      expect(zoom(1280, 800, 1920, 1080), 1);
      expect(zoom(1920, 1080, 1920, 1080), 1);
    });

    test('a 600 px wide screen counts as a tablet', () {
      expect(zoom(1500, 2000, 600, 960), 1);
    });
  });

  test('bad numbers do nothing', () {
    expect(zoom(0, 0, 393, 852), 1);
    expect(zoom(880, 1908, 0, 0), 1);
  });
}
